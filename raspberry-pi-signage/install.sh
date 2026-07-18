#!/usr/bin/env bash
set -euo pipefail

no_boot_config=0
no_apple_ca=0
for arg in "$@"; do
  case "$arg" in
    --no-boot-config)
      no_boot_config=1
      ;;
    --no-apple-ca)
      no_apple_ca=1
      ;;
    -h|--help)
      printf 'Usage: sudo ./install.sh [--no-boot-config] [--no-apple-ca]\n'
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

if [[ "$(uname -s)" != "Linux" ]] || ! command -v apt-get >/dev/null 2>&1; then
  printf 'This installer targets Raspberry Pi OS (Bookworm/Trixie) or another Linux system with apt.\n' >&2
  exit 1
fi

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  printf 'Run this installer with sudo.\n' >&2
  exit 1
fi

AERIAL_USER="${AERIAL_USER:-${SUDO_USER:-pi}}"
if ! id "$AERIAL_USER" >/dev/null 2>&1; then
  printf 'User does not exist: %s\n' "$AERIAL_USER" >&2
  exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
install_dir="/opt/aerial-signage"
config_dir="/etc/aerial-signage"
state_dir="/var/lib/aerial-signage"
video_dir="$state_dir/videos"

tmp_files=()
cleanup() {
  local tmp
  for tmp in ${tmp_files[@]+"${tmp_files[@]}"}; do
    rm -f -- "$tmp"
  done
}
trap cleanup EXIT

render_unit() {
  local source_file="$1"
  local target_file="$2"
  local tmp_file
  tmp_file="$(mktemp)"
  tmp_files+=("$tmp_file")
  awk -v user="$AERIAL_USER" '{ gsub(/__AERIAL_USER__/, user); print }' "$source_file" > "$tmp_file"
  install -m 0644 "$tmp_file" "$target_file"
}

install_apple_root_ca() {
  # The default video source (sylvan.apple.com) is signed by Apple's private
  # root CA, which is NOT in the Linux trust store, so downloads fail with
  # "unable to get local issuer certificate". Install that root (published by
  # Apple, fetched over a public-CA-verified connection, pinned by SHA-256) so
  # aerial-fetch can verify Apple's CDN. Harmless when the community manifest
  # is used instead. Skipped by --no-apple-ca or if already installed.
  local dest="/usr/local/share/ca-certificates/apple-root-ca.crt"
  local url="https://www.apple.com/appleca/AppleIncRootCertificate.cer"
  local expect="B0B1730ECBC7FF4505142C49F1295E6EDA6BCAED7E2C68C5BE91B5A11001F024"
  if [[ -f "$dest" ]]; then
    printf 'Apple Root CA already present.\n'
    return 0
  fi
  local der pem got
  der="$(mktemp)"; pem="$(mktemp)"; tmp_files+=("$der" "$pem")
  if ! curl -fsSL --max-time 30 -o "$der" "$url"; then
    printf 'warning: could not download Apple Root CA; Apple-hosted videos will fail to verify.\n' >&2
    printf '         Re-run installer online, or set AERIAL_MANIFEST_URL to the community manifest.\n' >&2
    return 0
  fi
  openssl x509 -inform DER -in "$der" -out "$pem" 2>/dev/null || {
    printf 'warning: Apple Root CA did not parse as a certificate; skipping.\n' >&2
    return 0
  }
  got="$(openssl x509 -in "$pem" -noout -fingerprint -sha256 | sed 's/.*=//; s/://g')"
  if [[ "$got" != "$expect" ]]; then
    printf 'warning: Apple Root CA SHA-256 mismatch (got %s); not installing.\n' "$got" >&2
    return 0
  fi
  install -m 0644 "$pem" "$dest"
  update-ca-certificates >/dev/null
  printf 'Installed Apple Root CA (SHA-256 verified).\n'
}

printf 'Installing mpv and dependencies...\n'
apt-get update
apt-get install -y mpv python3 ca-certificates openssl curl

if [[ "$no_apple_ca" -eq 0 ]]; then
  install_apple_root_ca
fi

printf 'Installing files to %s...\n' "$install_dir"
install -d -m 0755 "$install_dir"
cp -a "$script_dir/bin" "$script_dir/lua" "$script_dir/manifest" "$install_dir/"
# Drop any __pycache__ that a local test run may have left in bin/.
find "$install_dir" -type d -name __pycache__ -prune -exec rm -rf {} +
# cp -a preserves the invoking user's ownership. The fetch timer executes this
# code, so it must be root-owned and not writable by the signage user.
chown -R root:root "$install_dir"
chmod -R go-w "$install_dir"
chmod +x "$install_dir"/bin/*

printf 'Preparing state and config directories...\n'
install -d -m 0755 "$state_dir"
install -d -m 0755 "$video_dir"
chown -R "$AERIAL_USER:$AERIAL_USER" "$state_dir"
install -d -m 0755 "$config_dir"
if [[ ! -f "$config_dir/aerial-signage.conf" ]]; then
  install -m 0644 "$script_dir/config/aerial-signage.conf.example" "$config_dir/aerial-signage.conf"
fi

group_csv=""
for group in video render input tty; do
  if getent group "$group" >/dev/null 2>&1; then
    if [[ -n "$group_csv" ]]; then
      group_csv+=","
    fi
    group_csv+="$group"
  fi
done
if [[ -n "$group_csv" ]]; then
  usermod -aG "$group_csv" "$AERIAL_USER"
fi

printf 'Installing systemd units...\n'
render_unit "$script_dir/systemd/aerial-signage.service" "/etc/systemd/system/aerial-signage.service"
render_unit "$script_dir/systemd/aerial-fetch.service" "/etc/systemd/system/aerial-fetch.service"
install -m 0644 "$script_dir/systemd/aerial-fetch.timer" "/etc/systemd/system/aerial-fetch.timer"
systemctl daemon-reload
systemctl enable aerial-signage.service aerial-fetch.timer

if [[ "$no_boot_config" -eq 0 ]] && command -v raspi-config >/dev/null 2>&1; then
  printf 'Configuring boot-to-console via raspi-config...\n'
  raspi-config nonint do_boot_behaviour B2
fi

cat <<EOF
aerial-signage installed.

Next steps:
  1. Edit /etc/aerial-signage/aerial-signage.conf, especially AERIAL_CLOCK_OFFSET_MINUTES.
  2. Fetch initial videos:
     sudo -u "$AERIAL_USER" AERIAL_CONFIG=/etc/aerial-signage/aerial-signage.conf /opt/aerial-signage/bin/aerial-fetch --limit 10
  3. Reboot to start the kiosk on tty1:
     sudo reboot
EOF

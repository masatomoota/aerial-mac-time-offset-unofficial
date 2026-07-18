#!/usr/bin/env bash
set -euo pipefail

no_boot_config=0
for arg in "$@"; do
  case "$arg" in
    --no-boot-config)
      no_boot_config=1
      ;;
    -h|--help)
      printf 'Usage: sudo ./install.sh [--no-boot-config]\n'
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

if [[ "$(uname -s)" != "Linux" ]] || ! command -v apt-get >/dev/null 2>&1; then
  printf 'This installer targets Raspberry Pi OS Bookworm or another Linux system with apt.\n' >&2
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

printf 'Installing mpv and python3...\n'
apt-get update
apt-get install -y mpv python3

printf 'Installing files to %s...\n' "$install_dir"
install -d -m 0755 "$install_dir"
cp -a "$script_dir/bin" "$script_dir/lua" "$script_dir/manifest" "$install_dir/"
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

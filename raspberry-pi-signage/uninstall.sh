#!/usr/bin/env bash
set -euo pipefail

purge=0
for arg in "$@"; do
  case "$arg" in
    --purge)
      purge=1
      ;;
    -h|--help)
      printf 'Usage: sudo ./uninstall.sh [--purge]\n'
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  printf 'Run this uninstaller with sudo.\n' >&2
  exit 1
fi

if command -v systemctl >/dev/null 2>&1; then
  systemctl disable --now aerial-signage.service >/dev/null 2>&1 || true
  systemctl disable --now aerial-fetch.timer >/dev/null 2>&1 || true
  systemctl disable --now aerial-web.service >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/aerial-signage.service
  rm -f /etc/systemd/system/aerial-fetch.service
  rm -f /etc/systemd/system/aerial-fetch.timer
  rm -f /etc/systemd/system/aerial-web.service
  systemctl daemon-reload
  systemctl reset-failed aerial-signage.service aerial-fetch.service aerial-fetch.timer aerial-web.service >/dev/null 2>&1 || true
fi

rm -rf /opt/aerial-signage

if [[ "$purge" -eq 1 ]]; then
  rm -rf /etc/aerial-signage
  rm -rf /var/lib/aerial-signage
  printf 'aerial-signage removed, including config and cached videos.\n'
else
  printf 'aerial-signage removed. Config and cached videos were kept.\n'
  printf 'Use --purge to also remove /etc/aerial-signage and /var/lib/aerial-signage.\n'
fi

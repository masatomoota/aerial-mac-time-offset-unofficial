# Handoff — Raspberry Pi Aerial Digital Signage

## Summary

Added a **Linux / Raspberry Pi 4-5 digital-signage player** to this fork under
[`raspberry-pi-signage/`](../raspberry-pi-signage/). It loops Apple Aerial videos fullscreen with a
configurable **offset clock** overlay, faithfully reproducing this fork's signature macOS feature
(`AERIAL_CLOCK_OFFSET_MINUTES`, default +10 min). The macOS Xcode project is untouched — the Pi
player is a self-contained sibling.

- **Branch:** `feature/raspberry-pi-signage` (created from clean `master`).
- **Player stack:** `mpv` fullscreen kiosk on Raspberry Pi OS Bookworm, booted to console, owning
  DRM/KMS, HEVC hardware-decoded, driven by systemd with `Restart=always`. Clock overlay is an mpv
  Lua OSD script. The macOS AppKit/ScreenSaver stack does not exist on Linux, so we reproduced the
  behavior rather than porting the Swift code.
- **Why this design / all research:** see
  [`raspberry-pi-signage/docs/DESIGN_AND_RESEARCH.md`](../raspberry-pi-signage/docs/DESIGN_AND_RESEARCH.md)
  and [`raspberry-pi-signage/docs/linux-aerial-repo-analysis.md`](../raspberry-pi-signage/docs/linux-aerial-repo-analysis.md).

## File map (all under `raspberry-pi-signage/`)

| Path | Purpose |
| --- | --- |
| `bin/aerial-fetch` | Python 3 (stdlib only). Loads a JSON aerial manifest, selects a URL variant by `AERIAL_QUALITY`, downloads `.mov` files to the cache (atomic writes, retries, resumable, `--limit`), writes an mpv playlist. Has `--dry-run` and `--print-manifest`. Falls back to the bundled manifest if the remote is unreachable. |
| `bin/aerial-signage` | Bash launcher. Sources the config, applies defaults, exports `AERIAL_CLOCK_*`, execs `mpv` with kiosk + `hwdec=drm-copy` flags + the Lua script + the playlist. Errors clearly if the playlist is empty. |
| `lua/aerial_clock.lua` | **Pure** module (no mpv deps, unit-testable): `format_time(now_epoch,cfg)`, `alignment_for(corner)`, `rgb_to_ass_bgr(rrggbb)`, `offset_minutes_from_env(raw)` (defaults to 10, mirroring macOS). |
| `lua/clock-overlay.lua` | mpv glue. Reads config from env, `require`s `aerial_clock`, draws the clock every second via `mp.create_osd_overlay` (ASS). Robust: wrapped in pcall, never crashes mpv. |
| `config/aerial-signage.conf.example` | All settings + comments + defaults. Installed to `/etc/aerial-signage/aerial-signage.conf`. |
| `systemd/aerial-signage.service` | Main kiosk service (tty1, DRM, `Restart=always`). `__AERIAL_USER__` is substituted by the installer. |
| `systemd/aerial-fetch.service` + `.timer` | Weekly video-cache refresh (oneshot + timer). |
| `manifest/entries.json` | Bundled offline fallback = the real Apple set (63 entries, `sylvan.apple.com` HEVC URLs). |
| `install.sh` / `uninstall.sh` | Pi installer/uninstaller: apt-installs `mpv`, lays out `/opt/aerial-signage`, `/etc/aerial-signage`, `/var/lib/aerial-signage`, adds the user to `video render input tty`, installs+enables units, and (unless `--no-boot-config`) sets boot-to-console via `raspi-config`. |
| `tests/test_aerial_clock.lua`, `tests/test_fetch.py` | Unit tests for the clock logic and the fetcher's manifest-parse/variant-selection. |
| `README.md` / `README.ja.md` | User docs (install, full config table, troubleshooting, video source). |

## Configuration contract (env vars = config keys)

Clock: `AERIAL_CLOCK_ENABLED`, **`AERIAL_CLOCK_OFFSET_MINUTES`** (default 10, negative OK),
`AERIAL_CLOCK_FORMAT` (24h|12h|custom), `AERIAL_CLOCK_SECONDS`, `AERIAL_CLOCK_HIDE_AMPM`,
`AERIAL_CLOCK_CUSTOM_FORMAT` (strftime), `AERIAL_CLOCK_CORNER`
(topLeft|topRight|bottomLeft|bottomRight|center), `AERIAL_CLOCK_FONT_SIZE`, `AERIAL_CLOCK_FONT`,
`AERIAL_CLOCK_MARGIN`, `AERIAL_CLOCK_COLOR` (RRGGBB).
Video: `AERIAL_QUALITY` (1080-sdr default; 1080-hdr|4k-sdr|4k-hdr|1080-h264), `AERIAL_MANIFEST_URL`,
`AERIAL_CACHE_DIR`, `AERIAL_PLAYLIST`, `AERIAL_VIDEO_LIMIT`, `AERIAL_SHUFFLE`.
mpv: `AERIAL_MPV_VO` (gpu), `AERIAL_MPV_GPU_CONTEXT` (drm; `auto` for desktop test), `AERIAL_MPV_HWDEC`
(drm-copy; `auto` for desktop test), `AERIAL_MPV_EXTRA`.

## Key verified facts (don't re-derive)

- **Both Pi 4 and Pi 5 hardware-decode 4K HEVC.** Pi 5 has **no H.264 hardware decode**; Pi 4 caps
  H.264 HW decode at 1080p. => HEVC is the default. (Verified against official Raspberry Pi specs.)
- **Chromium on Pi cannot HW-decode HEVC** → the browser-kiosk approach was rejected; mpv is used.
- Default manifest = Apple set via `kopiro/xscreensaver-apple-aerial` mirror →
  `sylvan.apple.com` HEVC `.mov` (63 videos, ~265–354 MB each). Verified live (HTTP 200/206). If Apple
  changes URLs, switch `AERIAL_MANIFEST_URL` to `glouel/AerialCommunity` (GitHub-hosted, stable).

## Verification already done (on macOS dev machine — see DESIGN_AND_RESEARCH.md §Verification)

All green: `luac -p`, `lua tests/test_aerial_clock.lua`, `python3 -m py_compile bin/aerial-fetch`,
`python3 tests/test_fetch.py`, `bash -n`, `shellcheck`; live manifest fetch + dry-run selection;
real `.mov` downloads with atomic writes + playlist; Apple CDN accepts our client (HTTP 206). Most
important: the **actual `clock-overlay.lua` ran under real mpv v0.41 against a real aerial clip** and
produced the correct offset time (`now + 125 min`) — the signature feature works end-to-end.

## NEXT STEPS — must be validated on real Pi hardware (not possible on macOS)

1. **On a Pi 4 and Pi 5** (Raspberry Pi OS Bookworm 64-bit): `cd raspberry-pi-signage && sudo ./install.sh`,
   then `sudo -u <user> AERIAL_CONFIG=/etc/aerial-signage/aerial-signage.conf /opt/aerial-signage/bin/aerial-fetch --limit 3`,
   then `sudo reboot`. Confirm the aerial loop + offset clock appear on tty1.
2. **HEVC hardware decode**: confirm `--hwdec=drm-copy` actually engages (no dropped frames / high CPU).
   If not, try `AERIAL_MPV_HWDEC=v4l2m2m-copy` and check `/dev/video19` (`rpivid`) exists.
3. **DRM/KMS ownership from systemd**: the most likely tuning point. If the screen is black at boot,
   the `aerial-signage.service` may need `Conflicts=getty@tty1.service` and/or an autologin-on-tty1 +
   systemd *user* service. Validate and adjust `systemd/aerial-signage.service`.
4. **Full-size Apple downloads** over the real network; then drop `--limit` for the full set.
5. Optional: 4K panels → set `AERIAL_QUALITY=4k-sdr`.

## Tooling / environment notes for the next session

- **codex CLI** was used for the mechanical implementation (to save Claude quota). Its shell was
  broken (`/opt/homebrew/bin/codex-code-mode-host` missing); fixed with a symlink to
  `/Applications/ChatGPT.app/Contents/Resources/codex-code-mode-host`. codex runs were:
  `codex exec --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check -C <dir> "<prompt>"`.
- `mpv` was `brew install`ed on the dev mac only for the integration test (not required by the repo).
- `.gitignore` gained `__pycache__/` and `*.pyc`.

## Deploy note

This repo has **no `deploy.sh`** and this is a Pi-targeted deliverable. "Deploy" here = pushing to
GitHub (done) so any Pi can `git pull` and run `raspberry-pi-signage/install.sh`. There is no cloud
service to deploy to and no Pi attached to the dev machine.

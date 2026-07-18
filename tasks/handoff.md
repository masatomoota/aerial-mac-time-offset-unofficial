# Handoff — Raspberry Pi Aerial Digital Signage

## Session 4 (2026-07-18 PM): playback fix, Web UI, tvOS16/Sea catalog — CURRENT STATE

**Playback saga (Pi 4 + 4K TV, Trixie, mpv 0.40) — root causes found by measurement:**
1st symptom 3fps+haze: drm-copy CPU-copies tiled 10-bit HEVC → switched to zero-copy. 2nd: vo=gpu
renderer caps ~15-22fps presents (est-display-fps proved it). 3rd: gpu-next renders SAND 10-bit as
solid purple. 4th: even H.264 dropped frames — **real culprit: mpv default shaders too heavy for
V3D; `--profile=fast` lifts present rate to 55-60fps**. Final known-good config (0 drops, in README
"Performance tuning"): `1080-h264 + strict + vo=gpu-next + hwdec=no + --drm-mode=1920x1080
--video-sync=display-resample --profile=fast` (hwdec=v4l2m2m-copy also OK, slightly more jitter;
swdec ≈1.2 cores CPU). User confirmed motion improved; final visual sign-off of smoothness+haze
still pending on-site. If haze persists: A/B `--video-output-levels` and TV "HDMI black level".

**Web UI (`bin/aerial-web`, port 8080, systemd aerial-web.service, runs as root, optional
AERIAL_WEB_TOKEN):** Mac-app-equivalent SPA (dark theme) — scenes/videos with hide toggles,
source picker, quality/strict/shuffle/limit, 4 overlay panels, status (mpv IPC stats), Save&Apply/
Fetch/Restart/Reboot. Config writes validated against launcher grammar. APIs: /api/state,
/api/videos, /api/save, /api/fetch, /api/player/restart, /api/reboot.

**tvOS 16 catalog:** sources.json id=tvos16 → verified raw mirror (gist theothernt, byte-identical
to Apple resources-16.tar). Bundled fallback manifest/entries-tvos16.json. scene_map.json maps
Apple category UUIDs→scenes (Underwater→sea 21, Landscapes→nature 41, Cities→city 30, Space 22;
all 114 entries have LIVE url-1080-H264 — verified individually). aerial-fetch: AERIAL_SOURCE/
AERIAL_SCENES/AERIAL_HIDDEN_VIDEOS, labels.tsv sidecar, --list-videos.

**Multi-overlay lua:** message/clock/date/location layers, per-corner stacking; defaults = user's
macOS screenshots (clock bottomLeft 50 24h; date bottomLeft 25 ja textual; location topRight 28,
label from labels.tsv per video; message bottomRight 24 = booth Wi-Fi text "Studio Vibes Wi-Fi /
SSID : fcm-dkym-booth / PW : dkymfcm117").

**Device (dkym-booth-aerial, 172.16.30.70, Pi 4 8GB, Trixie):** deployed via rsync + install.sh;
aerial-web active (HTTP 200, APIs verified: 114 videos, correct scene counts); device conf:
source=tvos16, scenes=nature,city,sea (92 videos), quality=1080-h264 strict, clock offset 0,
clock bottomLeft 50. tvOS16 H.264 fetch (~29GB) was RUNNING in background at session end —
after it finishes: `sudo systemctl restart aerial-signage.service` to pick up the new playlist
+ labels, then verify overlays on the display. Old classic63 cache files (HEVC+H264, ~25GB)
remain in /var/lib/aerial-signage/videos and can be pruned if disk is needed.

**Repo state:** all of the above committed & pushed (master = feature/raspberry-pi-signage).
Older session notes follow below.

> **Update (2026-07-18, second session):** After the initial release, a Pi 3 compatibility mode and
> a full multi-agent bug review + fixes were added. See "Session 2: Pi 3 support & bug review"
> below. The original handoff follows it and remains accurate except where noted.
>
> **Update (2026-07-18, third session):** First real-hardware deployment to a Pi 4. See
> "Session 3: Live deploy" immediately below — it includes the one thing that only surfaced on real
> hardware (the Apple Root CA trust issue) and the exact device state.

## Session 3: Live deploy to a real Pi 4 (dkym-booth-aerial)

Target device (destined for a 代官山/Daikanyama booth):
- Raspberry Pi 4 Model B, 8 GB RAM, 116 GB SD (plenty free).
- **Raspberry Pi OS = Debian 13 "Trixie"**, 64-bit, **Lite** (console/`multi-user.target`), mpv
  **0.40.0**, python 3.13, systemd, passwordless sudo. Reached over wired SSH at `172.16.30.70`
  (mDNS `dkym-booth-aerial.local`), user `masatomo`, key auth. Wi-Fi (`dkym` SSID) preconfigured for
  the booth; deployed over wired at home.

What was validated ON HARDWARE (works):
- `install.sh` on Trixie: installs mpv, lays out /opt (root-owned), /etc, /var/lib, renders both
  units with `User=masatomo`, enables services, boot-to-console via raspi-config.
- **HEVC hardware decode confirmed**: `mpv --hwdec=drm-copy` → `Using hardware decoding (drm-copy)`,
  driving the rpivid stateless decoder (`/dev/video19`, `Hwaccel V4L2 HEVC stateless`). Our default
  `AERIAL_MPV_HWDEC=drm-copy` is correct on Trixie/mpv 0.40. (`v4l2m2m-copy` does NOT work for HEVC —
  it's the H.264 path; leave HEVC on `drm-copy`.)
- Clock overlay runs under mpv 0.40 (`create_osd_overlay` OK) and shows correct time.
- python fetcher tests pass under python 3.13.
- Config set: **`AERIAL_CLOCK_OFFSET_MINUTES=0`** (booth shows real time — the user's choice), 24h,
  bottomRight.
- Full 63-video Apple set fetched to `/var/lib/aerial-signage/videos` so the booth plays
  **fully offline** (no network needed at the venue; Wi-Fi only for the optional weekly refresh).

**THE hardware-only gotcha — Apple Root CA (now fixed in code):**
`sylvan.apple.com` is signed by Apple's *private* root CA (chain: leaf ← Apple Server Authentication
CA ← **Apple Root CA**). That root ships on Apple OSes but is NOT in the Debian/Linux trust store, so
`aerial-fetch` initially failed every download with `CERTIFICATE_VERIFY_FAILED: unable to get local
issuer certificate` (curl failed too — not our bug). Fix (committed): `install.sh` now installs the
Apple Root CA — downloaded from `https://www.apple.com/appleca/AppleIncRootCertificate.cer` over a
public-CA-verified connection and pinned to SHA-256
`B0B1730ECBC7FF4505142C49F1295E6EDA6BCAED7E2C68C5BE91B5A11001F024` — into
`/usr/local/share/ca-certificates/` + `update-ca-certificates`. `--no-apple-ca` skips it; the
community manifest avoids the need entirely. (On the live Pi this was applied manually first, then
baked into install.sh, so a fresh install now handles it automatically.)

Still NOT done (needs the physical display, which was disconnected during setup):
- On-screen output was never seen — HDMI was unplugged (setup done headless over SSH). The kiosk
  service is **enabled but intentionally not started** (starting it with no connected display would
  fail-loop on DRM). It will start at boot.
- **Operational note for the booth:** connect the HDMI display BEFORE powering on (Pi DRM/KMS wants
  the output present at boot; console hotplug is unreliable). Then `aerial-signage.service`
  auto-starts on tty1. To preview at home, attach a monitor and `sudo systemctl start
  aerial-signage.service` (or reboot).
- install.sh's boot behaviour uses `raspi-config nonint do_boot_behaviour B2` (console autologin) —
  confirm the getty@tty1 → aerial-signage handoff on a real boot with a display.

## Session 2: Pi 3 support & bug review

### Pi 3 support (`AERIAL_STRICT_QUALITY`)

- Pi 3 (VideoCore IV) has **no HEVC decode**, H.264 HW decode up to 1080p only, 1080p HDMI, and
  cannot software-decode HEVC. Supported config (documented in both READMEs, "Raspberry Pi 3"):
  `AERIAL_QUALITY=1080-h264`, `AERIAL_STRICT_QUALITY=1`, `AERIAL_MPV_HWDEC=v4l2m2m-copy`.
- `AERIAL_STRICT_QUALITY=1` makes `aerial-fetch` use ONLY the exact quality variant (no codec
  fallback — otherwise a missing H.264 variant would silently download an unplayable HEVC file).
  CLI: `--strict-quality` / `--no-strict-quality` (argparse BooleanOptionalAction, tri-state so the
  CLI can override config/env in both directions).
- All 63 entries in the bundled Apple manifest have `url-1080-H264`, so Pi 3 gets the full set.
- The `v4l2m2m` H.264 path on Bookworm is **not yet validated on real Pi 3 hardware**.

### Bug review (before hardware testing)

Three independent review streams, all findings adjudicated by the manager model against the code:
1. codex CLI full-code review (free) — report at scratchpad `review/REPORT_REVIEW_CODEX.md`.
2. Workflow: 4 sonnet finder agents (python/shell/lua/system dimensions) + per-finding sonnet
   verifiers — 9 confirmed findings.
3. codex re-reviews of the fix diffs — found 4 residual issues across two passes (injection via
   `KEY=x; cmd` lines, quotes kept on `KEY="v" # comment`, $VAR not resolving earlier same-file
   assignments, unset-$VAR divergence under `set -u`); all fixed. Final state: both parsers
   expand unset variables to empty, exactly like bash.

**Fixes applied (all with regression tests where testable):**
- `install.sh`: normalize `/opt/aerial-signage` to root-owned, `go-w` (was: `cp -a` preserved the
  invoking user's ownership → user-writable code executed by root via the timer). Renders BOTH
  systemd units now. Empty-array guard in `cleanup()`.
- `systemd/aerial-fetch.service`: `User=__AERIAL_USER__` (was: ran as root, re-owning the cache).
- `systemd/aerial-signage.service`: `Conflicts=getty@tty1.service`, `After=getty@tty1.service`,
  `TTYReset/TTYVHangup/TTYVTDisallocate=yes` (kiosk takes tty1 from the login getty).
- `bin/aerial-signage`: validates every config line against a strict full-line assignment regex
  before `source` — rejects `KEY = v`, `KEY=x; cmd`, `KEY=x cmd`, `$(...)`, backticks, stray text
  after quoted values, with a clear error (was: cryptic crash or arbitrary execution).
- `bin/aerial-fetch` `parse_key_value_config`: bash-parity — strips whitespace-preceded `#`
  comments (incl. after a closing quote), keeps `#` inside quotes, expands `$VAR`/`${VAR}` against
  earlier same-file assignments then the environment (not inside single quotes; unknown vars stay
  literal), skips lines the launcher would refuse (with warnings).
- `bin/aerial-fetch` `load_manifest`: schema validation (`normalize_entries`) now INSIDE the
  fallback try — a wrong-shaped remote JSON (e.g. rate-limit body) now falls back to the bundled
  manifest instead of aborting. Returns entries directly.
- `bin/aerial-fetch` `download_one`: catches `filename_for_url` ValueError → logs and skips that
  URL (was: one bad URL aborted the whole run before the playlist was written).
- `lua/aerial_clock.lua` / `clock-overlay.lua`: `math.floor` on epoch and margin so fractional
  config values cannot break `os.date`/`%d` on integer-checking Lua builds.
- `docs/linux-aerial-repo-analysis.md`: marked historical (its H.264-first advice was written under
  a wrong premise; DESIGN_AND_RESEARCH.md is authoritative).

Verification after fixes: 11 python tests + lua tests pass, shellcheck clean, 5 injection vectors
rejected with no side effects, bash/python config parity spot-checked on shared files.

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

# Todo

## Plan — Raspberry Pi Aerial digital signage

- [x] Wave 1: Investigate the "Ubuntu/Linux" Aerial options and Pi 4/5 video-decode reality
- [x] Wave 2: Decide architecture (mpv kiosk) and design the player + config contract
- [x] Wave 3: Implement fetcher, launcher, Lua offset clock, systemd units, installer, tests, docs
- [x] Wave 4: Verify on the dev machine (unit tests, live fetch, real mpv integration test)
- [x] Wave 5: Write docs + handoff, clean the tree, sync to GitHub

## Review

- Built `raspberry-pi-signage/` — an mpv-based fullscreen kiosk that loops Apple Aerial videos with a
  configurable offset clock overlay reproducing `AERIAL_CLOCK_OFFSET_MINUTES` (default +10 min).
- Chose mpv + systemd (boot-to-console, DRM/KMS, `hwdec=drm-copy`) after confirming both Pi 4 and Pi 5
  hardware-decode 4K HEVC and that Chromium on Pi cannot HW-decode HEVC. Rejected reusing
  `graysky2/xscreensaver-aerial` (xscreensaver-bound, mplayer, no clock).
- Default video source = the real Apple set (`kopiro` manifest → `sylvan.apple.com`, 63 HEVC videos);
  a snapshot is bundled as offline fallback; the `glouel/AerialCommunity` GitHub set is the documented
  alternative.
- All dev-machine checks pass; the actual Lua clock ran under real mpv and produced the correct
  offset time end-to-end.

## Session 2 (Pi 3 + bug review)

- [x] Wave 6: `AERIAL_STRICT_QUALITY` (Pi 3 H.264 strict mode) + `--[no-]strict-quality` + docs
- [x] Wave 7: Multi-agent review (codex + 4 sonnet finders + verifiers) — 9 confirmed findings
- [x] Wave 8: Fix all confirmed findings (+3 residual issues codex found in the fixes), add
      regression tests, re-verify, sync to GitHub

## Follow-up (needs real Pi hardware)

- [ ] Run `install.sh` on Pi 4 and Pi 5; confirm aerial loop + offset clock on tty1 after reboot.
- [ ] Confirm HEVC hardware decode engages (`drm-copy`; else `v4l2m2m-copy`), no dropped frames.
- [ ] Confirm the `Conflicts=getty@tty1.service` handoff works on boot (unit now includes it +
      TTY reset options; still unvalidated on hardware).
- [ ] Pi 3: validate the `1080-h264` + `AERIAL_STRICT_QUALITY=1` + `hwdec=v4l2m2m-copy` path.
- [ ] Validate full-size Apple downloads over the network; drop `--limit` for the full set.

## Session 5 Plan (Windows parity fixes)

- [x] Read the prior Windows-parity audit, Windows settings UI/runtime code, DisplaySettingsTransferFormat, existing Pi web/fetch/lua/tests/docs.
- [x] Add one documented enum mapping table for plist raw values, Pi env strings, and Windows UI values; use it in web import/UI and Lua aliases.
- [x] Make clock and date overlays render the same offset moment, add custom date/time format support, and switch default offset to `0`.
- [x] Add Windows/spec positions (`topCenter`, `bottomCenter`, `screenCenter`/`center`, `random`, plus Windows aliases) and per-position stacking.
- [x] Add Windows-style location display modes with safe fallback from labels TSV.
- [x] Restructure the web UI sections/labels/controls to mirror Windows settings while preserving dark theme, endpoints, save->fetch->restart, toast, and mpv stats.
- [x] Add `Import Display Settings...` plist import and a fixture-backed unit test.
- [x] Update README.md, README.ja.md, handoff, and thread notes; run the required self-checks.

## Session 5 Review

- Windows/spec display parity was added without changing the mpv/Lua architecture or existing HTTP endpoint names.
- Required self-checks passed: py_compile, `tests/test_fetch.py`, `tests/test_web.py`, Lua unit test, `luac -p`, `bash -n`, and `shellcheck`.
- Additional local Web UI smoke test passed on port 18991 for `/`, `/api/state`, and `/api/import-display-settings`.
- No git commands were run, per the user's explicit constraint.

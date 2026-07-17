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

## Follow-up (needs real Pi hardware)

- [ ] Run `install.sh` on Pi 4 and Pi 5; confirm aerial loop + offset clock on tty1 after reboot.
- [ ] Confirm HEVC hardware decode engages (`drm-copy`; else `v4l2m2m-copy`), no dropped frames.
- [ ] Tune `systemd/aerial-signage.service` for reliable DRM/KMS ownership on boot (possible
      `Conflicts=getty@tty1.service` / autologin + user service).
- [ ] Validate full-size Apple downloads over the network; drop `--limit` for the full set.

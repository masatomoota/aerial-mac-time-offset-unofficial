# aerial-signage — Design & Research Notes

This document captures *why* the Raspberry Pi signage player is built the way it is, so future
maintainers (human or LLM) do not have to re-derive the architecture decision.

## Goal

Turn a Raspberry Pi 4 or 5 into always-on digital signage that:
1. Plays Apple "Aerial" screensaver videos fullscreen in a continuous loop, and
2. Overlays a clock showing **`now + AERIAL_CLOCK_OFFSET_MINUTES`** (default +10 min) — the signature
   feature of the parent macOS fork (`Aerial/Source/Views/Layers/ClockLayer.swift`).

## Why not port the macOS app

The parent project is a macOS `ScreenSaver.framework` app written in Swift/AppKit, using AVFoundation
and Core Animation. Those are Apple-only frameworks — a Linux port would be a full rewrite, not a
build. So instead we built a small, purpose-made Linux player and only *reproduced the behavior* that
matters (aerial loop + offset clock).

## Options considered

| Approach | Verdict | Reason |
| --- | --- | --- |
| (a) Reuse `graysky2/xscreensaver-aerial` | Rejected | It is an **xscreensaver hack** tied to `XSCREENSAVER_WINDOW`/X11, uses `mplayer`, has **no clock/overlay**, and is not a standalone kiosk. Good only as a reference for Apple filename/URL knowledge. See `linux-aerial-repo-analysis.md`. |
| (b) **mpv fullscreen kiosk + Lua OSD clock** | **Chosen** | Least code, most reliable for 24/7 video. mpv hardware-decodes HEVC on Pi, Lua computes the offset clock natively, systemd `Restart=always` gives resilience. |
| (c) Chromium kiosk + HTML `<video>` + CSS clock | Rejected | **Chromium on Raspberry Pi cannot hardware-decode HEVC** (confirmed across RPi/Armbian/Vivaldi forums). Heavier and less stable for pure fullscreen video looping. |

## Codec facts (verified against official Raspberry Pi docs — do not second-guess)

- **Raspberry Pi 4** (VideoCore VI): hardware-decodes **H.265/HEVC up to 4Kp60**; H.264 hardware
  decode only up to 1080p60. (Official Pi 4 spec page: "H.265 (4kp60 decode); H264 (1080p60 decode)".)
- **Raspberry Pi 5** (VideoCore VII): hardware-decodes **HEVC up to 4Kp60**; **no H.264 hardware
  decoder at all** (CPU software-decodes H.264 — fine at 1080p). (Official Pi 5 product brief lists a
  "4Kp60 HEVC decoder" and no H.264 block; confirmed by RPi engineers on the forums.)
- **Conclusion: HEVC is the correct default codec for both boards.** We default to `1080-sdr` (1080p
  HEVC) for lower bitrate/thermals; `4k-sdr` is available for 4K panels. `1080-h264` exists as a
  fallback for unusual setups only.

## mpv player path (Pi)

- HEVC hardware decode on Pi needs the V4L2 stateless API: `--hwdec=drm-copy` (or `v4l2m2m-copy`),
  `--vo=gpu`, `--gpu-context=drm`.
- DRM/KMS output requires **exclusive display ownership** — boot the Pi to console (no desktop
  compositor) and run mpv on tty1 via systemd. A desktop compositor would hold DRM master and cause a
  black screen.
- For off-Pi testing set `AERIAL_MPV_GPU_CONTEXT=auto AERIAL_MPV_HWDEC=auto`.

## Video source / manifest

Apple aerials are described by a JSON `entries.json` manifest. Each entry exposes URL variants:
`url-1080-H264` (AVC), `url-1080-SDR` / `url-1080-HDR` / `url-4K-SDR` / `url-4K-HDR` (all HEVC),
container `.mov`, served from `https://sylvan.apple.com/...`.

- **Default manifest** = the real Apple set, community-mirrored:
  `https://raw.githubusercontent.com/kopiro/xscreensaver-apple-aerial/main/entries.json`
  (63 videos, all with `sylvan.apple.com` HEVC URLs). Verified live (HTTP 200/206, `video/quicktime`,
  ~354 MB per 4K file) at build time; Apple's CDN accepts a plain `urllib` client with a browser UA.
- A **snapshot** of that manifest is bundled at `manifest/entries.json` and used automatically if the
  mirror is unreachable.
- **Alternative** = the GitHub-hosted community set (fewer, donated videos, very stable):
  `https://raw.githubusercontent.com/glouel/AerialCommunity/master/entries.json` — switch
  `AERIAL_MANIFEST_URL` to it if Apple ever changes the sylvan URLs.

## Verification performed on this dev machine (macOS, no Pi)

- `luac -p`, `lua tests/test_aerial_clock.lua`, `python3 -m py_compile bin/aerial-fetch`,
  `python3 tests/test_fetch.py`, `bash -n`, `shellcheck` — all pass.
- **Live manifest fetch** (Apple + community) and **dry-run URL selection** — correct.
- **Real downloads**: fetched 20 real community `.mov` files with atomic writes + valid playlist;
  confirmed Apple sylvan CDN serves our client (HTTP 206 range GET).
- **Real mpv integration test**: ran the *actual* `lua/clock-overlay.lua` under mpv v0.41 against a
  real aerial clip with `AERIAL_CLOCK_OFFSET_MINUTES=125`. The script loaded (require path +
  `create_osd_overlay` API worked), the 1 s timer fired, and it produced exactly `now+125min` — the
  offset clock is correct.

## What still needs real Pi hardware to validate

These are inherently hardware-specific and could NOT be tested on macOS:
1. HEVC **hardware** decode via `--hwdec=drm-copy` on Pi 4 / Pi 5 (dropped-frame / thermal behavior).
2. **DRM/KMS on tty1** ownership from the systemd unit — `aerial-signage.service` now ships the
   standard kiosk pattern (`Conflicts=getty@tty1.service`, `After=getty@tty1.service`,
   `TTYReset/TTYVHangup/TTYVTDisallocate=yes`), but the boot-time handoff still needs confirming
   on a real Pi.
3. Boot-to-console autologin interaction (`raspi-config nonint do_boot_behaviour B2`).
4. Full-size (265–354 MB) Apple video downloads over the real network.
5. **Pi 3** (experimental): the `AERIAL_QUALITY=1080-h264` + `AERIAL_STRICT_QUALITY=1` +
   `AERIAL_MPV_HWDEC=v4l2m2m-copy` path (stateful V4L2 H.264 decode on Bookworm).

## Bug review (2026-07-18, pre-hardware)

Before hardware testing, the codebase went through three independent review streams (codex CLI
full review, a 4-dimension sonnet finder/verifier workflow, and a codex re-review of the fix
diff). All confirmed findings were fixed with regression tests — see `tasks/handoff.md`
("Session 2") for the itemized list. Highlights: /opt ownership normalization (root-executed code
must not be user-writable), `User=` on the fetch unit, getty@tty1 conflict handling, strict
config-line validation before bash `source` (rejects shell injection in the conf), bash-parity
config parsing in Python (inline comments, quoted values, $VAR scope expansion), manifest-shape
fallback, and per-URL download error isolation.

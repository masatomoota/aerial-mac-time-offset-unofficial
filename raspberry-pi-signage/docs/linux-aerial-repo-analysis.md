# REPORT A: Linux Aerial Reuse Investigation for Raspberry Pi Signage

> **Historical document — codec advice superseded.** The H.264-first recommendations below were
> written under an incorrect premise about Pi hardware decoding. Verified facts: **both Pi 4 and
> Pi 5 hardware-decode 4K HEVC**, Pi 5 has no H.264 hardware decoder, and this project therefore
> defaults to HEVC. See [DESIGN_AND_RESEARCH.md](./DESIGN_AND_RESEARCH.md) (authoritative). The
> repository analysis (sections 1-2) and the mpv-over-xscreensaver architecture conclusion remain
> valid.

Date: 2026-07-18  
Scope: All work was done inside this scratch directory. The primary repo was shallow-cloned from `https://github.com/graysky2/xscreensaver-aerial.git` at commit `0429d174ba047ff2bba857aea85dc056c5161ce3`.

## 1. Primary repository: `graysky2/xscreensaver-aerial`

### Files read

The repo is very small. I read all non-`.git` files:

- `xscreensaver-aerial/README.md` - 295 lines
- `xscreensaver-aerial/atv4-2k.sh` - 180 lines
- `xscreensaver-aerial/atv4-4k.sh` - 180 lines
- `xscreensaver-aerial/MIT` - 7 lines

There is no Python, C, compiled xscreensaver GL module, packaging file, or build system in this checkout.

### Language and tooling

The implementation is Bash shell:

- Both executable implementations start with `#!/bin/bash`: `xscreensaver-aerial/atv4-2k.sh:1`, `xscreensaver-aerial/atv4-4k.sh:1`.
- The scripts use shell arrays for video filenames, `date`, `wc`, `awk`, `sed`, `$RANDOM`, and `mplayer`.
- The README describes it as "An xscreensaver that randomly selects one of the Apple TV4 HD aerial movies and plays it using mplayer": `xscreensaver-aerial/README.md:2`.

### How it obtains Apple aerial videos

It does not dynamically fetch or parse Apple's `entries.json` or any other JSON manifest. It hardcodes filename arrays in the shell scripts:

- 2K day videos are in `DayArr` at `xscreensaver-aerial/atv4-2k.sh:14`.
- 2K night videos are in `NightArr` at `xscreensaver-aerial/atv4-2k.sh:98`.
- 4K day videos are in `DayArr` at `xscreensaver-aerial/atv4-4k.sh:14`.
- 4K night videos are in `NightArr` at `xscreensaver-aerial/atv4-4k.sh:98`.

At runtime, it first checks for a local file under:

- `movies=/opt/ATV4`: `xscreensaver-aerial/atv4-2k.sh:11`, `xscreensaver-aerial/atv4-4k.sh:11`.

If the selected file exists there, it plays the local file. If not, it streams from Apple's `sylvan.apple.com` base URL:

- `APPLEURL="https://sylvan.apple.com/Aerials/2x/Videos"`: `xscreensaver-aerial/atv4-2k.sh:172`, `xscreensaver-aerial/atv4-4k.sh:172`.
- The stream URL is constructed as `"$APPLEURL/$useit"`: `xscreensaver-aerial/atv4-2k.sh:173`, `xscreensaver-aerial/atv4-4k.sh:173`.

The README also includes optional manual download snippets. These download into `/opt/ATV4/`, which the README says should be created manually and world-readable:

- Expected offline install/cache location: `/opt/ATV4/`: `xscreensaver-aerial/README.md:67`.
- 2K download loop: `wget --no-clobber http://sylvan.apple.com/Aerials/2x/Videos/"$i"`: `xscreensaver-aerial/README.md:180`.
- 4K download loop: `wget --no-clobber http://sylvan.apple.com/Aerials/2x/Videos/"$i"`: `xscreensaver-aerial/README.md:291`.
- One special 2K AVC URL is downloaded from `http://sylvan.apple.com/Videos/comp_GMT307_136NC_134K_8277_NY_NIGHT_01_v25_SDR_PS_20180907_SDR_2K_AVC.mov`: `xscreensaver-aerial/README.md:176-177`.

Important cache distinction:

- Video files are not automatically cached by the runtime script. Runtime uses `/opt/ATV4` only if files were pre-downloaded.
- Playback queue state is cached in text files under `$XDG_CONFIG_HOME`, not video data:
  - 2K: `$XDG_CONFIG_HOME/.atv4-day` and `$XDG_CONFIG_HOME/.atv4-night`: `xscreensaver-aerial/atv4-2k.sh:118-119`.
  - 4K: `$XDG_CONFIG_HOME/.atv4-day-4k` and `$XDG_CONFIG_HOME/.atv4-night-4k`: `xscreensaver-aerial/atv4-4k.sh:118-119`.

README search result for Apple JSON manifest URLs:

- No `entries.json`, `manifest`, or Apple JSON manifest URL appears in `xscreensaver-aerial/README.md`.
- Exact Apple video URL patterns found in the README are:
  - `http://sylvan.apple.com/Videos/comp_GMT307_136NC_134K_8277_NY_NIGHT_01_v25_SDR_PS_20180907_SDR_2K_AVC.mov`
  - `http://sylvan.apple.com/Aerials/2x/Videos/"$i"`

### How it chooses videos

The scripts split videos into day and night arrays. They use the local system clock hour:

- `hour=$(date +%H)`: `xscreensaver-aerial/atv4-2k.sh:127`, `xscreensaver-aerial/atv4-4k.sh:127`.
- Night is selected if hour is greater than 19 or less than 7: `xscreensaver-aerial/atv4-2k.sh:128`, `xscreensaver-aerial/atv4-4k.sh:128`.
- Otherwise day is selected: `xscreensaver-aerial/atv4-2k.sh:130-132`, `xscreensaver-aerial/atv4-4k.sh:130-132`.

It maintains queue files to avoid repeats until a list is exhausted:

- Initialize DB from arrays if empty: `xscreensaver-aerial/atv4-2k.sh:122-123`, `xscreensaver-aerial/atv4-4k.sh:122-123`.
- Pick a random line and delete it from the DB after selection: `xscreensaver-aerial/atv4-2k.sh:134-155`, `xscreensaver-aerial/atv4-4k.sh:134-155`.

Small implementation note: when there are two or more videos left, `rndpick` is forced to be at least 2 (`while [[ $rndpick -lt 2 ]]`), so line 1 is never selected in that branch. Line 1 is only used when it is the sole remaining entry. This does not break playback, but it is not perfectly uniform random selection.

### How it plays video

The player binary is `mplayer`, not `mpv`, not xscreensaver GL, and not `feh`.

Dependency check:

- `command -v mplayer ...`: `xscreensaver-aerial/atv4-2k.sh:6-8`, `xscreensaver-aerial/atv4-4k.sh:6-8`.

Local playback command:

```sh
mplayer -nosound -really-quiet -nolirc -nostop-xscreensaver -wid "$XSCREENSAVER_WINDOW" -fs "$movies/$useit" &
```

Source: `xscreensaver-aerial/atv4-2k.sh:169`, `xscreensaver-aerial/atv4-4k.sh:169`.

Streaming playback command:

```sh
mplayer -nosound -really-quiet -nolirc -nostop-xscreensaver -wid "$XSCREENSAVER_WINDOW" -fs "$APPLEURL/$useit" &
```

Source: `xscreensaver-aerial/atv4-2k.sh:173`, `xscreensaver-aerial/atv4-4k.sh:173`.

Flag meanings relevant to porting:

- `-nosound`: no audio.
- `-really-quiet`: suppress logs.
- `-nolirc`: no LIRC remote control.
- `-nostop-xscreensaver`: do not inhibit xscreensaver while playing.
- `-wid "$XSCREENSAVER_WINDOW"`: embed the video in the X window provided by xscreensaver.
- `-fs`: fullscreen.

The `-wid "$XSCREENSAVER_WINDOW"` flag is the key coupling to xscreensaver/X11.

### Runtime dependencies and assumptions

README dependencies:

- `coreutils`: `xscreensaver-aerial/README.md:13`
- `mplayer`: `xscreensaver-aerial/README.md:14`
- `wget`: `xscreensaver-aerial/README.md:15`
- `xscreensaver`: `xscreensaver-aerial/README.md:16`

Actual runtime tools from the scripts:

- Bash
- `mplayer`
- `date`
- `wc`
- `awk`
- `sed`
- standard shell/coreutils behavior
- readable/writeable `$XDG_CONFIG_HOME`; if unset it defaults to `$HOME/.config`: `xscreensaver-aerial/atv4-2k.sh:3-4`

Installation assumptions:

- Scripts are copied into the xscreensaver hack directory, e.g. `/usr/lib/xscreensaver/` or `/usr/libexec/xscreensaver/`: `xscreensaver-aerial/README.md:45-58`.
- `~/.xscreensaver` is manually edited to add `"ATV4-2k" atv4-2k` and `"ATV4-4k" atv4-4k`: `xscreensaver-aerial/README.md:60-64`.
- Selection is then done through `xscreensaver-demo`: `xscreensaver-aerial/README.md:295`.

Display/session assumptions:

- It assumes X11/xscreensaver. `XSCREENSAVER_WINDOW` is an xscreensaver-provided X window ID; the script passes it directly to mplayer via `-wid`.
- It is not Wayland-native.
- It does not require a full desktop environment in principle, but it does require an X server plus xscreensaver infrastructure. A minimal X session could work; a headless tty-only system cannot display signage with this script as-is.

### Text, clock, and time overlay capability

There is no text overlay or clock overlay capability in `graysky2/xscreensaver-aerial` as cloned.

The only time logic is for day/night video selection using `date +%H`; it does not draw the time. The mplayer commands do not load subtitles, filters, OSD scripting, or an overlay process. There is no config for font, timezone, offset, text, position, or formatting.

### Headless, kiosk, and systemd suitability

As-is, it is not a headless player and not a kiosk application. It is an xscreensaver hack:

- xscreensaver launches it and provides `XSCREENSAVER_WINDOW`.
- It loops forever while the xscreensaver hack is active: `while (true)`: `xscreensaver-aerial/atv4-2k.sh:164`, `xscreensaver-aerial/atv4-4k.sh:164`.
- It deliberately lets xscreensaver display-sleep behavior control whether more videos are started; the README calls this out: `xscreensaver-aerial/README.md:5`.

Could it be run from systemd? Only indirectly, if systemd starts or manages an X session and xscreensaver. Running the script alone as a systemd service without a valid display and xscreensaver window would not reproduce fullscreen signage.

### License

MIT License. The repo contains `xscreensaver-aerial/MIT`, copyright `2015-2022 graysky`, with standard MIT permission text.

## 2. Candidate alternatives checked

### `https://github.com/JohnCoates/Aerial`

`git ls-remote` succeeded; shallow clone HEAD was `6b4aa82ab3d5e247a198d86c3d645fcf68c98fec`. The README says this is the historical `.saver` repository and points to a newer app repository: `JohnCoates-Aerial/Readme.md:1-10`. It is a macOS implementation, not portable to Raspberry Pi as-is: the main view imports `ScreenSaver`, `AVFoundation`, and `AVKit`, and subclasses `ScreenSaverView`: `JohnCoates-Aerial/Aerial/Source/Views/AerialView.swift:9-17`. Many files import `Cocoa`/`AppKit`, and it includes macOS-specific layer implementations such as `ClockLayer.swift`, `DateLayer.swift`, and `LayerManager.swift`. It is valuable as a feature reference, especially overlay behavior, but it is not a Linux signage codebase.

### `https://github.com/glouel/AerialCommunity`

`git ls-remote` succeeded; shallow clone HEAD was `176e73744899c04435a356e3552b113be227b84b`. This is not a player. The README says it hosts community videos donated for use in Aerial: `glouel-AerialCommunity/README.md:1-5`. Its approach is manifest/metadata distribution: `glouel-AerialCommunity/manifest.json` exposes `manifestUrl` as `https://raw.githubusercontent.com/glouel/AerialCommunity/master/entries.json`, marks it `cacheable`, and points to a license URL: `glouel-AerialCommunity/manifest.json:9-13`. The `entries.json` file lists assets with direct `url-4K-SDR`, `url-1080-SDR`, and `url-1080-H264` URLs, including GitHub release-hosted `.mov` files: `glouel-AerialCommunity/entries.json:9-11`. This is useful as an example manifest format and as a non-Apple content source with H.264 1080p variants, but it does not solve playback or overlay by itself.

## 3. Raspberry Pi signage feasibility ranking

### Rank 1: (b) mpv-based fullscreen looping player + clock overlay via mpv Lua OSD

Best fit.

Pros:

- Least moving parts for video signage: one media player process can own fullscreen video and OSD.
- `mpv` supports playlists, shuffle, loop behavior, local files and URLs, and Lua scripting for a clock overlay.
- Clock offset is straightforward in Lua: compute `os.time() + offset_seconds`, format it, and draw via `mp.osd_message` or ASS OSD.
- Works in kiosk/systemd-style deployments more cleanly than xscreensaver. On Raspberry Pi OS, it can run under X11, Wayland-compatible video output depending on build, or a minimal graphical session.
- Easy to prefer H.264 assets on Pi 4 and Pi 5. For graysky2's Apple list, most hardcoded files are HEVC; we should instead source H.264 variants from a manifest/source that exposes them, transcode/cache our own H.264 set, or restrict to known H.264 URLs.
- More reliable than Chromium for long-running local video loops because the media pipeline is the primary application rather than a browser tab.

Cons and risks:

- Need a small playlist/manifest generator and cache manager. graysky2 only gives hardcoded Apple `sylvan` filenames, mostly HEVC.
- Need codec testing on the exact Pi image and display resolution.
- For Pi 4, avoid HEVC according to the project constraint: Pi 4 has H.264 hardware decode but no HEVC hardware decode.
- For Pi 5, H.264 hardware decode block is gone, but CPU is stronger; still prefer 1080p H.264 for predictable thermal and CPU behavior.
- Apple URL stability is a risk if relying on old hardcoded `sylvan.apple.com` paths. A manifest-driven fetcher is better than baking the 2019-era filename list forever.

Implementation shape:

- Downloader/cache: small Bash/Python script that produces local playlist entries.
- Player: `mpv --fs --loop-playlist=inf --shuffle --no-audio --script=clock.lua playlist.m3u`.
- Overlay: `clock.lua` reads a config offset such as `clock_offset_seconds` or `TZ`, formats a clock, and updates OSD once per second.
- Service: a systemd user service or kiosk session starts X/Wayland and then mpv.

### Rank 2: (c) Chromium kiosk with HTML `<video>` loop and CSS/JS clock overlay

Viable, especially if the signage app needs a web control plane.

Pros:

- HTML/CSS makes clock layout, fonts, positioning, time offsets, and future UI configuration very easy.
- A local web app can provide settings, playlists, diagnostics, and remote management.
- Chromium kiosk mode is familiar on Raspberry Pi deployments.
- H.264 playback is well supported; choose 1080p H.264 local files for Pi 4/5.

Cons and risks:

- Browser kiosk has more moving parts than mpv: Chromium profile, autoplay rules, GPU/video acceleration flags, crash/session restore behavior, and occasional browser updates changing behavior.
- Long-running video loops can show memory growth or media pipeline edge cases depending on Chromium version and hardware acceleration.
- HEVC/H.265 in Chromium is a bigger portability risk than H.264. Avoid HEVC.
- If using Apple `.mov` files directly, Chromium container/codec support must be verified. MP4/H.264 is safer than MOV/HEVC.

Implementation shape:

- Local static or tiny server app with an array of cached video URLs.
- `<video autoplay muted playsinline>` with JS advancing to the next source on `ended`.
- CSS absolute-positioned clock overlay; offset handled in JS.
- Run `chromium --kiosk http://localhost:PORT/` from a graphical systemd session.

### Rank 3: (a) Reuse/adapt `graysky2/xscreensaver-aerial` as-is

Poor fit for the target signage product.

Pros:

- Extremely small codebase.
- Already has a curated list of Apple Aerial filenames and a no-repeat queue idea.
- Can stream directly from Apple if a file is missing locally.
- MIT licensed.

Cons and risks:

- It is not a standalone signage player. It is an xscreensaver hack tied to `XSCREENSAVER_WINDOW`.
- Requires X11/xscreensaver and manual `~/.xscreensaver` integration.
- No text/clock overlay, no clock offset, and no UI/config surface.
- Uses `mplayer`, which is less attractive than `mpv` for modern scripting and kiosk control.
- Hardcoded Apple filenames are mostly HEVC (`*_HEVC.mov`), which conflicts with the Pi 4/5 reliability goal. One special 2K AVC URL exists, but the list is overwhelmingly HEVC.
- No automatic caching. The offline download logic is a README snippet, not runtime behavior.
- The hardcoded Apple URL set may become stale, and the repo does not use Apple's manifest discovery.

Best reusable pieces:

- Filename lists, if the old Apple `sylvan` URLs are still accepted.
- Day/night classification.
- Non-repeat queue concept.

What should not be reused:

- xscreensaver launch model.
- mplayer `-wid "$XSCREENSAVER_WINDOW"` playback model.
- Lack of manifest parsing and lack of overlay architecture.

## 4. Recommendation

Build approach (b): an `mpv` fullscreen looping player with a small local cache/playlist generator and an `mpv` Lua clock overlay.

This best reproduces "aerial video loop + configurable clock offset overlay" on Raspberry Pi 4/5 with the least code and best reliability. Reuse only the safe ideas from `graysky2/xscreensaver-aerial`: the curated URL/filename knowledge, day/night buckets, and no-repeat playlist rotation. Do not reuse its xscreensaver integration as the runtime architecture.

Concrete recommendation:

- Prefer 1080p H.264 local assets for both Pi 4 and Pi 5.
- Avoid the graysky2 default HEVC lists unless benchmarking proves the exact Pi/display combination can decode them without dropped frames or overheating.
- Use `mpv` for playback and OSD, not Chromium, unless the project also needs a browser-based admin/config UI.
- Use systemd to launch a minimal graphical session plus `mpv`, and keep video cache management as a separate small component.
- Treat Apple `sylvan.apple.com` URLs as an input source to validate/cache, not as a runtime dependency for every playback loop.


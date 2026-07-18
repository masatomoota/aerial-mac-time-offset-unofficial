# Todo

- [x] Read Raspberry Pi Lua overlay rendering path and Windows overlay rendering path.
- [x] Identify why the white fill can render as black-looking overlay text.
- [x] Move ASS layer construction into pure Lua helper code for direct testing.
- [x] Match Windows text style: white fill, normal weight, no outline, gray #444 shadow.
- [x] Add ASS layer test coverage.
- [x] Run requested self-checks.

## Review

- Root cause: the Lua overlay set primary color with `\1c` but did not force primary alpha opaque; with shadow enabled and default style alpha/color state, the visible overlay could collapse to the dark shadow/back layer.
- Fix: `clock.build_layer_ass_line` now emits explicit `\1c&HFFFFFF&`, `\1a&H00&`, `\bord0`, `\shad1`, transparent outline alpha, and gray `#444` shadow tags.
- Tests: `lua tests/test_aerial_clock.lua`, `luac -p lua/*.lua`, `python3 tests/test_fetch.py`, and `python3 tests/test_web.py` passed.

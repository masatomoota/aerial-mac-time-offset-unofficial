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

# Todo - aerial-web Config Save Regression

- [x] Mirror `bin/aerial-signage` launcher defaults in `/api/state` effective config.
- [x] Treat empty file values as unset for effective state, matching Bash `${VAR:=default}` behavior.
- [x] Restrict `/api/save` writes to keys displayed by the form.
- [x] Remove empty-string displayed keys instead of writing blank overrides.
- [x] Validate displayed color keys as six hex characters.
- [x] Add regression tests for defaults, empty-value removal, and bad color rejection.
- [x] Run requested self-checks.

## Review - aerial-web Config Save Regression

- Root cause: the web state defaults did not fully mirror launcher defaults, so uninitialized form controls could submit browser defaults such as black color or empty strings.
- Fix: `/api/state` now returns launcher-effective defaults under non-empty file values, and `/api/save` sanitizes the displayed form surface before writing.
- Tests: `python3 -m py_compile bin/aerial-web`, `python3 tests/test_web.py`, and `python3 tests/test_fetch.py` passed.

# Todo - Windows Location Type POI Parity

- [x] Confirm Windows `information` semantics for Label, Video Name, and Location Information.
- [x] Add a stdlib Apple strings parser and bundle `manifest/poi-strings.json` for ja/en.
- [x] Extend `aerial-fetch` sidecar output with per-video labels and resolved POI rows.
- [x] Update Lua location overlay to use `videoName`/`poi` semantics and playback-time thresholds.
- [x] Fix web UI Type controls so Line 4 has one effective Type selector and `AERIAL_LOC_MODE` is saved/reflected.
- [x] Add parser, fetch sidecar, and Lua POI threshold tests.
- [x] Run the requested self-check command set.

## Review - Windows Location Type POI Parity

- Root cause: the Pi overlay only had the short `accessibilityLabel` reliably available. tvOS16 POI values are localization keys, but the fetch/overlay path did not bundle or resolve `TVIdleScreenStrings`, and the web UI showed a second broken Type selector for the location line.
- Fix: `manifest/poi-strings.json` now bundles ja/en POI strings; `aerial-fetch` writes `labels.json` with per-video `label`, `name`, and resolved `pointsOfInterest` rows while keeping `labels.tsv`; Lua reads JSON sidecars, observes `playback-time`, and switches `poi`/`information` text at thresholds with `AERIAL_DATE_LANG` fallback ja -> en -> label.
- Web UI: Line 4 now has one Type selector. `None` writes `AERIAL_LOC_ENABLED=0`; Label/Video Name/Location Information/Filename write `AERIAL_LOC_ENABLED=1` plus the corresponding `AERIAL_LOC_MODE`.
- Tests: requested py_compile, Python tests, Lua syntax/test, Bash syntax, and shellcheck all passed.

# Todo - Windows-Parity Text Phase 2

- [x] Read Windows `displayText` defaults, Position/Text Options UI, Moment formatting, and Pi overlay/web state paths.
- [x] Replace fixed clock/date/location/message Lua overlay with shared-position 4-line config model.
- [x] Add pure Lua Moment.js token formatter for Windows help tokens with tests.
- [x] Keep `AERIAL_CLOCK_OFFSET_MINUTES` semantics for every Time-Date line.
- [x] Add launcher/web effective-state migration from legacy `AERIAL_CLOCK/DATE/LOC/MSG` keys when new line keys are absent.
- [x] Rebuild Text UI around shared Position, Random interval, Max Width, 4 line Type controls, live preview, and global/per-line Text Options.
- [x] Add Videos Profiles under `/etc/aerial-signage/profiles/`.
- [x] Add Advanced Windows `config.json` import/export with base64 passthrough preservation and keep plist import.
- [x] Update docs and handoff.
- [x] Run final requested self-check command set.

## Review - Windows-Parity Text Phase 2

- Implementation switched runtime text rendering to `AERIAL_TEXT_*` + `AERIAL_LINE{1..4}_*`; legacy keys are migration inputs only when no new text keys exist.
- Web API now returns launcher-effective line-model config, validates all displayed color keys as six hex values, supports Profiles CRUD, and maps Windows `displayText` config both ways.
- Tests: requested py_compile, Python tests, Lua syntax/test, Bash syntax, and shellcheck all passed. Additional local HTTP/API and embedded JS syntax checks passed; browser interaction could not run because no Browser instance or Playwright package was available.

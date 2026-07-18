# Thread: Location POI Parity

## Scope

Ported Windows location overlay Type behavior into `raspberry-pi-signage` without git operations, per user request.

## Changes

- Added Apple `.strings` parsing helpers to `bin/aerial-fetch` for binary plist and old-style quoted `.strings` files.
- Generated `manifest/poi-strings.json` from the supplied tvOS16 `TVIdleScreenStrings.bundle` for `ja` and `en` (382 strings each).
- Extended `aerial-fetch` to keep writing `labels.tsv` and also write `labels.json` with `file`, `label`, `accessibilityLabel`, `id`, `scene`, `name`, and `pointsOfInterest: [{t,key,text_ja,text_en}]`.
- Updated Lua overlay loading to prefer `labels.json`, fall back to `labels.tsv`, and switch POI text from `playback-time` thresholds.
- Added pure Lua helpers for `videoName`/`name`, `poi`/`information`, language fallback, and legacy TSV POI parsing.
- Changed default `AERIAL_LABELS_FILE` to `/var/lib/aerial-signage/labels.json`.
- Reworked the web UI Location line so Line 4 has one Type selector that writes `AERIAL_LOC_ENABLED` and `AERIAL_LOC_MODE` correctly.
- Updated README/config/docs and orchestration interface/decision notes.

## Files Touched

- `bin/aerial-fetch`
- `bin/aerial-web`
- `bin/aerial-signage`
- `lua/aerial_clock.lua`
- `lua/clock-overlay.lua`
- `manifest/poi-strings.json`
- `tests/test_fetch.py`
- `tests/test_web.py`
- `tests/test_aerial_clock.lua`
- `README.md`
- `README.ja.md`
- `config/aerial-signage.conf.example`
- `docs/display-settings-mapping.md`
- `tasks/todo.md`
- `tasks/lessons.md`
- `tasks/orchestration/interfaces.md`
- `tasks/orchestration/decisions.md`

## Tests

- PASS: `python3 -m py_compile bin/aerial-fetch bin/aerial-web`
- PASS: `python3 tests/test_fetch.py`
- PASS: `python3 tests/test_web.py`
- PASS: `luac -p lua/*.lua`
- PASS: `lua tests/test_aerial_clock.lua`
- PASS: `bash -n bin/aerial-signage`
- PASS: `shellcheck bin/aerial-signage`

## Remaining

- No known remaining implementation work.
- No git status, commit, or diff commands were run because the user explicitly requested `NO git`.

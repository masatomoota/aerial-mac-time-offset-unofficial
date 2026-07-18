# Session 5 Windows Parity Thread

## Scope

Implement Windows-parity display defaults, overlay positions, location modes, web UI wording/layout, and plist import for `raspberry-pi-signage/`.

## Constraints

- Do not run any git command.
- Preserve existing uncommitted edits in `raspberry-pi-signage/bin/aerial-web` and `raspberry-pi-signage/tests/test_web.py`, especially save->fetch->restart, toast feedback, and mpv stats.
- Do not touch `/etc` or any device state; edit repo files only.

## Status

- Implementation and verification complete.

## Files Touched

- `raspberry-pi-signage/bin/aerial-fetch`
- `raspberry-pi-signage/bin/aerial-signage`
- `raspberry-pi-signage/bin/aerial-web`
- `raspberry-pi-signage/lua/aerial_clock.lua`
- `raspberry-pi-signage/lua/clock-overlay.lua`
- `raspberry-pi-signage/config/aerial-signage.conf.example`
- `raspberry-pi-signage/docs/display-settings-mapping.md`
- `raspberry-pi-signage/tests/test_fetch.py`
- `raspberry-pi-signage/tests/test_web.py`
- `raspberry-pi-signage/tests/test_aerial_clock.lua`
- `raspberry-pi-signage/tests/fixtures/display-settings-sample.plist`
- `raspberry-pi-signage/README.md`
- `raspberry-pi-signage/README.ja.md`
- `tasks/todo.md`
- `tasks/orchestration/decisions.md`
- `tasks/orchestration/interfaces.md`
- `tasks/handoff.md`

## Tests

- PASS: `python3 -m py_compile raspberry-pi-signage/bin/aerial-fetch raspberry-pi-signage/bin/aerial-web`
- PASS: `cd raspberry-pi-signage && python3 tests/test_fetch.py`
- PASS: `cd raspberry-pi-signage && python3 tests/test_web.py`
- PASS: `cd raspberry-pi-signage && lua tests/test_aerial_clock.lua`
- PASS: `cd raspberry-pi-signage && luac -p lua/*.lua`
- PASS: `cd raspberry-pi-signage && bash -n bin/aerial-signage install.sh`
- PASS: `cd raspberry-pi-signage && shellcheck bin/aerial-signage install.sh`
- PASS: local Web UI smoke test on port 18991 for `/`, `/api/state`, and `/api/import-display-settings`.

## Remaining Notes

- No git commands were run because the user explicitly forbade them.

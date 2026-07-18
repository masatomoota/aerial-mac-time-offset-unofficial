# Windows-Parity Text Phase 2

## Scope

Port Windows Text tab behavior to the Raspberry Pi signage implementation without git operations.

## Changed Files

- `lua/aerial_clock.lua`
- `lua/clock-overlay.lua`
- `bin/aerial-signage`
- `bin/aerial-web`
- `config/aerial-signage.conf.example`
- `tests/test_aerial_clock.lua`
- `tests/test_web.py`
- `README.md`
- `README.ja.md`
- `docs/display-settings-mapping.md`
- `tasks/todo.md`
- `tasks/orchestration/interfaces.md`
- `tasks/orchestration/decisions.md`
- `../tasks/handoff.md`

## Summary

- Added `AERIAL_TEXT_*` + `AERIAL_LINE{1..4}_*` as the primary runtime text schema.
- Implemented pure Lua Moment token formatting for the Windows help tokens.
- Replaced the fixed overlay renderer with a shared-position 4-line overlay and Random reposition timer.
- Added launcher and web effective-config migration from legacy clock/date/location/message keys when new keys are absent.
- Rebuilt the Text UI around Position and Text Options, with per-line type controls and live preview.
- Added Videos Profiles CRUD and Windows-compatible config.json import/export with unknown-key passthrough.

## Tests

- `python3 -m py_compile bin/aerial-fetch bin/aerial-web`: PASS
- `python3 tests/test_fetch.py`: PASS
- `python3 tests/test_web.py`: PASS
- `luac -p lua/*.lua`: PASS
- `lua tests/test_aerial_clock.lua`: PASS
- `bash -n bin/aerial-signage`: PASS
- `shellcheck bin/aerial-signage`: PASS
- Additional local check: `node --check` on embedded web JS and `GET /api/state` on temporary `aerial-web` server: PASS.
- Browser interaction note: Browser runtime reported no browser available, and local Playwright was not installed, so rendered interaction smoke could not run in this environment.

## Remaining

- Optional follow-up on a machine with Browser/Playwright: click through Text/Profile/Advanced flows visually.

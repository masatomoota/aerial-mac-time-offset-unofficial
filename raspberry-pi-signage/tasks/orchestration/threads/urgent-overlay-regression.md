# Urgent Overlay Regression

## Changes

- Added tested ASS line construction to `lua/aerial_clock.lua`.
- Updated `lua/clock-overlay.lua` to use the shared builder.
- Added assertions in `tests/test_aerial_clock.lua` for white primary fill and Windows-style shadow/outline tags.

## Files Touched

- `lua/aerial_clock.lua`
- `lua/clock-overlay.lua`
- `tests/test_aerial_clock.lua`
- `tasks/todo.md`
- `tasks/lessons.md`
- `tasks/orchestration/interfaces.md`
- `tasks/orchestration/decisions.md`
- `tasks/orchestration/threads/urgent-overlay-regression.md`

## Tests

- `lua tests/test_aerial_clock.lua`: PASS
- `luac -p lua/*.lua`: PASS
- `python3 tests/test_fetch.py`: PASS
- `python3 tests/test_web.py`: PASS

## Remaining Work

- None for this regression.

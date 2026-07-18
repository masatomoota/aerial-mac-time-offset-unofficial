# Decisions

## Session 5 Windows Parity

- Fixed-layer Pi overlays remain the runtime model; Windows `displayText` is mirrored at the UI/semantics boundary rather than replacing the mpv Lua overlay architecture.
- `AERIAL_CLOCK_OFFSET_MINUTES` default changes to `0` for Windows parity. Explicit existing config values remain honored.
- Repo/example defaults keep Pi fetch source `classic63`; the web UI presents `tvos16` as the Windows-parity recommended/default source option.
- Display-settings plist import is data-only: recognized overlay keys are mapped, unknown/unsupported keys are ignored, and shell/text-file paths are never executed.

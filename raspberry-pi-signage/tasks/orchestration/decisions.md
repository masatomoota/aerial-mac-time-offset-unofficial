# Decisions

- Keep config keys and existing layer enablement behavior unchanged.
- Centralize ASS event construction in `aerial_clock.lua` so style parity can be tested without mpv.
- Use Windows text rendering semantics for the ASS override line: white primary fill, normal weight, no visible outline, gray `#444` shadow.
- Do not run git commands or create commits for this task because the user explicitly requested `NO git`.
- Keep writing `labels.tsv`, but use `labels.json` as the default sidecar for structured POI rows because Windows POI parity requires per-threshold localized text.
- Treat `AERIAL_LOC_MODE=videoName` as the canonical UI value while keeping `name` as a legacy alias; treat `information` as an alias for `poi`.
- Phase 2 intentionally replaces the fixed overlay layer model with a Windows-parity 4-line model; old `AERIAL_CLOCK/DATE/LOC/MSG` keys remain migration inputs but are no longer the primary UI/runtime contract.
- Store custom Time-Date formats as Moment.js-style strings, not strftime, because Windows config.json and screenshots use Moment tokens.
- Preserve device continuity by migrating legacy keys only when no `AERIAL_TEXT_*` or `AERIAL_LINE*` key is present; explicit new keys win even if old keys also exist.
- Store unmapped Windows config.json fields as base64 JSON in `AERIAL_WINDOWS_CONFIG_PASSTHROUGH_B64` because the shell config grammar cannot safely store raw JSON with quotes.
- Do not run git commands or create commits for this task because the user explicitly requested `NO git`.

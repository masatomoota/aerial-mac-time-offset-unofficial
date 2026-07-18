# Decisions

- Keep config keys and existing layer enablement behavior unchanged.
- Centralize ASS event construction in `aerial_clock.lua` so style parity can be tested without mpv.
- Use Windows text rendering semantics for the ASS override line: white primary fill, normal weight, no visible outline, gray `#444` shadow.
- Do not run git commands or create commits for this task because the user explicitly requested `NO git`.

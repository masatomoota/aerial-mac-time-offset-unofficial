# Interfaces

- `aerial-fetch` now writes `labels.json` next to `labels.tsv`. The JSON sidecar shape is:
  `{"videos":[{"file": "...", "label": "...", "accessibilityLabel": "...", "id": "...", "scene": "...", "name": "...", "pointsOfInterest":[{"t": 0, "key": "...", "text_ja": "...", "text_en": "..."}]}]}`.
- `labels.tsv` remains written and readable for backward compatibility.
- Existing `AERIAL_*` config keys are unchanged; `AERIAL_LOC_MODE` additionally accepts `videoName` as the canonical Video Name value and `information` as a POI alias.
- Added pure Lua helper functions in `lua/aerial_clock.lua`:
  - `ass_escape(text)`
  - `font_tag(font)`
  - `build_layer_ass_line(opts)`
- `/api/state` returns launcher-effective `config`: `bin/aerial-signage` defaults underneath non-empty config-file values.
- `/api/save` only persists keys displayed by the web form, removes displayed keys submitted as empty strings, and rejects non-6-hex displayed color values.

## Windows-Parity Text Phase 2

- Runtime text overlay contract is now:
  - Global: `AERIAL_TEXT_POSITION`, `AERIAL_TEXT_FONT`, `AERIAL_TEXT_SIZE`, `AERIAL_TEXT_COLOR`, `AERIAL_TEXT_MARGIN`, `AERIAL_TEXT_MAX_WIDTH`, `AERIAL_TEXT_RANDOM_INTERVAL`.
  - Lines 1..4: `AERIAL_LINE{n}_TYPE`, `AERIAL_LINE{n}_FORMAT`, `AERIAL_LINE{n}_TEXT`, `AERIAL_LINE{n}_INFO_MODE`, `AERIAL_LINE{n}_USE_DEFAULT_FONT`, `AERIAL_LINE{n}_FONT`, `AERIAL_LINE{n}_FONT_SIZE`, `AERIAL_LINE{n}_COLOR`.
  - Offset: `AERIAL_CLOCK_OFFSET_MINUTES` remains the single offset source for every `timedate` line.
- Line types are `none`, `timedate`, `information`, `videoname`, and `message`.
- `/api/state` returns launcher-effective config and migrates legacy fixed-layer keys into the line model only when no new text/line keys are configured.
- `/api/export-settings` returns a Windows-compatible `config.json` payload with `textFont`, `textSize`, `textColor`, `randomSpeed`, and `displayText`.
- `/api/import-windows-settings` accepts Windows `config.json` text and returns mapped config updates; unmapped Windows keys are preserved in `AERIAL_WINDOWS_CONFIG_PASSTHROUGH_B64` for export round-trip.
- `/api/profiles`, `/api/profiles/save`, `/api/profiles/load`, and `/api/profiles/delete` manage named video selection JSON files under `/etc/aerial-signage/profiles/` (or `AERIAL_PROFILES_DIR` in tests).

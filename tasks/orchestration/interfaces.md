# Interfaces

## Raspberry Pi Signage Config Keys

- Existing HTTP endpoints remain unchanged: `/api/state`, `/api/videos`, `/api/save`, `/api/fetch`, `/api/player/restart`, `/api/reboot`.
- New HTTP endpoint: `/api/import-display-settings`, POST JSON object with `plist` string. It returns `{ok, config, imported_keys, skipped_keys}` and does not write files until the user saves/applies the returned config through the existing save flow.
- New/extended env keys:
  - `AERIAL_DATE_CUSTOM_FORMAT`: strftime format used when `AERIAL_DATE_FORMAT=custom`.
  - `AERIAL_LOC_MODE`: `accessibilityLabel`, `name`, `poi`, or `filename`.
  - Overlay corners accept spec values `topLeft`, `topCenter`, `topRight`, `bottomLeft`, `bottomCenter`, `bottomRight`, `screenCenter`, `random`, `absTopRight` plus legacy `center` and Windows aliases `topleft`, `topmiddle`, `topright`, `bottomleft`, `bottommiddle`, `bottomright`, `middle`, `left`, `right`.

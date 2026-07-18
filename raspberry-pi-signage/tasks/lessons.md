# Lessons

- For ASS overlays, setting `\1c` is not sufficient by itself. Always set the matching alpha tag (`\1a&H00&`) when the intended fill must be visible regardless of libass/mpv style defaults.
- When porting CSS text-shadow behavior to ASS, encode the whole style in one tested builder: fill color, fill alpha, outline width/color/alpha, shadow depth/color/alpha, font weight, and position.
- For web forms backed by shell defaults, `/api/state` must expose launcher-effective values before rendering controls. Otherwise browser control defaults can become real config overrides on save.
- Empty string form values should remove the displayed override instead of being persisted as `KEY=""`; this keeps Bash `${VAR:=default}` defaults authoritative.
- Color inputs must be validated server-side as six hex characters before config writes, even if the browser usually submits valid color values.
- Location Information is not the same as `accessibilityLabel`: tvOS16 manifests store `pointsOfInterest` as timestamp -> localization key, so fetch must resolve bundled Apple strings and the overlay must update from playback time thresholds.
- For Windows parity, store Time-Date formats as Moment.js tokens end-to-end. Translating them back to strftime in runtime config breaks import/export parity and live preview expectations.
- When replacing config models, decide migration from the raw config-file key presence, not from merged defaults; otherwise defaults make it impossible to tell "legacy device" from "explicit new model".
- Raw Windows config.json passthrough must not be stored directly in shell config values. Use an encoded blob so the launcher grammar remains safe.

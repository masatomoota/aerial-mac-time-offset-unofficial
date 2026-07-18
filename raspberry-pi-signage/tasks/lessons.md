# Lessons

- For ASS overlays, setting `\1c` is not sufficient by itself. Always set the matching alpha tag (`\1a&H00&`) when the intended fill must be visible regardless of libass/mpv style defaults.
- When porting CSS text-shadow behavior to ASS, encode the whole style in one tested builder: fill color, fill alpha, outline width/color/alpha, shadow depth/color/alpha, font weight, and position.

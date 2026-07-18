# Display Settings Mapping

This is the single mapping table used by the Raspberry Pi signage player when
normalizing macOS DisplaySettings plist values, Windows UI values, and native
`AERIAL_*` env strings.

| Meaning | Spec enum/raw value | Windows value | Pi env value |
| --- | --- | --- | --- |
| top left | `InfoCorner 0=topLeft` | `topleft` | `topLeft` |
| top center | `InfoCorner 1=topCenter` | `topmiddle` | `topCenter` |
| top right | `InfoCorner 2=topRight` | `topright` | `topRight` |
| bottom left | `InfoCorner 3=bottomLeft` | `bottomleft` | `bottomLeft` |
| bottom center | `InfoCorner 4=bottomCenter` | `bottommiddle` | `bottomCenter` |
| bottom right | `InfoCorner 5=bottomRight` | `bottomright` | `bottomRight` |
| screen center | `InfoCorner 6=screenCenter` | `middle` | `screenCenter` (`center` legacy alias) |
| random | `InfoCorner 7=random` | `random` | `random` |
| absolute top right | `InfoCorner 8=absTopRight` | `topright` fallback | `absTopRight` |
| clock default | `InfoClockFormat 0=tdefault` | `time` line default `hh:mm:ss` | `24h` |
| 24 hour clock | `InfoClockFormat 1=t24hours` | custom `HH:mm`-style string | `24h` |
| 12 hour clock | `InfoClockFormat 2=t12hours` | custom `hh:mm A`-style string | `12h` |
| custom clock | `InfoClockFormat 3=custom` | custom `timeString` | `custom` + `AERIAL_CLOCK_CUSTOM_FORMAT` |
| textual date | `InfoDate 0=textual` | custom `timeString` | `textual` |
| compact date | `InfoDate 1=compact` | custom `timeString` | `compact` (`numeric` legacy alias) |
| custom date | `InfoDate 2=custom` | custom `timeString` | `custom` + `AERIAL_DATE_CUSTOM_FORMAT` |
| video label | Windows `information/accessibilityLabel` | `accessibilityLabel` | `AERIAL_LOC_MODE=accessibilityLabel` |
| video name | Windows `information/name` | `name` | `AERIAL_LOC_MODE=name` |
| location information | Windows `information/poi` | `poi` | `AERIAL_LOC_MODE=poi` |
| filename fallback | none | none | `AERIAL_LOC_MODE=filename` |

Custom time/date strings are stored as strftime strings at runtime. The web
importer translates common Apple DateFormatter/Moment tokens to strftime and
preserves already-strftime strings unchanged.

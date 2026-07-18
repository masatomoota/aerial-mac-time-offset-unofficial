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
| clock/time-date line | Windows `displayText[position][line].type=time` | `timeString` Moment format | `AERIAL_LINE{n}_TYPE=timedate`, `AERIAL_LINE{n}_FORMAT` |
| video label | Windows `information/accessibilityLabel` | `accessibilityLabel` | `AERIAL_LINE{n}_TYPE=information`, `AERIAL_LINE{n}_INFO_MODE=accessibilityLabel` |
| video name | Windows `information/name` | `name` | `AERIAL_LINE{n}_TYPE=videoname` |
| location information | Windows `information/poi` | `poi` | `AERIAL_LINE{n}_TYPE=information`, `AERIAL_LINE{n}_INFO_MODE=poi` |
| filename fallback | none | none | `AERIAL_LINE{n}_TYPE=information`, `AERIAL_LINE{n}_INFO_MODE=filename` |
| custom text | Windows `displayText[position][line].type=text` | `text` | `AERIAL_LINE{n}_TYPE=message`, `AERIAL_LINE{n}_TEXT` |
| default font | Windows `defaultFont=true` | global `textFont/textSize/textColor` | `AERIAL_LINE{n}_USE_DEFAULT_FONT=1`, global `AERIAL_TEXT_*` |
| per-line font | Windows `defaultFont=false` | `font/fontSize/fontColor` | `AERIAL_LINE{n}_FONT`, `AERIAL_LINE{n}_FONT_SIZE`, `AERIAL_LINE{n}_COLOR` |

The Pi runtime now stores custom time/date strings as Moment.js-style strings
for Windows parity. Lua implements the Windows help tokens:
`YYYY YY MMMM MMM MM M DD D dddd ddd dd d Do HH H hh h mm m ss s A a`.

Legacy `AERIAL_CLOCK_*`, `AERIAL_DATE_*`, `AERIAL_LOC_*`, and `AERIAL_MSG_*`
keys are still accepted. If no `AERIAL_TEXT_*` or `AERIAL_LINE*` key is present,
`bin/aerial-signage` and `/api/state` migrate the old fixed layers into the new
line model at runtime so existing devices keep their current display.

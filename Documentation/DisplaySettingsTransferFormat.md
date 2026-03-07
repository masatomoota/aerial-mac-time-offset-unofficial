# Display Settings Transfer Format

This document is the canonical implementation guide for importing display-related settings exported from macOS Aerial via `Advanced > Export Display...`.

It is written for both humans and LLMs. If you are building a Windows importer, follow this file instead of reverse-engineering the macOS plist.

## Scope

This export contains only display and overlay presentation settings.

It intentionally excludes:

- cache and downloads
- update preferences
- debug flags
- audio playback settings
- source/library selection

## Container Format

- File format: XML property list (`.plist`)
- Top-level type: dictionary
- Writer on macOS: `PropertyListSerialization.data(... format: .xml ...)`
- Default export filename: `AerialDisplaySettings.plist`

Official export files include these metadata keys:

| Key | Type | Required | Meaning |
| --- | --- | --- | --- |
| `_AerialDisplaySettingsExport` | Boolean | Yes for official exports | Must be `true` for files created by `Export Display...` |
| `_AerialDisplaySettingsVersion` | Integer | Yes for official exports | Format version. Current value: `1` |

Notes:

- Missing setting keys are normal. The exporter only writes keys currently present in Aerial's preference store.
- Importers must ignore unknown keys.
- Importers should accept both official export files and raw Aerial preference plists when they contain recognized keys, but the official interchange format is the metadata-tagged export above.

## Normative Import Rules

If you are implementing an importer, use this behavior:

1. Parse the file as an XML plist dictionary.
2. If `_AerialDisplaySettingsVersion` is present and greater than the highest version you support, continue in best-effort mode and import only known keys.
3. For each recognized top-level key:
   - Validate the outer plist type.
   - If the key carries a JSON-in-string payload, decode that JSON.
   - If decoding or validation fails for one key, skip that key and continue.
4. Apply only keys that were present in the file.
5. Keep defaults for all missing keys.
6. Ignore unknown top-level keys and unknown JSON object fields.
7. Never execute referenced scripts or files during import. Import is data-only.

Recommended tolerance:

- Accept plist numbers delivered as integer or real and coerce them to the destination numeric type.
- Accept JSON numbers delivered as integer or real.
- Preserve raw strings even if the destination platform does not understand them yet.

## Top-Level Keys

### Display Layout and Dimming

| Key | Type | Meaning |
| --- | --- | --- |
| `newDisplayMode` | Integer enum | Which displays are used |
| `newViewingMode` | Integer enum | Independent/cloned/spanned/mirrored playback |
| `aspectMode` | Integer enum | Fill or fit |
| `displayMarginsAdvanced` | Boolean | Whether advanced per-display margins are enabled |
| `horizontalMargin` | Real | Horizontal margin ratio/value used by the current macOS UI |
| `verticalMargin` | Real | Vertical margin ratio/value used by the current macOS UI |
| `advancedMargins` | String containing JSON | Serialized `AdvancedMargin` payload |
| `dimBrightness` | Boolean | Enable brightness dimming |
| `dimOnlyAtNight` | Boolean | Limit dimming to night mode |
| `dimOnlyOnBattery` | Boolean | Limit dimming to battery usage |
| `overrideDimInMinutes` | Boolean | Whether manual dim delay override is enabled |
| `startDim` | Real | Starting dim level |
| `endDim` | Real | Ending dim level |
| `dimInMinutes` | Integer | Dimming duration/delay in minutes |

### Overlay Ordering and Payloads

| Key | Type | Meaning |
| --- | --- | --- |
| `layers` | String containing JSON | Ordered array of overlay identifiers |
| `LayerLocation` | String containing JSON | Location overlay settings |
| `LayerMessage` | String containing JSON | Message overlay settings |
| `LayerClock` | String containing JSON | Clock overlay settings |
| `LayerDate` | String containing JSON | Date overlay settings |
| `LayerBattery` | String containing JSON | Battery overlay settings |
| `LayerUpdates` | String containing JSON | Update indicator overlay settings |
| `LayerWeather` | String containing JSON | Weather overlay settings |
| `LayerCountdown` | String containing JSON | Countdown overlay settings |
| `LayerTimer` | String containing JSON | Timer overlay settings |
| `LayerMusic` | String containing JSON | Music overlay settings |

### Overlay Appearance

| Key | Type | Meaning |
| --- | --- | --- |
| `weatherWindMode` | Integer enum | Weather wind speed unit |
| `customDateFormat` | String | User-entered custom date format string |
| `customTimeFormat` | String | User-entered custom time format template |
| `fadeModeText` | Integer enum | Text fade mode |
| `highQualityTextRendering` | Boolean | High-quality text rendering toggle |
| `overrideMargins` | Boolean | Override overlay margins globally |
| `hideUnderCompanion` | Boolean | Hide overlays under Companion |
| `marginX` | Integer | Horizontal overlay margin |
| `marginY` | Integer | Vertical overlay margin |
| `shadowRadius` | Integer | Text shadow radius |
| `shadowOpacity` | Real | Text shadow opacity |
| `shadowOffsetX` | Real | Text shadow horizontal offset |
| `shadowOffsetY` | Real | Text shadow vertical offset |

### Time-Based Switching

| Key | Type | Meaning |
| --- | --- | --- |
| `timeMode` | Integer enum | Time source / switching mode |
| `manualSunrise` | String | Manual sunrise time, usually `HH:mm` |
| `manualSunset` | String | Manual sunset time, usually `HH:mm` |
| `latitude` | String | Latitude text entry as stored by macOS |
| `longitude` | String | Longitude text entry as stored by macOS |
| `solarMode` | Integer enum | Sun-event calculation mode |
| `sunEventWindow` | Integer | Window around sunrise/sunset in seconds |
| `darkModeNightOverride` | Boolean | Force dark mode during night mode |

### Miscellaneous Display Preferences

| Key | Type | Meaning |
| --- | --- | --- |
| `invertColors` | Boolean | Invert rendered video colors |
| `favorOrientation` | Boolean | Prefer videos matching screen orientation |
| `ciOverrideLanguage` | String | Language/locale override string |
| `newDisplayDict` | Dictionary of string -> bool | Per-display selection map |

## Enum Raw Values

These integer values are the wire format. Importers should map from these numbers, not from UI labels.

| Enum | Raw values |
| --- | --- |
| `DisplayMode` | `0=allDisplays`, `1=mainOnly`, `2=secondaryOnly`, `3=selection` |
| `ViewingMode` | `0=independent`, `1=cloned`, `2=spanned`, `3=mirrored` |
| `AspectMode` | `0=fill`, `1=fit` |
| `FadeMode` | `0=disabled`, `1=t0_5`, `2=t1`, `3=t2` |
| `InfoWeatherWind` | `0=kph`, `1=mps` |
| `TimeMode` | `0=disabled`, `1=nightShift`, `2=manual`, `3=lightDarkMode`, `4=coordinates`, `5=locationService` |
| `SolarMode` | `0=strict`, `1=official`, `2=civil`, `3=nautical`, `4=astronomical` |
| `InfoCorner` | `0=topLeft`, `1=topCenter`, `2=topRight`, `3=bottomLeft`, `4=bottomCenter`, `5=bottomRight`, `6=screenCenter`, `7=random`, `8=absTopRight` |
| `InfoDisplays` | `0=allDisplays`, `1=mainOnly`, `2=secondaryOnly` |
| `InfoTime` | `0=always`, `1=tenSeconds` |
| `InfoClockFormat` | `0=tdefault`, `1=t24hours`, `2=t12hours`, `3=custom` |
| `InfoDate` | `0=textual`, `1=compact`, `2=custom` |
| `InfoIconText` | `0=text`, `1=icon` |
| `InfoCountdownMode` | `0=preciseDate`, `1=timeOfDay` |
| `InfoLocationMode` | `0=useCurrent`, `1=manuallySpecify` |
| `InfoDegree` | `0=celsius`, `1=fahrenheit` |
| `InfoIconsWeather` | `0=flat`, `1=colorflat`, `2=oweather` |
| `InfoMessageType` | `0=text`, `1=shell`, `2=textfile` |
| `InfoRefreshPeriodicity` | `0=never`, `1=tenseconds`, `2=thirtyseconds`, `3=oneminute`, `4=fiveminutes`, `5=tenminutes` |
| `InfoWeatherMode` | `0=current`, `1=forecast6hours`, `2=forecast3days`, `3=forecast5days` |

`layers` uses string enum values instead of integers:

- `location`
- `message`
- `clock`
- `date`
- `battery`
- `updates`
- `weather`
- `countdown`
- `timer`
- `music`

## JSON-in-String Payloads

Several top-level plist strings contain nested JSON. This is not an accident; it mirrors the macOS storage layer.

### Common Overlay Fields

Every `Layer*` JSON object includes these common fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `isEnabled` | Boolean | Whether the overlay is active |
| `fontName` | String | Requested font family/name |
| `fontSize` | Number | Requested point size |
| `corner` | Integer enum | Overlay anchor position, see `InfoCorner` |
| `displays` | Integer enum | Which displays receive this overlay |

### `layers`

Top-level key: `layers`

JSON schema:

```json
["message", "clock", "date", "location"]
```

This array defines display order and availability of overlay types.

### `advancedMargins`

Top-level key: `advancedMargins`

This is a JSON string, not a plist dictionary.

Schema:

```json
{
  "displays": [
    {
      "zleft": 0,
      "ztop": 0,
      "offsetleft": 24,
      "offsettop": 18
    }
  ]
}
```

An empty string means "no advanced margin payload".

### `LayerLocation`

Additional fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `time` | Integer enum | See `InfoTime` |

### `LayerMessage`

Additional fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `message` | String | Literal message text |
| `shellScript` | String | Script path as stored on macOS |
| `textFile` | String | Text file path as stored on macOS |
| `messageType` | Integer enum | See `InfoMessageType` |
| `refreshPeriodicity` | Integer enum | See `InfoRefreshPeriodicity` |

Security note:

- Importers must never execute `shellScript` during import.

### `LayerClock`

Additional fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `showSeconds` | Boolean | Whether seconds are shown |
| `hideAmPm` | Boolean | Whether AM/PM is hidden |
| `clockFormat` | Integer enum | See `InfoClockFormat` |

### `LayerDate`

Additional fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `format` | Integer enum | See `InfoDate` |
| `withYear` | Boolean | Whether year is shown |

### `LayerBattery`

Additional fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `mode` | Integer enum | See `InfoIconText` |
| `disableWhenFull` | Boolean | Hide battery overlay when full |

### `LayerUpdates`

Additional fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `betaReset` | Boolean | Historical compatibility flag |

### `LayerWeather`

Additional fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `locationMode` | Integer enum | See `InfoLocationMode` |
| `locationString` | String | Manual location text |
| `degree` | Integer enum | See `InfoDegree` |
| `icons` | Integer enum | See `InfoIconsWeather` |
| `mode` | Integer enum | See `InfoWeatherMode` |
| `showHumidity` | Boolean | Show humidity text |
| `showWind` | Boolean | Show wind text |
| `showCity` | Boolean | Show city name |

### `LayerCountdown`

Additional fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `mode` | Integer enum | See `InfoCountdownMode` |
| `targetDate` | Number | Seconds from Apple's reference date |
| `enforceInterval` | Boolean | Use trigger interval |
| `triggerDate` | Number | Seconds from Apple's reference date |
| `showSeconds` | Boolean | Show seconds |

### `LayerTimer`

Additional fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `duration` | Number | Seconds from Apple's reference date |
| `showSeconds` | Boolean | Show seconds |
| `disableWhenElapsed` | Boolean | Disable overlay after elapsed |
| `replaceWithMessage` | Boolean | Replace timer with custom message |
| `customMessage` | String | Message shown after elapsed |

### `LayerMusic`

No additional fields beyond the common overlay fields.

## Date Encoding Inside JSON Payloads

`LayerCountdown.targetDate`, `LayerCountdown.triggerDate`, and `LayerTimer.duration` use Swift's default `JSONEncoder` date encoding.

That means the JSON number is:

- seconds from Apple's reference date
- reference instant: `2001-01-01T00:00:00Z`

Example:

```json
{"targetDate":123}
```

means 123 seconds after `2001-01-01T00:00:00Z`.

## Portability Notes for Windows

### Keys that are mostly portable

These should transfer directly:

- display/viewing/aspect mode enums
- dimming values
- overlay order and enablement
- most overlay text/formatting settings
- time-mode values
- language override

### Keys that are platform-sensitive

Handle these in best-effort mode:

| Key or field | Why it is platform-sensitive | Recommended Windows behavior |
| --- | --- | --- |
| `newDisplayDict` | Keys are macOS display IDs serialized as strings | Preserve if you can map displays. Otherwise ignore without failing import |
| `advancedMargins` | Depends on physical display arrangement and coordinate system | Apply only if the current Windows display topology can support it, otherwise skip/reset |
| `fontName` | Font may not exist on Windows | Preserve requested name; fall back at render time |
| `shellScript` | macOS file path / executable semantics | Preserve as data only; never execute during import |
| `textFile` | Path syntax may not exist on Windows | Preserve as data; missing path should not fail import |
| `customDateFormat` / `customTimeFormat` | Formatting tokens may not map 1:1 to Windows/.NET | Preserve raw string. Translate if supported, otherwise keep as opaque user data |

## Forward-Compatibility Rules

Future macOS exporters may add:

- new top-level keys
- new JSON fields
- new enum values
- a higher `_AerialDisplaySettingsVersion`

Windows importers should therefore:

- ignore unknown keys
- ignore unknown JSON object fields
- skip unsupported enum values rather than rejecting the file
- preserve raw stored values when possible for future re-export or diagnostics

## Minimal Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>_AerialDisplaySettingsExport</key>
  <true/>
  <key>_AerialDisplaySettingsVersion</key>
  <integer>1</integer>
  <key>newDisplayMode</key>
  <integer>0</integer>
  <key>fadeModeText</key>
  <integer>2</integer>
  <key>layers</key>
  <string>[
  "message",
  "clock",
  "weather"
]</string>
  <key>LayerClock</key>
  <string>{
  "clockFormat" : 0,
  "corner" : 3,
  "displays" : 0,
  "fontName" : "Helvetica Neue Medium",
  "fontSize" : 50,
  "hideAmPm" : false,
  "isEnabled" : true,
  "showSeconds" : true
}</string>
</dict>
</plist>
```

## Source of Truth

The current macOS implementation that writes and reads this format lives in:

- `Resources/MainUI/Settings panels/AdvancedViewController.swift`
- `Aerial/Source/Models/Prefs/PrefsDisplays.swift`
- `Aerial/Source/Models/Prefs/PrefsInfo.swift`
- `Aerial/Source/Models/Prefs/PrefsAdvanced.swift`
- `Aerial/Source/Models/Prefs/PrefsTime.swift`

If behavior changes in code, update this document in the same change.

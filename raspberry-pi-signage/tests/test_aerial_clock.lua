local script = arg and arg[0] or "tests/test_aerial_clock.lua"
local base = script:match("^(.*[/\\])") or ""
local clock = dofile(base .. "../lua/aerial_clock.lua")

local function assert_equal(actual, expected, label)
  if actual ~= expected then
    io.stderr:write(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual) .. "\n")
    os.exit(1)
  end
end

local function epoch(year, month, day, hour, min, sec)
  return os.time({ year = year, month = month, day = day, hour = hour, min = min, sec = sec })
end

assert_equal(clock.offset_minutes_from_env(nil), 0, "nil offset")
assert_equal(clock.offset_minutes_from_env("bad"), 0, "invalid offset")
assert_equal(clock.offset_minutes_from_env("-540"), -540, "negative offset")
assert_equal(clock.offset_minutes_from_env("90"), 90, "positive offset")

assert_equal(clock.format_time(epoch(2026, 1, 1, 0, 5, 9), { format = "24h" }), "00:05", "24h")
assert_equal(
  clock.format_time(epoch(2026, 1, 1, 3, 4, 5), { format = "24h", seconds = true }),
  "03:04:05",
  "24h seconds"
)
assert_equal(clock.format_time(epoch(2026, 1, 1, 0, 5, 0), { format = "12h" }), "12:05 AM", "12h AM")
assert_equal(clock.format_time(epoch(2026, 1, 1, 13, 7, 0), { format = "12h" }), "1:07 PM", "12h PM")
assert_equal(
  clock.format_time(epoch(2026, 1, 1, 13, 7, 8), { format = "12h", seconds = true, hide_ampm = true }),
  "1:07:08",
  "12h hide ampm"
)

-- fractional epochs (e.g. AERIAL_CLOCK_OFFSET_MINUTES=0.5) must not break os.date
assert_equal(
  clock.format_time(epoch(2026, 1, 1, 3, 4, 5) + 0.9, { format = "24h", seconds = true }),
  "03:04:05",
  "fractional epoch floored"
)

assert_equal(clock.alignment_for("topLeft"), 7, "topLeft")
assert_equal(clock.alignment_for("topCenter"), 8, "topCenter")
assert_equal(clock.alignment_for("topmiddle"), 8, "topmiddle alias")
assert_equal(clock.alignment_for("topRight"), 9, "topRight")
assert_equal(clock.alignment_for("bottomLeft"), 1, "bottomLeft")
assert_equal(clock.alignment_for("bottomCenter"), 2, "bottomCenter")
assert_equal(clock.alignment_for("bottomRight"), 3, "bottomRight")
assert_equal(clock.alignment_for("center"), 5, "center legacy")
assert_equal(clock.alignment_for("middle"), 5, "middle alias")
assert_equal(clock.alignment_for("left"), 4, "left")
assert_equal(clock.alignment_for("right"), 6, "right")
assert_equal(clock.alignment_for("unknown"), 3, "default alignment")
assert_equal(clock.rgb_to_ass_bgr("FF0000"), "&H0000FF&", "red bgr")

assert_equal(
  clock.format_moment(epoch(2026, 7, 18, 15, 4, 5), "YYYY YY MMMM MMM MM M DD D dddd ddd dd d Do HH H hh h mm m ss s A a"),
  "2026 26 July Jul 07 7 18 18 Saturday Sat Sa 6 18th 15 15 03 3 04 4 05 5 PM pm",
  "moment token coverage"
)
assert_equal(clock.format_moment(epoch(2026, 1, 2, 3, 4, 5), "[Today] HH:mm"), "Today 03:04", "moment literal brackets")

local ass_line = clock.build_layer_ass_line({
  corner = "bottomLeft",
  font_size = 50,
  border = 0,
  shadow = 1,
  color = "FFFFFF",
  font = "Segoe UI",
  x = 60,
  y = 1020,
  text = "12:34",
})
assert_equal(ass_line:match("\\1c&HFFFFFF&") ~= nil, true, "ass primary fill is white")
assert_equal(ass_line:match("\\1a&H00&") ~= nil, true, "ass primary fill is opaque")
assert_equal(ass_line:match("\\bord0\\shad1") ~= nil, true, "ass windows border shadow geometry")
assert_equal(ass_line:match("\\3c&H444444&\\3a&HFF&") ~= nil, true, "ass transparent gray outline")
assert_equal(ass_line:match("\\4c&H444444&\\4a&H00&") ~= nil, true, "ass gray shadow")
assert_equal(ass_line:match("\\b0") ~= nil, true, "ass normal font weight")

local multi_line = clock.build_text_ass_line({
  corner = "bottomLeft",
  x = 60,
  y = 1020,
  lines = {
    { text = "Line 1", font = "Segoe UI", font_size = 50, color = "FFFFFF" },
    { text = "Line 2", font = "Arial", font_size = 38, color = "FF0000" },
  },
})
assert_equal(multi_line:match("\\pos%(60,1020%)") ~= nil, true, "shared text position")
assert_equal(multi_line:match("Line 1\\N") ~= nil, true, "multi line separator")
assert_equal(multi_line:match("\\fnArial") ~= nil, true, "per-line font override")

assert_equal(clock.format_date(epoch(2026, 7, 18, 12, 0, 0), { format = "textual", lang = "ja" }), "7月18日（土）", "ja textual date")
assert_equal(
  clock.format_date(epoch(2026, 7, 18, 12, 0, 0), { format = "textual", lang = "ja", with_year = true }),
  "2026年7月18日（土）",
  "ja textual date with year"
)
assert_equal(
  clock.format_date(epoch(2026, 7, 18, 12, 0, 0), { format = "textual", lang = "en" }),
  "Saturday, July 18",
  "en textual date"
)
assert_equal(clock.format_date(epoch(2026, 7, 18, 12, 0, 0), { format = "compact" }), "07/18", "compact date")
assert_equal(
  clock.format_date(epoch(2026, 7, 18, 12, 0, 0), { format = "numeric", with_year = true }),
  "2026/07/18",
  "numeric date with year"
)
assert_equal(
  clock.format_date(epoch(2026, 7, 18, 12, 0, 0), { format = "custom", custom_format = "%Y.%m.%d" }),
  "2026.07.18",
  "custom date"
)
assert_equal(clock.unescape("a\\nb\\\\c"), "a\nb\\c", "unescape newline and backslash")

local poi_row = {
  accessibilityLabel = "Short Label",
  name = "Video Name",
  pointsOfInterest = {
    { t = 0, key = "K0", text_ja = "日本語0", text_en = "English 0" },
    { t = 20, key = "K20", text_ja = "", text_en = "English 20" },
    { t = 50, key = "K50", text_ja = "日本語50", text_en = "English 50" },
  },
}
assert_equal(clock.location_text(poi_row, "accessibilityLabel", 25, "ja", "file"), "Short Label", "location label")
assert_equal(clock.location_text(poi_row, "videoName", 25, "ja", "file"), "Video Name", "location videoName")
assert_equal(clock.location_text(poi_row, "name", 25, "ja", "file"), "Video Name", "location legacy name")
assert_equal(clock.location_text(poi_row, "poi", 0, "ja", "file"), "日本語0", "poi first threshold")
assert_equal(clock.location_text(poi_row, "poi", 25, "ja", "file"), "English 20", "poi ja falls back en")
assert_equal(clock.location_text(poi_row, "information", 55, "en", "file"), "English 50", "information alias")
assert_equal(clock.location_text({ accessibilityLabel = "Only Label", pointsOfInterest = {} }, "poi", 25, "ja", "file"), "Only Label", "poi fallback label")

local legacy_points = clock.legacy_poi_points('{"30":"Thirty","0":"Zero"}')
assert_equal(#legacy_points, 2, "legacy poi count")
assert_equal(clock.location_text({ accessibilityLabel = "Label", pointsOfInterest = legacy_points }, "poi", 10, "en", "file"), "Zero", "legacy poi threshold")

print("OK")

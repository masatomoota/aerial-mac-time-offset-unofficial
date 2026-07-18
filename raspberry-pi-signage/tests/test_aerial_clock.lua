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

print("OK")

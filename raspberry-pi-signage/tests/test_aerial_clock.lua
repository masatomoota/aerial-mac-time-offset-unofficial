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

assert_equal(clock.offset_minutes_from_env(nil), 10, "nil offset")
assert_equal(clock.offset_minutes_from_env("bad"), 10, "invalid offset")
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
assert_equal(clock.alignment_for("topRight"), 9, "topRight")
assert_equal(clock.alignment_for("bottomLeft"), 1, "bottomLeft")
assert_equal(clock.alignment_for("bottomRight"), 3, "bottomRight")
assert_equal(clock.alignment_for("center"), 5, "center")
assert_equal(clock.alignment_for("unknown"), 3, "default alignment")
assert_equal(clock.rgb_to_ass_bgr("FF0000"), "&H0000FF&", "red bgr")

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
assert_equal(clock.format_date(epoch(2026, 7, 18, 12, 0, 0), { format = "numeric" }), "2026-07-18", "numeric date")
assert_equal(clock.unescape("a\\nb\\\\c"), "a\nb\\c", "unescape newline and backslash")

print("OK")

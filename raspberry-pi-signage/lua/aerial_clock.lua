local M = {}

local function bool_value(value)
  return value == true or value == 1 or value == "1" or value == "true"
end

local function pad2(value)
  return string.format("%02d", value)
end

function M.format_time(now_epoch, cfg)
  cfg = cfg or {}
  -- Fractional offsets/epochs must not reach os.date: Lua 5.3+ builds raise
  -- "number has no integer representation" for non-integer arguments.
  now_epoch = math.floor(now_epoch)
  local mode = cfg.format or "24h"
  local seconds = bool_value(cfg.seconds)
  local hide_ampm = bool_value(cfg.hide_ampm)

  if mode == "custom" then
    return os.date(cfg.custom_format or "%H:%M", now_epoch)
  end

  local t = os.date("*t", now_epoch)
  if mode == "12h" then
    local suffix = t.hour >= 12 and " PM" or " AM"
    local hour = t.hour % 12
    if hour == 0 then
      hour = 12
    end
    local text = tostring(hour) .. ":" .. pad2(t.min)
    if seconds then
      text = text .. ":" .. pad2(t.sec)
    end
    if not hide_ampm then
      text = text .. suffix
    end
    return text
  end

  local text = pad2(t.hour) .. ":" .. pad2(t.min)
  if seconds then
    text = text .. ":" .. pad2(t.sec)
  end
  return text
end

function M.format_date(now_epoch, cfg)
  cfg = cfg or {}
  now_epoch = math.floor(now_epoch)
  local mode = cfg.format or "textual"
  local with_year = bool_value(cfg.with_year)
  local lang = cfg.lang or "ja"
  local t = os.date("*t", now_epoch)

  if mode == "custom" then
    return os.date(cfg.custom_format or "%Y-%m-%d", now_epoch)
  end

  if mode == "numeric" or mode == "compact" then
    if with_year then
      return string.format("%04d/%02d/%02d", t.year, t.month, t.day)
    end
    return string.format("%02d/%02d", t.month, t.day)
  end

  if lang == "en" then
    local weekdays = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
    local months = {
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    }
    local text = string.format("%s, %s %d", weekdays[t.wday], months[t.month], t.day)
    if with_year then
      text = text .. string.format(", %04d", t.year)
    end
    return text
  end

  local weekdays = { "日", "月", "火", "水", "木", "金", "土" }
  local text = string.format("%d月%d日（%s）", t.month, t.day, weekdays[t.wday])
  if with_year then
    text = string.format("%04d年%s", t.year, text)
  end
  return text
end

local month_names = {
  full = {
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  },
  short = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" },
}

local weekday_names = {
  full = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" },
  short = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" },
  min = { "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa" },
}

local function ordinal(value)
  local n = tonumber(value) or 0
  local mod100 = n % 100
  if mod100 >= 11 and mod100 <= 13 then
    return tostring(n) .. "th"
  end
  local mod10 = n % 10
  if mod10 == 1 then
    return tostring(n) .. "st"
  elseif mod10 == 2 then
    return tostring(n) .. "nd"
  elseif mod10 == 3 then
    return tostring(n) .. "rd"
  end
  return tostring(n) .. "th"
end

function M.format_moment(now_epoch, fmt)
  now_epoch = math.floor(now_epoch)
  fmt = tostring(fmt or "hh:mm:ss")
  local t = os.date("*t", now_epoch)
  local hour12 = t.hour % 12
  if hour12 == 0 then
    hour12 = 12
  end
  local values = {
    YYYY = string.format("%04d", t.year),
    YY = string.format("%02d", t.year % 100),
    MMMM = month_names.full[t.month],
    MMM = month_names.short[t.month],
    MM = pad2(t.month),
    M = tostring(t.month),
    DD = pad2(t.day),
    D = tostring(t.day),
    dddd = weekday_names.full[t.wday],
    ddd = weekday_names.short[t.wday],
    dd = weekday_names.min[t.wday],
    d = tostring(t.wday - 1),
    Do = ordinal(t.day),
    HH = pad2(t.hour),
    H = tostring(t.hour),
    hh = pad2(hour12),
    h = tostring(hour12),
    mm = pad2(t.min),
    m = tostring(t.min),
    ss = pad2(t.sec),
    s = tostring(t.sec),
    A = t.hour >= 12 and "PM" or "AM",
    a = t.hour >= 12 and "pm" or "am",
  }
  local tokens = {
    "YYYY",
    "MMMM",
    "dddd",
    "MMM",
    "ddd",
    "Do",
    "YY",
    "MM",
    "DD",
    "dd",
    "HH",
    "hh",
    "mm",
    "ss",
    "M",
    "D",
    "d",
    "H",
    "h",
    "m",
    "s",
    "A",
    "a",
  }
  local out = {}
  local i = 1
  while i <= #fmt do
    local ch = fmt:sub(i, i)
    if ch == "[" then
      local close = fmt:find("%]", i + 1)
      if close then
        out[#out + 1] = fmt:sub(i + 1, close - 1)
        i = close + 1
      else
        out[#out + 1] = ch
        i = i + 1
      end
    else
      local matched = false
      for _, token in ipairs(tokens) do
        if fmt:sub(i, i + #token - 1) == token then
          out[#out + 1] = values[token]
          i = i + #token
          matched = true
          break
        end
      end
      if not matched then
        out[#out + 1] = ch
        i = i + 1
      end
    end
  end
  return table.concat(out)
end

function M.unescape(text)
  local raw = tostring(text or "")
  local out = {}
  local i = 1
  while i <= #raw do
    local ch = raw:sub(i, i)
    if ch == "\\" and i < #raw then
      local next_ch = raw:sub(i + 1, i + 1)
      if next_ch == "n" then
        out[#out + 1] = "\n"
        i = i + 2
      elseif next_ch == "\\" then
        out[#out + 1] = "\\"
        i = i + 2
      else
        out[#out + 1] = ch
        i = i + 1
      end
    else
      out[#out + 1] = ch
      i = i + 1
    end
  end
  return table.concat(out)
end

function M.legacy_poi_points(raw)
  local points = {}
  for seconds, text in tostring(raw or ""):gmatch('"([^"]+)":"([^"]*)"') do
    local numeric_seconds = tonumber(seconds)
    if numeric_seconds then
      points[#points + 1] = {
        t = math.floor(numeric_seconds),
        key = text,
        text_en = text,
        text_ja = "",
      }
    end
  end
  table.sort(points, function(a, b)
    return (tonumber(a.t) or 0) < (tonumber(b.t) or 0)
  end)
  return points
end

function M.select_poi_point(points, playback_time)
  if type(points) ~= "table" or #points == 0 then
    return nil
  end
  local position = tonumber(playback_time) or 0
  local selected = nil
  for _, point in ipairs(points) do
    local t = tonumber(point.t) or 0
    if t <= position then
      selected = point
    elseif selected == nil then
      return point
    else
      return selected
    end
  end
  return selected or points[1]
end

function M.poi_text_for_language(point, lang, fallback)
  if type(point) ~= "table" then
    return fallback or ""
  end
  local preferred = tostring(lang or "ja")
  local text = point["text_" .. preferred]
  if text ~= nil and text ~= "" then
    return text
  end
  if preferred ~= "en" and point.text_en ~= nil and point.text_en ~= "" then
    return point.text_en
  end
  return fallback or ""
end

function M.location_text(row, mode, playback_time, lang, filename_fallback)
  if type(row) ~= "table" then
    return filename_fallback or ""
  end
  local fallback = row.accessibilityLabel or row.label or filename_fallback or ""
  local loc_mode = mode or "accessibilityLabel"
  if loc_mode == "filename" then
    return filename_fallback or fallback
  end
  if loc_mode == "name" or loc_mode == "videoName" then
    return row.name ~= nil and row.name ~= "" and row.name or fallback
  end
  if loc_mode == "poi" or loc_mode == "information" then
    local point = M.select_poi_point(row.pointsOfInterest, playback_time)
    return M.poi_text_for_language(point, lang or "ja", fallback)
  end
  return fallback
end

function M.alignment_for(corner)
  corner = M.normalize_corner(corner)
  local map = {
    topLeft = 7,
    topCenter = 8,
    topRight = 9,
    bottomLeft = 1,
    bottomCenter = 2,
    bottomRight = 3,
    screenCenter = 5,
    center = 5,
    left = 4,
    right = 6,
    absTopRight = 9,
  }
  return map[corner] or 3
end

-- See docs/display-settings-mapping.md for the authoritative spec/Windows/env table.
function M.normalize_corner(corner)
  local raw = tostring(corner or "")
  local map = {
    topLeft = "topLeft",
    topCenter = "topCenter",
    topRight = "topRight",
    bottomLeft = "bottomLeft",
    bottomCenter = "bottomCenter",
    bottomRight = "bottomRight",
    screenCenter = "screenCenter",
    center = "screenCenter",
    random = "random",
    absTopRight = "absTopRight",
    topleft = "topLeft",
    topmiddle = "topCenter",
    topright = "topRight",
    bottomleft = "bottomLeft",
    bottommiddle = "bottomCenter",
    bottomright = "bottomRight",
    middle = "screenCenter",
    left = "left",
    right = "right",
  }
  return map[raw] or raw
end

function M.rgb_to_ass_bgr(rrggbb)
  local raw = tostring(rrggbb or "FFFFFF"):gsub("#", "")
  if not raw:match("^[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]$") then
    raw = "FFFFFF"
  end
  local rr = raw:sub(1, 2):upper()
  local gg = raw:sub(3, 4):upper()
  local bb = raw:sub(5, 6):upper()
  return "&H" .. bb .. gg .. rr .. "&"
end

function M.ass_escape(text)
  return tostring(text):gsub("\\", "\\\\"):gsub("{", "\\{"):gsub("}", "\\}"):gsub("\n", "\\N")
end

function M.font_tag(font)
  if font == nil or font == "" then
    return ""
  end
  return "\\fn" .. M.ass_escape(font)
end

function M.build_layer_ass_line(opts)
  opts = opts or {}
  local corner = opts.corner or "bottomRight"
  local primary = M.rgb_to_ass_bgr(opts.color or "FFFFFF")
  local shadow = M.rgb_to_ass_bgr(opts.shadow_color or "444444")
  return string.format(
    "{\\an%d\\fs%d\\b0\\bord%d\\shad%d\\1c%s\\1a&H00&\\3c%s\\3a&HFF&\\4c%s\\4a&H00&%s\\pos(%d,%d)}%s",
    opts.alignment or M.alignment_for(corner),
    opts.font_size or 38,
    opts.border or 0,
    opts.shadow or 1,
    primary,
    shadow,
    shadow,
    M.font_tag(opts.font or ""),
    opts.x or 0,
    opts.y or 0,
    M.ass_escape(opts.text or "")
  )
end

function M.build_text_ass_line(opts)
  opts = opts or {}
  local lines = opts.lines or {}
  local corner = opts.corner or "bottomRight"
  local fragments = {}
  for _, line in ipairs(lines) do
    if line.text ~= nil and line.text ~= "" then
      local primary = M.rgb_to_ass_bgr(line.color or opts.color or "FFFFFF")
      local shadow = M.rgb_to_ass_bgr(opts.shadow_color or "444444")
      fragments[#fragments + 1] = string.format(
        "{\\fs%d\\b0\\bord%d\\shad%d\\1c%s\\1a&H00&\\3c%s\\3a&HFF&\\4c%s\\4a&H00&%s}%s",
        line.font_size or opts.font_size or 38,
        opts.border or 0,
        opts.shadow or 1,
        primary,
        shadow,
        shadow,
        M.font_tag(line.font or opts.font or ""),
        M.ass_escape(line.text or "")
      )
    end
  end
  return string.format(
    "{\\an%d\\pos(%d,%d)}%s",
    opts.alignment or M.alignment_for(corner),
    opts.x or 0,
    opts.y or 0,
    table.concat(fragments, "\\N")
  )
end

function M.offset_minutes_from_env(raw)
  local value = tonumber(raw)
  if value == nil then
    return 0
  end
  return value
end

return M

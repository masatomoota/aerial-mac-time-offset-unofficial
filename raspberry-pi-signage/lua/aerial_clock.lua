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

function M.offset_minutes_from_env(raw)
  local value = tonumber(raw)
  if value == nil then
    return 0
  end
  return value
end

return M

local M = {}

local function bool_value(value)
  return value == true or value == 1 or value == "1" or value == "true"
end

local function pad2(value)
  return string.format("%02d", value)
end

function M.format_time(now_epoch, cfg)
  cfg = cfg or {}
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

function M.alignment_for(corner)
  local map = {
    topLeft = 7,
    topRight = 9,
    bottomLeft = 1,
    bottomRight = 3,
    center = 5,
  }
  return map[corner] or 3
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
    return 10
  end
  return value
end

return M

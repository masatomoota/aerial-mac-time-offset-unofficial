local ok, err = pcall(function()
  local script_dir = nil
  if mp and mp.get_script_directory then
    script_dir = mp.get_script_directory()
  end
  if not script_dir then
    local info = debug.getinfo(1, "S")
    local source = info and info.source or ""
    script_dir = source:match("^@(.+)/[^/]+$") or "."
  end

  package.path = script_dir .. "/?.lua;" .. package.path
  local clock = require("aerial_clock")

  local function env(name, default)
    local value = os.getenv(name)
    if value == nil or value == "" then
      return default
    end
    return value
  end

  if env("AERIAL_CLOCK_ENABLED", "1") ~= "1" then
    return
  end

  local cfg = {
    format = env("AERIAL_CLOCK_FORMAT", "24h"),
    seconds = env("AERIAL_CLOCK_SECONDS", "0") == "1",
    hide_ampm = env("AERIAL_CLOCK_HIDE_AMPM", "0") == "1",
    custom_format = env("AERIAL_CLOCK_CUSTOM_FORMAT", "%H:%M"),
  }
  local corner = env("AERIAL_CLOCK_CORNER", "bottomRight")
  local font_size = math.floor(tonumber(env("AERIAL_CLOCK_FONT_SIZE", "48")) or 48)
  local font = env("AERIAL_CLOCK_FONT", "")
  local margin = math.floor(tonumber(env("AERIAL_CLOCK_MARGIN", "60")) or 60)
  local color = clock.rgb_to_ass_bgr(env("AERIAL_CLOCK_COLOR", "FFFFFF"))
  local offset_minutes = clock.offset_minutes_from_env(os.getenv("AERIAL_CLOCK_OFFSET_MINUTES"))
  local align = clock.alignment_for(corner)

  local function ass_escape(text)
    return tostring(text):gsub("\\", "\\\\"):gsub("{", "\\{"):gsub("}", "\\}")
  end

  local function position_for(name)
    if name == "topLeft" then
      return margin, margin
    elseif name == "topRight" then
      return 1920 - margin, margin
    elseif name == "bottomLeft" then
      return margin, 1080 - margin
    elseif name == "center" then
      return 960, 540
    end
    return 1920 - margin, 1080 - margin
  end

  local function font_tag()
    if font == "" then
      return ""
    end
    return "\\fn" .. ass_escape(font)
  end

  local overlay = mp.create_osd_overlay("ass-events")
  overlay.res_x = 1920
  overlay.res_y = 1080

  local function update()
    local x, y = position_for(corner)
    local text = clock.format_time(os.time() + offset_minutes * 60, cfg)
    overlay.data = string.format(
      "{\\an%d\\fs%d\\bord2\\shad1\\1c%s%s\\pos(%d,%d)}%s",
      align,
      font_size,
      color,
      font_tag(),
      x,
      y,
      ass_escape(text)
    )
    overlay:update()
  end

  local function safe_update()
    local update_ok, update_err = pcall(update)
    if not update_ok and mp and mp.msg and mp.msg.error then
      mp.msg.error("clock overlay update failed: " .. tostring(update_err))
    end
  end

  safe_update()
  mp.add_periodic_timer(1, safe_update)
end)

if not ok and mp and mp.msg and mp.msg.error then
  mp.msg.error("clock overlay disabled: " .. tostring(err))
end

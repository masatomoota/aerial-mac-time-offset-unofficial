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

  local function truthy(value)
    return value == true or value == "1" or value == "true" or value == "yes" or value == "on"
  end

  local function number_env(name, default)
    local value = tonumber(env(name, tostring(default)))
    if value == nil then
      return default
    end
    return value
  end

  local function base_position(corner, margin)
    corner = clock.normalize_corner(corner)
    if corner == "topLeft" then
      return margin, margin
    elseif corner == "topCenter" then
      return 960, margin
    elseif corner == "topRight" then
      return 1920 - margin, margin
    elseif corner == "bottomLeft" then
      return margin, 1080 - margin
    elseif corner == "bottomCenter" then
      return 960, 1080 - margin
    elseif corner == "bottomRight" then
      return 1920 - margin, 1080 - margin
    elseif corner == "left" then
      return margin, 540
    elseif corner == "right" then
      return 1920 - margin, 540
    elseif corner == "screenCenter" or corner == "center" then
      return 960, 540
    elseif corner == "absTopRight" then
      return 1920 - margin, margin
    end
    return 1920 - margin, 1080 - margin
  end

  local labels = {}

  local function basename(path)
    return tostring(path or ""):match("([^/\\]+)$") or tostring(path or "")
  end

  local function strip_ext(path)
    return tostring(path or ""):gsub("%.[^%.]+$", "")
  end

  local function read_file(path)
    local handle = io.open(path, "r")
    if not handle then
      return nil
    end
    local text = handle:read("*a")
    handle:close()
    return text
  end

  local function load_labels_json(path)
    local text = read_file(path)
    if not text then
      return false
    end
    local ok_utils, utils = pcall(require, "mp.utils")
    if not ok_utils or not utils or not utils.parse_json then
      return false
    end
    local payload = utils.parse_json(text)
    if type(payload) ~= "table" or type(payload.videos) ~= "table" then
      return false
    end
    for _, item in ipairs(payload.videos) do
      if type(item) == "table" and item.file then
        local label = item.accessibilityLabel or item.label or ""
        labels[item.file] = {
          accessibilityLabel = label,
          label = label,
          id = item.id or "",
          scene = item.scene or "",
          name = item.name ~= "" and item.name or label,
          pointsOfInterest = type(item.pointsOfInterest) == "table" and item.pointsOfInterest or {},
        }
      end
    end
    return true
  end

  local function load_labels_tsv(path)
    local handle = io.open(path, "r")
    if not handle then
      return false
    end
    for line in handle:lines() do
      local file, label, asset_id, scene, name, poi = line:match("^([^\t]+)\t([^\t]*)\t?([^\t]*)\t?([^\t]*)\t?([^\t]*)\t?(.*)$")
      if file and label then
        labels[file] = {
          accessibilityLabel = label,
          label = label,
          id = asset_id or "",
          scene = scene or "",
          name = name ~= "" and name or label,
          pointsOfInterest = clock.legacy_poi_points(poi or ""),
        }
      end
    end
    handle:close()
    return true
  end

  local function load_labels(path)
    if path:match("%.json$") and load_labels_json(path) then
      return
    end
    if path:match("%.tsv$") then
      local json_path = path:gsub("%.tsv$", ".json")
      if load_labels_json(json_path) then
        return
      end
    end
    load_labels_tsv(path)
  end

  load_labels(env("AERIAL_LABELS_FILE", "/var/lib/aerial-signage/labels.json"))

  local overlay = mp.create_osd_overlay("ass-events")
  overlay.res_x = 1920
  overlay.res_y = 1080

  local offset_minutes = clock.offset_minutes_from_env(os.getenv("AERIAL_CLOCK_OFFSET_MINUTES"))
  local osd_border = math.floor(number_env("AERIAL_OSD_BORDER", 0))
  local osd_shadow = math.floor(number_env("AERIAL_OSD_SHADOW", 1))
  local global_font = env("AERIAL_TEXT_FONT", "Segoe UI")
  local global_size = number_env("AERIAL_TEXT_SIZE", 2)
  local global_color = env("AERIAL_TEXT_COLOR", "FFFFFF")
  local margin = math.floor(number_env("AERIAL_TEXT_MARGIN", 60))
  local max_width = env("AERIAL_TEXT_MAX_WIDTH", "50")
  local random_interval = math.max(1, math.floor(number_env("AERIAL_TEXT_RANDOM_INTERVAL", 30)))
  local configured_position = clock.normalize_corner(env("AERIAL_TEXT_POSITION", "bottomLeft"))
  local active_position = configured_position
  local random_positions = { "topLeft", "topCenter", "topRight", "bottomLeft", "bottomCenter", "bottomRight", "left", "right", "screenCenter" }

  local line_specs = {}
  for i = 1, 4 do
    local prefix = "AERIAL_LINE" .. tostring(i)
    line_specs[#line_specs + 1] = {
      type = env(prefix .. "_TYPE", "none"),
      format = env(prefix .. "_FORMAT", "hh:mm:ss"),
      text = clock.unescape(env(prefix .. "_TEXT", "")),
      info_mode = env(prefix .. "_INFO_MODE", "poi"),
      default_font = truthy(env(prefix .. "_USE_DEFAULT_FONT", "1")),
      font = env(prefix .. "_FONT", ""),
      font_size = number_env(prefix .. "_FONT_SIZE", global_size),
      color = env(prefix .. "_COLOR", ""),
    }
  end

  local function current_video_text(mode)
    local path = nil
    if mp and mp.get_property then
      path = mp.get_property("path") or mp.get_property("filename")
    end
    local file = basename(path)
    local row = labels[file]
    local lang = env("AERIAL_DATE_LANG", "ja")
    local position = 0
    if mp and mp.get_property_number then
      position = mp.get_property_number("playback-time", nil) or mp.get_property_number("time-pos", 0) or 0
    end
    if row then
      return clock.location_text(row, mode, position, lang, strip_ext(file))
    end
    return strip_ext(file)
  end

  local function renderable_lines()
    local display_epoch = os.time() + offset_minutes * 60
    local lines = {}
    for _, spec in ipairs(line_specs) do
      local line_type = tostring(spec.type or "none")
      local text = ""
      if line_type == "timedate" or line_type == "time" then
        text = clock.format_moment(display_epoch, spec.format)
      elseif line_type == "videoname" or line_type == "videoName" then
        text = current_video_text("videoName")
      elseif line_type == "information" or line_type == "poi" then
        text = current_video_text(spec.info_mode ~= "" and spec.info_mode or "poi")
      elseif line_type == "message" or line_type == "text" then
        text = spec.text
      end
      if text ~= "" then
        local font = spec.default_font and global_font or (spec.font ~= "" and spec.font or global_font)
        local size_multiplier = spec.default_font and global_size or spec.font_size
        local color = spec.default_font and global_color or (spec.color ~= "" and spec.color or global_color)
        lines[#lines + 1] = {
          text = text,
          font = font,
          font_size = math.floor(25 * tonumber(size_multiplier or global_size)),
          color = color,
        }
      end
    end
    return lines
  end

  local function choose_random_position()
    active_position = random_positions[math.random(#random_positions)]
  end

  local function render_all()
    if configured_position == "random" and not active_position or active_position == "random" then
      choose_random_position()
    end
    local lines = renderable_lines()
    local x, y = base_position(active_position, margin)
    overlay.data = clock.build_text_ass_line({
      corner = active_position,
      font_size = math.floor(25 * global_size),
      border = osd_border,
      shadow = osd_shadow,
      color = global_color,
      shadow_color = "444444",
      font = global_font,
      x = x,
      y = y,
      max_width = max_width,
      lines = lines,
    })
    overlay:update()
  end

  local function safe_render()
    local update_ok, update_err = pcall(render_all)
    if not update_ok and mp and mp.msg and mp.msg.error then
      mp.msg.error("overlay update failed: " .. tostring(update_err))
    end
  end

  math.randomseed(os.time())
  if configured_position == "random" then
    choose_random_position()
    mp.add_periodic_timer(random_interval, function()
      choose_random_position()
      safe_render()
    end)
  end

  safe_render()
  mp.add_periodic_timer(1, safe_render)
  mp.register_event("file-loaded", safe_render)
  if mp.observe_property then
    mp.observe_property("playback-time", "number", safe_render)
  end
end)

if not ok and mp and mp.msg and mp.msg.error then
  mp.msg.error("overlay disabled: " .. tostring(err))
end

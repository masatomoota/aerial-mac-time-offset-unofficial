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
    return math.floor(value)
  end

  local function ass_escape(text)
    return tostring(text):gsub("\\", "\\\\"):gsub("{", "\\{"):gsub("}", "\\}"):gsub("\n", "\\N")
  end

  local function font_tag(font)
    if font == "" then
      return ""
    end
    return "\\fn" .. ass_escape(font)
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

  local function load_labels(path)
    local handle = io.open(path, "r")
    if not handle then
      return
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
          poi = poi or "",
        }
      end
    end
    handle:close()
  end

  load_labels(env("AERIAL_LABELS_FILE", "/var/lib/aerial-signage/labels.tsv"))

  local osd_border = number_env("AERIAL_OSD_BORDER", 0)
  local osd_shadow = number_env("AERIAL_OSD_SHADOW", 1)

  local layer_specs = {
    CLOCK = {
      prefix = "AERIAL_CLOCK",
      default_enabled = "1",
      default_corner = "bottomLeft",
      default_size = 50,
      default_margin = 60,
    },
    DATE = {
      prefix = "AERIAL_DATE",
      default_enabled = "0",
      default_corner = "bottomLeft",
      default_size = 25,
      default_margin = 60,
    },
    MSG = {
      prefix = "AERIAL_MSG",
      default_enabled = "0",
      default_corner = "bottomRight",
      default_size = 24,
      default_margin = 60,
    },
    LOC = {
      prefix = "AERIAL_LOC",
      default_enabled = "0",
      default_corner = "topRight",
      default_size = 28,
      default_margin = 60,
    },
  }

  local function build_layer(name)
    local spec = layer_specs[name]
    if env(spec.prefix .. "_ENABLED", spec.default_enabled) ~= "1" then
      return nil
    end
    local overlay = mp.create_osd_overlay("ass-events")
    overlay.res_x = 1920
    overlay.res_y = 1080
    return {
      name = name,
      overlay = overlay,
      corner = clock.normalize_corner(env(spec.prefix .. "_CORNER", spec.default_corner)),
      font_size = number_env(spec.prefix .. "_FONT_SIZE", spec.default_size),
      font = env(spec.prefix .. "_FONT", ""),
      color = clock.rgb_to_ass_bgr(env(spec.prefix .. "_COLOR", "FFFFFF")),
      margin = number_env(spec.prefix .. "_MARGIN", spec.default_margin),
      text = "",
    }
  end

  local layers = {}
  for _, name in ipairs({ "CLOCK", "DATE", "MSG", "LOC" }) do
    local layer = build_layer(name)
    if layer then
      layers[name] = layer
    end
  end

  local offset_minutes = clock.offset_minutes_from_env(os.getenv("AERIAL_CLOCK_OFFSET_MINUTES"))
  local clock_cfg = {
    format = env("AERIAL_CLOCK_FORMAT", "24h"),
    seconds = truthy(env("AERIAL_CLOCK_SECONDS", "0")),
    hide_ampm = truthy(env("AERIAL_CLOCK_HIDE_AMPM", "0")),
    custom_format = env("AERIAL_CLOCK_CUSTOM_FORMAT", "%H:%M"),
  }
  local date_cfg = {
    format = env("AERIAL_DATE_FORMAT", "textual"),
    with_year = truthy(env("AERIAL_DATE_WITH_YEAR", "0")),
    lang = env("AERIAL_DATE_LANG", "ja"),
    custom_format = env("AERIAL_DATE_CUSTOM_FORMAT", "%Y-%m-%d"),
  }

  if layers.MSG then
    layers.MSG.text = clock.unescape(env("AERIAL_MSG_TEXT", "Studio Vibes Wi-Fi\\nSSID : fcm-dkym-booth\\nPW : dkymfcm117"))
  end

  math.randomseed(os.time())
  local random_positions = { "topLeft", "topCenter", "topRight", "bottomLeft", "bottomCenter", "bottomRight", "left", "right", "screenCenter" }
  for _, layer in pairs(layers) do
    if layer.corner == "random" then
      layer.corner = random_positions[math.random(#random_positions)]
    end
  end

  local function current_location_text()
    local path = nil
    if mp and mp.get_property then
      path = mp.get_property("path") or mp.get_property("filename")
    end
    local file = basename(path)
    local row = labels[file]
    local mode = env("AERIAL_LOC_MODE", "accessibilityLabel")
    if row then
      if mode == "filename" then
        return strip_ext(file)
      elseif mode == "name" then
        return row.name ~= "" and row.name or row.accessibilityLabel
      elseif mode == "poi" then
        if row.poi ~= "" then
          local position = 0
          if mp and mp.get_property_number then
            position = mp.get_property_number("time-pos", 0) or 0
          end
          local best_time = -1
          local best_text = ""
          for seconds, text in row.poi:gmatch('"([^"]+)":"([^"]*)"') do
            local numeric_seconds = tonumber(seconds)
            if numeric_seconds and numeric_seconds <= position and numeric_seconds >= best_time then
              best_time = numeric_seconds
              best_text = text
            end
          end
          if best_text ~= "" then
            return best_text
          end
        end
        return row.accessibilityLabel
      end
      return row.accessibilityLabel ~= "" and row.accessibilityLabel or strip_ext(file)
    end
    return strip_ext(file)
  end

  local function refresh_dynamic_text()
    local display_epoch = os.time() + offset_minutes * 60
    if layers.CLOCK then
      layers.CLOCK.text = clock.format_time(display_epoch, clock_cfg)
    end
    if layers.DATE then
      layers.DATE.text = clock.format_date(display_epoch, date_cfg)
    end
  end

  local function refresh_file_text()
    if layers.LOC then
      layers.LOC.text = current_location_text()
    end
  end

  local function stack_offsets()
    local offsets = {}
    local occupied = {}
    for _, name in ipairs({ "CLOCK", "DATE", "MSG", "LOC" }) do
      local layer = layers[name]
      if layer then
        local corner = layer.corner
        occupied[corner] = occupied[corner] or 0
        offsets[name] = occupied[corner]
        occupied[corner] = occupied[corner] + math.floor(layer.font_size * 1.4)
      end
    end
    return offsets
  end

  local function render_all()
    local offsets = stack_offsets()
    for _, name in ipairs({ "CLOCK", "DATE", "MSG", "LOC" }) do
      local layer = layers[name]
      if layer then
        local x, y = base_position(layer.corner, layer.margin)
        local offset = offsets[name] or 0
        if layer.corner == "bottomLeft" or layer.corner == "bottomCenter" or layer.corner == "bottomRight" then
          y = y - offset
        elseif layer.corner == "topLeft" or layer.corner == "topCenter" or layer.corner == "topRight" or layer.corner == "screenCenter" or layer.corner == "left" or layer.corner == "right" or layer.corner == "absTopRight" then
          y = y + offset
        end
        layer.overlay.data = string.format(
          "{\\an%d\\fs%d\\bord" .. osd_border .. "\\shad" .. osd_shadow .. "\\1c%s%s\\pos(%d,%d)}%s",
          clock.alignment_for(layer.corner),
          layer.font_size,
          layer.color,
          font_tag(layer.font),
          x,
          y,
          ass_escape(layer.text)
        )
        layer.overlay:update()
      end
    end
  end

  local function safe_update_dynamic()
    local update_ok, update_err = pcall(function()
      refresh_dynamic_text()
      render_all()
    end)
    if not update_ok and mp and mp.msg and mp.msg.error then
      mp.msg.error("overlay update failed: " .. tostring(update_err))
    end
  end

  local function safe_update_file()
    local update_ok, update_err = pcall(function()
      refresh_file_text()
      render_all()
    end)
    if not update_ok and mp and mp.msg and mp.msg.error then
      mp.msg.error("location overlay update failed: " .. tostring(update_err))
    end
  end

  refresh_file_text()
  safe_update_dynamic()
  if layers.CLOCK or layers.DATE then
    mp.add_periodic_timer(1, safe_update_dynamic)
  end
  if layers.LOC then
    mp.register_event("file-loaded", safe_update_file)
  end
end)

if not ok and mp and mp.msg and mp.msg.error then
  mp.msg.error("overlay disabled: " .. tostring(err))
end

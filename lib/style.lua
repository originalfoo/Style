--[[
 _____ _         _         ___ ______ _____
/  ___| |       | |       / _ \| ___ \_   _|
\ `--.| |_ _   _| | ___  / /_\ \ |_/ / | |
 `--. \ __| | | | |/ _ \ |  _  |  __/  | |
/\__/ / |_| |_| | |  __/ | | | | |    _| |_
\____/ \__|\__, |_|\___| \_| |_|_|   /_____|
            __/ |
           |___/

A simplified DSL for defining LuaGuiElement
stylesheet prototypes; much more concise
than the cumbersome vanilla format.

style[type] 'name' { settings } --> prototype

By: Aubergine18 (git:aubergine10) | License: MIT

Source: https://github.com/aubergine10/Style

Docs: https://github.com/aubergine10/Style/wiki

--]]

-- luacheck: globals data color

-- quick bail if already initialised
if _G.style then
  return { style = _G.style, image = _G.image, sound = _G.sound }
end

-- get handle to where the gui styles are defined
local define = data.raw['gui-style'].default

-- retrieve an existing stylesheet
-- local sheet = style('sheet-name')
local style = setmetatable( {}, {
  __call = function( _, name, convert )
    if not name then -- return container
      return define
    elseif type(name) == 'table' then -- define new style
      local proto = name[2]
      name = name[1]
      if not name or not proto then
        error 'style: invalid syle definition'
      end
      if define[name] then
        error('style: prototype "'..name..'" already defined')
      end
      define[name] = proto
      return proto
    elseif convert then -- convert proto befor returning
      local proto = define[name]
      return proto and convert(proto, name) or nil, name
    else -- return raw proto
      return define[name], name
    end
  end
} )

local image, sound
    = {}   , {}

-- indexes for parsed arrays (see style.parse)
local x, y, w, h, top, right, bottom, left
    = 1, 2, 1, 2, 1  , 2    , 3     , 4

-- parse "padding"-like arrays
-- likely to change in future, internal use only
function style.parse( values, default )
  if values == nil then
    return { default, default, default, default }
  elseif type( values ) ~= 'table' then
    return { values, values, values, values }
  elseif #values == 1 then
    local val = values[top]
    values[right], values[bottom], values[left] = val, val, val
    return values
  elseif #values == 2 then
    values[bottom], values[left] = values[top], values[right]
    return values
  elseif #values == 4 then
    return values
  else
    error 'style.parse: specify none, 1, 2 or 4 values'
  end
end

local parse = style.parse

-- determine path to file
-- likely to change in future, internal use only
function style.addPathTo( filename )
  if filename:find( '__', 1, true ) == 1 then
    return filename
  else
    return (_G.style.path or '') .. filename
  end
end

-- no image
image.none = { type = 'none' }

-- composite image
function image.composite( filename )
  if not filename or type(filename) ~= 'string' then
    error 'image.composite: must specify filename'
  end
  return function( settings )
    -- finalize settings
    settings     = settings or {}
    local pos    = parse( settings.pos   , 0 )
    local corner = parse( settings.corner, 1 )
    -- build composite
    return {
      type         = 'composition';
      filename     = style.addPathTo( filename );
      position     = { pos   [x], pos   [y] };
      corner_size  = { corner[w], corner[h] };
      scale        = settings.scale;
      opacity      = settings.opacity; -- 0..1
      priority     = 'extra-high-no-scale';
    }
  end
end

-- monolith image
function image.monolith( filename )
  if not filename or type(filename) ~= 'string' then
    error 'image.monolith: must specify filename'
  end
  return function( settings )
    -- finalize settings
    settings    = settings or {}
    local pos   = parse( settings.pos, 0) -- x, y
    local size  = parse( settings.size  ) -- w, h
    local border= parse( settings.border) -- top, right, bottom, left
    -- build composite
    return {
      type = 'monolith';
      -- border props don't seem to do anything
      top_monolith_border    = border [top   ];
      right_monolith_border  = border [right ];
      bottom_monolith_border = border [bottom];
      left_monolith_border   = border [left  ];
      monolith_image = {
        filename     = style.addPathTo( filename );
        x            = pos  [x];
        y            = pos  [y];
        width        = size [w];
        height       = size [h];
        scale        = settings.scale; -- doesn't seem to work
        opacity      = settings.opacity; -- 0..1
        priority     = 'extra-high-no-scale';
      };
      -- stretch image to fill parent?
      stretch_monolith_image_to_size = settings.autoSize;
    }
  end
end

do--sandbox
  local validType = { string = true, table = true }

  -- click sound(s) for buttons
  -- specify multiple filenames in array for random sound each click
  function sound.effect( filenames, volume, preload )
    if not filenames or not validType[type( filenames )] then
      error 'sound.effect: must specify filename(s)'
    end
    volume  = volume or 1
    preload = preload or true
    if type( filenames ) == 'string' then filenames = { filenames } end
    -- build sound array
    local sounds = {}
    for i, filename in ipairs( filenames ) do
      sounds[i] = {
        filename = style.addPathTo( filename );
        volume   = volume;
        preload  = preload;
      }
    end--for
    return sounds
  end--function style.sound

end--sandbox


-- internal: parse common attributes used by most styles
function style.parse_common( settings )
  settings.size     = parse( settings.size     ) -- w, h
  settings.minSize  = parse( settings.minSize  ) -- w, h
  settings.maxSize  = parse( settings.maxSize  ) -- w, h
  settings.padding  = parse( settings.padding  ) -- top, right, bottom, left
end


-- intenral: used by flow, frame, scrollpane
function style.parse_flow( flow )
  if not flow then return end
  style.parse_common( flow )
  flow.autoSize = parse( flow.autoSize ) -- w, h (booleans)
  flow.spacing  = parse( flow.spacing  ) -- x, y
  -- build and return style
  return {
    type   = 'flow_style';
    parent = flow.extends or ( flow.extends ~= false and 'flow_style' );
    -- flow
    visible              = flow.visible;
    width                = flow.size    [w];
    height               = flow.size    [h];
    minimal_width        = flow.minSize [w];
    minimal_height       = flow.minSize [h];
    maximal_width        = flow.maxSize [w];
    maximal_height       = flow.maxSize [h];
    resize_row_to_width  = flow.autoSize[w];
    resize_to_row_height = flow.autoSize[h];
    top_padding          = flow.padding [top   ];
    right_padding        = flow.padding [right ];
    bottom_padding       = flow.padding [bottom];
    left_padding         = flow.padding [left  ];
    horizontal_spacing   = flow.spacing [x];
    vertical_spacing     = flow.spacing [y];
    max_on_row           = flow.maxOnRow; -- no idea what this does
  }
end


-- flow stylesheet
function style.flow( name )
  if not name or type(name) ~= 'string' then
    error 'style.flow: must specify a name'
  end
  return function( settings )
    local flow = settings or {}
    -- build and register style
    define[name] = style.parse_flow( flow )
    return define[name]
  end
end


-- frame stylesheet
function style.frame( name )
  if not name or type(name) ~= 'string' then
    error 'style.frame: must specify a name'
  end
  return function( settings )
    settings = settings or {}
    local frame   , title
        = settings, settings.title or {}
    style.parse_common( frame )
    frame.autoSize = parse( frame.autoSize ) -- w, h (booleans)
    title.padding  = parse( title.padding  ) -- top, right, bottom, left
    -- build and register style
    define[name] = {
      type   = 'frame_style';
      parent = frame.extends or ( frame.extends ~= false and 'frame_style' );
      -- frame
      visible                = frame.visible;
      graphical_set          = frame.background;
      width                  = frame.size    [w];
      height                 = frame.size    [h];
      minimal_width          = frame.minSize [w];
      minimal_height         = frame.minSize [h];
      maximal_width          = frame.maxSize [w];
      maximal_height         = frame.maxSize [h];
      resize_row_to_width    = frame.autoSize[w];
      resize_to_row_height   = frame.autoSize[h];
      top_padding            = frame.padding [top   ];
      right_padding          = frame.padding [right ];
      bottom_padding         = frame.padding [bottom];
      left_padding           = frame.padding [left  ];
      -- title
      font                   = title.font;
      font_color             = title.color;
      title_top_padding      = title.padding [top   ];
      title_right_padding    = title.padding [right ];
      title_bottom_padding   = title.padding [bottom];
      title_left_padding     = title.padding [left  ];
      -- flow
      flow_style = style.parse_flow( settings.flow )
    }--define
    return define[name]
  end
end


-- scrollpane stylesheet
function style.scrollpane( name )
  if not name or type(name) ~= 'string' then
    error 'style.scrollpane: must specify a name'
  end
  return function( settings )
    local pane = settings or {}
    local scrollbar = pane.scrollbar or {}
    style.parse_common( pane )
    scrollbar.spacing = parse( scrollbar.spacing ) -- x, y
    -- build and register style
    define[name] = {
      type   = 'scroll_pane_style';
      parent = pane.extends or ( pane.extends ~= false and 'scroll_pane_style' );
      -- scroll pane
      visible        = pane.visible;
      width          = pane.size    [w];
      height         = pane.size    [h];
      minimal_width  = pane.minSize [w];
      minimal_height = pane.minSize [h];
      maximal_width  = pane.maxSize [w];
      maximal_height = pane.maxSize [h];
      top_padding    = pane.padding [top   ];
      right_padding  = pane.padding [right ];
      bottom_padding = pane.padding [bottom];
      left_padding   = pane.padding [left  ];
      -- scrollbars
      horizontal_scroll_bar_spacing = scrollbar.spacing [x];
      vertical_scroll_bar_spacing   = scrollbar.spacing [y];
      -- flow
      flow_style = style.parse_flow( settings.flow )
    }
    return define[name]
  end
end


-- button stylesheet
function style.button( name )
  if not name or type(name) ~= 'string' then
    error 'style.button: must specify a name'
  end
  return function( settings )
    local button   = settings        or {}
    local default  = button.default  or {}
    local hover    = button.hover    or {}
    local clicked  = button.clicked  or {}
    local disabled = button.disabled or {}
    local line     = button.line     or {}
    style.parse_common( button )
    -- build and register style
    define[name] = {
      type   = 'button_style';
      parent = button.extends or ( button.extends ~= false and 'button_style' );
      -- button
      visible                = button.visible;
      scalable               = button.scalable; -- not sure if works; sprite button only?
      top_padding            = button.padding [top   ];
      right_padding          = button.padding [right ];
      bottom_padding         = button.padding [bottom];
      left_padding           = button.padding [left  ];
      width                  = button.size    [w];
      height                 = button.size    [h];
      minimal_width          = button.minSize [w];
      minimal_height         = button.minSize [h];
      maximal_width          = button.maxSize [w];
      maximal_height         = button.maxSize [h];
      -- button states
      default_graphical_set  = default.background;
      default_font_color     = default.color;
      hovered_graphical_set  = hover.background;
      hovered_font_color     = hover.color;
      clicked_graphical_set  = clicked.background;
      clicked_font_color     = clicked.color;
      disabled_graphical_set = disabled.background;
      disabled_font_color    = disabled.color;
      -- caption
      align                  = button.align;
      font                   = button.font;
      -- horizontal line (no idea if this works)
      line_color             = line.color;
      line_width             = line.width;
      -- pie chart
      pie_progress_color     = button.pieColor;
      -- sounds
      left_click_sound       = button.sound;
    }
    return define[name]
  end
end


-- label stylesheet
function style.label( name )
  if not name or type(name) ~= 'string' then
    error 'style.label: must specify a name'
  end
  return function( settings )
    local label = settings or {}
    style.parse_common( label )
    -- build and register style
    define[name] = {
      type   = 'label_style';
      parent = label.extends or ( label.extends ~= false and 'label_style' );
      -- label
      visible                = label.visible;
      width                  = label.size    [w];
      height                 = label.size    [h];
      minimal_width          = label.minSize [w];
      minimal_height         = label.minSize [h];
      maximal_width          = label.maxSize [w];
      maximal_height         = label.maxSize [h];
      top_padding            = label.padding [top   ];
      right_padding          = label.padding [right ];
      bottom_padding         = label.padding [bottom];
      left_padding           = label.padding [left  ];
      -- caption
      align                  = label.align; -- not tested, only works if width set?
      font                   = label.font;
      font_color             = label.color;
    }
    return define[name]
  end
end


-- publish globals
_G.style, _G.image, _G.sound = style, image, sound

return { style = style, image = image, sound = sound }
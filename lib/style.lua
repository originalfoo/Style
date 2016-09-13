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
`*_style` prototypes in a much more concise
manner than the cumbersome vanilla format.

style[type] 'name' { settings } --> prototype

By: Aubergine18 (git:aubergine10) | License: MIT

Source: https://github.com/aubergine10/Style

Docs: https://github.com/aubergine10/Style/wiki/style-API

--]]

-- luacheck: globals data

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

-- DEPRECATED - DO NOT USE!!
function style.addPathTo( filename )
  if filename:find( '__', 1, true ) == 1 then
    return filename
  else
    local prefix = _G.style.path or ''
    return prefix .. filename
  end
end


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


-- checkbox stylesheet
function style.checkbox( name )
  if not name or type(name) ~= 'string' then
    error 'style.checkbox: must specify a name'
  end
  return function( settings )
    local checkbox = settings          or {}
    local default  = checkbox.default  or {}
    local hover    = checkbox.hover    or {}
    local clicked  = checkbox.clicked  or {}
    local selected = checkbox.selected or {}
    style.parse_common( checkbox )
    -- build and register style
    define[name] = {
      type   = 'checkbox_style';
      parent = checkbox.extends or ( checkbox.extends ~= false and 'checkbox_style' );
      -- checkbox
      visible            = checkbox.visible;
      top_padding        = checkbox.padding [top   ];
      right_padding      = checkbox.padding [right ];
      bottom_padding     = checkbox.padding [bottom];
      left_padding       = checkbox.padding [left  ];
      width              = checkbox.size    [w];
      height             = checkbox.size    [h];
      minimal_width      = checkbox.minSize [w];
      minimal_height     = checkbox.minSize [h];
      maximal_width      = checkbox.maxSize [w];
      maximal_height     = checkbox.maxSize [h];
      -- checkbox states
      default_background = default.background;
      hovered_background = hover.background;
      clicked_background = clicked.background;
      checked            = selected.background; -- overlays on top  of other states
      -- caption
      align              = checkbox.align;
      font_color         = checkbox.color;
      font               = checkbox.font;
      -- sounds
      left_click_sound   = checkbox.sound;
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
      visible        = label.visible;
      width          = label.size    [w];
      height         = label.size    [h];
      minimal_width  = label.minSize [w];
      minimal_height = label.minSize [h];
      maximal_width  = label.maxSize [w];
      maximal_height = label.maxSize [h];
      top_padding    = label.padding [top   ];
      right_padding  = label.padding [right ];
      bottom_padding = label.padding [bottom];
      left_padding   = label.padding [left  ];
      -- caption
      align          = label.align; -- not tested, only works if width set?
      font           = label.font;
      font_color     = label.color;
    }
    return define[name]
  end
end


-- textfield stylesheet
function style.textfield( name )
  if not name or type(name) ~= 'string' then
    error 'style.textfield: must specify a name'
  end
  return function( settings )
    local textfield = settings or {}
    style.parse_common( textfield )
    -- build and register style
    define[name] = {
      type   = 'textfield_style';
      parent = textfield.extends or ( textfield.extends ~= false and 'textfield_style' );
      -- textfield
      visible        = textfield.visible;
      width          = textfield.size    [w];
      height         = textfield.size    [h];
      minimal_width  = textfield.minSize [w];
      minimal_height = textfield.minSize [h];
      maximal_width  = textfield.maxSize [w];
      maximal_height = textfield.maxSize [h];
      top_padding    = textfield.padding [top   ];
      right_padding  = textfield.padding [right ];
      bottom_padding = textfield.padding [bottom];
      left_padding   = textfield.padding [left  ];
      graphical_set  = textfield.background;
      -- caption
      align          = textfield.align; -- not tested, only works if width set?
      font           = textfield.font;
      font_color     = textfield.color;
      -- the background color of selected text
      selection_background_color = textfield.selectedColor;
    }
    return define[name]
  end
end


-- publish globals
_G.style = style
return style
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

-- luacheck: globals data color log

local style = { api = true }

-- get handle to where the gui styles are defined
local define = data.raw['gui-style'].default

-- indexes for parsed arrays (see style.expamd)
local x, y, w, h, top, right, bottom, left
    = 1, 2, 1, 2, 1  , 2    , 3     , 4

-- internal: parse "padding"-like arrays
function style.expamd( values, default )
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
    error 'style.expamd: specify none, 1, 2 or 4 values'
  end
end

local expand = style.expamd

-- DEPRECATED - DO NOT USE!!
function style.parse( ... )
  log 'style.parse is deprecated, use style.expand instead'
  return style.expand( ... )
end

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
  settings.size     = expand( settings.size     ) -- w, h
  settings.minSize  = expand( settings.minSize  ) -- w, h
  settings.maxSize  = expand( settings.maxSize  ) -- w, h
  settings.padding  = expand( settings.padding  ) -- top, right, bottom, left
end

-- internal: parse color properties
function style.parse_color( ... )
  local typ = type( ... )
  if typ == 'nil' then
    return nil
  elseif typ == 'string' then -- hex
    return color( ... )
  elseif typ == 'table' then
    return ...
  elseif typ == 'number' then
    local vals = table.pack( ... )

    -- convert indices to color properties
      vals.r      , vals.g      , vals.b      , vals.a
    = vals[1] or 0, vals[2] or 0, vals[3] or 0, vals[4] or 1

    return vals
  else
    return nil
  end
end

local parseColor = style.parse_color

-- intenral: used by flow, frame, scrollpane
function style.parse_flow( flow )
  if not flow then return end
  style.parse_common( flow )
  flow.autoSize = expand( flow.autoSize ) -- w, h (booleans)
  flow.spacing  = expand( flow.spacing  ) -- x, y
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

function style.flow( name )
  if type(name) ~= 'string' then
    error 'style.flow: invalid stylesheet name'
  end
  return function( settings )
    local flow = settings or {}
    -- build and register style
    define[name] = style.parse_flow( flow )
    return define[name]
  end
end

function style.frame( name )
  if type(name) ~= 'string' then
    error 'style.frame: invalid stylesheet name'
  end
  return function( settings )
    settings = settings or {}
    local frame   , title
        = settings, settings.title or {}
    style.parse_common( frame )
    frame.autoSize = expand( frame.autoSize ) -- w, h (booleans)
    title.padding  = expand( title.padding  ) -- top, right, bottom, left
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
      font_color             = parseColor( title.color );
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

function style.scrollpane( name )
  if type(name) ~= 'string' then
    error 'style.scrollpane: invalid stylesheet name'
  end
  return function( settings )
    local pane = settings or {}
    local scrollbar = pane.scrollbar or {}
    style.parse_common( pane )
    scrollbar.spacing = expand( scrollbar.spacing ) -- x, y
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

function style.button( name )
  if type(name) ~= 'string' then
    error 'style.button: invalid stylesheet name'
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
      default_font_color     = parseColor( default.color );
      hovered_graphical_set  = hover.background;
      hovered_font_color     = parseColor( hover.color );
      clicked_graphical_set  = clicked.background;
      clicked_font_color     = parseColor( clicked.color );
      disabled_graphical_set = disabled.background;
      disabled_font_color    = parseColor( disabled.color );
      -- caption
      align                  = button.align;
      font                   = button.font;
      -- horizontal line (no idea if this works)
      line_color             = parseColor( line.color );
      line_width             = line.width;
      -- pie chart
      pie_progress_color     = parseColor( button.pieColor );
      -- sounds
      left_click_sound       = button.sound;
    }
    return define[name]
  end
end

-- internal: build either radiobutton or checkbox
function style.build_toggle_element( name, settings, type )
  local element  = settings         or {}
  local default  = element.default  or {}
  local hover    = element.hover    or {}
  local clicked  = element.clicked  or {}
  local selected = element.selected or {}
  style.parse_common( element )
  -- build and register style
  define[name] = {
    type   = type;
    parent = element.extends or ( element.extends ~= false and type );
    -- element
    visible            = element.visible;
    top_padding        = element.padding [top   ];
    right_padding      = element.padding [right ];
    bottom_padding     = element.padding [bottom];
    left_padding       = element.padding [left  ];
    width              = element.size    [w];
    height             = element.size    [h];
    minimal_width      = element.minSize [w];
    minimal_height     = element.minSize [h];
    maximal_width      = element.maxSize [w];
    maximal_height     = element.maxSize [h];
    -- element states
    default_background = default.background;
    hovered_background = hover.background;
    clicked_background = clicked.background;
    -- checkbox:
    checked            = selected.background; -- overlays on top  of other states
    -- radiobutton:
    selected           = selected.background; -- overlays on top  of other states
    -- caption
    align              = element.align;
    font_color         = parseColor( element.color );
    font               = element.font;
    -- sounds
    left_click_sound   = element.sound;
  }
  return define[name]
end

function style.radiobutton( name )
  if type(name) ~= 'string' then
    error 'style.radiobutton: invalid stylesheet name'
  end
  return function( settings )
    return style.build_toggle_element( name, settings, 'radiobutton_style' )
  end
end

function style.checkbox( name )
  if type(name) ~= 'string' then
    error 'style.checkbox: invalid stylesheet name'
  end
  return function( settings )
    return style.build_toggle_element( name, settings, 'checkbox_style' )
  end
end

function style.label( name )
  if type(name) ~= 'string' then
    error 'style.label: invalid stylesheet name'
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
      font_color     = parseColor( label.color );
    }
    return define[name]
  end
end

function style.textfield( name )
  if type(name) ~= 'string' then
    error 'style.textfield: invalid stylesheet name'
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
      font_color     = parseColor( textfield.color );
      -- the background color of highlighted (selected) text
      selection_background_color = textfield.highlight;
    }
    return define[name]
  end
end

function style.table( name )
  if type(name) ~= 'string' then
    error 'style.table: invalid stylesheet name'
  end
  return function( settings )
    local table = settings  or {}
    local row   = table.row or {}
    local col   = table.col or {}
    style.parse_common( table )
    table.spacing = expand( table.spacing ) -- x, y
    -- build and register style
    define[name] = {
      type   = 'table_style';
      parent = table.extends or ( table.extends ~= false and 'table_style' );
      -- table
      visible               = table.visible;
      width                 = table.size    [w];
      height                = table.size    [h];
      minimal_width         = table.minSize [w];
      minimal_height        = table.minSize [h];
      maximal_width         = table.maxSize [w];
      maximal_height        = table.maxSize [h];
      top_padding           = table.padding [top   ];
      right_padding         = table.padding [right ];
      bottom_padding        = table.padding [bottom];
      left_padding          = table.padding [left  ];
      horizontal_spacing    = table.spacing [x];
      vertical_spacing      = table.spacing [y];
      cell_padding          = table.cellPadding;
      -- row
      hovered_row_color     = parseColor( row.hovered );
      selected_row_color    = parseColor( row.selected );
      odd_row_graphical_set = row.background;
      -- column
      column_graphical_set  = col.background;
      column_ordering_ascending_indicator  = col.ascending;
      column_ordering_descending_indicator = col.descending;
    }
    return define[name]
  end
end

-- style()
_G.style = setmetatable( style, {

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

  end--function __call

} )

return _G.style
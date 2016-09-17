--[[
 _____                              ___ ______ _____
|_   _|                            / _ \| ___ \_   _|
  | | _ __ ___   __ _  __ _  ___  / /_\ \ |_/ / | |
  | || '_ ` _ \ / _` |/ _` |/ _ \ |  _  |  __/  | |
 _| || | | | | | (_| | (_| |  __/ | | | | |    _| |_
|____/_| |_| |_|\__,_|\__, |\___| \_| |_|_|   |____/
                       __/ |
                      |___/

Simple API for creating image descriptor tables.

Requires style.lua's expand function

By: Aubergine18 (git:aubergine10) | License: MIT

Source: https://github.com/aubergine10/Style

Docs: https://github.com/aubergine10/Style/wiki/image-API

--]]

-- luacheck: globals data color

local image = { api = true }

-- indexes for parsed arrays (see style.expnd)
local x, y, w, h, top, right, bottom, left
    = 1, 2, 1, 2, 1  , 2    , 3     , 4

local expand         , parseColor
    = _G.style.expand, _G.style.parse_color

local defPri  , guiPri
    = 'medium', 'extra-high-no-scale'

-- determine path to image file
-- deprecated style.path used as fallback until 1.0 release
function image.addPathTo( filename )
  if filename:find( '__', 1, true ) == 1 then
    return filename
  else
    local prefix = _G.image.path or (_G.style and _G.style.path) or ''
    return prefix .. filename
  end
end

-- no image
image.none = { type = 'none' }

-- a raw image which can be used in various prototypes
-- (not just LuaGuiElement styles)
function image.raw( filename, apiMethod )
  if type(filename) ~= 'string' then
    error( (apiMethod or 'image.raw') .. ': invalid filename' )
  end
  return function( settings )
    local _    = settings or {}
    _.pos      = expand( _.pos, 0 ) -- x, y
    _.size     = expand( _.size   ) -- w, h
    _.tint     = parseColor( _.tint )
    _.priority = _.priority or guiPri

    return {
      filename = image.addPathTo( filename );

      opacity  = _.opacity  ;
      x        = _.pos[x]   ;
      y        = _.pos[y]   ;
      priority = _.priority ;
      scale    = _.scale    ;
      width    = _.size[w]  ;
      height   = _.size[h]  ;
      tint     = _.tint     ;
    }, _
  end
end

-- monolith image
local stretch = 'stretch_monolith_image_to_size'

function image.monolith( filename )
  return function( settings )
    local raw, _ = image.raw( filename, 'image.monolith' )( settings )

    _.border = expand( settings.border ) -- top, right, bottom, left

    if type( _.autoSize ) == 'table' then
      _.autoSize = _.autoSize[1]
    end

    return {
      type                   = 'monolith'       ;
      monolith_image         = raw              ;

      [stretch]              = _.autoSize       ;
      top_monolith_border    = _.border[top   ] ;
      right_monolith_border  = _.border[right ] ;
      bottom_monolith_border = _.border[bottom] ;
      left_monolith_border   = _.border[left  ] ;
    }
  end
end

-- composite image
function image.composite( filename )
  if type(filename) ~= 'string' then
    error 'image.composite: invalid filename'
  end
  return function( settings )
    local _  = settings or {}
    _.pos    = expand( _.pos   , 0 )
    _.corner = expand( _.corner, 1 )
    _.tint   = parseColor( _.tint )

    return {
      type        = 'composition'                ;
      filename    = image.addPathTo( filename )  ;

      position    = { _.pos[x]   , _.pos[y]    } ;
      corner_size = { _.corner[w], _.corner[h] } ;
      scale       = _.scale                      ;
      opacity     = _.opacity                    ;
      priority    = _.priority or guiPri         ;
      tint        = _.tint                       ;
    }
  end
end

-- animation image, used primarily for entities
local axial = 'axially_symmetrical'

function image.animation( filename )
  if type(filename) ~= 'string' then
    error 'image.animation: invalid filename'
  end
  return function( settings )
    local _ = settings or {}
    _.pos   = expand( _.pos  , 0 ) -- x, y
    _.shift = expand( _.shift, 0 ) -- x, y
    _.size  = expand( _.size     ) -- w, h
    _.tint  = parseColor( _.tint )

    return {
      filename        = image.addPathTo( filename );

      blend_mode      = _.blend              ;
      line_length     = _.columns            ;
      direction_count = _.directions or 1    ;
      flags           = _.flags              ;
      frame_count     = _.frames             ;
      [axial]         = _.mirror             ;
      x               = _.pos[x]             ;
      y               = _.pos[y]             ;
      priority        = _.priority or defPri ;
      scale           = _.scale              ;
      shift           = _.shift              ;
      width           = _.size[w]            ;
      height          = _.size[h]            ;
      speed           = _.speed or 1         ;
      tint            = _.tint               ;
    }
  end
end

_G.image = image
return _G.image
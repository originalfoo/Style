--[[
 _____ _                _             _      ___ ______ _____
/  ___| |              | |           | |    / _ \| ___ \_   _|
\ `--.| |__   ___  _ __| |_ ___ _   _| |_  / /_\ \ |_/ / | |
 `--. \ '_ \ / _ \| '__| __/ __| | | | __| |  _  |  __/  | |
/\__/ / | | | (_) | |  | || (__| |_| | |_  | | | | |    _| |_
\____/|_| |_|\___/|_|   \__\___|\__,_|\__| \_| |_|_|   |____/

Simple API for creating custom-input prototypes.

By: Aubergine18 (git:aubergine10) | License: MIT

Source: https://github.com/aubergine10/Style

Docs: https://github.com/aubergine10/Style/wiki/shortcut-API

--]]

-- luacheck: globals data

-- quick bail if already initialised
if _G.shortcut then return _G.shortcut end

local shortcut = setmetatable( {}, {
  __call = function( self, keys )
    if not keys or type(keys) ~= 'string' then
      error 'shortcut: must specify shortcut keys'
    end
    keys = keys:upper()
    return function( settings )
      if not settings or type(settings) ~= 'table' or not settings.event then
        error 'shortcut: must specify event name'
      end
      local proto = {
        type = 'custom-input';
        name = settings.event;
        key_sequence = keys;
        consuming    = self.consume[settings.scope or settings.consume] or 'none';
      }
      data:extend{ proto }
      return proto
    end
  end
})

-- internal dictionary to map scope to consuming
shortcut.consume = {
  -- vanilla
  ['none'       ] = 'none';
  ['all'        ] = 'all';
  ['script-only'] = 'script-only';
  ['game-only'  ] = 'game-only';
  -- shortform
  ['script'     ] = 'script-only';
  ['game'       ] = 'game-only';
  -- api
  ['global'     ] = 'none';
  ['self'       ] = 'all';
  ['self + game'] = 'script-only';
  ['self + mods'] = 'game-only';
}

_G.shortcut = shortcut
return shortcut
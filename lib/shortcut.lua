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

-- luacheck: globals data log

local shortcut = { api = true, used = {} }

-- internal: log newly added/discovered shortcut.
-- asterisk at end of log entry means shortcut was
-- defined using the shortcut api
function shortcut:log( keys, event, consume, api )
  log(
    'Shortcut "'..keys..'" '..
    'triggers "'..event..'" '..
    '('..(consume or 'none')..')'..api
  )
  self.used[keys] = true
end

-- are keys already used?
function shortcut:defined( keys )
  return self.used[keys]
end

-- internal:
-- find any keys that were defined without this api
-- and add them to our list of used keys
function shortcut:refresh()
  local shortcuts = data.raw['custom-input']
  if not shortcuts then return end

  for _,input in pairs(shortcuts) do

    local keys = input.key_sequence:upper()

    if not self:defined(keys) then
      self:log( keys, input.name, input.consuming, '' )
    end

  end--for
end

-- internal:
-- choose earliest unused key from selection,
-- or if none available use first selection
function shortcut:chooseFrom( selection )
  -- refresh list of used keys
  self:refresh()
  -- choose first unused if possible
  local keys
  for i = 1, #selection do
    local choice = selection[i]:upper()
    if not self:defined(choice) then
      keys = choice
      break
    end
  end
  -- revert to first item if necessary
  return keys or selection[1]
end

-- internal: dictionary to map scope to consuming
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

local valid = { string = true, table = true }

-- shortcut() method
-- used to define keyboard shortcuts
_G.shortcut = setmetatable( shortcut, {

  __call = function( self, keys )

    if not valid[type(keys)] then
      error 'shortcut: invalid shortcut keys'
    end

    if type(keys) == 'table' then
      keys = self:chooseFrom( keys )
    else
      keys = keys:upper()
    end

    return function( settings )

      if type(settings) ~= 'table' or not settings.event then
        error 'shortcut: invalid settings table or event name'
      end

      local proto = {
        type = 'custom-input';
        name = settings.event;
        key_sequence = keys;
        consuming = self.consume[
          settings.scope or settings.consume or 'none'
        ];
      }

      data:extend { proto }

      self:log( keys, settings.event, proto.consuming, '*' )
      return proto

    end--function settings

  end

})

return _G.shortcut
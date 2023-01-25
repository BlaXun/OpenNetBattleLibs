--- The Field Watcher watches (duh!) the tiles on the field and invokes callback-methods
--- to inform about changes in states 
---
--- Currently the Field Watcher watches the tiles for change regarding TileState and change in owning team
field_watcher = {}

--- identifier_from_tile
-- Returns a unique identifier for the given tile
-- @param tile The tile for whicha identifier will be returned
-- @return A identifier (String) used to identify the tile
function identifier_from_tile(tile)
  return tostring(tile:x()) .. '/' .. tostring(tile:y())
end

--- create_watcher
-- Creates a FieldWatcher-Instance and returns it
-- Before it will report any changes you will have to use the FieldWatchers register()-method (usually in the players init or on_battle_start()-method)
-- Once you got the instance you can set the following functions 
--
-- on_tile_state_did_change(tile,previous_state,new_state)
-- Called whenever the state / type of a tile changed
-- List of possible TileState-Values https://protobasilisk.github.io/OpenNetBattleDocs/api/#tilestate
--
-- on_tile_team_did_change(tile,previous_team,new_team)
-- Called whenever the team changed that owns the given tile
-- List of possible Team-Values https://protobasilisk.github.io/OpenNetBattleDocs/api/#team
--
-- Once you are done with the FieldWatcher please call the unregister()-method (usually in the players on_battle_end()-method)

-- @param entity The entity on which the FieldWatcher (Component) will be registered. Usually a player
-- @param field  A reference to the field that should be watched
-- @return a new FieldWatcher
function field_watcher.create_watcher(entity, field)

  local watcher = Battle.Component.new(entity,Lifetimes.Battlestep)
  watcher.owner = entity
  watcher.field = field
  watcher.previous_panel_states = {}
  watcher.previous_panel_team = {}

  watcher.on_tile_state_did_change = nil
  watcher.on_tile_team_did_change = nil
  watcher.on_update = nil
  watcher.total_frames_processed = 0
  watcher.all_tiles = function(self)
    return self.field:find_tiles(function(t)
      return not t:is_edge()
    end)
  end

  for k, v in pairs(watcher:all_tiles()) do
    watcher.previous_panel_states[identifier_from_tile(v)] = v:get_state()
    watcher.previous_panel_team[identifier_from_tile(v)] = v:get_team()
  end

  watcher.compare_tiles = function(self)

    for k, v in pairs(self:all_tiles()) do

      local previous_team = self.previous_panel_team[identifier_from_tile(v)]
      local previous_state = self.previous_panel_states[identifier_from_tile(v)]
      local current_state = v:get_state()
      local current_team = v:get_team()

      if previous_state ~= current_state then
        if self.on_tile_state_did_change ~= nil then
          self.on_tile_state_did_change(v, previous_state, current_state)
        end
      end

      if previous_team ~= current_team then
        if self.on_tile_team_did_change ~= nil then
          self.on_tile_team_did_change(v, previous_team, current_team)
        end
      end

      self.previous_panel_states[identifier_from_tile(v)] = current_state
      self.previous_panel_team[identifier_from_tile(v)] = current_team
    end

  end

  watcher.update_func = function(self, elapsed_time)
    self.total_frames_processed = self.total_frames_processed+elapsed_time
    self:compare_tiles()

    if self.on_update ~= nil then
      self:on_update(elapsed_time)
    end
  end

  watcher.register = function(self)
    self.owner:register_component(self)
  end

  watcher.unregister = function(self)
    if self:is_injected() then
      self:eject()
    end
  end

  return watcher
end

return field_watcher
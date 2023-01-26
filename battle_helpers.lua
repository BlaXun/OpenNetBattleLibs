--Functions for easy reuse in scripts
--Version 1.8 (optionally ignore neutral team for get_first_target_ahead, add is_tile_free_for_movement)
--Version 1.7 (fixed find targets ahead getting non character/obstacles)

battle_helpers = {}

--- does_artifact_with_name_for_team_exist_on_field
-- Checks the field wether a artifact with the given name exists
-- that belongs to the given team
--
-- @param artifact_name The name of the artifact to be found
-- @param team The team to which the artifact must belong
-- @param The field. We need it to perform the search
function battle_helpers.does_artifact_with_name_for_team_exist_on_field(artifact_name,team,field)
  local artifacts = field:find_entities(function(t)
    return t:get_name() == artifact_name and t:get_team() == team
  end)

  return #artifacts > 0
end

-- TODO: Test this one!
function battle_helpers.create_shakre_effect(entity, duration_in_seconds, strength)
  local shake_artifact = Battle.Artifact.new()
  local time = 0

  shake_artifact.update_func = function(self, delta)
      time = time+delta;
      self:shake_camera(strength, duration_in_seconds)
      if time >= duration_in_seconds then
        self:delete()
      end
  end

  entity:get_field():spawn(shake_artifact, entity:get_current_tile())
end

--- get_random_enemy_tile
-- Returns a random tile that belongs to the opponents of the given entity
-- @param entity The entity for which enemies a random tle should be returned
-- @return A tile or nil
function battle_helpers.get_random_enemy_tile(entity)

	local enemy_tiles = battle_helpers.get_enemy_tiles(entity)
	local random_tile = nil -- Or a default tile, in case there are no valid tiles
	if #enemy_tiles > 0 then
	  random_tile = enemy_tiles[math.random(1, #enemy_tiles)]
	end
	
	return random_tile
end

--- get_enemy_tiles
-- Returns all tiles for the opposing faction of this entity
-- @param entity The entity for which enemies the tiles should be returned
-- @return A list with all enemy tiles
function battle_helpers.get_enemy_tiles(entity)
  local field = entity:get_field()
	local enemy_tiles = field:find_tiles(function(t)
	  return not t:is_edge() and t:get_team() ~= entity:get_team()
	end)
	
	return enemy_tiles
end

--- Returns all tiles with the given state (TileState)
function battle_helpers.all_tiles_with_state(field, state)
	local tiles_with_state = field:find_tiles(function(t)
	  return not t:is_edge() and t:get_state() == state
	end)
	
	return tiles_with_state
end

--- get_enemy_last_column_tiles
-- Returns all tiles at the very last column of the enemies to that user
-- @param The user for which all enemy tiles should be found
-- @param A list of all tiles on the last colum
function battle_helpers.get_enemy_last_column_tiles(user)
  local enemy_tiles = {}
  local field = user:get_field()
  if user:get_team() == Team.Red then
    table.insert(enemy_tiles,field:tile_at(6,1))
    table.insert(enemy_tiles,field:tile_at(6,2))
    table.insert(enemy_tiles,field:tile_at(6,3))
  elseif user:get_team() == Team.Blue then
    table.insert(enemy_tiles,field:tile_at(1,1))
    table.insert(enemy_tiles,field:tile_at(1,2))
    table.insert(enemy_tiles,field:tile_at(1,3))
  end

	return enemy_tiles
end

--- spawn_visual_artifact
-- Creates a visual artifact and returns it
-- @param charachter A entity. The facing of this character is used to set the artifacts facing
-- @param tile The tile on which the artifact should be spawned. If it is a edge tile and "show_alo_on_edge_tiles" is either not set or set to false no artifact will be created
-- @oaram texture A texture that was previously loaded using Engine.load_texture
-- @param animation_path The path to the .animation file of this vfx
-- @param animation_state The state in the .animation file that shall be used
-- @param position_x Horizontal offset to display the vfx
-- @param position_y Vertical offset to display the vfx
-- @param dont_flip_offset If set to true the given position_x and position_y values will not be flipped when facing is Direction.Left
-- @param show_also_on_edge_tiles Wether to spawn the artifact even if the tile is an edge tile
-- @return The created artifact or nil
function battle_helpers.spawn_visual_artifact(character,tile,texture,animation_path,animation_state,position_x,position_y,dont_flip_offset,show_also_on_edge_tiles)

  if show_also_on_edge_tiles == true or tile:is_edge() == false then
    local visual_artifact = Battle.Artifact.new()
    visual_artifact:set_texture(texture,true)
    local anim = visual_artifact:get_animation()
    local sprite = visual_artifact:sprite()
    local field = character:get_field()
    local facing = character:get_facing()
    anim:load(animation_path)
    anim:set_state(animation_state)
    anim:on_complete(function()
      visual_artifact:delete()
    end)
    if facing == Direction.Left and not dont_flip_offset then
      position_x = position_x *-1
    end
    visual_artifact:set_facing(facing)
    visual_artifact:set_offset(position_x,position_y)
    anim:refresh(sprite)
    field:spawn(visual_artifact, tile:x(), tile:y())
    return visual_artifact
  end

  return nil
end

--- find_all_enemis
-- Returns a list of all enemies (Entity) on the field
-- @param user The player for which all enemies should be returned
-- @return A list containing all enemies
function battle_helpers.find_all_enemies(user)
  local field = user:get_field()
  local user_team = user:get_team()
  local list = field:find_characters(function(character)
    if character:get_team() ~= user_team then
      --if you are not with me, you are against me
      return true
    end
  end)
  return list    
end

--- find_targets_ahead
-- Returns all targets for the given user that are on the same row infront of that user
-- In This context targets are characters and obstacles
--
-- @param user The user (Entity) for which to return targets
-- @return A list containing all found targets
function battle_helpers.find_targets_ahead(user)
  local field = user:get_field()
  local user_tile = user:get_current_tile()
  local user_team = user:get_team()
  local user_facing = user:get_facing()
  local list = field:find_entities(function(entity)
    if Battle.Character.from(entity) == nil and Battle.Obstacle.from(entity) == nil then
      return false
    end
    local entity_tile = entity:get_current_tile()
    if entity_tile:y() == user_tile:y() and entity:get_team() ~= user_team then
      if user_facing == Direction.Left then
        if entity_tile:x() < user_tile:x() then
          return true
        end
      elseif user_facing == Direction.Right then
        if entity_tile:x() > user_tile:x() then
          return true
        end
      end
      return false
    end
  end)
  return list
end

--- get_first_target_ahead
-- Returns the first target for the given user that is on the same row infront of that user
-- In This context targets are characters and obstacles
--
-- @param user The user (Entity) for which to return the first target
-- @return Either a valid target (Character / Obstacle) or nil
function battle_helpers.get_first_target_ahead(user,ignore_neutral_team)
  local targets = battle_helpers.find_targets_ahead(user)
  local filtered_targets = {}
  if ignore_neutral_team then
    for index, target in ipairs(targets) do
      if target:get_team() ~= Team.Other then
        filtered_targets[#filtered_targets+1] = target
      end
    end
  else
    filtered_targets = targets
  end
  table.sort(filtered_targets,function (a, b)
    return a:get_current_tile():x() > b:get_current_tile():x()
  end)
  if #filtered_targets == 0 then
    return nil
  end
  if filtered_targets == Direction.Left then
    return filtered_targets[1]
  else
    return filtered_targets[#filtered_targets]
  end
end

function battle_helpers.drop_trace_fx(target_artifact,lifetime_ms)
  --drop an afterimage artifact mimicking the appearance of an existing spell/artifact/character and fade it out over it's lifetime_ms
  local fx = Battle.Artifact.new()
  local anim = target_artifact:get_animation()
  local field = target_artifact:get_field()
  local offset = target_artifact:get_offset()
  local texture = target_artifact:get_texture()
  local elevation = target_artifact:get_elevation()
  fx:set_facing(target_artifact:get_facing())
  fx:set_texture(texture, true)
  fx:get_animation():copy_from(anim)
  fx:get_animation():set_state(anim:get_state())
  fx:set_offset(offset.x,offset.y)
  fx:set_elevation(elevation)
  fx:get_animation():refresh(fx:sprite())
  fx.starting_lifetime_ms = lifetime_ms
  fx.lifetime_ms = lifetime_ms
  fx.update_func = function(self, dt)
    self.lifetime_ms = math.max(0, self.lifetime_ms-math.floor(dt*1000))
    local alpha = math.floor((fx.lifetime_ms/fx.starting_lifetime_ms)*255)
    self:set_color(Color.new(0, 0, 0,alpha))

    if self.lifetime_ms == 0 then 
      self:erase()
    end
  end

	local tile = target_artifact:get_current_tile()
    field:spawn(fx, tile:x(), tile:y())
    return fx
end

function battle_helpers.is_tile_free_for_movement(tile,character,must_be_walkable)
  --Basic check to see if a tile is suitable for a chracter of a team to move to
  if tile:get_team() ~= character:get_team() and tile:get_team() ~= Team.Other then 
    return false 
  end
  if not tile:is_walkable() and must_be_walkable then 
    return false 
  end
  if tile:is_edge() or tile:is_hidden() then
    return false
  end
  local occupants = tile:find_entities(function(other_entity)
    if Battle.Character.from(other_entity) == nil and Battle.Obstacle.from(other_entity) == nil then
      --if it is not a character and it is not an obstacle
      return false
    end
    return true
  end)
  if #occupants > 0 then 
    return false
  end
  
  return true
end

return battle_helpers
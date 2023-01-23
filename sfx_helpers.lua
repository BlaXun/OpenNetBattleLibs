-- Helper class to take care of stuff regarding soundeffects

sfx_helpers = {}

--- load_sounds
-- Loads the given sounds into memory and returns them as a easily accessible map 

-- @param sfx_names_and_paths A map that uses a sound identifier of your choice as key and the soundeffects name (and if required, path) as value
-- @return A map with the loaded sounds. Use the same key as you provided on the input parameter to access the sound
-- Example usage
-- 
-- local sounds = load_sounds({SHOT_SFX = 'Shot.ogg', HIT_SFX = 'Hit.ogg'})
-- Engine.play_audio(sounds.SHOT_SFX,AudioPriority.Highest)
function sfx_helpers.load_sounds(sfx_names_and_paths)

  local sfx_by_names_map = {}
  for k, v in pairs(sfx_names_and_paths) do
    sfx_by_names_map[k] = Engine.load_audio(_modpath..v)
  end
  return sfx_by_names_map
end

--- play_sfx
-- Encapsulates the Engine.play_sound method to offer a single method for playing sound
-- The method can be decorated / enhanced however you see fit. But using this all the time makes
-- sure you can easily change stuff around
--
-- @param sound The sound file to play (must be a sound that was previously loaded using Engine.load_audio)
-- @param priority The priority to use for this effect. Must be of type AudioPriority
--                 AudioPriority.Lowest, AudioPriority.Low, AudioPriority.High, AudioPriority.Highest
--
-- (https://protobasilisk.github.io/OpenNetBattleDocs/api/#audiopriority)
function sfx_helpers.play_sfx(sound, priority)
  Engine.play_audio(sound, priority)
end

return sfx_helpers
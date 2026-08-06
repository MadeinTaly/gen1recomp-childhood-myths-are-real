-- Childhood Mythos Are Real
--
-- The playground legends of 1998, made true. Not the glitches -- those are
-- their own mod -- but the things people *swore* were in the cartridge and
-- never were.
--
-- ------- the rule this mod is built around
--
-- **Turning it off must never cost the player their save.**
--
-- That is not a slogan, it is a specific failure this engine has. A saved
-- game stores the map you stood on by id, and `MapLoader.build` opens with
--
--     assert(def, "unknown map: " .. tostring(mapId))
--
-- with no pcall anywhere up the call chain (OverworldController:285). So a
-- player who saves inside a map this mod invented, then disables the mod,
-- does not lose a myth -- the game refuses to start.
--
-- The fix is the `save.writing` event, which fires after the world has been
-- captured into the save table and before a byte reaches disk. If the
-- player is standing in one of ours when they save, the save records them
-- at home in Pallet Town instead. With the mod on that is a small surprise;
-- with the mod gone it is the difference between a working cartridge and a
-- brick.
--
-- Everything else follows the same rule. Every Pokemon this mod can hand
-- you is a species the base game already has, so a full box survives the
-- mod being removed. Nothing here registers a species -- that is a later
-- version's problem, and it is a much harder one.
--
-- ------- the myths
--
-- TRUCK   Use Strength on the truck by the S.S. Anne and Mew is under it.
--         The truck is real. Mew was not. Now it is.
-- GHOST   Before the Silph Scope the tower ghosts are unidentifiable
--         shapes, and everyone believed one of them could be caught.
-- GARDEN  A hidden passage behind Bill's house, with rare Pokemon in it.
-- ANNE    The S.S. Anne never comes back. After the Elite Four, it does.

return function(mod)
  local Flags = require("src.script.Flags")
  local TextBox = require("src.render.TextBox")
  local BattleState = require("src.battle.BattleState")

  -- ------- options
  --
  -- One switch per myth. All on: someone who opts into an experimental mod
  -- called "Childhood Mythos Are Real" wants the myths. The structural half
  -- of each (a map, an object) is registered at load, so switching one back
  -- on takes a restart; the trigger half is read live, so switching one OFF
  -- stops it happening immediately.
  mod.options:define({
    { key = "truck",  label = "THE TRUCK",    type = "toggle", default = true },
    { key = "ghost",  label = "TOWER GHOST",  type = "toggle", default = true },
    { key = "garden", label = "BILLS GARDEN", type = "toggle", default = true },
    { key = "anne",   label = "SS ANNE",      type = "toggle", default = true },
  })

  local function on(key)
    local ok, value = pcall(function() return mod.options:get(key) end)
    if not ok or value == nil then return true end
    return value and true or false
  end

  -- ------- transparency
  --
  -- Every map this mod invents is listed here, and nothing may be added to
  -- the mod without being added here too. See the header.
  -- Listed unconditionally on purpose: rehome must recognise the id even in
  -- a session where the garden was not registered, because the SAVE being
  -- read may have been written by a session where it was.
  local GARDEN = "CHILDHOOD_MYTHS_BILLS_GARDEN"
  local OUR_MAPS = { [GARDEN] = true }

  -- You wake up in your own bed.
  --
  -- REDS_HOUSE_2F's bed is the solid pair of blocks in the top-left corner
  -- (16 and 17, tiles 0..3 x 0..1), so the nearest tile a player can
  -- actually stand on is (0,2): directly below it, which is the step you
  -- take getting out of bed. The whole of row 2 is floor, so this cannot
  -- land anyone inside a wall.
  --
  -- It is also the only reading of this that is kind. Saving inside a
  -- legend and waking at home turns the one piece of necessary bookkeeping
  -- in this mod into the oldest ending there is.
  local HOME = { map = "REDS_HOUSE_2F", x = 0, y = 2, facing = "down" }

  local function rehome(save)
    local p = save and save.player
    if not (p and OUR_MAPS[p.map]) then return false end
    p.map, p.x, p.y, p.facing = HOME.map, HOME.x, HOME.y, HOME.facing
    p.surfing = false
    return true
  end
  mod.exports.rehome = rehome

  mod.events:on("save.writing", function(payload)
    rehome(payload and payload.save)
  end)

  -- ------- shared helpers
  --
  -- Nothing here assumes the dataset. A myth anchored to a map or a species
  -- the player's data does not carry is simply not registered, rather than
  -- registered and left to fail validation -- which is what CI's three-
  -- species fixture proved, eleven errors at a time.
  -- `mod.content.<name>` is a facade, not the Registry object: it carries
  -- register / override / patch / remove / get / each and nothing else, so
  -- `:has()` is not on it. Asking through a pcall that turns any error into
  -- "no" is worse than useless -- it switched off all four myths at once
  -- and the mod still loaded clean. Ask with `get`, and let a mistake here
  -- be loud.
  local function have(registry, id)
    local reg = mod.content[registry]
    return reg ~= nil and reg:get(id) ~= nil
  end

  local function found(key) return mod.save:get(key) == true end
  local function remember(key) mod.save:set(key, true) end

  -- Text first, battle underneath: the stack pops the box the player is
  -- reading and the battle is what it uncovers.
  local function encounter(game, species, level, message)
    game.stack:push(BattleState.newWild(game, species, level))
    game.stack:push(TextBox.new(game, message))
  end

  local function carrying(game, itemId)
    return (game.save.inventory and game.save.inventory[itemId] or 0) > 0
  end

  -- ------- myth 1: Mew under the truck
  --
  -- The dock decodes as fourteen-by-six blocks of plain pier and carries no
  -- objects at all, so the truck is this mod's -- original art, drawn in
  -- tools/make_truck.py, in the four values an object sprite is allowed.
  --
  -- The dock's object list is EMPTY in the base data, which is the only
  -- reason a whole-field patch is safe here. See BILLS_HOUSE below for the
  -- case where it is not.
  local HAVE_DOCK = have("maps", "VERMILION_DOCK")

  mod.content.sprites:register("CHILDHOOD_MYTHS_SPRITE_TRUCK", {
    id = "CHILDHOOD_MYTHS_SPRITE_TRUCK",
    image = "mods/childhood_myths_are_real/assets/truck.png",
    frames = 1,
    walker = false,
  })

  -- Tile (4,0) is pier the player can stand beside: the walkable strip on
  -- this map is the top two rows, so they face it from (4,1).
  local TRUCK_X, TRUCK_Y = 4, 0

  if HAVE_DOCK then
  mod.content.maps:patch("VERMILION_DOCK", {
    objects = {
      { index = 1, name = "CHILDHOOD_MYTHS_TRUCK", sprite = "CHILDHOOD_MYTHS_SPRITE_TRUCK",
        x = TRUCK_X, y = TRUCK_Y, movement = "STAY", range = "NONE" },
    },
  })

  mod.content.map_scripts:register("VERMILION_DOCK", {
    onInteract = function(game, _, fx, fy)
      if fx ~= TRUCK_X or fy ~= TRUCK_Y then return false end
      if not on("truck") then return false end

      if found("truck") then
        game.stack:push(TextBox.new(game,
          "The TRUCK is where\nyou left it.\fWhatever was under\nit is yours now."))
        return true
      end

      -- The rumour was always specific: you needed STRENGTH. Without it the
      -- truck is just a truck, which is what it was for twenty-five years.
      if not carrying(game, "HM_STRENGTH") then
        game.stack:push(TextBox.new(game,
          "A parked TRUCK.\fIt will not budge.\nSomething very\vstrong could\vmove it."))
        return true
      end

      remember("truck")
      encounter(game, "MEW", 7,
        "You shoved the\nTRUCK aside!\fSomething was\nsleeping under it!")
      return true
    end,
  })
  end

  -- ------- myth 2: the ghost that can be caught
  --
  -- Map.ghostBattles is data, not code -- it reads def.ghostBattles and only
  -- falls back to the SILPH_SCOPE default for POKEMON_TOWER maps -- so the
  -- tower's unidentifiable wild battles are untouched here. This is one
  -- specific ghost, in the dead end at (3,10) on 6F, and only while the
  -- player still has no Scope. That is the myth exactly: before the Scope,
  -- there is a way.
  local GHOST_X, GHOST_Y = 3, 10

  if have("maps", "POKEMON_TOWER_6F") and have("pokemon", "GASTLY") then
  mod.content.map_scripts:register("POKEMON_TOWER_6F", {
    onStep = function(game, _, x, y)
      if x ~= GHOST_X or y ~= GHOST_Y then return false end
      if not on("ghost") then return false end
      if found("ghost") then return false end
      if carrying(game, "SILPH_SCOPE") then return false end

      remember("ghost")
      encounter(game, "GASTLY", 30,
        "The air here is\ncold and still.\fA SHAPE notices\nyou, and waits.")
      return true
    end,
  })
  end

  -- ------- myth 3: the garden behind Bill's house
  --
  -- A real map, so it can be walked and it can hold wild Pokemon. Every
  -- species in it is one the base game already has: a Pokemon caught here
  -- survives this mod being deleted, which a mod-registered species would
  -- not.
  --
  -- Blocks are OVERWORLD: 3 is solid, 1 is path, 11 is the tall grass whose
  -- tile the encounter check looks for. Border 3 so the edges read as fence
  -- rather than as somewhere to walk off.
  -- The garden needs a tileset to be drawn from, a house to hang off, and
  -- something to put in the grass. Any of those missing and there is no
  -- garden -- which is the honest outcome, not eleven validation errors.
  local WANTED = {
    { level = 28, species = "EEVEE" },
    { level = 30, species = "DITTO" },
    { level = 28, species = "EEVEE" },
    { level = 32, species = "CHANSEY" },
    { level = 30, species = "DITTO" },
    { level = 34, species = "PORYGON" },
    { level = 30, species = "LAPRAS" },
    { level = 32, species = "CHANSEY" },
    { level = 34, species = "PORYGON" },
    { level = 36, species = "LAPRAS" },
  }
  local SLOTS = {}
  for _, slot in ipairs(WANTED) do
    if have("pokemon", slot.species) then SLOTS[#SLOTS + 1] = slot end
  end

  local HAVE_GARDEN = have("maps", "BILLS_HOUSE")
    and have("tilesets", "OVERWORLD") and #SLOTS > 0

  local G, P, W = 11, 1, 3
  if HAVE_GARDEN then
  mod.content.maps:register(GARDEN, {
    id = GARDEN, label = "BILL'S GARDEN", index = 1001,
    tileset = "OVERWORLD", width = 6, height = 6, borderBlock = W,
    palette = "PALLET",
    blocks = {
      W, W, W, W, W, W,
      W, G, G, G, G, W,
      W, G, P, P, G, W,
      W, G, P, P, G, W,
      W, G, G, G, G, W,
      W, W, P, P, W, W,
    },
    -- tiles, not blocks: block (2,5) covers x=4..5, y=10..11
    warps = {
      { x = 5, y = 11, destMap = "BILLS_HOUSE", destWarp = 3 },
      { x = 6, y = 11, destMap = "BILLS_HOUSE", destWarp = 3 },
    },
  })

  mod.content.encounters:register(GARDEN, { grass = { rate = 25, slots = SLOTS } })

  -- BILLS_HOUSE already HAS two warps, and a record patch replaces a field
  -- rather than growing it, so the original pair is restated here. Losing
  -- them would seal the player inside the house -- the test asserts both
  -- still point outdoors, because this is the kind of thing that breaks
  -- quietly and only for someone who already went in.
  --
  -- (0,2) is one of the two isolated floor tiles in the corners of that
  -- room. A passage you find by walking into a corner is what the rumour
  -- described.
  mod.content.maps:patch("BILLS_HOUSE", {
    warps = {
      { x = 2, y = 7, destMap = "LAST_MAP", destWarp = 1 },
      { x = 3, y = 7, destMap = "LAST_MAP", destWarp = 1 },
      { x = 0, y = 2, destMap = GARDEN, destWarp = 1 },
    },
  })
  end

  -- ------- myth 4: the S.S. Anne comes back
  --
  -- EVENT_SS_ANNE_LEFT is an ordinary flag, and everything about the dock
  -- and the ship's ten maps keys off it. Clearing it puts the ship back
  -- where it was. The gate is the Elite Four, so it reads as the reward it
  -- always should have been rather than as the ship never leaving.
  if have("maps", "VERMILION_CITY") then
  mod.content.map_scripts:register("VERMILION_CITY", {
    onEnter = function(game)
      if not on("anne") then return end
      if found("anne") then return end
      if not Flags.get(game.save, "EVENT_BEAT_CHAMPION_RIVAL") then return end
      if not Flags.get(game.save, "EVENT_SS_ANNE_LEFT") then return end

      remember("anne")
      Flags.clear(game.save, "EVENT_SS_ANNE_LEFT")
      game.stack:push(TextBox.new(game,
        "A ship's horn!\fThe S.S. ANNE has\ncome back into\vport."))
    end,
  })
  end

  mod.exports.maps = OUR_MAPS
  mod.exports.home = HOME
end

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
-- KID     A kid on the dock, standing near the same truck everyone swore
--         hid something. Talk to him and he keeps score of the other
--         four, and has one of his own once they have all come true.

return function(mod)
  local Flags = require("src.script.Flags")
  local TextBox = require("src.render.TextBox")
  local BattleState = require("src.battle.BattleState")

  -- ------- options
  --
  -- One switch per myth, and one more for the kid who keeps score of them.
  -- All on: someone who opts into an experimental mod called "Childhood
  -- Mythos Are Real" wants the myths. The structural half of each (a map,
  -- an object) is registered at load, so switching one back on takes a
  -- restart; the trigger half is read live, so switching one OFF stops it
  -- happening immediately.
  mod.options:define({
    { key = "truck",  label = "THE TRUCK",    type = "toggle", default = true },
    { key = "ghost",  label = "TOWER GHOST",  type = "toggle", default = true },
    { key = "garden", label = "BILLS GARDEN", type = "toggle", default = true },
    { key = "anne",   label = "SS ANNE",      type = "toggle", default = true },
    { key = "kid",    label = "THE KID",      type = "toggle", default = true },
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

  -- ------- STRENGTH is a move, not an item in the bag
  --
  -- 0.2.0 asked `carrying(game, "HM_STRENGTH")`, and there is no such item
  -- id anywhere in a Gen 1 dataset: the extractor's own item list
  -- (tools/rom_manifest.json, "items") carries no HM or TM entry at all --
  -- `hms` is a list of MOVE names, CUT/FLY/SURF/STRENGTH/FLASH. So that
  -- test could never be true, on anybody's save, and the truck answered
  -- "it will not budge" forever. This is the whole of the truck myth not
  -- working, and it was invisible because the suite's own fixture invented
  -- the same id the mod did.
  --
  -- The engine's own question is `ow:partyKnows("STRENGTH")`, which is what
  -- the field-move menu asks (src/world/WorldAPI.lua:185) and which also
  -- honours the badge gate -- the rumour's "something very strong" is a
  -- Pokemon that knows the move, exactly as pushing a boulder is. The
  -- second argument of an onInteract IS the live overworld
  -- (OverworldController:2033 passes `self`), so this needs nothing new.
  --
  -- The fallback reads the party directly, for a call with no overworld
  -- behind it -- which is what the unit suite does.
  local function canUseStrength(game, ow)
    if ow and type(ow.partyKnows) == "function" then
      local ok, mon = pcall(function() return ow:partyKnows("STRENGTH") end)
      if ok then return mon ~= nil end
    end
    for _, mon in ipairs((game.save and game.save.party) or {}) do
      for _, move in ipairs(mon.moves or {}) do
        local id = type(move) == "table" and move.id or move
        if id == "STRENGTH" then return true end
      end
    end
    return false
  end

  -- ------- a cell the player can actually stand on
  --
  -- Every myth anchored to a base-game map picks a cell by hand, and 0.2.0
  -- picked all of them from map dimensions rather than from map DATA: the
  -- blocks come out of the player's own ROM and this repository has none,
  -- so "the dead end at (3,10)" and "the corner at (0,2)" were educated
  -- guesses that nothing ever checked. A guess that lands on a wall is a
  -- myth that never fires and never says why -- which is exactly what was
  -- reported.
  --
  -- So the cell is now CHECKED against the loaded map, through the engine's
  -- own walkability (Map:isWalkableCell, the same table Collision consults),
  -- and when the authored one turns out to be solid the nearest standable
  -- cell to it is used instead. Nearest rather than first: it keeps the
  -- author's intent -- that corner, that side of the room -- when the guess
  -- was merely off by a tile.
  --
  -- A dataset that cannot answer (no blocks, no tileset, an engine without
  -- the module) leaves the authored cell alone. Unknown is not "solid".
  local Map = select(2, pcall(require, "src.world.Map"))
  if type(Map) ~= "table" or type(Map.new) ~= "function" then Map = nil end

  local builtMaps = setmetatable({}, { __mode = "k" })
  local function mapView(mapDef)
    if not (Map and type(mapDef) == "table" and mapDef.blocks) then return nil end
    local hit = builtMaps[mapDef]
    if hit ~= nil then return hit or nil end
    local tileset = mapDef.tileset and mod.content.tilesets:get(mapDef.tileset)
    local ok, view = pcall(Map.new, mapDef, tileset)
    builtMaps[mapDef] = (ok and view) or false
    return (ok and view) or nil
  end

  -- true / false / nil, where nil is "this dataset cannot say"
  local function standable(mapDef, x, y)
    local view = mapView(mapDef)
    if not view then return nil end
    local ok, walkable = pcall(function()
      return view:inBounds(x, y) and view:isWalkableCell(x, y) or false
    end)
    if not ok then return nil end
    return walkable
  end

  -- def.width/height are BLOCKS; a block is two cells on a side.
  local function cellBounds(mapDef)
    return (tonumber(mapDef.width) or 0) * 2, (tonumber(mapDef.height) or 0) * 2
  end

  local function nearestStandable(mapDef, preferred, accept)
    if standable(mapDef, preferred.x, preferred.y) ~= false then
      return preferred, false
    end
    local w, h = cellBounds(mapDef)
    local best, bestDistance
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        if standable(mapDef, x, y) and (not accept or accept(x, y)) then
          local distance = math.abs(x - preferred.x) + math.abs(y - preferred.y)
          if not bestDistance or distance < bestDistance then
            best, bestDistance = { x = x, y = y }, distance
          end
        end
      end
    end
    if not best then return preferred, false end
    return best, true
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

  -- ------- myth 5: the kid, who keeps score
  --
  -- He is not a fifth legend, he is a witness -- the one every playground
  -- had, who had heard all the others and would tell you about the one you
  -- had not found yet. He lives on this same dock rather than a map of his
  -- own on purpose: `maps:patch` REPLACES the `objects` field rather than
  -- growing it (see BILLS_HOUSE below for the case where that matters for
  -- warps), so a second `patch` call here would silently delete the truck.
  -- He is therefore a second entry in the SAME patch, added below, and his
  -- `onInteract` is a second branch in the SAME map script, checked first.
  --
  -- (6,0) is two tiles further down the same walkable top row the truck
  -- sits on, close enough to read as "hanging around the truck" and far
  -- enough that the two objects and the two players standing to face them,
  -- at (4,1) and (6,1), never overlap.
  local KID_X, KID_Y = 6, 0

  -- No new art for a kid standing still: reuse a sprite the base game
  -- already carries. Every id below was read out of tools/rom_manifest.json,
  -- which is the extractor's own list of the 72 overworld sprites it pulls
  -- from the cartridge -- these are names that exist, not names that sound
  -- like they should. GAMEBOY_KID leads because it is the rumour's own
  -- portrait: a boy holding the machine the rumour was about. The rest are
  -- fallbacks for a dataset that carries a different subset. None existing
  -- is not an error -- see the file's header helper comment -- it just
  -- means no kid this run, same as a myth missing its map.
  local KID_SPRITE_CANDIDATES = {
    "SPRITE_GAMEBOY_KID", "SPRITE_YOUNGSTER", "SPRITE_LITTLE_BOY", "SPRITE_BUG_CATCHER",
  }
  local KID_SPRITE
  for _, candidate in ipairs(KID_SPRITE_CANDIDATES) do
    if have("sprites", candidate) then KID_SPRITE = candidate break end
  end

  -- The reward for four out of four is one wild MEWTWO, not a second MEW.
  -- MEW is already spoken for by the truck, and repeating it would read as
  -- a rerun rather than as a fifth rumour paying off. MEWTWO was the OTHER
  -- big schoolyard claim of 1998 -- "there's one you can't even see" -- and
  -- it is a species the base game already has (Cerulean Cave, postgame),
  -- so a box holding one survives this mod being removed exactly the way
  -- the other three myths' Pokemon do.
  local KID_REWARD_SPECIES, KID_REWARD_LEVEL = "MEWTWO", 70

  -- Everything the kid needs has to exist, or he is not registered at all:
  -- the dock to stand on, a sprite to be drawn with, and the species his
  -- payoff hands out. A kid who exists but can never pay off the fourth
  -- myth is worse than no kid.
  local HAVE_KID = HAVE_DOCK and KID_SPRITE ~= nil
    and have("pokemon", KID_REWARD_SPECIES)

  -- Order matters here: it is the order he reports on, and the order the
  -- header comment and the README list the four in.
  local MYTH_ORDER = { "truck", "ghost", "garden", "anne" }
  local MYTH_LABEL = {
    truck = "THE TRUCK", ghost = "TOWER GHOST", garden = "BILLS GARDEN", anne = "SS ANNE",
  }
  -- The rumour as the playground told it -- never a tile, never a map id.
  local MYTH_CLAIM = {
    truck  = "SOMETHING SLEEPS\nUNDER A TRUCK\vBY THE DOCK!",
    ghost  = "ONE OF THE GHOSTS\nIN THE TOWER YOU\vCAN CATCH!",
    garden = "THERE'S A SECRET\nGARDEN SOMEWHERE\vWITH RARE ONES!",
    anne   = "THE SHIP COMES\nBACK SOMEDAY,\vI SWEAR IT!",
  }

  local function missingMyths()
    local missing = {}
    for _, key in ipairs(MYTH_ORDER) do
      if not found(key) then missing[#missing + 1] = key end
    end
    return missing
  end

  if HAVE_DOCK then
  local dockObjects = {
    { index = 1, name = "CHILDHOOD_MYTHS_TRUCK", sprite = "CHILDHOOD_MYTHS_SPRITE_TRUCK",
      x = TRUCK_X, y = TRUCK_Y, movement = "STAY", range = "NONE" },
  }
  if HAVE_KID then
    dockObjects[#dockObjects + 1] = {
      index = 2, name = "CHILDHOOD_MYTHS_KID", sprite = KID_SPRITE,
      x = KID_X, y = KID_Y, movement = "STAY", range = "NONE",
    }
  end

  mod.content.maps:patch("VERMILION_DOCK", { objects = dockObjects })

  mod.content.map_scripts:register("VERMILION_DOCK", {
    onInteract = function(game, ow, fx, fy)
      -- Checked first, and returns unconditionally either way, so this
      -- never falls through into the truck's own coordinate check below.
      if HAVE_KID and fx == KID_X and fy == KID_Y then
        if not on("kid") then return false end

        if found("kid") then
          game.stack:push(TextBox.new(game,
            "THANKS AGAIN FOR\nBELIEVING ME."))
          return true
        end

        local missing = missingMyths()

        if #missing == 0 then
          remember("kid")
          encounter(game, KID_REWARD_SPECIES, KID_REWARD_LEVEL,
            "YOU WERE RIGHT\nABOUT ALL OF IT!\fEVEN THIS ONE\nWAS TRUE ALL\vALONG...")
          return true
        end

        if #missing == #MYTH_ORDER then
          -- Nothing proven yet: he introduces himself and repeats ONE
          -- rumour, picked at random, the way any one kid on any one
          -- playground only ever swore to the one his cousin told him.
          local pick = MYTH_ORDER[math.random(#MYTH_ORDER)]
          game.stack:push(TextBox.new(game,
            "MY COUSIN SWEARS\nHE'S SEEN STUFF.\f" .. MYTH_CLAIM[pick]))
          return true
        end

        -- Some found, some not: he admits the ones you proved him right
        -- about, then names every one still outstanding, one to a page.
        local pages = { "SO IT WAS TRUE!\nI KNEW IT!" }
        for _, key in ipairs(missing) do
          pages[#pages + 1] = "STILL LOOKING\nFOR " .. MYTH_LABEL[key] .. "?"
        end
        game.stack:push(TextBox.new(game, table.concat(pages, "\f")))
        return true
      end

      if fx ~= TRUCK_X or fy ~= TRUCK_Y then return false end
      if not on("truck") then return false end

      if found("truck") then
        game.stack:push(TextBox.new(game,
          "The TRUCK is where\nyou left it.\fWhatever was under\nit is yours now."))
        return true
      end

      -- The rumour was always specific: you needed STRENGTH. Without it the
      -- truck is just a truck, which is what it was for twenty-five years.
      -- Asked of the party, not of the bag -- see canUseStrength.
      if not canUseStrength(game, ow) then
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
  --
  -- (3,10) is where the dead end was authored to be, and 0.2.0 trusted that
  -- number blind. It is now put to the map: if the player's own 6F has a
  -- wall there, the nearest cell they can stand on takes over, so the myth
  -- fires on a floor rather than never.
  local GHOST_CELL = { x = 3, y = 10 }

  -- ------- and why it is no longer ONE tile
  --
  -- 0.3.0-beta.1 moved this cell off a wall, which was necessary and not
  -- sufficient. A floor of six-by-ten blocks is roughly two hundred cells,
  -- and a player climbing the tower walks maybe a dozen of them: a trigger
  -- that waits on ONE named cell is a trigger almost nobody meets, whether
  -- or not that cell is solid. That is the likelier half of "it just doesn't
  -- happen" -- and it is not a bug I could have found by reading the map,
  -- because the map was never the problem.
  --
  -- So the floor is the trigger. Anywhere on 6F, while the rumour's own
  -- conditions hold -- the Scope not in the bag, this myth not yet found --
  -- the shape notices you. That is also closer to what was actually
  -- whispered: not "stand on this tile", but "one of the ghosts up there is
  -- catchable".
  --
  -- Not instantly, though: WALK_BEFORE steps of grace, so it does not fire
  -- on the stairs the moment the floor loads. Cheap and boring on purpose --
  -- a counter in this screen's own save, not a random roll, so it cannot
  -- fail to happen and cannot happen twice.
  local WALK_BEFORE = 6

  if have("maps", "POKEMON_TOWER_6F") and have("pokemon", "GASTLY") then
  mod.content.map_scripts:register("POKEMON_TOWER_6F", {
    onStep = function(game, _, x, y)
      if not on("ghost") then return false end
      if found("ghost") then return false end
      if carrying(game, "SILPH_SCOPE") then return false end

      local walked = (mod.save:get("ghostSteps") or 0) + 1
      mod.save:set("ghostSteps", walked)
      if walked < WALK_BEFORE then return false end

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

  -- BILLS_HOUSE already HAS its own warps, and a record patch replaces a
  -- field rather than growing it -- so the door out has to survive this
  -- patch or the player is sealed inside the house.
  --
  -- 0.2.0 restated that pair BY HAND, as (2,7) and (3,7) pointing at
  -- LAST_MAP. That is two guesses about somebody else's data: if the real
  -- pair sits anywhere else, or names its destination differently, the
  -- patch does not preserve the exits, it REPLACES them with a door that
  -- may lead nowhere. The exits are now COPIED from the record itself, so
  -- whatever the player's own ROM says the door is, it stays the door.
  --
  -- The entrance is authored for the corner at (0,2) -- a passage you find
  -- by walking into a corner is what the rumour described -- and then put
  -- to the map like the ghost's cell, because that number was a guess too.
  -- A cell already carrying a warp is refused: standing on the door and
  -- being sent to the garden is not a secret passage, it is a broken exit.
  local billsDef = mod.content.maps:get("BILLS_HOUSE")
  local warps = {}
  local taken = {}
  for _, warp in ipairs((billsDef and billsDef.warps) or {}) do
    warps[#warps + 1] = warp
    taken[tostring(warp.x) .. "," .. tostring(warp.y)] = true
  end

  -- EVERY corner, not one of them.
  --
  -- The rumour is "a passage behind Bill's house", and the passage has no
  -- door drawn on it -- that is the point of a secret. But a single unmarked
  -- cell in a room is a coin flip on whether anyone ever stands there, and
  -- 0.3.0-beta.1 still had exactly one. "Walk into a corner" is the version
  -- of this rumour that a player can actually act on, so all four corners
  -- are the passage: whichever one they try is the one that works.
  --
  -- Each is the nearest cell to that corner the player can stand on, so a
  -- corner that is furniture or wall moves inward rather than being lost. A
  -- cell already carrying a warp is refused -- standing on the front door
  -- and being sent to the garden is not a secret passage, it is a broken
  -- exit -- and so is a cell already claimed by another corner, which is
  -- what keeps a tiny room from turning every tile into a trapdoor.
  local w, h = cellBounds(billsDef)
  local corners = {
    { x = 0, y = 0 }, { x = w - 1, y = 0 },
    { x = 0, y = h - 1 }, { x = w - 1, y = h - 1 },
  }
  local entries = {}
  for _, corner in ipairs(corners) do
    local cell = nearestStandable(billsDef, corner,
      function(cx, cy) return not taken[cx .. "," .. cy] end)
    local key = cell.x .. "," .. cell.y
    if not taken[key] and standable(billsDef, cell.x, cell.y) ~= false then
      taken[key] = true
      entries[#entries + 1] = cell
    end
  end

  -- A dataset that cannot answer walkability at all (no blocks, no tileset)
  -- leaves the authored corner as the single entrance, which is what every
  -- earlier release shipped.
  if #entries == 0 then entries[1] = { x = 0, y = 2 } end

  mod.log:info("garden entrances: %d", #entries)
  local BACK = #warps + 1
  for _, cell in ipairs(entries) do
    warps[#warps + 1] = { x = cell.x, y = cell.y, destMap = GARDEN, destWarp = 1 }
  end
  mod.content.maps:patch("BILLS_HOUSE", { warps = warps })

  -- The way back names the FIRST of them: they all lead to the same garden,
  -- and coming out of one door you did not go in by is a smaller surprise
  -- than coming out into a wall.
  mod.content.maps:patch(GARDEN, {
    warps = {
      { x = 5, y = 11, destMap = "BILLS_HOUSE", destWarp = BACK },
      { x = 6, y = 11, destMap = "BILLS_HOUSE", destWarp = BACK },
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

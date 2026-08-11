-- Standalone: luajit mods/childhood_myths_are_real/tests/mythos_test.lua
--
-- The thing this file exists for is the transparency guarantee, not the
-- myths. A myth that does not fire is a disappointment; a save that will
-- not load is somebody's playthrough. So the rehome assertions come first
-- and are the ones written most carefully.
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local Data = require("src.core.Data")
Data:load()

local Flags = require("src.script.Flags")
local MapScripts = require("src.script.MapScripts")
local MapLoader = require("src.world.MapLoader")
local BattleState = require("src.battle.BattleState")

local ID = "childhood_myths_are_real"
local DIR = os.getenv("CHILDHOOD_MYTHS_DIR") or "mods/childhood_myths_are_real"

-- CI has no ROM: it boots tests/fixture_data, which is three species and
-- two maps and has none of Kanto in it. The myths are all anchored to real
-- Kanto maps, so those assertions are gated on the dataset actually
-- carrying them -- while the transparency guarantee, which is the part
-- that must never break, is checked on BOTH.
local KANTO = Data.maps.BILLS_HOUSE ~= nil
  and Data.maps.VERMILION_DOCK ~= nil
  and Data.maps.POKEMON_TOWER_6F ~= nil
  and Data.maps.REDS_HOUSE_2F ~= nil

-- The kid reuses a base-game sprite rather than shipping his own art, and
-- mirrors main.lua's own candidate list exactly -- if that list changes
-- there, it has to change here too, or this stops testing what ships.
local KID_SPRITE_CANDIDATES = { "SPRITE_YOUNGSTER", "YOUNGSTER", "SPRITE_BOY", "BOY" }
local HAVE_KID_SPRITE = false
for _, id in ipairs(KID_SPRITE_CANDIDATES) do
  if Data.sprites[id] then HAVE_KID_SPRITE = true end
end
local HAVE_KID = KANTO and HAVE_KID_SPRITE and Data.pokemon.MEWTWO ~= nil

-- Snapshot what the base game says BEFORE the mod runs. Anything the mod
-- claims to preserve has to be compared against this, not against itself.
local BASE_BILLS_WARPS = {}
if KANTO then
  for i, w in ipairs(Data.maps.BILLS_HOUSE.warps or {}) do
    BASE_BILLS_WARPS[i] = { x = w.x, y = w.y, destMap = w.destMap }
  end
  T.check(#BASE_BILLS_WARPS >= 2, "the base game's BILLS_HOUSE has its exits")
else
  T.check(true, "fixture dataset: no Kanto, so the map myths are skipped")
end

-- Which maps existed BEFORE the mod ran. Anything new afterwards is the
-- mod's, and every one of those has to be covered by rehome. An earlier
-- version of this test guessed by index >= 1000 and caught the fixture's
-- own two maps instead, which is the wrong answer arrived at confidently.
local BASE_MAPS = {}
for id in pairs(Data.maps) do BASE_MAPS[id] = true end

-- Experimental mods are disabled until the player opts in, and a disabled
-- mod loads clean by never running -- so every assertion below would pass
-- vacuously. Fake the opt-in the way the manager would have written it.
local SaveData = require("src.core.SaveData")
local realLoadOptions = SaveData.loadOptions
SaveData.loadOptions = function(fs)
  local opts = realLoadOptions(fs)
  opts.mods = opts.mods or {}
  opts.mods[ID] = true
  return opts
end
local run = T.sdk.loadMod(DIR, { data = Data })
SaveData.loadOptions = realLoadOptions

T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
T.check(run.mod ~= nil and run.mod.enabled,
  "the mod is ENABLED -- otherwise every assertion below is vacuous")
T.check(#(run.loader.optionSchemas[ID] or {}) > 0, "and its body actually ran")

do
  local hasKidOption = false
  for _, row in ipairs(run.loader.optionSchemas[ID] or {}) do
    if row.key == "kid" then hasKidOption = true end
  end
  T.check(hasKidOption, "THE KID has its own OPTIONS toggle, default on")
end

local exports = run.loader.exports[ID]
local GARDEN = "CHILDHOOD_MYTHS_BILLS_GARDEN"

-- The kid stands on VERMILION_DOCK, a map the base game already has, not
-- a map this mod invents -- so `rehome` has nothing new to cover for him.
-- This has to hold true unconditionally, ROM or no ROM, or a save
-- standing next to him would be exactly the kind of hole the header's
-- rule exists to close.
do
  local count = 0
  for _ in pairs(exports.maps or {}) do count = count + 1 end
  T.eq(count, 1, "the kid did not grow the mod a map of its own")
end

local store = run.loader.modOptions[ID] or {}
run.loader.modOptions[ID] = store

-- ------- a game to poke

local Pokemon = require("src.pokemon.Pokemon")

-- A real, healthy party member. Without one BattleState.newWild logs
-- "no healthy party" and hands back a battle marked dead -- which still
-- pushes, so a test that only counted pushes would pass while proving
-- nothing about WHICH battle started.
local function onePokemon()
  local mon = Pokemon.new(Data, "PIDGEY", 20)
  mon.hp = mon.maxHp or mon.hp or 20
  return { mon }
end

local pushed
local function fakeGame(opts)
  opts = opts or {}
  pushed = {}
  return {
    data = Data,
    save = {
      player = { map = opts.map or "PALLET_TOWN", x = 1, y = 1, facing = "down" },
      inventory = opts.inventory or {},
      flags = {},
      pokedex = { seen = {}, owned = {} },
      party = onePokemon(),
      modData = {},
    },
    stack = { push = function(_, st) pushed[#pushed + 1] = st end,
              pop = function() end },
  }
end

-- ------- THE GUARANTEE: a save inside a myth is a save that still loads
--
-- MapLoader.build asserts on an unknown map id and nothing up the chain
-- pcalls it, so a save pointing at CHILDHOOD_MYTHS_BILLS_GARDEN with this mod
-- removed does not lose a myth -- it refuses to boot. rehome is the whole
-- defence.

do
  local save = { player = { map = GARDEN, x = 5, y = 5,
                            facing = "up", surfing = true } }
  local moved = exports.rehome(save)
  T.check(moved, "rehome acts on a save taken inside the garden")
  T.check(save.player.map ~= GARDEN, "the save no longer names the mod's map")

  -- and where it lands has to be a real, standable tile in the BASE game
  local home = exports.home
  T.eq(save.player.map, home.map, "it lands in Red's bedroom")
  if KANTO then
    T.check(Data.maps[home.map] ~= nil,
      "which is a map the base game has, with or without this mod")
    local m = MapLoader.load(Data, home.map)
    T.check(m:isWalkableCell(home.x, home.y),
      ("and (%d,%d) is floor, not a wall or the bed itself")
        :format(home.x, home.y))
  end
  T.eq(save.player.x, home.x, "the save carries that x")
  T.eq(save.player.y, home.y, "and that y")
  T.check(save.player.surfing == false, "and is not left surfing indoors")
end

do
  -- it must not touch anybody else's save
  local save = { player = { map = "CERULEAN_CITY", x = 9, y = 9, facing = "left" } }
  local moved = exports.rehome(save)
  T.check(not moved, "rehome leaves a save on a vanilla map alone")
  T.eq(save.player.map, "CERULEAN_CITY", "the map is untouched")
  T.eq(save.player.x, 9, "and so is the position")
end

do
  -- every map the mod invents must be in the list rehome checks, or the
  -- guarantee has a hole in it exactly the shape of the map somebody forgot
  local declared = exports.maps or {}
  local added = {}
  for id in pairs(Data.maps) do
    if not BASE_MAPS[id] then added[#added + 1] = id end
  end
  if KANTO then
    T.check(#added > 0, "the mod registered at least one map of its own")
  end
  for _, id in ipairs(added) do
    T.check(declared[id],
      ("%s is a map this mod invented, and rehome covers it"):format(id))
  end
end

-- ------- the garden

if KANTO then
  T.check(Data.maps[GARDEN] ~= nil, "the garden is registered")
  local ok, err = pcall(MapLoader.load, Data, GARDEN)
  T.check(ok, "and it LOADS (" .. tostring(not ok and err or "") .. ")")

  local m = MapLoader.load(Data, GARDEN)
  local grass, floor = 0, 0
  for y = 0, 11 do
    for x = 0, 11 do
      if m:isGrassCell(x, y) then grass = grass + 1 end
      if m:isWalkableCell(x, y) then floor = floor + 1 end
    end
  end
  T.check(grass > 0, "it has tall grass, so the encounters can happen")
  T.check(floor > grass, "and floor to stand on besides the grass")

  local enc = Data.encounters and Data.encounters[GARDEN]
  T.check(enc and enc.grass and #enc.grass.slots > 0, "the grass has a table")

  -- Every species here has to exist WITHOUT this mod, or a Pokemon caught
  -- in the garden is a corrupt party slot the day the mod is uninstalled.
  local bad = {}
  for _, slot in ipairs(enc.grass.slots) do
    local def = Data.pokemon[slot.species]
    if not def or not def.dex then bad[#bad + 1] = tostring(slot.species) end
  end
  T.eq(#bad, 0, "every species in the garden is a base-game one ("
    .. table.concat(bad, " ") .. ")")

  -- the way in and the way out
  local toGarden
  for _, w in ipairs(Data.maps.BILLS_HOUSE.warps or {}) do
    if w.destMap == GARDEN then toGarden = w end
  end
  T.check(toGarden ~= nil, "Bill's house has a way into the garden")
  local back = false
  for _, w in ipairs(Data.maps[GARDEN].warps or {}) do
    if w.destMap == "BILLS_HOUSE" then back = true end
  end
  T.check(back, "and the garden has a way back out")
end

-- ------- the regression that would seal a player in
--
-- BILLS_HOUSE is patched to add the garden warp, and a record patch
-- REPLACES a field rather than growing it. Restating the original two is
-- easy to get wrong and the damage only shows up for someone who already
-- walked in.

if KANTO then
  local warps = Data.maps.BILLS_HOUSE.warps or {}
  for _, base in ipairs(BASE_BILLS_WARPS) do
    local kept = false
    for _, w in ipairs(warps) do
      if w.x == base.x and w.y == base.y and w.destMap == base.destMap then
        kept = true
      end
    end
    T.check(kept, ("the original exit at %d,%d still leads to %s")
      :format(base.x, base.y, base.destMap))
  end
end

-- ------- the truck

if KANTO then
  T.check(Data.sprites.CHILDHOOD_MYTHS_SPRITE_TRUCK ~= nil, "the truck sprite is registered")
  local truck
  for _, o in ipairs(Data.maps.VERMILION_DOCK.objects or {}) do
    if o.sprite == "CHILDHOOD_MYTHS_SPRITE_TRUCK" then truck = o end
  end
  T.check(truck ~= nil, "and the truck is on the dock")

  local dock = MapScripts.get("VERMILION_DOCK")
  T.check(dock and dock.onInteract, "the dock has an onInteract")

  -- facing anything else does nothing at all
  local g = fakeGame()
  T.check(not dock.onInteract(g, nil, 20, 5), "facing empty pier does nothing")
  T.eq(#pushed, 0, "and pushes nothing")

  -- the legend was specific: you needed STRENGTH
  g = fakeGame()
  T.check(dock.onInteract(g, nil, truck.x, truck.y),
    "facing the truck without STRENGTH is handled")
  T.eq(#pushed, 1, "it says something")
  local wild = 0
  for _, st in ipairs(pushed) do if st and st.isBattle then wild = wild + 1 end end
  T.eq(wild, 0, "but no Mew: the truck does not budge without STRENGTH")

  -- with it
  g = fakeGame({ inventory = { HM_STRENGTH = 1 } })
  T.check(dock.onInteract(g, nil, truck.x, truck.y), "with STRENGTH it fires")
  T.check(#pushed >= 2, "a message and something under it")
  local battle
  for _, st in ipairs(pushed) do if st and st.kind == "wild" then battle = st end end
  T.check(battle ~= nil, "what is under the truck is a WILD BATTLE")
  T.check(battle and not battle.dead,
    "a real one -- not the dead battle newWild hands back with no party")
  T.eq(battle and battle.enemy and battle.enemy.name, "MEW",
    "and it is MEW, which is the entire point of the myth")
  T.check(battle and tostring(battle.introText):find("MEW", 1, true) ~= nil,
    "the player reads \"Wild MEW appeared!\" -- got "
      .. tostring(battle and battle.introText))
  T.check(run.loader.modSave[ID] and run.loader.modSave[ID].truck == true,
    "and the mod remembers, so it cannot be farmed")

  -- second time
  g = fakeGame({ inventory = { HM_STRENGTH = 1 } })
  dock.onInteract(g, nil, truck.x, truck.y)
  local again = 0
  for _, st in ipairs(pushed) do if st and st.isBattle then again = again + 1 end end
  T.eq(again, 0, "the second look finds nothing under it")
end

-- ------- the kid

-- He shares the truck's patch call and the truck's map script, which is
-- exactly the arrangement the header warns about: a second `maps:patch`
-- on this map would have replaced `objects` wholesale and erased the
-- truck. So the first thing worth proving is that both are still here
-- together, before anything about the kid himself.
if HAVE_KID then
  local truck, kid
  for _, o in ipairs(Data.maps.VERMILION_DOCK.objects or {}) do
    if o.sprite == "CHILDHOOD_MYTHS_SPRITE_TRUCK" then truck = o end
    if o.name == "CHILDHOOD_MYTHS_KID" then kid = o end
  end
  T.check(truck ~= nil, "the truck is still on the dock")
  T.check(kid ~= nil, "and so is the kid")
  T.eq(kid and kid.x, 6, "standing two tiles past it")
  T.eq(kid and kid.y, 0, "on the same walkable row")

  local dock = MapScripts.get("VERMILION_DOCK")

  -- THE KID off: facing him does nothing, same as any other switch here
  run.loader.modSave[ID] = {}
  store.kid = false
  local g = fakeGame()
  T.check(not dock.onInteract(g, nil, kid.x, kid.y), "THE KID off: he says nothing")
  T.eq(#pushed, 0, "and pushes nothing")
  store.kid = nil

  -- nothing found yet: he still talks, but names exactly one rumour, and
  -- gives away no coordinate -- the tile he stands on names none of them
  run.loader.modSave[ID] = {}
  g = fakeGame()
  T.check(dock.onInteract(g, nil, kid.x, kid.y), "with nothing found, he talks")
  T.eq(#pushed, 1, "one box")
  T.eq(pushed[1] and #pushed[1].pages, 2, "an intro page and one claim")
  local claimLine = pushed[1] and pushed[1].pages[2] and pushed[1].pages[2][1]
  local claims = {
    "SOMETHING SLEEPS", "ONE OF THE GHOSTS", "THERE'S A SECRET", "THE SHIP COMES",
  }
  local isClaim = false
  for _, line in ipairs(claims) do if claimLine == line then isClaim = true end end
  T.check(isClaim, "and it is one of the four rumours, not a coordinate -- got "
    .. tostring(claimLine))
  T.check(not (run.loader.modSave[ID] and run.loader.modSave[ID].kid),
    "talking about it is not the same as being owed the reward")

  -- some found, some not: he admits the ones you proved, then names every
  -- myth still outstanding, one per page -- deterministic here because
  -- only one is left
  run.loader.modSave[ID] = { truck = true, ghost = true, garden = true }
  g = fakeGame()
  T.check(dock.onInteract(g, nil, kid.x, kid.y), "with three of four found, he talks")
  T.eq(#pushed, 1, "still one box")
  T.eq(pushed[1] and #pushed[1].pages, 2, "the acknowledgement and the one still missing")
  local missingLine = pushed[1] and pushed[1].pages[2] and pushed[1].pages[2][2]
  T.check(missingLine and missingLine:find("SS ANNE", 1, true) ~= nil,
    "and it names the S.S. ANNE by name -- got " .. tostring(missingLine))

  -- all four: the payoff, gated on every one of them and not one fewer
  run.loader.modSave[ID] = { truck = true, ghost = true, garden = true, anne = false }
  g = fakeGame()
  dock.onInteract(g, nil, kid.x, kid.y)
  local earlyBattle
  for _, st in ipairs(pushed) do if st and st.kind == "wild" then earlyBattle = st end end
  T.check(earlyBattle == nil, "three of four proven is not four of four: no reward yet")

  run.loader.modSave[ID] = { truck = true, ghost = true, garden = true, anne = true }
  g = fakeGame()
  T.check(dock.onInteract(g, nil, kid.x, kid.y), "with all four found, he pays off")
  T.check(#pushed >= 2, "a message and something under it, same shape as the other myths")
  local reward
  for _, st in ipairs(pushed) do if st and st.kind == "wild" then reward = st end end
  T.check(reward ~= nil, "the payoff is a WILD BATTLE")
  T.check(reward and not reward.dead, "a real one")
  T.eq(reward and reward.enemy and reward.enemy.name, "MEWTWO",
    "and it is MEWTWO -- the other big schoolyard claim, not a second MEW")
  T.check(run.loader.modSave[ID] and run.loader.modSave[ID].kid == true,
    "and the mod remembers, so this cannot be farmed")

  -- second time: he has nothing left to keep score of
  g = fakeGame()
  dock.onInteract(g, nil, kid.x, kid.y)
  local again = 0
  for _, st in ipairs(pushed) do if st and st.kind == "wild" then again = again + 1 end end
  T.eq(again, 0, "and the second visit hands out nothing more")

  run.loader.modSave[ID] = {}
elseif KANTO then
  T.check(true,
    "this dataset has no known kid sprite id and/or no MEWTWO, so no kid -- "
      .. "the honest outcome, not a validation error")
end

-- ------- the option actually switches a myth off

if KANTO then
  run.loader.modSave[ID] = {}
  store.truck = false
  local dock = MapScripts.get("VERMILION_DOCK")
  local truck
  for _, o in ipairs(Data.maps.VERMILION_DOCK.objects or {}) do
    if o.sprite == "CHILDHOOD_MYTHS_SPRITE_TRUCK" then truck = o end
  end
  local g = fakeGame({ inventory = { HM_STRENGTH = 1 } })
  T.check(not dock.onInteract(g, nil, truck.x, truck.y),
    "THE TRUCK off: the truck is just a truck again")
  T.eq(#pushed, 0, "and nothing happens at all")
  store.truck = nil
end

-- ------- the ghost

if KANTO then
  run.loader.modSave[ID] = {}
  local tower = MapScripts.get("POKEMON_TOWER_6F")
  T.check(tower and tower.onStep, "the tower has an onStep")

  local g = fakeGame()
  T.check(not tower.onStep(g, nil, 9, 9), "an ordinary tile in the tower is quiet")

  -- with the Scope the ghosts are named, and the myth is over
  g = fakeGame({ inventory = { SILPH_SCOPE = 1 } })
  T.check(not tower.onStep(g, nil, 3, 10),
    "with the SILPH SCOPE there is no myth left to have")
  T.eq(#pushed, 0, "so nothing happens")

  -- without it
  g = fakeGame()
  T.check(tower.onStep(g, nil, 3, 10), "without it, the shape turns round")
  T.check(#pushed >= 2, "text, and a battle under it")
  local ghost
  for _, st in ipairs(pushed) do if st and st.kind == "wild" then ghost = st end end
  T.check(ghost and not ghost.dead, "a real wild battle")
  T.check(ghost and ghost.enemy and ghost.enemy.name ~= nil,
    "against something you can throw a ball at")
  local lvl = ghost and ghost.enemy and ghost.enemy.mon and ghost.enemy.mon.level
  T.check((lvl or 0) >= 25,
    "and it is no ordinary tower encounter: level " .. tostring(lvl))

  g = fakeGame()
  T.check(not tower.onStep(g, nil, 3, 10), "and only ever once")
end

-- ------- the S.S. Anne

if KANTO then
  run.loader.modSave[ID] = {}
  local city = MapScripts.get("VERMILION_CITY")
  T.check(city and city.onEnter, "Vermilion has an onEnter")

  -- mid-game: the ship is gone and stays gone
  local g = fakeGame()
  Flags.set(g.save, "EVENT_SS_ANNE_LEFT")
  city.onEnter(g, nil)
  T.check(Flags.get(g.save, "EVENT_SS_ANNE_LEFT"),
    "before the Elite Four the ship is still gone")
  T.eq(#pushed, 0, "and nothing announces itself")

  -- after the champion
  g = fakeGame()
  Flags.set(g.save, "EVENT_SS_ANNE_LEFT")
  Flags.set(g.save, "EVENT_BEAT_CHAMPION_RIVAL")
  city.onEnter(g, nil)
  T.check(not Flags.get(g.save, "EVENT_SS_ANNE_LEFT"),
    "after the champion the S.S. ANNE comes back")
  T.check(#pushed >= 1, "and you hear the horn")

  -- a save that never had the ship leave is untouched
  run.loader.modSave[ID] = {}
  g = fakeGame()
  Flags.set(g.save, "EVENT_BEAT_CHAMPION_RIVAL")
  city.onEnter(g, nil)
  T.eq(#pushed, 0, "a player whose ship never sailed hears nothing")
end

-- ------- the art is ours, and is a legal object sprite

do
  local path = Data.sprites.CHILDHOOD_MYTHS_SPRITE_TRUCK.image
  T.check(type(path) == "string" and path:find("childhood_myths_are_real", 1, true),
    "the truck's art comes from this mod, not from the ROM cache")
  T.check(Data.sprites.CHILDHOOD_MYTHS_SPRITE_TRUCK.source == nil,
    "and carries no ROM source line")
end

run.release()
T.finish("childhood_myths_are_real")

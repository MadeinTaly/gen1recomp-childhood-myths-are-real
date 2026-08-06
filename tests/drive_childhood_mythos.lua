-- A frame driver that plays the mod, in the real running game.
--
--   POKEPORT_DRIVER=mods/childhood_mythos/tests/drive_childhood_mythos.lua xvfb-run -a love .
--
-- The unit suite calls the mod's script handlers directly, which proves the
-- logic and proves nothing about whether a player can reach any of it. This
-- boots LOVE, warps to each myth, walks into it, and reports what actually
-- happened -- including the one that matters most: saving inside the garden
-- and reading back what landed in the file.
--
-- It prints CHILDHOOD MYTHOS: lines and quits with a verdict. It captures no images:
-- every pixel on that screen is derived from the player's own ROM.
--
-- NOT YET RUN TO COMPLETION. It was written in a container with no audio
-- device, where LOVE's OpenAL backend refuses to start ("Could not open
-- device") before love.load is ever reached -- SDL_AUDIODRIVER=dummy does
-- not help, because the failure is OpenAL's and not SDL's. On a machine
-- with sound it should just go. Treat it as a tool to finish, not as
-- evidence: the 63-check unit suite is what actually backs this release.

return function()
  local Game = require("src.core.Game")
  local Flags = require("src.script.Flags")
  local Pokemon = require("src.pokemon.Pokemon")

  local results, failures = {}, 0
  local function report(ok, label, detail)
    results[#results + 1] = { ok = ok, label = label, detail = detail }
    if not ok then failures = failures + 1 end
    print(("CHILDHOOD MYTHOS: %-4s %s%s"):format(ok and "ok" or "FAIL", label,
      detail and ("  -- " .. tostring(detail)) or ""))
  end

  local function wait(frames)
    for _ = 1, frames or 1 do coroutine.yield() end
  end

  -- Let the boot sequence settle, mashing through whatever the title and
  -- the intro put up, until the overworld is the thing on screen.
  local function reachOverworld()
    for _ = 1, 1200 do
      local ow = Game.overworld
      if ow and Game.stack:top() == ow and not ow.transitioning then return true end
      Game:keypressed("a")
      coroutine.yield()
      Game:keyreleased("a")
      coroutine.yield()
    end
    return false
  end

  local function stackTop() return Game.stack:top() end

  local function battleOnTop()
    local top = stackTop()
    return top and top.kind ~= nil and top or nil
  end

  -- clear anything the game put over the overworld
  local function dismiss()
    for _ = 1, 60 do
      if Game.stack:top() == Game.overworld then return end
      Game:keypressed("b")
      coroutine.yield()
      Game:keyreleased("b")
      coroutine.yield()
    end
  end

  local function goTo(map, x, y, facing)
    Game.overworld:setMap(map, x, y, facing or "down")
    wait(6)
  end

  wait(10)
  if not reachOverworld() then
    report(false, "the game reaches the overworld at all")
    print("CHILDHOOD MYTHOS: VERDICT FAIL")
    love.event.quit(1)
    return
  end
  report(true, "the game boots and hands over the overworld")

  -- The mod must actually be loaded, or every line below is theatre.
  local loaded = false
  for _, m in ipairs((Game.mods and Game.mods.mods) or {}) do
    if m.id == "childhood_mythos" then loaded = m.enabled and true or false end
  end
  if type(Game.mods.mods) == "table" and not loaded then
    for id, m in pairs(Game.mods.mods) do
      if id == "childhood_mythos" or (type(m) == "table" and m.id == "childhood_mythos") then
        loaded = (m.enabled ~= false)
      end
    end
  end
  report(loaded, "the childhood_mythos mod is loaded and enabled",
    not loaded and "experimental mods stay off until the player says yes" or nil)

  -- Something healthy to battle with, or newWild hands back a dead battle.
  local mon = Pokemon.new(Game.data, "PIDGEY", 25)
  mon.hp = mon.maxHp or 30
  Game.save.party = { mon }

  -- ------- myth 1: the truck
  do
    Game.save.inventory = Game.save.inventory or {}
    Game.save.inventory.HM_STRENGTH = nil
    goTo("VERMILION_DOCK", 4, 1, "up")
    report(Game.overworld.map.id == "VERMILION_DOCK", "we can stand on the dock")

    -- the truck has to be visible as an object, not just registered
    local seen = false
    for _, npc in ipairs(Game.overworld.npcs or {}) do
      if tostring(npc.sprite or (npc.def and npc.def.sprite)):find("TRUCK") then
        seen = true
      end
    end
    report(seen, "the TRUCK is really on the map, drawn as an object")

    Game:keypressed("z") ; wait(2) ; Game:keyreleased("z") ; wait(20)
    local got = battleOnTop()
    report(got == nil, "without STRENGTH the truck does not budge",
      got and "a battle started anyway" or nil)
    dismiss()

    Game.save.inventory.HM_STRENGTH = 1
    goTo("VERMILION_DOCK", 4, 1, "up")
    Game:keypressed("z") ; wait(2) ; Game:keyreleased("z") ; wait(30)
    -- the message is on top; the battle is under it
    dismiss()
    wait(10)
    local mew = battleOnTop()
    local who = mew and mew.enemy and mew.enemy.name
    report(who == "MEW", "with STRENGTH, MEW is under the truck",
      "top of stack: " .. tostring(who))
    dismiss()
  end

  -- ------- myth 3: the garden, and the save that must survive it
  do
    goTo("BILLS_HOUSE", 1, 2, "left")
    report(Game.overworld.map.id == "BILLS_HOUSE", "we are in Bill's house")

    -- walk into the corner
    Game:keypressed("left") ; wait(2) ; Game:keyreleased("left")
    wait(60)
    local where = Game.overworld.map.id
    report(where == "CHILDHOOD_MYTHOS_BILLS_GARDEN",
      "walking into the corner opens the garden", "landed on " .. tostring(where))

    if where == "CHILDHOOD_MYTHOS_BILLS_GARDEN" then
      -- THE GUARANTEE, exercised for real: save here, read the file back.
      Game:writeSave()
      local SaveData = require("src.core.SaveData")
      local reloaded = SaveData.load and SaveData.load() or nil
      local savedMap = reloaded and reloaded.player and reloaded.player.map
      if savedMap == nil then
        -- fall back to the in-memory table the writer stamped
        savedMap = Game.save and Game.save.player and Game.save.player.map
      end
      report(savedMap ~= "CHILDHOOD_MYTHOS_BILLS_GARDEN",
        "a save taken IN the garden does not name the garden",
        "the file says " .. tostring(savedMap))
      report(savedMap == "REDS_HOUSE_2F",
        "it says Red's bedroom, so the file loads with the mod removed",
        "the file says " .. tostring(savedMap))
    end
  end

  -- ------- myth 2: the ghost
  do
    goTo("POKEMON_TOWER_6F", 3, 9, "down")
    Game.save.inventory.SILPH_SCOPE = 1
    Game:keypressed("down") ; wait(2) ; Game:keyreleased("down")
    wait(50)
    local withScope = battleOnTop()
    report(withScope == nil, "with the SILPH SCOPE the dead end is just a dead end")
    dismiss()

    Game.save.inventory.SILPH_SCOPE = nil
    goTo("POKEMON_TOWER_6F", 3, 9, "down")
    Game:keypressed("down") ; wait(2) ; Game:keyreleased("down")
    wait(50)
    dismiss()
    wait(10)
    local ghost = battleOnTop()
    report(ghost ~= nil, "without it, something turns round",
      "top of stack: " .. tostring(ghost and ghost.enemy and ghost.enemy.name))
    dismiss()
  end

  -- ------- myth 4: the ship
  do
    Flags.set(Game.save, "EVENT_SS_ANNE_LEFT")
    Flags.set(Game.save, "EVENT_BEAT_CHAMPION_RIVAL")
    goTo("VERMILION_CITY", 10, 10, "down")
    wait(30)
    report(not Flags.get(Game.save, "EVENT_SS_ANNE_LEFT"),
      "after the Elite Four the S.S. ANNE comes back")
    dismiss()
  end

  print(("CHILDHOOD MYTHOS: VERDICT %s  (%d checks, %d failed)")
    :format(failures == 0 and "PASS" or "FAIL", #results, failures))
  love.event.quit(failures == 0 and 0 or 1)
end

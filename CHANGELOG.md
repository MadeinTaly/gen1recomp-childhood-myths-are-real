# Changelog

## 0.3.0-beta.3 — the truck and the kid could never speak

Reported: the kid who keeps score of the myths shows unreadable glyphs.

He does, and so does the truck, and **neither of them has ever said a word of
what they were written to say.** The reason is one line of engine order:
`OverworldState:interact` looks for an object on the cell you are facing
FIRST, talks to it, and returns (`src/world/OverworldController.lua:
2151-2178`). The map script's `onInteract` — where every line of this mod's
dialogue lived — is thirty lines further down, past the signs, the card-key
doors and the hidden items. For a cell with an object standing on it, it is
never reached at all.

So the A press went to the vanilla talk path, which looks up a `TEXT_*` id.
These objects carry none: they are this mod's, added to a dock the base game
leaves empty. What prints for a missing text id is the indecipherable text in
the report.

The engine names the seam in the same breath as the problem: "a runtime
object a mod spawned carries no `TEXT_*` id, so the vanilla path has nothing
to say for it; a mod that owns the object wraps this and simply does not call
`next()`". So the dialogue now lives in a `world.talk` wrap, which is raised
*before* the map's text tables. Anything that is not ours falls straight
through, untouched, as it always did — and `onInteract` keeps a copy for a
boot where these are not objects at all.

Asserted the way it should have been from the start: the A press on the kid
and on the truck is answered by this mod and does NOT fall through, and an
ordinary NPC still talks exactly as before. 50 checks became 56.

**THE KID exists**, incidentally — that was the other half of the question.
He stands two tiles down the dock from the truck and wears `SPRITE_GAMEBOY_KID`,
which is a real id in the extractor's own list of 72. It is only that until
now, talking to him did not reach him.

## 0.3.0-beta.2 — a myth you can actually walk into

beta.1 moved the ghost and the garden off walls, which was necessary and not
sufficient. Six-by-ten blocks of tower floor is roughly two hundred cells; a
player climbing it walks maybe a dozen. **A trigger waiting on one named cell
is a trigger almost nobody meets**, whether or not that cell is solid — and
that is the likelier half of "it just doesn't happen". It is also not
something the map data could have told me, because the map was never the
problem.

**The tower floor is the trigger now.** Anywhere on 6F, while the rumour's own
conditions hold — the SILPH SCOPE not in your bag, this myth not yet found —
the shape notices you. Six steps of grace first, so it does not fire on the
stairs the moment the floor loads, counted in this mod's own save rather than
rolled: it cannot fail to happen, and it cannot happen twice. That is also
closer to what was actually whispered — not "stand on this tile", but "one of
the ghosts up there can be caught".

**Every corner of Bill's house is the passage.** The rumour is a hidden way
with no door drawn on it, which is the point of a secret; but one unmarked
cell in a room is a coin flip on whether anybody ever stands there. All four
corners now lead to the garden — whichever one you try is the one that works
— each moved inward to the nearest cell you can stand on if the corner itself
is furniture, and never placed on top of the front door.

## 0.3.0-beta.1 — the myths were anchored to guesses

Reported: the ghost and Bill's garden "just don't happen", with both switched
on and the engine up to date. They did not, and neither did the truck. Three
separate reasons, all of the same kind — this mod was anchoring its myths to
numbers nobody had ever checked against the game's own data.

**The truck could never move.** It asked whether the player was carrying an
item called `HM_STRENGTH`. There is no such item id in a Gen 1 dataset: the
extractor's item list carries no HM or TM entry at all, and `hms` is a list of
MOVE names. So the test was false on every save that has ever existed, and the
truck answered "it will not budge" forever. It now asks the engine's own
question — `ow:partyKnows("STRENGTH")`, the same one the field-move menu asks,
badge gate included — which is what the rumour meant by "something very
strong" in the first place.

**The ghost and the garden were placed on walls.** The tower's dead end at
(3,10) and the corner in Bill's house at (0,2) were derived from map
dimensions rather than from map data: the blocks come out of the player's own
ROM, which this repository does not have, so both were educated guesses that
nothing ever verified. A guess that lands on a solid tile is a myth that never
fires and never says why, which is exactly what was reported.

Both cells are now put to the map through the engine's own walkability, and
when the authored one turns out to be solid the nearest cell the player can
stand on takes over — nearest, so the author's intent survives a guess that
was merely off by a tile. A dataset that cannot answer leaves the authored
cell alone: unknown is not "solid".

**Bill's front door was being replaced by a guess.** A record patch replaces a
field rather than growing it, so the house's own exits had to survive the
garden being added — and 0.2.0 restated them by hand, as two warps at (2,7)
and (3,7) pointing at `LAST_MAP`. That is two more guesses about somebody
else's data, and if the real pair sits anywhere else the patch was not
preserving the exits, it was overwriting them. The exits are now copied from
the record itself, and the garden's way back names whichever slot the passage
actually landed in.

**The suite could not have caught any of this**, which is the part worth
writing down. Every myth assertion was gated on the dataset carrying Kanto,
and CI's fixture is three species and two maps — so on CI the myths were never
registered at all, and the suite passed while three of them could not fire on
a cartridge. It now builds a dataset with real collision in it, puts the
authored cells on walls on purpose, and asserts the myths relocate onto ground
the player can reach. 17 checks became 35.

It ships as a pre-release: all of this is confirmed against the engine's own
data and a synthetic Kanto, and none of it against a real ROM — which is
precisely the mistake 0.2.0 made. The launcher leaves everyone on 0.2.0 until
someone playing a real cartridge says these fire.

## 0.2.0 — the fifth one is a witness

- **THE KID.** He is not a fifth legend, he is a witness -- the one every
  playground had, who had heard all the other rumours and would tell you
  which one you had not gotten round to yet. He stands two tiles down the
  dock from the truck, sharing that map's own patch and map script rather
  than getting one of his own, because a second `maps:patch` call on
  VERMILION_DOCK would have replaced the truck's object list wholesale
  instead of adding to it. Talk to him with nothing found and he repeats
  one rumour, picked at random, in playground language and with no
  coordinates. Prove some of the four and he keeps score of what is left,
  one myth per text box. Prove all four and he hands you a fifth, one
  final time: a wild MEWTWO, the other big schoolyard claim of 1998 and a
  species the base game already has. No new sprite is drawn for him --
  he reuses one the cartridge already carries, preferring the boy holding
  a GAME BOY because that is the rumour's own portrait, and falling back
  through three other ids read out of the extractor's own sprite manifest.
  If a dataset carries none of them he is simply not registered, the same
  honest way a myth without its map is not. His
  own switch under OPTIONS, default on.

## 0.1.0 — four of them

The first four playground legends, made true. Nothing announces itself: the
conditions are the ones the rumour gave, and there is no list of what you
have found.

- **THE TRUCK.** The truck parked by the S.S. ANNE is real — but not in the
  data. The dock decodes as fourteen-by-six blocks of plain pier with no
  objects at all, and the four unused blocks in its tileset are floor and
  filler. So the truck is this mod's own art, drawn in `tools/make_truck.py`
  in the four values an object sprite is allowed. Shove it aside with
  STRENGTH and what is under it is what everybody said was under it. Once.
- **TOWER GHOST.** One dead end on POKEMON TOWER 6F, and only while you
  still have no SILPH SCOPE. `Map.ghostBattles` is data rather than code, so
  the tower's ordinary unidentifiable battles are untouched — this is one
  specific shape, and it turns round.
- **BILLS GARDEN.** A passage in the corner of Bill's house and grass on the
  other side, with EEVEE, DITTO, CHANSEY, PORYGON and LAPRAS in it.
- **SS ANNE.** Beat the Elite Four and the ship comes back into port.

One switch per myth under OPTIONS, all on.

### Safe to remove

This is the part that got the most care, because it is the part that can
cost somebody a playthrough rather than a myth.

A save stores the map you stood on by id, and `MapLoader.build` opens with
an `assert` on an unknown one, with no `pcall` anywhere up the chain. A
player who saved inside the garden and then disabled this mod would not lose
a garden — the game would refuse to start.

So saving inside a myth writes you home instead. You wake in your own bed in
Pallet Town, which is the oldest ending there is, and the save names a map
every install has.

The same rule shapes everything else: every Pokémon this mod can give you is
a base-game species, so a full box survives the mod being deleted. Nothing
here registers a species.

### Nothing is assumed about your data

A myth anchored to a map or a species your dataset does not carry is simply
not registered. CI runs on a three-species fixture with none of Kanto in it,
and the mod loads clean there — it just has no myths to offer.

### Tests

63 checks on a full dataset, 15 on the fixture. The transparency guarantees
are verified by sabotage: making `rehome` a no-op, dropping Bill's original
exits, and landing the player inside the bed instead of beside it each turn
the suite red.

# Changelog

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

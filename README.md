# Childhood Myths Are Real

> ### *Memento, puer.*

A mod for [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp).

In 1998 everyone's cousin had seen Mew under the truck. Everyone's friend
knew someone who caught a ghost in the tower. There were photocopied pages
passed around a playground explaining exactly which steps to take.

None of it was in the cartridge. This puts it there.

## The four

| | |
| --- | --- |
| **THE TRUCK** | The truck by the S.S. ANNE. Use STRENGTH on it. |
| **TOWER GHOST** | A dead end on POKéMON TOWER 6F, before you have the SILPH SCOPE. |
| **BILLS GARDEN** | The corner of Bill's house. |
| **SS ANNE** | Beat the Elite Four. |

That table is more than the rumour ever gave anyone, and it is already more
than the mod tells you in game. **Nothing announces itself.** There is no
list of what you have found, no marker for what you have not, and no menu
entry that lights up. Looking was the whole point; a checklist would be a
different mod, and a worse one.

Each of the four has its own switch under `OPTIONS`. All on.

## It is safe to remove

This mattered more than any of the myths, so it is worth saying plainly.

A saved game records the map you were standing on by name. The engine opens
that map with an `assert`, and nothing catches it. So if a mod invents a map,
and you save inside it, and you later turn that mod off — the game does not
lose a map. It refuses to start.

**Saving inside a myth writes you home instead.** You wake up in your own bed
in Pallet Town, and the save names a map every copy of the game has. Turn
this mod off whenever you like: you lose the myths, never the file.

Everything else follows the same rule. Every Pokémon this can give you is one
the base game already has, so a boxful survives the mod being deleted. It
registers no new species at all.

## Tell me which myth to build next

Four is not the list. It is the four I could reach first, and the ones worth
having are the ones I never heard — every playground had its own, and they
all mutated on the way round.

Open an issue if you want:

- **a myth I have not built.** The S.S. ANNE's secret decks. The Safari
  Zone's hidden areas. The PokeGods somebody swore came after 151. Mew in
  the truck is famous; the local ones are better;
- **a myth from where YOU grew up** — with the exact steps as you were told
  them, however absurd. "Surf up and down the coast a hundred times, do not
  save, walk backwards through the gate" is precisely the useful level of
  detail;
- **a different way to find them.** Right now nothing announces itself, on
  purpose. If you think there should be a rumour system, an NPC who tells
  you half of one, a diary that fills in behind you -- say so;
- **something bigger.** This mod's premise has a lot of room in it.

### And the art, which is genuinely open

The myths that are left **never had a real appearance.** A PokeGod invented
on a playground, a creature people thought they saw in a blurry magazine
photo. There is no original to copy, so whatever you draw *becomes* the
version everybody sees.

| | |
| --- | --- |
| overworld object | 16x16 PNG |
| battle picture | 56x56 PNG |
| colours | exactly four: `#000000`, `#555555`, `#AAAAAA`, transparent |

**Ideas are the contribution.** You do not have to build it, mock it up or
know Lua -- describe what you want and why, and it gets considered. The best
ones ship.

If an idea comes with art, the art has to be **yours**: nothing traced,
edited or recoloured from a ROM, a fan game, a wiki or another mod. That is
what keeps this shippable, and it is what the other authors on the index are
owed.

## Building on it

```sh
python3 tools/modkit.py validate mods/mythos --strict
python3 tools/modkit.py lint     mods/mythos
luajit mods/mythos/tests/mythos_test.lua
POKEPORT_DATA_DIR=tests/fixture_data luajit mods/mythos/tests/mythos_test.lua
python3 tools/make_truck.py        # redraws assets/truck.png
```

The suite is 63 checks on a full dataset and 15 on the ROM-free fixture. If
you change how saving inside a myth behaves, sabotage the change and watch
the suite go red before you trust it — those assertions are the ones
protecting somebody's file.

## Licence and affiliation

MIT. See `LICENSE`.

Not affiliated with Nintendo, Game Freak or The Pokémon Company. Ships no
ROM data and no game assets: the only image in it is a truck, drawn by a
script you can read.

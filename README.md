# Childhood Myths Are Real

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

## Help wanted, and not only from programmers

The next versions need **art** far more than they need code, and the art has
a hard rule attached: it has to be **original**. Nothing ripped from a ROM,
a fan game, a wiki or another mod — not because anyone is being precious,
but because the whole project stands on not shipping other people's game
data, and because the other modders on the index deserve the same courtesy
we want.

Which turns out to suit this mod exactly. The remaining myths are things
that **never had a real appearance**: PokéGods invented on a playground,
a creature people thought they saw in a blurry magazine photograph. There is
no original to copy. Whatever you draw *is* the definitive version.

Open an issue if you want to:

- **draw something** — a 16×16 overworld sprite, or a 56×56 battle picture,
  in four values (black, `#555`, `#AAA`, transparent);
- **describe a myth properly** — how it was told where you grew up, and what
  the exact steps were meant to be. Regional variants are the good stuff;
- **say one of these is wrong** — if a trigger does not match the legend you
  remember, that is a bug report, and a welcome one.

There are issue templates for the first two. You do not need to know Lua for
either.

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

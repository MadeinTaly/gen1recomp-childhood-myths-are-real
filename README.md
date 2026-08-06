# Childhood Mythos Are Real

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

## Ideas, and help building them

**Got an idea for something this should do?** Open an issue — there is a
template for it. You do not need to know any Lua, and you do not need to
have worked out how it would be built. Describe what you want and why.

**Want to build it yourself?** Open a pull request. Collaboration is welcome
on any part of this.

Anything you send that includes art has to be your own work — nothing
traced, edited or recoloured from a ROM, a fan game, a wiki or another mod.

## Building on it

```sh
python3 tools/modkit.py validate mods/childhood_mythos --strict
python3 tools/modkit.py lint     mods/childhood_mythos
luajit mods/childhood_mythos/tests/mythos_test.lua
POKEPORT_DATA_DIR=tests/fixture_data luajit mods/childhood_mythos/tests/mythos_test.lua
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

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
| **THE KID** | A kid standing near the truck. Talk to him. |

That table is more than the rumour ever gave anyone, and it is already more
than the mod tells you in game. **Nothing announces itself.** There is no
list of what you have found, no marker for what you have not, and no menu
entry that lights up. Looking was the whole point; a checklist would be a
different mod, and a worse one.

Each of the five has its own switch under `OPTIONS`. All on. Turning one off
stops it happening straight away; turning one back on takes a restart,
because the map and the objects are registered when the mod loads.

THE KID is the exception to "nothing announces itself," and on purpose: he
is not a fifth legend, he is a witness. Every playground had one -- the kid
who had heard all the other rumours and would tell you which one you had
not gotten round to yet. Talk to him with none of the four proven and he
repeats one of the rumours, playground-vague, no coordinates. Prove some of
them and he keeps score of what is left. Prove all four and he has one
rumour of his own -- the other big claim of 1998, the one nobody could even
see. He stands next to the truck rather than getting a map of his own,
which is also why: he does not cost the save-safety guarantee anything.

## Installing it

Download `childhood_myths_are_real-0.2.0.zip` from
[Releases](https://github.com/MadeinTaly/gen1recomp-childhood-myths-are-real/releases)
and install it the way Gen1Recomp installs any mod — drop it in `mods/` and
let the manager unpack it, or point the manager at the file.

This mod is marked **experimental**, which means Gen1Recomp keeps it switched
off until you say otherwise. Enable it in the mod manager, then start the
game: nothing will happen until you do.

## It is safe to remove

This mattered more than any of the myths, so it is worth saying plainly.

A saved game records the map you were standing on by id. The engine opens
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

Clone this repo into a Gen1Recomp checkout as `mods/childhood_myths_are_real`,
and run everything below from the engine's root:

```sh
python3 tools/modkit.py validate mods/childhood_myths_are_real --strict
python3 tools/modkit.py lint     mods/childhood_myths_are_real
luajit mods/childhood_myths_are_real/tests/childhood_myths_are_real_test.lua
POKEPORT_DATA_DIR=tests/fixture_data \
  luajit mods/childhood_myths_are_real/tests/childhood_myths_are_real_test.lua
python3 mods/childhood_myths_are_real/tools/make_truck.py  # redraws the truck
```

The suite is 17 checks on the ROM-free fixture, and more still on a full
dataset -- including the kid's own block, which only runs there, and only
when the dataset actually carries a usable stand-in sprite for him. If
you change how saving inside a myth behaves, sabotage the change and watch
the suite go red before you trust it — those assertions are the ones
protecting somebody's file.


## Support

If this made the myths real, you can support the author here:
<https://linktr.ee/made_in_taly>

## Licence and affiliation

MIT. See `LICENSE`.

Not affiliated with Nintendo, Game Freak or The Pokémon Company. Ships no
ROM data and no game assets: the only image in it is a truck, drawn by a
script you can read.

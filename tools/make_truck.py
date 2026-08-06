#!/usr/bin/env python3
"""Draw the truck.

The truck is the whole point of the first myth, and it is not in the data:
the Vermilion dock decodes as fourteen-by-six blocks of plain pier, and the
four unused blocks in the SHIP_PORT tileset are floor and filler, not a
vehicle. So the mod brings its own -- original art, drawn here in code
rather than lifted from anywhere.

The engine's own object sprites set the format, and it is narrow: 16x16
RGBA, and exactly four values -- black, 85, 170, and fully transparent
white. Anything else is not a Game Boy sprite, so `check()` refuses to
write a file that has drifted.

    python3 tools/make_truck.py
"""

import os
import sys

try:
    from PIL import Image
except ImportError:                                          # pragma: no cover
    sys.exit("needs pillow:  pip install pillow")

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "truck.png")

K = (0, 0, 0, 255)          # outline
D = (85, 85, 85, 255)       # shadow / tyre
L = (170, 170, 170, 255)    # body
_ = (255, 255, 255, 0)      # transparent

INK = {"K": K, "D": D, "L": L, ".": _}

# A side-on box truck: cargo body left, cab and windscreen right, two
# wheels under the chassis. Sixteen rows of sixteen, and the art is the
# string -- there is no clever generator to get wrong.
TRUCK = [
    "................",
    "................",
    ".KKKKKKKKKK.....",
    ".KLLLLLLLLK.....",
    ".KLLLLLLLLK.....",
    ".KLLLLLLLLKKKKK.",
    ".KLLLLLLLLKDDDK.",
    ".KLLLLLLLLKDDDK.",
    ".KLLLLLLLLKLLLK.",
    ".KKKKKKKKKKKKKK.",
    ".KKDDKKKKKKDDKK.",
    "..KDDK....KDDK..",
    "..KKKK....KKKK..",
    "................",
    "................",
    "................",
]


def check(rows):
    """Refuse to write anything that is not a legal object sprite."""
    problems = []
    if len(rows) != 16:
        problems.append("height is %d, must be 16" % len(rows))
    for y, row in enumerate(rows):
        if len(row) != 16:
            problems.append("row %d is %d wide, must be 16" % (y, len(row)))
        for ch in row:
            if ch not in INK:
                problems.append("row %d uses %r, not one of K D L ." % (y, ch))

    ink = sum(1 for row in rows for ch in row if ch != ".")
    if ink == 0:
        problems.append("the sprite is empty")

    # The wheels are the thing that makes it read as a vehicle rather than a
    # crate, and they are the easiest detail to lose while nudging the art.
    wheels = [y for y, row in enumerate(rows) if row.count("D") >= 4]
    if len(wheels) < 2:
        problems.append("no wheels: fewer than two rows carry a tyre")

    # It must sit ON something, not float: the bottom inked row is the axle
    # line, and nothing may hang below the frame.
    inked_rows = [y for y, row in enumerate(rows) if any(c != "." for c in row)]
    if inked_rows and inked_rows[-1] > 13:
        problems.append("the truck runs off the bottom of the sprite")

    return problems


def build(rows):
    img = Image.new("RGBA", (16, 16), _)
    px = img.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            px[x, y] = INK[ch]
    return img


def main():
    problems = check(TRUCK)
    if problems:
        for p in problems:
            print("  ! " + p, file=sys.stderr)
        sys.exit("refusing to write a sprite that is not a legal 16x16 object")

    out = os.path.normpath(OUT)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    build(TRUCK).save(out)

    used = sorted({ch for row in TRUCK for ch in row})
    print("wrote %s  (16x16 RGBA, inks %s)" % (out, " ".join(used)))


if __name__ == "__main__":
    main()

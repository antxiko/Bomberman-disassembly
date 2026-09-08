# Bomber Man (Hudson Soft, 1983) — a commented disassembly

*(También [en castellano](README.es.md).)*

**[→ Read it on the web](https://antxiko.github.io/Bomberman-disassembly/)**

A complete, commented disassembly of Hudson Soft's Bomber Man for MSX1, 1983,
on an 8 KB cartridge. The smallest cartridge in this series.

| | |
|---|---|
| binary explained | **100%** — 8,192 of 8,192 bytes |
| traced code | 3,557 bytes (43.4%) |
| identified data | 4,635 bytes (56.6%) |
| routines | 200, **none below 10% commented** |
| comment density | **50.2%** |
| tests | 64 |
| VRAM comparison against openMSX | **0 differences** |

## What is inside

**The cartridge header is code.** INIT is `0x4004`, which is exactly where the
MSX format puts STATEMENT, DEVICE and TEXT. Those fields and the six reserved
bytes are `ld sp,0F000h` and the three calls of the start-up. Only the first
four bytes are really a header.

**Not a single sprite.** `0x5062` writes a `0xD0` into the first sprite
attribute and never touches the list again. The bomber, the monsters, the bombs
and the flames are all name-table tiles, all two by two, and the game has no
map data structure: it reads the tile number. Three comparisons carry the whole
game — `cp 020h` (free), `cp 0e0h` (flame), `cp 0c0h` (something that kills).

**Two programmers, and a typo.** The title screen says `PROGRAMMER:Y.TANAKA`
and `T.SASAGAWA`, and the last line reads `PUSH SPACE-KEY OR TORIGER`.

**Every fourth stage the game drops the bombs for you**, announced by a
blinking `BOMB AUTO SETTING STAGE` under exactly the same `and 003h`.

**The blast reaches two cells and only breaks the bricks in one** — read in the
unrolled loop at `0x4AAC`, and then measured in openMSX.

**Eight prizes cycle under the bricks**, and the auto-bomb stage does not
get the same one as the three that follow it.

**The monster turns red when it is hunting you**: the same byte picks the
drawing and decides the behaviour.

More in [Findings](docs/FINDINGS.md).

## Reproducing it

The cartridge is not distributed. Put your own dump next to the Makefile as
`bomberman.rom`:

```
sha256  eab39bab547089facf9df3021e729b65fba2b263c505325d034ed1b6e3df8eea
size    8192 bytes
```

Then:

```
make all        # trace, generate, reassemble, check and test
make imagenes   # draw docs/imagenes from the ROM
make web        # build both language sites
make cotejo     # compare our VRAM with openMSX's
make alcance    # measure the blast's reach on the machine
make fase4      # check the auto-bomb mode on the machine
```

`make verify` is the one that decides whether the disassembly is trustworthy:
it reassembles with pasmo and compares the sha256 with the original.

## What is where

```
src/bomberman.asm       the listing, generated — do not edit by hand
src/bomberman.notes     the comments, anchored to addresses
src/bomberman.entries   the entry points the tracer cannot work out
src/bomberman.nocode    the ranges that are NOT code, with the reason
tools/                  the tracer, the generator, the drawing and the checks
tests/                  64 checks that do not need the cartridge
docs/                   the site, in English and Spanish
```

## Licence

The tools, the notes and the documentation are published under the terms in
[LICENSE](LICENSE). The game's code belongs to its authors and to Hudson Soft;
this is preservation, study and documentation work, and the cartridge image is
not distributed. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).

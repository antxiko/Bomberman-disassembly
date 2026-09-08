# The cartridge

8 KB in page 1 (`0x4000`–`0x5FFF`), MSX1. It is the smallest cartridge in the
series, and the first Hudson Soft one.

## The header is code

An MSX cartridge starts with `AB`, the INIT address, and then STATEMENT,
DEVICE, TEXT and six reserved bytes. Here INIT is `0x4004`, which is exactly
where those fields should begin. Read as instructions:

```
4000  41 42        "AB"
4002  04 40        INIT = 0x4004
4004  31 00 F0     ld sp,0F000h
4007  CD D1 4F     call 4FD1h        the RAM's starting values
400A  CD 62 50     call 5062h        the VDP
400D  CD 4E 40     call 404Eh        the PSG, with its table right behind
```

Only the **first four bytes** of the cartridge are really a header. The other
nine are the first four instructions, and there is not one byte left for
STATEMENT, DEVICE or TEXT.

## The memory map

| where | what |
|---|---|
| `0x4000`–`0x5FFF` | the cartridge |
| `0xE000`–`0xE2FF` | **the screen**, 768 bytes: what is seen |
| `0xE300`–`0xE389` | the variables |
| `0xE38A`–`0xE689` | **the board**, another 768 bytes: what stays |
| `0xF000` | the stack |

The two RAM screens are what organises the whole game, and they are explained
in [The code](THE-CODE.html).

## The VDP

The eight registers come from the table at `0x5144` and `monta_el_vdp`
(`0x5062`) writes them out:

| register | value | what it says |
|---|---|---|
| R0 | `0x02` | SCREEN 2 |
| R1 | `0xC2` | 16 KB, display on, 16×16 sprites |
| R2 | `0x06` | name table at `0x1800` |
| R3 | `0x7F` | colour at `0x0000`, three banks of `0x800` |
| R4 | `0x07` | patterns at `0x2000`, three banks |
| R5 | `0x38` | sprite attributes at `0x1C00` |
| R6 | `0x07` | sprite patterns at `0x3800` |
| R7 | `0xF0` | white ink on transparent background |

**The sprite registers are declared and never used.** Right after writing
them, `0x507C` puts a `0xD0` into the first attribute — the "no more sprites"
marker — and the cartridge **never touches the list again**. Everything that
moves in this game is a name-table tile.

## No interrupt and no sync

`monta_el_vdp` puts a `ret` into H.TIMI (`0xFD9F`): the BIOS stops interfering
on every interrupt. And the game **does not wait for the display sweep**: the
pace is set by an empty loop of `0x500` turns at the end of `cierra_el_cuadro`
(`0x46C8`). The screen is dumped when it is due, not when the VDP is safe.

## The three graphics blocks

The format used by `carga_los_graficos_en_los_tres_tercios` (`0x5088`) is:

```
2 bytes   destination in VRAM; the third is added to the high byte
1 byte    how many tiles, and ZERO means 256
n*8       the patterns, which LDIRVM dumps in one go
pairs     (colour, how many tiles) for FILVRM, closed by 0xFF
```

It is called three times with A = 0, 8 and `0x10`, which added to the
destination's high byte give the three thirds of SCREEN 2.

| block | destination | tiles | what it brings |
|---|---|---|---|
| `0x514C` | `0x0000` | 256 | the whole title screen |
| `0x5B26` | `0x0080` | 10 | the letters of SCORE and BONUS |
| `0x5B7C` | `0x0100` | 64 | the digits, the monsters and the bomber |

**The three tile without a gap**: `0x514C` ends at `0x5B26`, which ends at
`0x5B7C`, which ends at `0x5E38`. That is what proves the format is read
correctly: if the tile count or the colour-run count were off by one byte, the
next block would not start where it starts.

## The font changes halfway through

The big block loads the title screen's 256 tiles. When the game starts,
`0x4074` and `0x407A` load the two small ones **on top**: where the title
screen has the big BOMBER MAN wordmark, the game puts the monsters.

Everything from tile `0x90` up **is never overwritten**, and that is where the
H, D, F, A, M and I needed by the bottom label come from. So the in-game
caption is written with tiles from **three different blocks**, and that is why
there is no way to read a text out of this cartridge without drawing it.

![The title screen's tiles](imagenes/casillas.png)

![The in-game tiles](imagenes/casillas_partida.png)

## The sound

Two formats, both made of (register, value) pairs closed by `0xFF`.

**The short one is embedded right behind the `call`.**
`vuelca_la_tabla_del_psg` (`0x404E`) starts with a `pop hl`: it does not pick
up a datum, it picks up the **return address**, which is where the table
starts because the table is glued behind the `call`. When it is done it does
`push hl / ret` and carries on executing **after** it. There are three such
places, and they are the three ranges in `.nocode`.

**The long one is kept with one pointer per voice**, at `(0xE305)` and
`(0xE307)`, and `sigue_los_dos_guiones_de_sonido` (`0x4025`) advances it one
frame per turn. Here each `0xFF` closes the frame, not the script: the script
ends with a double `0xFF`. There are five: the door fanfare, the prize picked
up, the enemy blowing up, the bomber's death and the footstep.

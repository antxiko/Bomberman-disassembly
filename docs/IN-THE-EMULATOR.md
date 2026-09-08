# In the emulator

Three measurements, all of them on the machine and all reproducible with
`make`. No image in this repository comes from the emulator: the captures are
**for checking**, not for publishing.

## Booting it

```
openmsx -machine Philips_VG_8020 -cart bomberman.rom
```

The VG-8020's BIOS takes more than five seconds to call INIT. Before that the
cartridge has not even copied the starting values into RAM, and a dump taken at
three seconds is worthless.

## The VRAM comparison

```
make cotejo
```

It boots openMSX with no window, lets the title screen run, **presses space
through the keyboard matrix** (row 8, bit 0, which is what GTTRIG reads on
input 0) and dumps the VDP's 16 KB twice, plus 1,792 bytes of RAM. Then
`tools/coteja_vram.py` subtracts them from the VRAM that `tools/vram.py`
builds.

```
==================================================================
 LA PORTADA, contra el volcado de t=8
==================================================================
  color                         0 de  6144  ok
  patrones                      0 de  6144  ok
  tabla de nombres              0 de   768  ok
==================================================================
 LA PARTIDA, contra el volcado de t=18
==================================================================
  color                         0 de  6144  ok
  patrones                      0 de  6144  ok
  marco y pilares               0 de   184  ok
  ladrillos que rompen la regla      0 de    29  ok
  premio y puerta bajo ladrillo      0 de     2  ok
==================================================================
 0 diferencias en todo lo que no decide el azar.
```

Each line says something different:

- **Colour and patterns** come whole from the three graphics blocks, so they
  have to be zero. If not, the format at `0x5088` is misread.
- **The title screen's name table** is deterministic too: the nineteen labels,
  the big wordmark and the sample row.
- **The in-game screen cannot be compared tile by tile**, because the deal is
  left to the R register. What is checked is everything else: that the frame
  and the thirty-five pillars are exactly where `0x4DB7` puts them, that every
  brick on the board obeys the rules of `0x4E35`, and that the prize and the
  door are underneath one.

**And a trap that cost a round trip.** Comparing the VRAM's name table with the
RAM screen says nothing: `vuelca_la_pantalla` (`0x510E`) dumps it **and leaves
it blank**, so at any instant the RAM is half-built while the VRAM holds the
last complete frame. The frame and the pillars have to be looked at in the name
table.

The twenty differences that turned up on the title screen the first time were
all explained, and two of them were findings:

- Six tiles of the score and six of the record, which the build was not
  writing.
- The monster's and the bomb's blink, which in VRAM is the one from the frame
  before the dump.
- **The sample bomb in state 4** instead of 1, which is the chain reaction set
  off by untouched RAM. It is told in [Findings](FINDINGS.html).

## Measuring the blast's reach

```
make alcance
```

The listing says the flame reaches two board cells per side but only wears down
the bricks in the first. That can be read, but it can also be **measured**.

`tools/omsx_alcance.tcl` gets into a game, dumps the board, **writes two bomb
records by hand** into the list at `0xE359` — state 1, column, row and count
zero, which is exactly what `pon_una_bomba` leaves — and dumps the board again
eight seconds later.

The two cells were picked by reading the board from an earlier dump: emulation
is deterministic, so the same timings give the same deal.

```
  ladrillos antes  : 29
  ladrillos despues: 27
  bomb A: brick 1 cell  to the right in ( 5, 0) -> FALLS
  bomb A: brick 1 cell  below         in ( 4, 1) -> FALLS
  bomb B: brick 2 cells to the left   in (11, 0) -> STILL STANDING
```

## Checking the auto-bomb mode

```
make fase4
```

It forces the stage to 4 by writing `(0xE310)` and dumps the name table four
times in a row, to catch the bottom label in both halves of its blink. This
comes out:

```
a row 23: '#                           @:3#'
b row 23: '#                           @:3#'
c row 23: '#  BOMB AUTO SETTING STAGE  @:3#'
d row 23: '#  BOMB AUTO SETTING STAGE  @:3#'
```

On every other stage that row carries the signature
` BOMBERMAN HUDSONSOFT 1983` and does not blink.

## Tricks for looking inside

Seeing the board, which is where the real map is:

```
debug read_block memory 0xE38A 768
```

Skipping stages, which is what `make fase4` does:

```
debug write memory 0xE310 4
```

Seeing who is hunting: byte `+3` of the first enemy record.

```
debug read memory 0xE31F
```

When it is zero, that monster is coming for you — and it turns red.

**And the golden rule for any dump of this cartridge**: the RAM screen
(`0xE000`) is always half-built. What has to be read is the VRAM name table
(`0x1800`), which holds the last complete frame.

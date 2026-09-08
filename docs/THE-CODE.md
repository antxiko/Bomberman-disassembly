# The code

3,557 bytes of code and 4,635 of data, 200 routines, and one idea that explains
everything: **the game has no map data structure**. It reads the tile number.

## Two screens in RAM, not one

| where | what |
|---|---|
| `0xE000`–`0xE2FF` | **the screen**: what is seen. Every frame it is dumped whole to VRAM with an LDIRVM and left blank |
| `0xE38A`–`0xE689` | **the board**: what stays. The bricks, the flames while they last, the prize and the door once uncovered |

Both have the same shape — 24 rows of 32 tiles — and the same cursor
arithmetic: `pon_el_cursor` (`0x5128`) gives the address in the screen and
`pon_el_cursor_en_el_tablero` (`0x4F6F`) the same tile in the board, by adding
`0x38A`.

That is where it comes from that **the wall and the pillars cannot be broken**:
they only exist in the screen, `pinta_el_tablero` (`0x4DB7`) repaints them
every frame, and they are not where the flames write. And the bricks only exist
in the board.

## What each tile means

| tiles | what they are |
|---|---|
| `0x00`–`0x09` | the digits |
| `0x0A`, `0x0E` | the prize and the door, two by two |
| `0x10`–`0x19` | the letters of SCORE and BONUS |
| `0x20` | empty tile |
| `0x22`–`0x2F` | the enemy blowing up, seven frames |
| `0x60`–`0x7B` | the bomb: four sizes times two of blink |
| `0x80`–`0x87` | the brick crumbling, eight frames |
| `0x88`, `0x89` | the border wall and the fixed pillar |
| `0x8A`–`0x8D` | the bomber standing |
| `0xA0`–`0xBF` | the bomber walking: four directions times two steps |
| `0xC0`–`0xCF` | the enemy alive, four frames |
| `0xE0`–`0xEF` | the flame |

And out of that come the three comparisons that repeat all over the listing:

- `cp 020h` — "it is free"
- `cp 0e0h` — "there is a flame"
- `cp 0c0h` — "there is something that kills", which covers flames **and**
  monsters because they are laid out next to each other on purpose

## The main loop is the game's index

`bucle_principal` (`0x40CC`): twenty calls in a row, one per system, in the
order in which they paint over one another.

```
cierra_el_cuadro                 the counters, the dump and the sound
copia_el_tablero_a_la_pantalla   the board on top of the screen
pinta_el_tablero                 the frame and the pillars
avanzan_las_bombas               the countdown
pinta_las_bombas_y_las_llamas
pon_una_bomba                    reads the trigger
avanza_el_bombero                walks, or dies
mueve_los_enemigos
pinta_el_premio / pinta_la_puerta
pinta_los_enemigos
descubre_el_premio / descubre_la_puerta
pinta_al_bombero                 on top of everything
saca_los_enemigos_de_castigo
pisa_la_puerta_o_el_premio
descuenta_el_bonus
pinta_el_marcador
pinta_el_aviso_de_bomba_automatica
```

And three exits, which are the three ways a life ends: dead (`0xE37B`), door
stepped on (`0xE316`) or stage cleared (`0xE318`).

**The order is the logic.** Each thing leaves its trace in the tiles for the
next one to read, and that is why the bomber is painted **before** checking
whether he has been killed: as he writes over the tile, he reads what was
there.

There are two cut-down versions of the same loop: `un_cuadro_sin_mando`
(`0x4231`), without anything that attends to the player, and
`un_cuadro_de_adorno` (`0x4253`), without enemies. They are used in the
celebrations and at game over: everything is still seen moving, but you are no
longer in charge.

## Everything is two by two

`pinta_cuatro_casillas` (`0x4B7B`) writes A, A+1 on top and A+`0x10`, A+`0x11`
below. The `0x1F` in the middle is 32 minus the `inc bc` already done, and the
`0x0F` is `0x10` minus the `inc a`.

That is how the bomber, the monster, the bomb, the flame, the prize, the door,
the brick and the pillar are painted: **all of them**. And the real board, in
two-by-two cells, is 15 columns by 11 rows inside a 32-by-24 screen.

## How a stage is sown

`siembra_la_fase` (`0x4E35`) keeps no map: it writes the bricks into the board
and there they stay. The only thing noted separately is **where the first one
fell** — hiding the prize — and **where the last one fell** — hiding the door —
because `0x4EB1` only saves the prize the first time and the door is noted
every time.

The rules of the draw, in order:

1. two or more cells away from the bomber's spot
2. of the two coordinates, **one odd and one even**. With both odd it would
   land on a pillar; with both even, on the cells the game always leaves clear
3. none of the eight in the table at `0x4EDF`, which are the neighbours of the
   four corners the enemies come out of

It does not check whether there is already a brick there, so two can land on
the same cell and fewer than thirty-five come out. In the emulator dump there
were **29**.

## The counter with a ceiling

It is how **all** the game's time is measured. `avanza_un_contador` (`0x46BE`)
takes a pointer to a (count, ceiling) pair: it adds one and on reaching the
ceiling goes back to zero. There are six pairs in a row from `0xE36F`, and
anyone who wants to do something "now and then" checks whether their count is
zero.

| pair | ceiling | what it measures |
|---|---|---|
| `0xE36F` | 4 | the bomber's step |
| `0xE371` | 4 | his death throes |
| `0xE373` | 7 | the enemy blowing up |
| `0xE375` | 5 | the enemies' step |
| `0xE377` | 3 | the bomb and the crumbling brick |
| `0xE379` | 50 | the bonus |

All six ceilings come from the starting-values table at `0x4FDD` and are
**never touched again**. That is the speed of the whole game.

## The two lists

**Enemies** at `0xE31C`: eight seven-byte records, closed by the `0xFF` at
`0xE354`.

```
+0  what it is doing: 0 free, 1 alive, 2..9 blowing up, 0xFF end of list
+1  column       +2  row
+3  drawing frame, counting 3, 2, 1, 0 and round again
+4  countdown to the next frame
+5  where it is heading: 0 left, 1 right, 2 up, 3 down
+6  unused
```

The `+3` does two things at once: it picks the drawing and it decides the
behaviour. When it is zero the enemy **goes after the bomber**, and that is
precisely the red frame.

**Bombs** at `0xE359`: five four-byte records.

```
+0  0 free, 1..4 the fuse, 5..12 the blast, 13 put it out
+1  column       +2  row       +3  count to the next frame
```

There is no other limit: the game has no "bombs remaining".

## The blast, and the unrolled loop

`pinta_la_explosion` (`0x4A8C`) paints the centre without asking and walks the
four arms with the table at `0x4F8D`: **eight strips of four tiles**, one per
side and per each of the two rows — or columns — it occupies. Four screen tiles
per side are **two board cells**.

The loop is unrolled on purpose, one copy per tile, because each stops on
something different:

| tile | stops on | which routine it uses |
|---|---|---|
| 1st | the wall only | `pinta_una_llama_y_gasta_el_ladrillo` |
| 2nd | brick, wall or pillar | `pinta_una_llama_y_gasta_el_ladrillo` |
| 3rd | brick, wall or pillar | `pinta_una_llama_sin_gastar` |
| 4th | brick, wall or pillar | `pinta_una_llama_sin_gastar` |

The difference that matters: the first two **wear the brick down** — adding one
to its drawing every three frames until it disappears — and the last two return
**without writing** if what they find is a brick. Since the first two are the
board cell right next to the bomb and the last two the one after, the result is
that the blast **reaches two cells but only breaks the bricks in the first**.

It is measured on the machine, not deduced: [In the
emulator](IN-THE-EMULATOR.html).

## A register trick worth keeping

`si_toca_gasta_el_ladrillo` (`0x4B4E`) has to add one to A and has not one
register free. It solves it like this:

```
push af           A onto the stack
ex (sp),hl        and from the stack into H, which is where A now is
ld a,(0e377h)     the three-frame count
or a
jr nz,...
inc h             one more frame of crumbling
ex (sp),hl        H back onto the stack
pop af            and from there into A, already changed
```

## The randomness

`numero_al_azar` (`0x4EF9`) feeds back `(0xE384)` with sixteen bits and mixes in
the Z80's **R register**. It returns the low byte.

That mixing is not a decoration: if R advanced by the same amount between two
draws, the series of cells collapses into three to five values and repeats. A
test in the repository checks it with four different steps. On the machine that
does not happen, because between two draws a varying number of instructions
runs depending on how many times the draw had to be repeated.

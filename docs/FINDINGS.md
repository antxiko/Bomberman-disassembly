# Findings

What turned up when the eight kilobytes were taken apart, with the address next
to it so it can be checked.

## The cartridge header is code

INIT is `0x4004`, which is exactly where the MSX format puts STATEMENT, DEVICE
and TEXT. Those three fields and the six reserved bytes **are not fields**:
they are `ld sp,0F000h` and the three calls of the start-up.

Only the first four bytes of the cartridge are really a header.

## Two programmers, and a typo by Hudson

The title screen, drawn from the ROM, says on row 20
**PROGRAMMER:Y.TANAKA** and on row 21 **T.SASAGAWA**.

And the last line says:

```
PUSH SPACE-KEY OR TORIGER
```

TORIGER, not TRIGGER.

Neither can be read by looking at the bytes. The cartridge's font is not quite
ASCII — `0x21`, which would be a `!`, is the colon here — and on top of that it
**changes halfway through the game**: the same codes that on the title screen
are the letters of the big wordmark are the monsters during play. The only way
to quote a text out of this cartridge is to draw it.

## Every fourth stage the game drops the bombs for you

`pon_una_bomba` (`0x4922`) checks the stage number with an `and 003h`: on
multiples of four it **does not ask for the trigger**. And
`pinta_el_aviso_de_bomba_automatica` (`0x4D3A`) turns on a label under exactly
the same condition, blinking sixteen frames on and eight off:

```
  BOMB AUTO SETTING STAGE
```

A whole game mode in two instructions. And it fits the enemy table: stage 4,
the first auto-bomb one, has **fewer** enemies than stage 3.

## The blast reaches two cells and only breaks the bricks in one

Each arm is four screen tiles, that is two board cells. But the loop at
`0x4AAC` is unrolled with one copy per tile, and the first two call
`pinta_una_llama_y_gasta_el_ladrillo` (`0x4B21`) while the third and fourth
call `pinta_una_llama_sin_gastar` (`0x4B5A`), which returns **without writing**
if what it finds is a brick.

**Measured in openMSX**, not deduced. Two bombs written by hand into the list
at `0xE359`: one with a brick right next to it on the right and below, one with
the neighbouring cell clear and the brick two away.

```
bomb A: brick 1 cell  to the right in ( 5, 0) -> FALLS
bomb A: brick 1 cell  below         in ( 4, 1) -> FALLS
bomb B: brick 2 cells to the left   in (11, 0) -> STILL STANDING
```

## Eight prizes, and the auto-bomb stage does not get the same one

Under the first brick `siembra_la_fase` deals there is a prize, and not always
the same one. The sixteen words of the table at `0x419B` point at **two-tile**
graphics blocks, and the destinations say it all: the even ones go to `0x0050`
— tile `0x0A` — and the odd ones to `0x00D0` — tile `0x1A`. Those four tiles
are exactly the ones `pinta_el_premio` (`0x45F6`) paints.

`0x4167` loads a **pair** of consecutive words, that is one top half and one
bottom half, so the sixteen blocks are **eight whole prizes**: a helicopter, a
money bag with a dollar sign, a penny-farthing, a carriage, a steaming cup, a
stringed instrument and two more. The one for the first three stages, a chest,
comes in the game's big block and is not in the table.

And which one it is comes from two masks on the stage number: `and 003h` picks
the half of the table — **the bottom half on multiples of four**, the auto-bomb
stages — and `and 00Ch` which of the four pairs. So the auto-bomb stage's prize
**is not the same** as the three that follow it.

![The eight prizes](imagenes/premios.png)

## The monster turns red when it is coming for you

Byte `+3` of the enemy's record does two things: it picks the drawing
(`0xC0 + frame*4`) and it decides the behaviour. When it is zero, the enemy
**chases the bomber** (`0x477B`); the rest of the time it wanders and changes
its mind at random.

And zero is precisely the red frame. The other three are purple.

## Not a single sprite in the whole cartridge

`monta_el_vdp` (`0x507C`) writes a `0xD0` into the first sprite attribute — the
"no more" marker — and **never touches the list again**. VDP registers 5 and 6
are declared and never used.

Everything that moves is a name-table tile, and everything is two by two. That
explains the whole architecture: two 768-byte screens in RAM, and the tile
number acting as the map.

## The randomness leans on the refresh register

`numero_al_azar` (`0x4EF9`) mixes the Z80's **R register** into the seed. If R
advanced by the same amount between two draws, the series of cells collapses
into **three to five values** and repeats;
`test_el_azar_del_cartucho_se_apoya_en_el_registro_r` checks it with four
different steps.

On the machine that does not happen, because between two draws a varying number
of instructions runs depending on how many times the draw had to be repeated.
The consequence: **a stage's layout cannot be reproduced from outside**.

## Four pieces of code nobody reaches

Three whole routines, without a single `call` naming them anywhere in the 8 KB:

| address | what it does |
|---|---|
| `0x4EF0` | clears a board cell. It is the standalone version of what `0x4A7A` does inside another routine |
| `0x4F84` | a `0x400`-turn wait, the little sister of the one at `0x4F7B` |
| `0x50D6` | writes VDP register 7, which is only set once from the start-up table |

And a fourth: the `cp 089h` at `0x4AC9`, which would check for the pillar on
the first tile of each blast arm. An unconditional `jr` steps over it.

That last one **changes nothing**, and that is why nobody ever fixed it: the
next tile hits the other half of the same pillar and the flame stops there
anyway. They are declared as code, because instructions is what they are.

## Six bytes that run and do nothing

At `0x4864`, inside `pinta_los_enemigos`:

```
4864  4F  ld c,a
4865  42  ld b,d
4866  41  ld b,c
4867  44  ld b,h
4868  44  ld b,h
4869  00  nop
```

Nobody reads B or C back before writing them: the first thing to touch them is
an `ld bc,00007h`. Read as text, in the cartridge's own font, they say
**OBADD**. It is the only thing in the 8 KB that serves neither as data nor as
instruction.

There is a similar leftover at `0x49D6`: a `cp 006h` whose two exits go to the
same label.

## Blowing up the door is expensive

If a flame reaches the prize or the door, `pinta_una_casilla_del_premio`
(`0x461E`) notes the spot and asks for punishment.
`saca_los_enemigos_de_castigo` (`0x453B`) waits for that cell to be clear and
brings out **four more enemies** there.

The door uncovers itself again; the prize is lost.

## And running out of bonus is worse

If the bonus reaches zero, `se_agoto_el_bonus` (`0x449F`) calls
`borra_el_tablero` (`0x4F55`) and **wipes the 768 bytes at once**: the
thirty-five bricks, the prize and the door. And it leaves both "already found"
flags set, so they are never looked for again.

The stage is left with no way out and can only be finished by killing
everything.

## The title screen's bomb shows the last frame of the fuse

`pon_la_bomba_del_titulo` (`0x4442`) puts it in state 1. But when painting it,
`mira_si_la_alcanza_otra_llama` (`0x4A6D`) looks at what is underneath **in the
board**, and on entering the title screen the board has not been cleared: they
are untouched RAM bytes.

In the openMSX dump they are `0xFF`, that is more than `0xE0`, which is what
`0x4A6D` takes for a flame. So it sets state 4 and count 6 — the dumped record
says exactly `04 0E 0A 06`, which is what `0x4A71` and `0x4A75` write — and
there it stays, because nobody calls `avanzan_las_bombas` on the title screen.

It is the bombs' chain reaction, set off by uninitialised memory.

## The starting-values `ldir` copies too much

`pon_los_valores_de_partida` (`0x4FD1`) dumps `0x90` bytes from `0x4FDD` to
`0xE305`. But `0x4FDD + 0x90 = 0x506D`, and the code of `monta_el_vdp` starts
at `0x5062`: the last eleven bytes that reach RAM are **the first instructions
of that routine**, not data.

It bothers nobody — they land in variables that are written before being read —
but the data block is declared only as far as it really is data.

## A `dec bc` that makes two labels fit

The top score line takes up all of row 0:

```
SCORE:nnnnnn BONUS:nnnnn STG:nn
```

`escribe_cinco_cifras_y_un_cero` prints five digits and sticks a zero on the
end, so the score is shown multiplied by ten. The bonus does not want that
zero, and `0x4D2A` erases it with a `dec bc` and a space. Into that gap fits
**the leading space of `" STG:"`**, which is written first on purpose.

At the bottom the same thing happens in reverse: the signature
` BOMBERMAN HUDSONSOFT 1983` runs from column 1 to 26 and the lives label
starts at 26, so the `3` of 1983 eats the label's first space. Painting them
the other way round loses the `3`.

And that signature has **no space between HUDSON and SOFT**, unlike the title
screen's.

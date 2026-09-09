# Open questions

All 8,192 bytes are explained and the listing reassembles to the same sha256.
What is left are questions of another kind: things the binary cannot answer on
its own.

## Who T.SASAGAWA is

The title screen gives two names, `Y.TANAKA` and `T.SASAGAWA`, without saying
who did what. The first is sometimes credited as this game's programmer; about
the second we have found nothing. Neither the cartridge nor the listing helps
further.

## Why stage 4 has fewer enemies than stage 3

The table at `0x4217` gives 1, 2, 3, **2** and 4 enemies for the first five
stages. The fourth is the first auto-bomb stage, and easing the pressure while
the bombs drop by themselves makes sense, but that is a guess: the binary only
says there is a 2 there.

## Whether there is another build

We have only seen one dump of this cartridge. In other games in the series two
and even three builds have turned up, differing by a handful of bytes, and the
only way to know is to compare. If anyone has another dump of Bomber Man for
MSX, we are interested.

## The six bytes at `0x4864`

They run and do nothing; read as text, in the cartridge's own font, they say
`OBADD`. That it is five letters and a zero is suggestive but proves nothing:
they could be a leftover from an earlier build, a string someone started and
never finished, or plain coincidence. **We do not know what they were.**

## The eight prizes, now identified

*Closed on 2026-09-09.* This used to say that two of the eight were unknown —
and on top of that, two of the ones taken for granted were misread. **theNestruo**
put it right ([issue #1](https://github.com/antxiko/Bomberman-disassembly/issues/1)),
and with his reading in hand all eight are legible:

| | prize |
|---|---|
| 1 | a **telescope** on its red tripod — it had been read as a helicopter |
| 2 | a money bag with a dollar sign |
| 3 | a penny-farthing |
| 4 | a carriage |
| 5 | a steaming cup |
| 6 | a **cocktail glass** — it had been read as a stringed instrument |
| 7 | a **red soda can**, lettered in black |
| 8 | a **cigarette pack**, seen at an angle with its lid up |

The shape of the last two is checked by drawing them from the ROM and blowing
them up; what their lettering says — "Coke" on the can and a "7" on the pack —
is theNestruo's reading, from knowing the game, and is credited to him here.

## Whether the dead `cp 089h` at `0x4AC9` ever ran

It is there, it is correct Z80, and an unconditional `jr` steps over it. What
we do not know is whether the `jr` replaced something or the `cp` is a
leftover. Since the effect on screen is the same — the next tile hits the other
half of the pillar and the flame stops there — nobody had any reason to notice.

## Which machine it was made for

`monta_el_vdp` removes the BIOS's H.TIMI hook and the game does not wait for
the display sweep: the pace is set by an empty loop. That means **the game's
speed depends on the processor's clock**, not on the display's, and that it
runs faster on a faster machine. We do not know whether that was intended.

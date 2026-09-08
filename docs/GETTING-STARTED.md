# Getting started

This repository does not ship the cartridge. It ships the commented listing,
the tools that generate it and the checks that hold it up. With the ROM dump
next to it, everything is reproducible with `make`.

## What you need

- **Python 3**, nothing installed on top.
- **pasmo**, to reassemble and check that the listing gives the ROM back.
- **openMSX**, only for the two measurements taken on the machine itself.
- The dump, under this name and with this sha256:

```
bomberman.rom
eab39bab547089facf9df3021e729b65fba2b263c505325d034ed1b6e3df8eea
8192 bytes
```

`make comprueba` verifies the sha before anything else.

## The one command

```
make all
```

It chains four steps, and the order matters:

| step | what it does |
|---|---|
| `make listado` | traces the flow from INIT and generates `src/bomberman.asm` |
| `make verify` | reassembles with pasmo and compares the sha256 with the original |
| `make sanity` | checks that not one byte of the cartridge is left unexplained |
| `make test` | the 64 checks on the listing and on what it claims |

`make verify` is the one that decides whether the disassembly is trustworthy:
if the 8192 reassembled bytes do not give the same sha256, the listing is
lying somewhere.

## The other commands

```
make densidad     # how many instructions carry a comment, routine by routine
make imagenes     # draws docs/imagenes from the ROM, capturing nothing
make cotejo       # boots openMSX, dumps its VRAM and subtracts ours from it
make alcance      # measures on the machine how far a blast breaks bricks
```

## How it is laid out

```
src/bomberman.asm       the listing, generated
src/bomberman.notes     the comments, anchored to addresses
src/bomberman.entries   the entry points the tracer cannot work out
src/bomberman.nocode    the ranges that are NOT code, with the reason
tools/                  the tracer, the generator and the checks
tests/                  64 checks that do not need the cartridge
docs/                   this site, in both languages
```

**The listing is not edited by hand.** The comments live in
`src/bomberman.notes`, each one anchored to an address, and they survive a
re-trace: if the tracer changes its mind about where a routine starts, the
comments still land where they should. `make listado` glues them on.

## Why there are three annotation files and not one

Because each answers a different question, and keeping them apart puts in
writing **what is known and how it is known**:

- `.entries` are the addresses the tracer cannot reach on its own, each with
  its justification. This cartridge has eight: INIT, the three continuations
  of the inline sound tables, and the four pieces of code nobody calls.
- `.nocode` are the three stretches that look like code and are data, with the
  reason next to them.
- `.notes` is everything else: labels, line comments, block headers and data
  ranges.

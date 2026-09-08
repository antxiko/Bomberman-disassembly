# Bomber Man (Hudson Soft, 1983) — desensamblado comentado

*(Also [in English](README.md).)*

**[→ Leerlo en la web](https://antxiko.github.io/Bomberman-disassembly/es/)**

Desensamblado completo y comentado del Bomber Man de Hudson Soft para MSX1,
1983, en un cartucho de 8 KB. El más pequeño de esta serie.

| | |
|---|---|
| binario explicado | **100 %** — 8.192 de 8.192 bytes |
| código trazado | 3.557 bytes (43,4 %) |
| datos identificados | 4.635 bytes (56,6 %) |
| rutinas | 200, **ninguna por debajo del 10 % comentada** |
| densidad de comentarios | **50,2 %** |
| comprobaciones | 64 |
| cotejo de VRAM contra openMSX | **0 diferencias** |

## Lo que hay dentro

**La cabecera del cartucho es código.** INIT vale `0x4004`, que es justo donde
el formato del MSX coloca STATEMENT, DEVICE y TEXT. Esos campos y los seis
bytes reservados son `ld sp,0F000h` y las tres llamadas del arranque. Sólo los
cuatro primeros bytes son cabecera de verdad.

**Ni un sprite.** `0x5062` escribe un `0xD0` en el primer atributo de sprite y
no vuelve a tocar la lista. El bombero, los bichos, las bombas y las llamas son
casillas de la tabla de nombres, todo de dos por dos, y el juego no tiene una
estructura de datos del mapa: lee el número de casilla. Tres comparaciones
sostienen el juego entero — `cp 020h` (libre), `cp 0e0h` (llama), `cp 0c0h`
(algo que mata).

**Dos programadores, y una errata.** La pantalla de título dice
`PROGRAMMER:Y.TANAKA` y `T.SASAGAWA`, y la última línea pone
`PUSH SPACE-KEY OR TORIGER`.

**Cada cuatro fases el juego pone las bombas por ti**, anunciado por un
`BOMB AUTO SETTING STAGE` parpadeante bajo el mismo `and 003h`.

**La explosión alcanza dos casillas y sólo tira los ladrillos de una** — leído
en el bucle desenrollado de `0x4AAC`, y luego medido en openMSX.

**Ocho premios se turnan debajo de los ladrillos**, y el de la fase de bomba
automática no es el de las tres que van detrás.

**El bicho se pone rojo cuando te persigue**: el mismo byte elige el dibujo y
decide el comportamiento.

Más en [Hallazgos](docs/es/HALLAZGOS.md).

## Cómo reproducirlo

El cartucho no se distribuye. Pon tu propio volcado al lado del Makefile con el
nombre `bomberman.rom`:

```
sha256  eab39bab547089facf9df3021e729b65fba2b263c505325d034ed1b6e3df8eea
tamaño  8192 bytes
```

Y luego:

```
make all        # trazar, generar, reensamblar, comprobar y pasar los tests
make imagenes   # dibujar docs/imagenes desde la ROM
make web        # montar la web en los dos idiomas
make cotejo     # restar nuestra VRAM de la de openMSX
make alcance    # medir el alcance de la explosión en la máquina
make fase4      # comprobar el modo de bomba automática en la máquina
```

`make verify` es el que decide si el desensamblado es fiable: reensambla con
pasmo y compara el sha256 con el original.

## Qué hay dónde

```
src/bomberman.asm       el listado, generado — no se edita a mano
src/bomberman.notes     los comentarios, anclados a dirección
src/bomberman.entries   los puntos de entrada que el trazador no puede deducir
src/bomberman.nocode    las zonas que NO son código, con su razón
tools/                  el trazador, el generador, el dibujo y las comprobaciones
tests/                  64 comprobaciones que no necesitan el cartucho
docs/                   la web, en inglés y en castellano
```

## Licencia

Las herramientas, las notas y la documentación se publican bajo los términos de
[LICENSE](LICENSE). El código del juego es de sus autores y de Hudson Soft;
esto es trabajo de preservación, estudio y documentación, y la imagen del
cartucho no se distribuye. Véase [AVISO-LEGAL.md](AVISO-LEGAL.md).

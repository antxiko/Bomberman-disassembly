# En el emulador

Tres medidas, las tres sobre la máquina y las tres reproducibles con `make`.
Ninguna imagen de este repositorio sale del emulador: las capturas son **para
comprobar**, no para publicar.

## Arrancarlo

```
openmsx -machine Philips_VG_8020 -cart bomberman.rom
```

La BIOS del VG-8020 tarda más de cinco segundos en llamar a INIT. Antes de eso
el cartucho ni siquiera ha copiado los valores de partida a la RAM, y un
volcado hecho a los tres segundos no vale para nada.

## El cotejo de la VRAM

```
make cotejo
```

Arranca openMSX sin ventana, deja correr la portada, **pulsa el espacio con la
matriz del teclado** (fila 8, bit 0, que es lo que lee GTTRIG en la entrada 0)
y vuelca dos veces los 16 KB del VDP más 1792 bytes de RAM. Luego
`tools/coteja_vram.py` los resta de la VRAM que monta `tools/vram.py`.

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

Cada línea dice algo distinto:

- **Color y patrones** salen enteros de los tres bloques de gráficos, así que
  tienen que dar cero. Si no, el formato de `0x5088` está mal leído.
- **La tabla de nombres de la portada** también es determinista: los diecinueve
  rótulos, el rótulo grande y la fila de muestra.
- **La pantalla de la partida no se puede comparar casilla a casilla**, porque
  el reparto lo echa a suertes el registro R. Lo que sí se comprueba es todo lo
  demás: que el marco y los treinta y cinco pilares están exactamente donde
  `0x4DB7` los pone, que cada ladrillo del tablero cumple las reglas de
  `0x4E35`, y que el premio y la puerta están debajo de uno.

**Y una trampa que costó una vuelta.** Comparar la tabla de nombres de la VRAM
con la pantalla de la RAM no dice nada: `vuelca_la_pantalla` (`0x510E`) la
vuelca **y la deja en blanco**, así que en cualquier instante la RAM está a
medio montar mientras la VRAM guarda el último cuadro entero. El marco y los
pilares hay que mirarlos en la tabla de nombres.

Las veinte diferencias que salieron en la portada la primera vez estaban todas
explicadas, y dos eran hallazgos:

- Seis casillas del marcador y seis del récord, que el montaje no escribía.
- El parpadeo del bicho y de la bomba, que en la VRAM es el del cuadro anterior
  al del volcado.
- **La bomba de muestra en el estado 4** y no en el 1, que es la reacción en
  cadena disparada por RAM sin estrenar. Está contada en
  [Hallazgos](HALLAZGOS.html).

## La medida del alcance de la explosión

```
make alcance
```

Del listado sale que la llama alcanza dos casillas de tablero por lado pero
sólo gasta los ladrillos de la primera. Eso se puede leer, pero también se
puede **medir**.

`tools/omsx_alcance.tcl` entra en la partida, vuelca el tablero, **escribe dos
fichas de bomba a mano** en la lista de `0xE359` —estado 1, columna, fila y
cuenta a cero, que es exactamente lo que deja `pon_una_bomba`— y vuelve a
volcar el tablero ocho segundos después.

Las dos casillas se eligieron leyendo el tablero de un volcado anterior: la
emulación es determinista, así que con los mismos tiempos sale el mismo
reparto.

```
  ladrillos antes  : 29
  ladrillos despues: 27
  bomba A: ladrillo a 1 casilla  por la derecha   en ( 5, 0) -> CAE
  bomba A: ladrillo a 1 casilla  por la abajo     en ( 4, 1) -> CAE
  bomba B: ladrillo a 2 casillas por la izquierda en (11, 0) -> SIGUE EN PIE
```

## La comprobación del modo de bomba automática

```
make fase4
```

Fuerza la fase a 4 escribiendo `(0xE310)` y vuelca la tabla de nombres cuatro
veces seguidas, para pillar el rótulo de abajo en las dos mitades de su
parpadeo. Sale esto:

```
a fila 23: '#                           @:3#'
b fila 23: '#                           @:3#'
c fila 23: '#  BOMB AUTO SETTING STAGE  @:3#'
d fila 23: '#  BOMB AUTO SETTING STAGE  @:3#'
```

En las demás fases esa fila lleva la firma ` BOMBERMAN HUDSONSOFT 1983` y no
parpadea.

## Trucos para mirarlo por dentro

Ver el tablero, que es donde está el mapa de verdad:

```
debug read_block memory 0xE38A 768
```

Saltarse fases, que es lo que hace `make fase4`:

```
debug write memory 0xE310 4
```

Ver quién persigue: el byte `+3` de la primera ficha de enemigo.

```
debug read memory 0xE31F
```

Cuando vale cero, ese bicho va a por ti — y se pone rojo.

**Y la regla de oro para cualquier volcado de este cartucho**: la pantalla de
la RAM (`0xE000`) está siempre a medio montar. Lo que hay que leer es la tabla
de nombres de la VRAM (`0x1800`), que guarda el último cuadro entero.

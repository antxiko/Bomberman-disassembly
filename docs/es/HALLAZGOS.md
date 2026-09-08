# Hallazgos

Lo que apareció al desmontar los ocho kilobytes, con la dirección al lado para
que se pueda comprobar.

## La cabecera del cartucho es código

INIT vale `0x4004`, que es exactamente donde el formato del MSX coloca
STATEMENT, DEVICE y TEXT. Esos tres campos y los seis bytes reservados **no son
campos**: son `ld sp,0F000h` y las tres llamadas del arranque.

Sólo los cuatro primeros bytes del cartucho son cabecera de verdad.

## Dos programadores, y una errata de Hudson

La pantalla de título, dibujada desde la ROM, dice en la fila 20
**PROGRAMMER:Y.TANAKA** y en la 21 **T.SASAGAWA**.

Y la última línea dice:

```
PUSH SPACE-KEY OR TORIGER
```

TORIGER, no TRIGGER.

Ninguna de las dos cosas se puede leer mirando los bytes. La fuente del
cartucho no es ASCII del todo —el `0x21`, que sería un `!`, aquí son los dos
puntos— y encima **cambia a mitad de juego**: los mismos códigos que en la
portada son las letras del rótulo grande, en la partida son los bichos. La
única forma de citar un texto de este cartucho es dibujarlo.

## Cada cuatro fases el juego pone las bombas por ti

`pon_una_bomba` (`0x4922`) mira el número de fase con un `and 003h`: si es
múltiplo de cuatro, **no pide el disparo**. Y
`pinta_el_aviso_de_bomba_automatica` (`0x4D3A`) enciende un rótulo con
exactamente la misma condición, parpadeando dieciséis cuadros sí y ocho no:

```
  BOMB AUTO SETTING STAGE
```

Un modo de juego entero en dos instrucciones. Y encaja con la tabla de
enemigos: la fase 4, la primera de bomba automática, tiene **menos** enemigos
que la 3.

## La explosión alcanza dos casillas y sólo tira los ladrillos de una

Cada brazo son cuatro casillas de pantalla, o sea dos de tablero. Pero el bucle
de `0x4AAC` está desenrollado con una copia por casilla, y las dos primeras
llaman a `pinta_una_llama_y_gasta_el_ladrillo` (`0x4B21`) mientras que la
tercera y la cuarta llaman a `pinta_una_llama_sin_gastar` (`0x4B5A`), que se
vuelve **sin escribir** si lo que hay es un ladrillo.

**Medido en openMSX**, no deducido. Dos bombas escritas a mano en la lista de
`0xE359`: una con ladrillo pegado a la derecha y abajo, otra con la casilla de
al lado libre y el ladrillo a dos.

```
bomba A: ladrillo a 1 casilla  por la derecha   en ( 5, 0) -> CAE
bomba A: ladrillo a 1 casilla  por la abajo     en ( 4, 1) -> CAE
bomba B: ladrillo a 2 casillas por la izquierda en (11, 0) -> SIGUE EN PIE
```

## El bicho se pone rojo cuando va a por ti

El byte `+3` de la ficha del enemigo hace dos cosas: elige el dibujo
(`0xC0 + cuadro*4`) y decide el comportamiento. Cuando vale cero, el enemigo
**persigue al bombero** (`0x477B`); el resto del tiempo anda a lo suyo y cambia
de idea al azar.

Y cero es justo el cuadro rojo. Los otros tres son morados.

## Ni un sprite en todo el cartucho

`monta_el_vdp` (`0x507C`) escribe un `0xD0` en el primer atributo de sprite —la
marca de «no hay más»— y **no vuelve a tocar la lista nunca**. Los registros 5
y 6 del VDP se declaran y no se usan.

Todo lo que se mueve son casillas de la tabla de nombres, y todo ocupa dos por
dos. Eso explica la arquitectura entera: dos pantallas de 768 bytes en la RAM,
y el número de casilla haciendo de mapa.

## El azar se apoya en el registro de refresco

`numero_al_azar` (`0x4EF9`) le mezcla a la semilla el **registro R** del Z80.
Si R avanzara siempre lo mismo entre dos sorteos, la serie de casillas se
cierra en **tres a cinco valores** y se repite; lo comprueba
`test_el_azar_del_cartucho_se_apoya_en_el_registro_r` con cuatro pasos
distintos.

En la máquina no pasa porque entre dos sorteos se ejecutan más o menos
instrucciones según cuántas veces haya habido que repetir el sorteo. La
consecuencia: **el reparto de una fase no se puede reproducir desde fuera**.

## Cuatro trozos de código a los que no llega nadie

Tres rutinas enteras, sin un solo `call` que las nombre en los 8 KB:

| dirección | qué hace |
|---|---|
| `0x4EF0` | borra una casilla del tablero. Es la versión suelta de lo que hace `0x4A7A` dentro de otra rutina |
| `0x4F84` | una espera de `0x400` vueltas, hermana pequeña de la de `0x4F7B` |
| `0x50D6` | escribe el registro 7 del VDP, que sólo se pone una vez desde la tabla de arranque |

Y una cuarta: el `cp 089h` de `0x4AC9`, que comprobaría el pilar en la primera
casilla de cada brazo de la explosión. Por encima pasa un `jr` incondicional.

Ese último **no cambia nada**, y por eso nadie lo arregló: la casilla siguiente
da con la otra mitad del mismo pilar y la llama se para ahí igual. Se declaran
como código, porque instrucciones son.

## Seis bytes que se ejecutan y no hacen nada

En `0x4864`, dentro de `pinta_los_enemigos`:

```
4864  4F  ld c,a
4865  42  ld b,d
4866  41  ld b,c
4867  44  ld b,h
4868  44  ld b,h
4869  00  nop
```

Nadie vuelve a leer B ni C antes de escribirlos: el primero que los toca es un
`ld bc,00007h`. Leídos como texto, y con la propia fuente del cartucho, dicen
**OBADD**. Es lo único de los 8 KB que no sirve ni de dato ni de instrucción.

Hay otro resto parecido en `0x49D6`: un `cp 006h` cuyas dos salidas van a la
misma etiqueta.

## Reventar la puerta sale caro

Si una llama alcanza el premio o la puerta, `pinta_una_casilla_del_premio`
(`0x461E`) apunta el sitio y pide castigo. `saca_los_enemigos_de_castigo`
(`0x453B`) espera a que esa casilla quede limpia y saca **cuatro enemigos más**
por ahí.

La puerta se vuelve a descubrir sola; el premio se pierde.

## Y quedarse sin bonus, más caro todavía

Si el bonus llega a cero, `se_agoto_el_bonus` (`0x449F`) llama a
`borra_el_tablero` (`0x4F55`) y **borra los 768 bytes de golpe**: los treinta y
cinco ladrillos, el premio y la puerta. Y deja las dos banderas de «ya está
descubierto» puestas a uno, así que ya no se vuelven a buscar.

La fase se queda sin salida y sólo se puede terminar matándolos a todos.

## La bomba de la portada sale en el último cuadro de la mecha

`pon_la_bomba_del_titulo` (`0x4442`) la pone en el estado 1. Pero al pintarla,
`mira_si_la_alcanza_otra_llama` (`0x4A6D`) mira lo que hay debajo **en el
tablero**, y al entrar en la portada el tablero no se ha borrado: son bytes de
la RAM sin estrenar.

En el volcado de openMSX valen `0xFF`, o sea más de `0xE0`, que es lo que
`0x4A6D` toma por una llama. Así que le mete el estado 4 y la cuenta 6 —la
ficha volcada dice exactamente `04 0E 0A 06`, que es lo que escriben `0x4A71` y
`0x4A75`— y ahí se queda, porque en la portada nadie llama a
`avanzan_las_bombas`.

Es la reacción en cadena de las bombas, disparada por memoria sin inicializar.

## El `ldir` de los valores de partida copia de más

`pon_los_valores_de_partida` (`0x4FD1`) vuelca `0x90` bytes desde `0x4FDD` a
`0xE305`. Pero `0x4FDD + 0x90 = 0x506D`, y el código de `monta_el_vdp` empieza
en `0x5062`: los once últimos bytes que llegan a la RAM son **las primeras
instrucciones de esa rutina**, no datos.

No molesta a nadie —caen en variables que se escriben antes de leerse— pero el
bloque de datos se declara sólo hasta donde es dato de verdad.

## Un `dec bc` que hace encajar dos rótulos

El marcador de arriba ocupa la fila 0 entera:

```
SCORE:nnnnnn BONUS:nnnnn STG:nn
```

`escribe_cinco_cifras_y_un_cero` saca cinco cifras y pega un cero detrás, así
que el marcador se enseña multiplicado por diez. Al bonus ese cero le sobra, y
`0x4D2A` lo borra con un `dec bc` y un espacio. En ese hueco encaja **el
espacio con el que empieza `" STG:"`**, que se escribe antes a propósito.

Abajo pasa lo mismo al revés: la firma ` BOMBERMAN HUDSONSOFT 1983` ocupa de la
columna 1 a la 26 y el rótulo de las vidas empieza en la 26, así que el `3` de
1983 se come el primer espacio del rótulo. Pintarlo al revés pierde el `3`.

Y esa firma va **sin espacio entre HUDSON y SOFT**, al contrario que la de la
portada.

# El código

3557 bytes de código y 4635 de datos, 200 rutinas, y una idea que lo explica
todo: **el juego no tiene una estructura de datos del mapa**. Lee el número de
casilla.

## Dos pantallas en la RAM, no una

| dónde | qué |
|---|---|
| `0xE000`–`0xE2FF` | **la pantalla**: lo que se ve. Cada cuadro se vuelca entera a la VRAM con un LDIRVM y se deja en blanco |
| `0xE38A`–`0xE689` | **el tablero**: lo que permanece. Los ladrillos, las llamas mientras duran, el premio y la puerta cuando ya están descubiertos |

Las dos tienen la misma forma —24 filas de 32 casillas— y la misma aritmética
de cursor: `pon_el_cursor` (`0x5128`) da la dirección en la pantalla y
`pon_el_cursor_en_el_tablero` (`0x4F6F`) la misma casilla en el tablero,
sumándole `0x38A`.

De ahí sale que **el muro y los pilares no se pueden romper**: sólo están en la
pantalla, los repinta `pinta_el_tablero` (`0x4DB7`) cada cuadro, y no están
donde las llamas escriben. Y los ladrillos sólo están en el tablero.

## El significado de cada casilla

| casillas | qué son |
|---|---|
| `0x00`–`0x09` | las cifras |
| `0x0A`, `0x0E` | el premio y la puerta, de dos por dos |
| `0x10`–`0x19` | las letras de SCORE y BONUS |
| `0x20` | casilla vacía |
| `0x22`–`0x2F` | el enemigo reventando, siete cuadros |
| `0x60`–`0x7B` | la bomba: cuatro tamaños por dos de parpadeo |
| `0x80`–`0x87` | el ladrillo desmoronándose, ocho cuadros |
| `0x88`, `0x89` | el muro del borde y el pilar fijo |
| `0x8A`–`0x8D` | el bombero quieto |
| `0xA0`–`0xBF` | el bombero andando: cuatro sentidos por dos pasos |
| `0xC0`–`0xCF` | el enemigo vivo, cuatro cuadros |
| `0xE0`–`0xEF` | la llama |

Y de ahí salen las tres comparaciones que se repiten por todo el listado:

- `cp 020h` — «está libre»
- `cp 0e0h` — «hay una llama»
- `cp 0c0h` — «hay algo que mata», que vale para las llamas **y** para los
  bichos porque están puestos seguidos a propósito

## El bucle principal es el índice del juego

`bucle_principal` (`0x40CC`): veinte llamadas seguidas, una por sistema, en el
orden en que se pintan encima unas de otras.

```
cierra_el_cuadro                 los contadores, el volcado y el sonido
copia_el_tablero_a_la_pantalla   el tablero encima de la pantalla
pinta_el_tablero                 el marco y los pilares
avanzan_las_bombas               la cuenta atrás
pinta_las_bombas_y_las_llamas
pon_una_bomba                    lee el disparo
avanza_el_bombero                anda, o se muere
mueve_los_enemigos
pinta_el_premio / pinta_la_puerta
pinta_los_enemigos
descubre_el_premio / descubre_la_puerta
pinta_al_bombero                 encima de todo
saca_los_enemigos_de_castigo
pisa_la_puerta_o_el_premio
descuenta_el_bonus
pinta_el_marcador
pinta_el_aviso_de_bomba_automatica
```

Y tres puertas de salida, que son las tres formas de acabar una vida: muerto
(`0xE37B`), puerta pisada (`0xE316`) o fase limpia (`0xE318`).

**El orden es la lógica.** Cada cosa deja su rastro en las casillas para que la
siguiente lo lea, y por eso el bombero se pinta **antes** de mirar si le han
matado: al escribirse encima de la casilla, lee lo que había.

Hay dos versiones recortadas del mismo bucle: `un_cuadro_sin_mando` (`0x4231`),
sin lo que atiende al jugador, y `un_cuadro_de_adorno` (`0x4253`), sin
enemigos. Son las que se usan en las celebraciones y en el fin de partida:
todo se sigue viendo moverse, pero ya no se manda.

## Todo mide dos por dos

`pinta_cuatro_casillas` (`0x4B7B`) escribe A, A+1 arriba y A+`0x10`, A+`0x11`
abajo. El `0x1F` del medio es 32 menos el `inc bc` que ya se hizo, y el `0x0F`,
`0x10` menos el `inc a`.

Así se pinta el bombero, el bicho, la bomba, la llama, el premio, la puerta, el
ladrillo y el pilar: **todo**. Y el tablero de verdad, en casillas de dos por
dos, son 15 columnas por 11 filas dentro de una pantalla de 32 por 24.

## Cómo se siembra una fase

`siembra_la_fase` (`0x4E35`) no guarda ningún mapa: escribe los ladrillos en el
tablero y ahí se quedan. Lo único que apunta aparte es **dónde cayó el
primero** —que esconde el premio— y **dónde cayó el último** —que esconde la
puerta—, porque `0x4EB1` sólo guarda el premio la primera vez y la puerta se
apunta siempre.

Las reglas del sorteo, en orden:

1. a dos o más casillas del sitio del bombero
2. de las dos coordenadas, **una impar y la otra par**. Con las dos impares
   caería encima de un pilar; con las dos pares, en las casillas que el juego
   deja siempre libres
3. ninguna de las ocho de la tabla de `0x4EDF`, que son las vecinas de las
   cuatro esquinas por donde salen los enemigos

No se mira si ya hay un ladrillo ahí, así que dos pueden caer en la misma
casilla y salir menos de treinta y cinco. En el volcado del emulador salieron
**29**.

## El contador con tope

Es como se mide **todo** el tiempo del juego. `avanza_un_contador` (`0x46BE`)
recibe un puntero a una pareja (cuenta, tope): suma uno y al llegar al tope
vuelve a cero. Hay seis parejas seguidas desde `0xE36F`, y quien quiere hacer
algo «de vez en cuando» mira si su cuenta vale cero.

| pareja | tope | qué mide |
|---|---|---|
| `0xE36F` | 4 | el paso del bombero |
| `0xE371` | 4 | su agonía |
| `0xE373` | 7 | el enemigo reventando |
| `0xE375` | 5 | el paso de los enemigos |
| `0xE377` | 3 | la bomba y el ladrillo desmoronándose |
| `0xE379` | 50 | el bonus |

Los seis topes salen de la tabla de valores de partida de `0x4FDD` y **no se
tocan nunca más**. Ahí está la velocidad del juego entero.

## Las dos listas

**Enemigos** en `0xE31C`: ocho fichas de siete bytes, cerradas por el `0xFF` de
`0xE354`.

```
+0  qué hace: 0 libre, 1 vivo, 2..9 reventando, 0xFF fin de la lista
+1  columna       +2  fila
+3  cuadro de dibujo, que cuenta 3, 2, 1, 0 y vuelta
+4  cuenta atrás hasta el cuadro siguiente
+5  hacia dónde va: 0 izquierda, 1 derecha, 2 arriba, 3 abajo
+6  sin usar
```

El `+3` hace dos cosas a la vez: elige el dibujo y decide el comportamiento.
Cuando vale cero el enemigo **va a por el bombero**, y ese es justo el cuadro
rojo.

**Bombas** en `0xE359`: cinco fichas de cuatro bytes.

```
+0  0 libre, 1..4 la mecha, 5..12 la explosión, 13 apagar
+1  columna       +2  fila       +3  cuenta hasta el cuadro siguiente
```

No hay ningún límite más: el juego no lleva «cuántas bombas te quedan».

## La explosión, y el bucle desenrollado

`pinta_la_explosion` (`0x4A8C`) pinta el centro sin preguntar y recorre los
cuatro brazos con la tabla de `0x4F8D`: **ocho tiras de cuatro casillas**, una
por lado y por cada una de las dos filas —o columnas— que ocupa. Cuatro
casillas de pantalla por lado son **dos casillas de tablero**.

El bucle está desenrollado a propósito, con una copia por casilla, porque cada
una se para de una forma distinta:

| casilla | se para con | qué rutina usa |
|---|---|---|
| 1ª | sólo el muro | `pinta_una_llama_y_gasta_el_ladrillo` |
| 2ª | ladrillo, muro o pilar | `pinta_una_llama_y_gasta_el_ladrillo` |
| 3ª | ladrillo, muro o pilar | `pinta_una_llama_sin_gastar` |
| 4ª | ladrillo, muro o pilar | `pinta_una_llama_sin_gastar` |

La diferencia que importa: las dos primeras **gastan** el ladrillo —le suman
uno al dibujo cada tres cuadros hasta hacerlo desaparecer— y las dos últimas se
vuelven **sin escribir** si lo que hay es un ladrillo. Como las dos primeras
son la casilla de tablero pegada a la bomba y las dos últimas la siguiente, el
resultado es que la explosión **alcanza dos casillas pero sólo tira los
ladrillos de la primera**.

Está medido en la máquina, no deducido: [En el emulador](EN-EL-EMULADOR.html).

## Un truco de registros que merece la pena

`si_toca_gasta_el_ladrillo` (`0x4B4E`) tiene que sumarle uno a A y no le queda
ni un registro libre. Lo resuelve así:

```
push af           A a la pila
ex (sp),hl        y de la pila a H, que es donde va la A
ld a,(0e377h)     la cuenta de tres cuadros
or a
jr nz,...
inc h             un cuadro más de desmoronarse
ex (sp),hl        H otra vez a la pila
pop af            y de ahí a A, ya cambiada
```

## El azar

`numero_al_azar` (`0x4EF9`) realimenta `(0xE384)` con dieciséis bits y le mezcla
el **registro R** del Z80. Devuelve el byte de abajo.

Esa mezcla no es un adorno: si R avanzara siempre lo mismo entre dos sorteos, la
serie de casillas se cierra en tres a cinco valores y se repite. Lo comprueba un
test del repositorio con cuatro pasos distintos. En la máquina no pasa porque
entre dos sorteos se ejecutan más o menos instrucciones según cuántas veces
haya habido que repetir el sorteo.

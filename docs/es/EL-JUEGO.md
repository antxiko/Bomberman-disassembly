# El juego

Bomber Man, de Hudson Soft, 1983. Ocho kilobytes. Se pone una bomba, se corre,
la bomba revienta los ladrillos de al lado, y debajo de uno de ellos está la
puerta.

![La portada](../imagenes/titulo.png)

La portada, dibujada desde la ROM. Arriba el rótulo grande —que no es un
dibujo guardado, sino nueve letras de dos por dos que pinta un bucle— y debajo
una **leyenda** que explica el juego entero: el bombero, el bicho con lo que
vale, el cofre del premio y la puerta.

## Las reglas, medidas sobre el código

| cosa | valor | dónde |
|---|---|---|
| tablero | 15 columnas × 11 filas | `0x4E15` |
| pilares fijos | 35, donde las dos coordenadas son impares | `0x4DB7` |
| ladrillos por fase | 35 sorteos, con repeticiones | `0x4E65` |
| vidas | 3 | `0x4069` |
| bonus de partida | 1000, bajando de 10 en 10 cada 50 cuadros | `0x4080` |
| bombas a la vez | 5 | lista de `0xE359` |
| enemigos a la vez | 8 | lista de `0xE31C` |

El marcador se enseña **multiplicado por diez**: `escribe_cinco_cifras_y_un_cero`
(`0x4F29`) saca cinco cifras y pega un cero detrás. Al bonus se lo quita quien
llama, y en el hueco que deja encaja el espacio con el que empieza `" STG:"`.

## Cuántos enemigos, y a qué ritmo

La tabla de `0x4217`, dos bytes por fase. De la sexta en adelante todas juegan
con la quinta línea.

| fase | enemigos | cadencia |
|---|---|---|
| 1 | 1 | `0x10` |
| 2 | 2 | `0x15` |
| 3 | 3 | `0x1A` |
| 4 | **2** | `0x1F` |
| 5 y siguientes | 4 | `0x24` |

La cuarta fase tiene **menos** enemigos que la tercera. Es la primera fase de
bomba automática, y quizá por eso.

## Las fases de bomba automática

Cada cuatro fases el juego deja de pedir el disparo y **pone las bombas solo**.
Lo deciden dos instrucciones, `0x4922` y `0x4D3A`, con el mismo `and 003h`
sobre el número de fase: una desactiva la comprobación del disparo y la otra
enciende el rótulo que lo anuncia abajo, parpadeando dieciséis cuadros sí y
ocho no:

```
  BOMB AUTO SETTING STAGE
```

## Cómo se muere

Dos formas, y **una sola comparación** las cubre las dos. Al pintar el bombero,
`pinta_una_casilla_del_bombero` (`0x4BEB`) mira lo que había debajo: si es
`0xC0` o más, empieza la agonía. De `0xC0` a `0xCF` están los bichos y de
`0xE0` a `0xEF` las llamas, puestos seguidos a propósito.

Como el bombero se pinta **después** que los enemigos y que las llamas, lo que
lee es lo de ese mismo cuadro.

![Los ocho cuadros de morir](../imagenes/agonia.png)

Ocho cuadros, y van hacia atrás en la hoja de casillas: del `0x4E` al `0x40`.
El último no es un dibujo del bombero, es un **OUT** verde encima de lo que
queda de él.

## El bicho que te persigue es el rojo

El mismo byte de la ficha del enemigo elige el dibujo y decide el
comportamiento. Cuando vale cero, el enemigo **va a por el bombero** (`0x477B`);
el resto del tiempo anda a lo suyo y cambia de idea al azar. Y cero es
justamente el cuadro de dibujo rojo.

![El bicho vivo](../imagenes/enemigos.png)

Los dos primeros son el cuadro 0. Los otros seis, morados.

## Lo que vale cada cosa

- **Un enemigo**: `(cuadro de dibujo × 4) + 2`, más un número al azar de 1 a 4.
  Sale entre 3 y 18, o sea entre **30 y 180 puntos** en pantalla. El rótulo de
  la portada, al lado del bicho, anuncia `200-10`.
- **El premio**: un número al azar entre `0x10` y `0x7E`, siempre par y siempre
  con el bit 4 puesto. Entre **160 y 1260 puntos**.
- **El bonus**: al limpiar la fase se cambia por marcador de diez en diez, con
  un pitido por cada diez.

## Las dos formas de acabar una fase

**Pisar la puerta** (`0xE316`) o **matarlos a todos** (`0xE318`). Sólo la
segunda cobra el bonus.

Y hay una tercera que no es un final sino un castigo: si el bonus llega a cero,
`se_agoto_el_bonus` (`0x449F`) **borra el tablero entero**. Los treinta y cinco
ladrillos, el premio y la puerta desaparecen de golpe, y con las dos banderas
de «ya está descubierto» puestas a uno ya no se vuelven a buscar. La fase se
queda sin salida.

![Una partida](../imagenes/partida.png)

Una partida en marcha, repartida con las tres reglas del cartucho y pintada con
sus rutinas. Los ladrillos son **uno de los repartos posibles**: el de verdad lo
decide el registro R del Z80 en el instante en que se pulsa el disparo.

# Preguntas abiertas

Los 8192 bytes están explicados y el listado reensambla al mismo sha256. Lo que
queda son preguntas de otro tipo: cosas que el binario no puede contestar solo.

## Quién es T.SASAGAWA

La portada da dos nombres, `Y.TANAKA` y `T.SASAGAWA`, sin decir quién hizo qué.
El primero se cita a veces como el programador de este juego; del segundo no
hemos encontrado nada. Ni el cartucho ni el listado ayudan más.

## Por qué la fase 4 tiene menos enemigos que la 3

La tabla de `0x4217` da 1, 2, 3, **2** y 4 enemigos para las cinco primeras
fases. La cuarta es la primera de bomba automática, y bajar la presión mientras
las bombas caen solas tiene sentido, pero eso es una suposición: el binario
sólo dice que ahí pone un 2.

## Si hay otra compilación

De este cartucho sólo hemos visto un volcado. En otros juegos de la serie han
aparecido dos y hasta tres compilaciones que sólo se distinguen por unos bytes,
y la única forma de saberlo es comparar. Si alguien tiene otro volcado de
Bomber Man para MSX, interesa.

## Los seis bytes de `0x4864`

Se ejecutan y no hacen nada; leídos como texto, con la propia fuente del
cartucho, dicen `OBADD`. Que sean cinco letras y un cero es sugerente pero no
prueba nada: pueden ser un resto de una compilación anterior, una cadena que
alguien empezó y no terminó, o simple casualidad. **No sabemos qué eran.**

## Qué diferencia hay de verdad entre los dieciséis dibujos de fase

`0x4167` carga dos bloques de la tabla de `0x419B` cada cuatro fases, y cada
bloque redefine dos casillas. Están dibujados —salen en la portada— y se ve que
lo que cambia es la cara del bicho, pero **no hemos jugado lo bastante como
para decir si además cambia el comportamiento**. Por el código no: la tabla
sólo carga gráficos.

## Si el `cp 089h` muerto de `0x4AC9` llegó a ejecutarse alguna vez

Está ahí, es Z80 correcto, y un `jr` incondicional pasa por encima. Lo que no
sabemos es si el `jr` sustituyó a algo o si el `cp` es un resto. Como el efecto
en pantalla es el mismo —la casilla siguiente da con la otra mitad del pilar y
la llama se para ahí—, nadie tenía motivo para notarlo.

## Qué máquina se usó

`monta_el_vdp` quita el gancho H.TIMI de la BIOS y el juego no espera al
barrido: el ritmo lo marca un bucle en vacío. Eso significa que **la velocidad
del juego depende de la frecuencia del procesador**, no de la de la pantalla, y
que en una máquina más rápida corre más. No sabemos si eso era intencionado.

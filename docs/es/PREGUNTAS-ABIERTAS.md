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

## Los ocho premios, ya identificados

*Cerrado el 2026-09-09.* Aquí se decía que dos de los ocho no se sabía qué eran,
y además dos de los que se daban por seguros estaban mal leídos. Lo corrigió
**theNestruo** ([issue #1](https://github.com/antxiko/Bomberman-disassembly/issues/1)),
y con su lectura delante los ocho se ven:

| | premio |
|---|---|
| 1 | un **telescopio** sobre su trípode rojo —se había leído como un helicóptero— |
| 2 | un saco de dinero con el símbolo del dólar |
| 3 | un velocípedo |
| 4 | un carruaje |
| 5 | una taza humeante |
| 6 | una **copa de cóctel** —se había leído como un instrumento de cuerda— |
| 7 | una **lata roja de refresco**, con las letras en negro |
| 8 | un **paquete de tabaco**, visto en escorzo y con la solapa levantada |

La forma de los dos últimos se comprueba dibujándolos de la ROM y ampliándolos;
lo que dicen sus letras —«Coke» en la lata y un «7» en el paquete— es lectura de
theNestruo, que conoce el juego, y aquí se recoge con su crédito.

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

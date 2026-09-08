# Empezar

Este repositorio no trae el cartucho. Trae el listado comentado, las
herramientas que lo generan y las comprobaciones que lo sujetan. Con el
volcado de la ROM al lado, todo se reproduce con `make`.

## Lo que hace falta

- **Python 3**, sin nada instalado aparte.
- **pasmo**, para reensamblar y comprobar que el listado vuelve a dar la ROM.
- **openMSX**, sólo para las dos medidas que se hacen sobre la máquina.
- El volcado, con este nombre y este sha256:

```
bomberman.rom
eab39bab547089facf9df3021e729b65fba2b263c505325d034ed1b6e3df8eea
8192 bytes
```

`make comprueba` verifica el sha antes de nada.

## La orden que lo hace todo

```
make all
```

Encadena cuatro pasos, y el orden importa:

| paso | qué hace |
|---|---|
| `make listado` | traza el flujo desde INIT y genera `src/bomberman.asm` |
| `make verify` | reensambla con pasmo y compara el sha256 con el original |
| `make sanity` | comprueba que ni un byte del cartucho se queda sin explicar |
| `make test` | las 64 comprobaciones sobre el listado y sobre lo que afirma |

`make verify` es el que decide si el desensamblado es fiable: si los 8192
bytes reensamblados no dan el mismo sha256, el listado miente en algún sitio.

## Las otras órdenes

```
make densidad     # cuántas instrucciones llevan comentario, rutina por rutina
make imagenes     # dibuja docs/imagenes desde la ROM, sin capturar nada
make cotejo       # arranca openMSX, vuelca su VRAM y la resta de la nuestra
make alcance      # mide en la máquina hasta dónde tira ladrillos una explosión
```

## Cómo está organizado

```
src/bomberman.asm       el listado, generado
src/bomberman.notes     los comentarios, anclados a dirección
src/bomberman.entries   los puntos de entrada que el trazador no puede deducir
src/bomberman.nocode    las zonas que NO son código, con su razón
tools/                  el trazador, el generador y las comprobaciones
tests/                  64 comprobaciones que no necesitan el cartucho
docs/                   esta web, en los dos idiomas
```

**El listado no se edita a mano.** Los comentarios viven en
`src/bomberman.notes`, cada uno anclado a una dirección, y sobreviven a un
retrazado: si el trazador cambia de opinión sobre dónde empieza una rutina,
los comentarios siguen donde tienen que estar. `make listado` los pega.

## Por qué hay tres ficheros de anotación y no uno

Porque cada uno responde a una pregunta distinta, y separarlos deja por
escrito **qué se sabe y cómo se sabe**:

- `.entries` son las direcciones a las que el trazador no puede llegar solo, y
  cada una lleva su justificación. En este cartucho hay ocho: INIT, las tres
  continuaciones de las tablas de sonido incrustadas y los cuatro trozos de
  código que no llama nadie.
- `.nocode` son los tres tramos que parecen código y son datos, con el motivo
  al lado.
- `.notes` es todo lo demás: etiquetas, comentarios de línea, cabeceras de
  bloque y rangos de datos.

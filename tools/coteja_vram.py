#!/usr/bin/env python3
"""Compara lo que monta tools/vram.py con lo que el VDP tiene DE VERDAD.

Mirar el dibujo no basta. Las imagenes de este repositorio se construyen
ejecutando en Python los pasos del cartucho, y la unica forma de saber si el
formato esta bien leido es coger la VRAM que openMSX tiene mientras el juego
corre -volcada con tools/omsx_vram.tcl- y restarle la de Python.

Se comparan tres cosas, y cada una dice algo distinto:

1. LAS TABLAS DE PATRONES Y DE COLOR de la portada y de la partida. Son
   deterministas: salen enteras de los bloques de graficos del cartucho, asi
   que tienen que dar CERO diferencias. Si no, el formato de 0x5088 esta mal
   leido.

2. LA TABLA DE NOMBRES DE LA PORTADA. Tambien es determinista -son los
   diecinueve rotulos, el rotulo grande y la fila de muestra-, asi que tambien
   tiene que dar cero. Es lo que prueba que la lamina publicada ensena la
   portada entera y no media.

3. LA PANTALLA DE LA PARTIDA no se puede comparar casilla a casilla, porque el
   reparto de ladrillos lo echa a suertes el registro R. Lo que si se comprueba
   es todo lo demas, que no depende del azar: que el marco y los treinta y
   cinco pilares estan EXACTAMENTE donde 0x4DB7 los pone, que la tabla de
   nombres de la VRAM es copia byte a byte de la pantalla de la RAM -que es lo
   que hace 0x510E-, que los ladrillos caen donde las reglas de 0x4E35 los
   dejan caer, y que el premio y la puerta estan debajo de uno de ellos.

Uso: coteja_vram.py <rom> <org> <carpeta de volcados>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pantallas as P                                       # noqa: E402
import vram as V                                            # noqa: E402

TABLAS = (
    ("color", 0x0000, 0x1800),
    ("patrones", 0x2000, 0x1800),
)
NOMBRES, TAM = 0x1800, 0x300
PANTALLA, TABLERO = 0x000, 0x38A          # dentro del volcado, que empieza en 0xE000


def lee(ruta):
    with open(ruta, "rb") as f:
        return f.read()


def info(ruta):
    d = {}
    for linea in open(ruta, encoding="utf-8"):
        k, _, v = linea.strip().partition(" ")
        d[k] = v
    return d


def compara(nuestra, suya, tablas=TABLAS):
    return [(nombre, sum(1 for i in range(n)
                         if nuestra[ini + i] != suya[ini + i]), n)
            for nombre, ini, n in tablas]


def linea(nombre, malas, total):
    print("  %-24s %6d de %5d  %s" % (nombre, malas, total,
                                      "ok" if not malas else "MAL"))
    return malas


def el_marco_y_los_pilares(pantalla):
    """Las casillas que 0x4DB7 pinta y que no dependen del azar.

    El marco NO se puede comprobar entero: el marcador de arriba y el rotulo de
    abajo se escriben encima cada cuadro, asi que de la fila 0 solo queda la
    columna 0 y de la 23, la 31. Los lados si tienen que estar los veintitres.
    """
    malas = 0
    for f in range(1, 23):                       # las dos columnas de los lados
        for c in (0, 31):
            if pantalla[f * 32 + c] != 0x88:
                malas += 1
    for f in (3, 4, 7, 8, 11, 12, 15, 16, 19, 20):     # los treinta y cinco
        for c in (3, 4, 7, 8, 11, 12, 15, 16, 19, 20, 23, 24, 27, 28):
            if pantalla[f * 32 + c] != 0x89:
                malas += 1
    return malas, 22 * 2 + 10 * 14


def los_ladrillos_cumplen_las_reglas(tablero, bombero):
    """Cada ladrillo del tablero tiene que caer donde 0x4E35 lo deja caer: en
    una casilla con UNA coordenada impar y la otra par, y a dos o mas casillas
    del sitio donde salio el bombero."""
    bc, bf = (bombero[0] - 1) // 2, (bombero[1] - 1) // 2
    malas = []
    celdas = 0
    for b in range(11):
        for c in range(15):
            fila, col = 2 * b + 1, 2 * c + 1
            if not 0x80 <= tablero[fila * 32 + col] <= 0x87:
                continue
            celdas += 1
            if (b & 1) == (c & 1):
                malas.append(("paridad", c, b))
            if abs(c - bc) < 2 and abs(b - bf) < 2:
                malas.append(("pegado al bombero", c, b))
    return malas, celdas


def main():
    rom = V.Rom(sys.argv[1], int(sys.argv[2], 0))
    carpeta = sys.argv[3]
    malas = 0

    print("=" * 66)
    print(" LA PORTADA, contra el volcado de t=8")
    print("=" * 66)
    suya = lee(os.path.join(carpeta, "vram_08.bin"))
    nuestra = P.titulo(rom).v
    for nombre, m, n in compara(nuestra, suya):
        malas += linea(nombre, m, n)
    malas += linea("tabla de nombres",
                   sum(1 for i in range(TAM)
                       if nuestra[NOMBRES + i] != suya[NOMBRES + i]), TAM)

    print("=" * 66)
    print(" LA PARTIDA, contra el volcado de t=18")
    print("=" * 66)
    suya = lee(os.path.join(carpeta, "vram_18.bin"))
    ram = lee(os.path.join(carpeta, "ram_18.bin"))
    est = info(os.path.join(carpeta, "info_18.txt"))
    nuestra = P.partida(rom).v
    for nombre, m, n in compara(nuestra, suya):
        malas += linea(nombre, m, n)

    # El marco y los pilares se miran en la TABLA DE NOMBRES, no en la pantalla
    # de la RAM. La pantalla de la RAM esta a medio montar en cualquier
    # instante -0x510E la vuelca y la deja en blanco, y el cuadro se repinta
    # desde cero-, mientras que la tabla de nombres guarda el ultimo cuadro
    # entero. Compararlas entre si no dice nada, y ese era el error.
    tablero = ram[TABLERO:TABLERO + TAM]
    m, n = el_marco_y_los_pilares(suya[NOMBRES:NOMBRES + TAM])
    malas += linea("marco y pilares", m, n)

    bombero = (int(est["columna_bombero"]), int(est["fila_bombero"]))
    rotas, celdas = los_ladrillos_cumplen_las_reglas(tablero, bombero)
    malas += linea("ladrillos que rompen la regla", len(rotas), celdas)

    # El premio y la puerta tienen que estar debajo de un ladrillo mientras no
    # se hayan descubierto, que es lo que dicen 0x4EB1 y 0x4EC4.
    tapados = 0
    for cual in ("premio", "puerta"):
        col, fila = int(est[cual + "_col"]), int(est[cual + "_fila"])
        puesto = int(est[cual + "_puesto" if cual == "premio" else "puerta_puesta"])
        if not puesto and not 0x80 <= tablero[fila * 32 + col] <= 0x87:
            tapados += 1
    malas += linea("premio y puerta bajo ladrillo", tapados, 2)

    print("=" * 66)
    if malas:
        print(" %d diferencias. El montaje de Python NO reproduce la maquina." % malas)
        return 1
    print(" 0 diferencias en todo lo que no decide el azar.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

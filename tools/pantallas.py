#!/usr/bin/env python3
"""Monta pantallas enteras ejecutando en Python los pasos del cartucho.

No hay ni una captura de pantalla en este repositorio. Cada lamina se construye
igual que la construye el juego -cargando sus bloques de graficos en una VRAM
de mentira, con tools/vram.py, y pintando esa VRAM con la paleta del TMS9918-,
y cada funcion lleva al lado la direccion de la rutina que traduce.

Lo que sale:

    titulo.png      la pantalla de titulo, con sus diecinueve rotulos
    rotulo.png      el logotipo recortado, para la cabecera de la web
    casillas.png    las 256 casillas del primer bloque de graficos
    fuente.png      las que son letras y numeros, de la 0x20 a la 0x5D
    animacion.png   los dieciseis dibujos que reparte la tabla de 0x419B

Uso: pantallas.py <rom> <org> <carpeta de salida>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vram as V                                             # noqa: E402


def guarda(filas, fn, esc=2):
    f = V.escala(filas, esc)
    V.png(len(f[0]), len(f), f, fn)
    print("  %-24s %d x %d" % (os.path.basename(fn), len(f[0]), len(f)))


# ----------------------------------------------------------------------
# LAS PANTALLAS
# ----------------------------------------------------------------------
def titulo(rom, dibujos=None):
    """`L_4279`, que es a donde salta INIT: borra la pantalla, carga el bloque
    de graficos de 0x514C y suelta la tira de rotulos de 0x4323.

    `dibujos` es la pareja de bloques que 0x4167 va turnando desde la tabla de
    0x419B; sin ella se monta la pantalla tal como queda nada mas entrar.
    """
    v = V.Vram()
    V.borra_la_pantalla(v)                       # 0x511A
    V.carga_los_graficos(rom, v, 0x514C)         # 0x427F
    if dibujos:
        for p in dibujos:
            V.carga_los_graficos(rom, v, p)      # 0x4189 y 0x4191
    V.pinta_una_tira_de_rotulos(rom, v, 0x4323)  # 0x42C5
    V.vuelca_la_pantalla(v)                      # 0x510E
    return v


def hoja_de_casillas(v, ini, n, banda=0, cols=16, sep=1):
    """Las casillas ini..ini+n del banco que se pida, en rejilla."""
    filas = (n + cols - 1) // cols
    w, h = cols * (8 + sep) + sep, filas * (8 + sep) + sep
    lienzo = [[(0x18, 0x18, 0x20)] * w for _ in range(h)]
    for k in range(n):
        d = V.casilla(v, ini + k, banda)
        ox = sep + (k % cols) * (8 + sep)
        oy = sep + (k // cols) * (8 + sep)
        for y in range(8):
            lienzo[oy + y][ox:ox + 8] = d[y]
    return lienzo


def recorta(px, fila, col, alto, ancho):
    return [f[col * 8:(col + ancho) * 8] for f in px[fila * 8:(fila + alto) * 8]]


def hoja_de_animacion(rom, v0, cols=4, sep=2):
    """Los dieciseis dibujos que 0x4171 reparte desde la tabla de 0x419B.

    Cada uno es un bloque del mismo formato que los demas y REDEFINE unas
    casillas concretas: el destino dice en cual empieza -entre ocho, que es lo
    que ocupa una- y la cuenta cuantas son. Asi que en vez de buscarlos en la
    pantalla, que es donde no estan hasta que el juego los pone, se cargan y
    se dibujan LAS CASILLAS QUE CADA UNO DEFINE, que es lo que el bloque dice
    de si mismo.
    """
    trozos = []
    for i in range(16):
        p = rom.w(0x419B + 2 * i)
        v = V.Vram()
        V.carga_los_graficos(rom, v, 0x514C)
        V.carga_los_graficos(rom, v, p)
        primera = rom.w(p) // 8
        n = rom.b(p + 2) or 256
        ancho = min(n, 8)
        alto = (n + ancho - 1) // ancho
        t = [[(0x18, 0x18, 0x20)] * (ancho * 8) for _ in range(alto * 8)]
        for k in range(n):
            d = V.casilla(v, (primera + k) & 0xFF, 0)
            ox, oy = (k % ancho) * 8, (k // ancho) * 8
            for y in range(8):
                t[oy + y][ox:ox + 8] = d[y]
        trozos.append(t)
    alto = max(len(t) for t in trozos)
    ancho = max(len(t[0]) for t in trozos)
    filas = (len(trozos) + cols - 1) // cols
    cw, ch = ancho + sep, alto + sep
    lienzo = [[(0x18, 0x18, 0x20)] * (cols * cw + sep)
              for _ in range(filas * ch + sep)]
    for k, t in enumerate(trozos):
        ox, oy = sep + (k % cols) * cw, sep + (k // cols) * ch
        for y in range(len(t)):
            lienzo[oy + y][ox:ox + len(t[y])] = t[y]
    return lienzo


def main():
    rom = V.Rom(sys.argv[1], int(sys.argv[2], 0))
    out = sys.argv[3]
    os.makedirs(out, exist_ok=True)

    v = titulo(rom)
    px = V.pinta_pantalla(v)
    guarda(px, os.path.join(out, "titulo.png"))

    # El logotipo: las filas donde la tira de rotulos pone BOMB y las casillas
    # grandes que lo rodean, sacadas de la propia pantalla montada.
    # El rotulo: las dos filas de arriba, donde la tira de 0x4323 pone
    # BOMBER / MAN con el marcador al lado.
    guarda(recorta(px, 6, 3, 3, 27), os.path.join(out, "rotulo.png"), 3)

    guarda(hoja_de_casillas(v, 0, 256), os.path.join(out, "casillas.png"), 3)
    guarda(hoja_de_casillas(v, 0x20, 62), os.path.join(out, "fuente.png"), 3)
    guarda(hoja_de_animacion(rom, v), os.path.join(out, "animacion.png"))


if __name__ == "__main__":
    main()

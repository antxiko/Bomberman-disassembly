#!/usr/bin/env python3
"""Cuenta los ladrillos que tira una explosion, antes y despues, EN LA MAQUINA.

Del listado sale que la llama alcanza dos casillas de tablero por lado pero
solo gasta los ladrillos de la primera: las dos primeras casillas de cada tira
llaman a `pinta_una_llama_y_gasta_el_ladrillo` (0x4B21) y la tercera y la
cuarta a `pinta_una_llama_sin_gastar` (0x4B5A), que se vuelve sin escribir si
lo que hay es un ladrillo. Eso se puede leer, pero tambien se puede MEDIR, y
esto es lo segundo.

tools/omsx_alcance.tcl mete a mano dos bombas en la lista de 0xE359 y vuelca el
tablero antes y despues:

    bomba A en la casilla (4,0), con ladrillo PEGADO a la derecha y abajo
    bomba B en la casilla (13,0), con la de al lado libre y el ladrillo a DOS

Si la lectura del listado es correcta, los dos de la A caen y el de la B se
queda. Las dos casillas se eligieron leyendo el tablero de un volcado anterior;
la emulacion es determinista, asi que el reparto es el mismo.

Uso: mide_el_alcance.py <carpeta de volcados>
"""
import os
import sys

BOMBAS = {"A": (4, 0), "B": (13, 0)}
ESPERADO = {(5, 0): "cae", (4, 1): "cae", (11, 0): "sigue"}


def lee(ruta):
    with open(ruta, "rb") as f:
        return f.read()


def ladrillos(tablero):
    """Las casillas de tablero que tienen un ladrillo, en cualquiera de sus
    ocho cuadros de desmoronarse."""
    return {(c, b) for b in range(11) for c in range(15)
            if 0x80 <= tablero[(2 * b + 1) * 32 + (2 * c + 1)] <= 0x87}


def main():
    carpeta = sys.argv[1] if len(sys.argv) > 1 else "work/omsx"
    antes = ladrillos(lee(os.path.join(carpeta, "tablero_antes.bin")))
    despues = ladrillos(lee(os.path.join(carpeta, "tablero_despues.bin")))
    print("=" * 66)
    print(" El alcance de la explosion, medido en openMSX")
    print("=" * 66)
    print("  ladrillos antes  : %d" % len(antes))
    print("  ladrillos despues: %d" % len(despues))
    print("  nuevos           : %s" % sorted(despues - antes))

    malas = 0
    for nombre, (bc, bb) in sorted(BOMBAS.items()):
        for dc, db, lado in ((-1, 0, "izquierda"), (1, 0, "derecha"),
                             (0, -1, "arriba"), (0, 1, "abajo")):
            for k in (1, 2):
                c, b = bc + dc * k, bb + db * k
                if (c, b) not in antes:
                    continue
                cayo = (c, b) not in despues
                debe = ESPERADO.get((c, b))
                bien = (debe == "cae") == cayo if debe else (k == 1) == cayo
                malas += 0 if bien else 1
                print("  bomba %s: ladrillo a %d casilla%s por la %-9s "
                      "en (%2d,%2d) -> %-13s %s"
                      % (nombre, k, " " if k == 1 else "s", lado, c, b,
                         "CAE" if cayo else "SIGUE EN PIE",
                         "ok" if bien else "NO ERA ESO"))
    print("=" * 66)
    if malas:
        print(" %d resultados no cuadran con lo que dice el listado." % malas)
        return 1
    print(" La llama alcanza dos casillas y solo tira los ladrillos de la"
          " primera.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

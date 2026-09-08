#!/usr/bin/env python3
"""Rehace en Python la VRAM que monta el cartucho, paso por paso.

No hay ni una captura de pantalla en este repositorio: las imagenes salen de
ejecutar aqui las mismas operaciones que hace la ROM, en el mismo orden. Cada
funcion lleva al lado la direccion de la rutina que traduce.

LA GEOMETRIA la declaran los ocho registros de 0x5144, que 0x5062 vuelca:

    R0 = 0x02   SCREEN 2
    R1 = 0xC2   16 KB, pantalla encendida, sprites de 16x16
    R2 = 0x06   nombres            0x1800..0x1AFF
    R3 = 0x7F   color              0x0000..0x17FF  (tres bancos de 0x800)
    R4 = 0x07   patrones           0x2000..0x37FF  (tres bancos de 0x800)
    R5 = 0x38   atributos de spr   0x1C00..0x1C7F
    R6 = 0x07   patrones de spr    0x3800..0x3FFF
    R7 = 0xF0   tinta blanca sobre fondo transparente

En SCREEN 2 los registros 3 y 4 NO son una direccion sino base y mascara: el
bit 2 de R4 da la base de los patrones (0x2000) y los dos de abajo dicen que
los tres tercios son independientes; con R3 pasa lo mismo para el color, que
aqui empieza en 0x0000. Los colores DEBAJO de los patrones, o sea al reves de
lo habitual.

Y LA PANTALLA SE MONTA EN LA RAM. La tabla de nombres no se escribe casilla a
casilla: el juego lleva una copia de los 768 bytes en 0xE000 -0x511A la rellena
de espacios y 0x510E la vuelca entera con LDIRVM-, y todo lo que pinta escribe
ahi. Por eso aqui hay un `ram` de 768 bytes al lado de la VRAM.
"""
import struct
import sys
import zlib

ORG = 0x4000
TAM = 0x2000

# Los quince colores del TMS9918 mas el transparente, en RGB.
PALETA = [(0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
          (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
          (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
          (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255)]

COLORES = 0x0000
NOMBRES = 0x1800
SPR_ATRIBUTOS = 0x1C00
PATRONES = 0x2000
SPR_PATRONES = 0x3800

PANTALLA_EN_RAM = 0xE000


class Rom:
    def __init__(self, path, org=ORG):
        self.d = open(path, "rb").read()
        self.org = org

    def b(self, a):
        return self.d[a - self.org]

    def w(self, a):
        return self.d[a - self.org] | (self.d[a - self.org + 1] << 8)


class Vram:
    """Los 16 KB del VDP y, al lado, los 768 bytes de pantalla que el juego
    lleva en la RAM."""

    def __init__(self):
        self.v = bytearray(0x4000)
        self.ram = bytearray(0x300)

    def vuelca(self, a, datos):
        self.v[a:a + len(datos)] = datos

    def rellena(self, a, n, b):
        self.v[a:a + n] = bytes([b]) * n


# ----------------------------------------------------------------------
# LAS RUTINAS DEL CARTUCHO
# ----------------------------------------------------------------------
def borra_la_pantalla(v):
    """`borra_la_pantalla` (0x511A): los 768 bytes de 0xE000 a 0x20, que es la
    casilla en blanco."""
    v.ram[:] = bytes([0x20]) * 0x300


def vuelca_la_pantalla(v):
    """`vuelca_la_pantalla` (0x510E): LDIRVM de 0xE000 a la VRAM 0x1800, los
    768 bytes de la tabla de nombres de una vez."""
    v.v[NOMBRES:NOMBRES + 0x300] = v.ram


def carga_los_graficos(rom, v, p):
    """`carga_los_graficos_en_los_tres_tercios` (0x5088) y su nucleo (0x5093).

    0x5088 llama tres veces con A = 0, 8 y 0x10; ese valor se le suma al byte
    ALTO del destino, o sea 0x000, 0x800 y 0x1000: los tres tercios. El destino
    que trae el bloque es el de la tabla de COLOR, y los patrones van 0x2000
    mas arriba (el `add a,020h` de 0x509B).

    El bloque:
        2 bytes   destino en la tabla de color
        1 byte    cuantas casillas, y el CERO vale 256 (0x50A2)
        n*8       los patrones, que LDIRVM vuelca de golpe
        parejas   (color, cuantas casillas) que FILVRM pinta, cerradas por 0xFF

    Devuelve donde acaba el bloque, que es lo que permite encadenarlos y
    comprobar que teselan sin hueco.
    """
    for tercio in (0x0000, 0x0800, 0x1000):
        q = p
        dst = rom.w(q) + tercio
        q += 2
        n = rom.b(q) or 256
        q += 1
        v.v[PATRONES + dst:PATRONES + dst + n * 8] = rom.d[q - ORG:q - ORG + n * 8]
        q += n * 8
        color = dst
        while rom.b(q) != 0xFF:
            # OJO: la cuenta son BYTES de la tabla de color, no casillas. El
            # bucle de 0x50B6 se la pasa tal cual a FILVRM y luego hace
            # `add hl,bc`, y el `dec c / inc bc` de 0x50C2 convierte el cero
            # en 256. Contarlas como casillas -por ocho- desborda la tabla de
            # color por arriba y acaba pisando la de patrones.
            valor, cuantas = rom.b(q), rom.b(q + 1) or 256
            v.v[color:color + cuantas] = bytes([valor]) * cuantas
            color += cuantas
            q += 2
        q += 1
    return q


def pon_el_cursor(fila, columna):
    """`pon_el_cursor` (0x5128): fila por 32 mas la columna, sobre 0xE000."""
    return fila * 32 + columna


def pinta_una_tira_de_rotulos(rom, v, p):
    """`pinta_una_tira_de_rotulos` (0x4314): por cada rotulo la fila y la
    columna y luego el texto cerrado por 0x00; la tira acaba en 0xFF.
    Escribe en la pantalla de la RAM, no en la VRAM."""
    puestos = []
    while rom.b(p) != 0xFF:
        fila, columna = rom.b(p), rom.b(p + 1)
        p += 2
        d = pon_el_cursor(fila, columna)
        texto = []
        while rom.b(p):
            v.ram[d] = rom.b(p)
            texto.append(rom.b(p))
            d += 1
            p += 1
        p += 1
        puestos.append((fila, columna, bytes(texto)))
    return p + 1, puestos


# ----------------------------------------------------------------------
# PINTAR
# ----------------------------------------------------------------------
def casilla(v, n, banda):
    """Los 8x8 pixeles de la casilla n en el tercio que se pida."""
    pat = PATRONES + banda * 0x800 + n * 8
    col = COLORES + banda * 0x800 + n * 8
    out = []
    for f in range(8):
        forma, c = v.v[pat + f], v.v[col + f]
        tinta, papel = PALETA[c >> 4], PALETA[c & 0x0F]
        out.append([tinta if forma & (0x80 >> b) else papel for b in range(8)])
    return out


def pinta_pantalla(v, fondo=None):
    """Los 256x192 pixeles: 24 filas de 32 casillas, cada tercio con su banco.

    R7 vale 0xF0, o sea tinta blanca y fondo TRANSPARENTE; con el color 0 el
    VDP saca el del borde, que aqui es el negro.
    """
    if fondo is None:
        fondo = PALETA[1]
    px = [[fondo] * 256 for _ in range(192)]
    for f in range(24):
        for c in range(32):
            d = casilla(v, v.v[NOMBRES + f * 32 + c], f // 8)
            for y in range(8):
                for x in range(8):
                    col = d[y][x]
                    px[f * 8 + y][c * 8 + x] = fondo if col == PALETA[0] else col
    return px


def sprite(v, patron, color):
    """Los 16x16 de un patron de sprite: 32 bytes, los dieciseis primeros la
    mitad IZQUIERDA y los dieciseis siguientes la DERECHA. R1 los declara de
    16x16 sin ampliar."""
    base = SPR_PATRONES + (patron & 0xFC) * 8
    px = [[None] * 16 for _ in range(16)]
    for mitad in range(2):
        for f in range(16):
            fila = v.v[base + mitad * 16 + f]
            for b in range(8):
                if fila & (0x80 >> b):
                    px[f][mitad * 8 + b] = PALETA[color & 0x0F]
    return px


# ----------------------------------------------------------------------
# PNG
# ----------------------------------------------------------------------
def png(w, h, filas, fn):
    raw = b"".join(b"\0" + bytes(b for px in fila for b in px) for fila in filas)

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
    with open(fn, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def escala(filas, n):
    return [[px for px in fila for _ in range(n)] for fila in filas
            for _ in range(n)]


if __name__ == "__main__":
    r = Rom(sys.argv[1] if len(sys.argv) > 1 else "bomberman.rom")
    v = Vram()
    fin = carga_los_graficos(r, v, 0x514C)
    print("el primer bloque de graficos acaba en 0x%04X" % fin)

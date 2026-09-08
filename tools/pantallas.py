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
import random
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
    """`la_portada` (0x4279) y su bucle (0x4290), enteros.

    No basta con cargar los graficos y soltar la tira de rotulos: el bucle
    repinta la portada de arriba abajo cada cuadro, y lo que se ve son SEIS
    cosas, en este orden. Dejarse las cuatro ultimas es lo que hacia que la
    lamina publicada saliera sin el rotulo grande ni la fila de muestra.

    `dibujos` es la pareja de bloques que 0x4167 va turnando desde la tabla de
    0x419B; sin ella se monta la pantalla tal como queda nada mas entrar.
    """
    v = V.Vram()
    V.borra_la_pantalla(v)                       # 0x4279
    V.carga_los_graficos(rom, v, 0x514C)         # 0x427F
    if dibujos:
        for p in dibujos:
            V.carga_los_graficos(rom, v, p)      # 0x4189 y 0x4191
    for i in range(0xC0):                        # 0x42A4: seis filas de
        v.ram[i] = 0x89                          #   ladrillo
    p = 0x446E                                   # 0x42AD: el rotulo GRANDE,
    while rom.b(p) != 0xFF:                      #   nueve ternas
        casilla, fila, col = rom.b(p), rom.b(p + 1), rom.b(p + 2)
        V.pinta_cuatro_casillas(v.ram, V.pon_el_cursor(fila, col), casilla)
        p += 3
    V.pinta_una_tira_de_rotulos(rom, v, 0x4323)  # 0x42C5: los diecinueve
    for d in (0x216, 0x256):                     # 0x42CB y 0x42D4: el record y
        for k in range(6):                       #   el marcador, seis ceros
            v.ram[d + k] = 0                     #   mientras nadie haya jugado
    V.pinta_cuatro_casillas(v.ram, 0x0E1, 0x8C)  # 0x42DD: el bombero
    # 0x42E5 y 0x42E8: la bomba y el enemigo de muestra, que no van en ninguna
    # tira sino en las listas, puestos a mano por 0x4442 y 0x4456. La bomba en
    # la fila 10 columna 14 y el enemigo en la fila 7 columna 10.
    #
    # Y LA BOMBA SALE EN EL ULTIMO CUADRO DE LA MECHA, no en el primero. 0x4442
    # la pone en el estado 1, pero al pintarla 0x4A6D mira lo que hay debajo EN
    # EL TABLERO, y al entrar en la portada el tablero no se ha borrado: son
    # bytes de la RAM sin estrenar. En el volcado de openMSX valen 0xFF, o sea
    # mas de 0xE0, que es lo que 0x4A6D toma por una llama, asi que le mete el
    # estado 4 y la cuenta 6 -la ficha volcada dice exactamente 04 0E 0A 06- y
    # ahi se queda, porque en la portada nadie llama a `avanzan_las_bombas`.
    # El `parpadeo` es el que tenia la maquina en el cuadro del volcado.
    parpadeo = 2
    V.pinta_cuatro_casillas(v.ram, V.pon_el_cursor(0x0A, 0x0E),
                            0x60 + 3 * 4 + parpadeo)
    V.pinta_cuatro_casillas(v.ram, V.pon_el_cursor(0x07, 0x0A),
                            0xC0 + 1 * 4 + parpadeo)
    V.pinta_cuatro_casillas(v.ram, 0x0F1, 0x0A)  # 0x4301: el premio
    V.pinta_cuatro_casillas(v.ram, 0x0F9, 0x0E)  # 0x4309: y la puerta
    V.vuelca_la_pantalla(v)                      # 0x510E
    return v


# ----------------------------------------------------------------------
# UNA PARTIDA, REPARTIDA POR EL PROPIO CARTUCHO
# ----------------------------------------------------------------------
class AzarDelCartucho:
    """`numero_al_azar` (0x4EF9), instruccion por instruccion.

    El cartucho realimenta (0xE384) con dieciseis bits y ADEMAS le mezcla el
    registro R, o sea el contador de refresco de la memoria del Z80. Y esa
    mezcla no es un adorno: es de donde sale casi todo el azar. Si R avanzara
    siempre lo mismo entre dos sorteos -que es lo que hace `paso`- la serie se
    cierra en TRES a CINCO casillas y se repite; lo comprueba el test
    `test_el_azar_del_cartucho_se_apoya_en_el_registro_r`.

    En la maquina R no avanza igual, porque entre dos sorteos se ejecutan mas
    o menos instrucciones segun cuantas veces haya habido que repetir el
    sorteo. Por eso el reparto de una fase NO se puede reproducir desde fuera,
    y por eso la lamina de la partida usa `RepartoCualquiera`.
    """

    def __init__(self, semilla=0xFFFF, paso=1, r=0):
        self.hl = semilla                   # el valor de arranque de 0x505C
        self.paso = paso
        self.r = r

    def __call__(self):
        h, l = self.hl >> 8, self.hl & 0xFF
        a = h
        for _ in range(2):                  # rla, rla: el acarreo entra a cero
            a = (a << 1) & 0xFF
        a ^= l                              # xor l, que ademas borra el acarreo
        c = a & 1                           # rra: el bit de abajo se guarda
        h ^= l                              # ld a,h / xor l / ld h,a
        self.r = (self.r + self.paso) & 0x7F
        l ^= self.r                         # ld a,r / xor l / ld l,a
        l = (l << 1) | c                    # rl l
        c, l = l >> 8, l & 0xFF             # el acarreo pasa a H
        h = ((h << 1) | c) & 0xFF           # rl h
        self.hl = (h << 8) | l
        return l                            # se devuelve el byte de abajo


class RepartoCualquiera:
    """Un azar de fuera, para poder repartir UNA fase concreta y dibujarla.

    Lo que se mira en la lamina no es que salga tal reparto -eso lo decide el
    registro R de la maquina cuando se pulsa el disparo- sino que el reparto
    CUMPLA las tres reglas de 0x4E35 y que todo lo demas se pinte como lo
    pinta el cartucho. Las reglas las aplica `siembra_la_fase`, que es una
    traduccion del listado; de aqui solo salen los numeros.
    """

    def __init__(self, semilla=1983):
        self.r = random.Random(semilla)

    def __call__(self):
        return self.r.randrange(256)


def una_casilla_al_azar(azar):
    """`una_casilla_al_azar` (0x4E15): columna de 0 a 14 y fila de 0 a 10,
    sorteando otra vez lo que se salga. Quince por once es el tablero."""
    c = azar() & 0x1F
    while c >= 0x0F:
        c = azar() & 0x1F
    f = azar() & 0x1F
    while f >= 0x0B:
        f = azar() & 0x1F
    return c, f


def siembra_la_fase(rom, v, azar):
    """`siembra_la_fase` (0x4E35): el sitio del bombero y los treinta y cinco
    ladrillos, con el premio debajo del primero y la puerta debajo del ultimo.

    Devuelve (columna, fila) del bombero, del premio y de la puerta, todas ya
    en casillas de pantalla.
    """
    while True:                                     # 0x4E35: el bombero
        c, f = una_casilla_al_azar(azar)
        if not 2 <= c <= 12 or not 2 <= f <= 8:
            continue
        bc, bf = 2 * c + 1, 2 * f + 1               # 0x4E2A
        if v.ram[V.pon_el_cursor(bf, bc)] == 0x20:  # 0x4E57: nada de pilares
            break
    refc, reff = c, f                               # (0xE37C) y (0xE37D)
    prohibidas = []
    p = 0x4EDF
    while rom.b(p) != 0xFF:
        prohibidas.append((rom.b(p), rom.b(p + 1)))
        p += 2
    premio = puerta = None
    for _ in range(0x23):                           # 0x4E65: treinta y cinco
        while True:
            c, f = una_casilla_al_azar(azar)
            if abs(refc - c) < 2 and abs(reff - f) < 2:
                continue                            # 0x4E6D: pegado al bombero
            if (c & 1) == (f & 1):
                continue                            # 0x4E87: una impar y una par
            fila, col = 2 * f + 1, 2 * c + 1        # 0x4E98
            if (fila, col) in prohibidas:
                continue                            # 0x4E9E: las ocho esquinas
            break
        if premio is None:
            premio = (col, fila)                    # 0x4EB1: solo el primero
        puerta = (col, fila)                        # 0x4EC4: siempre, gana el ultimo
        V.pinta_cuatro_casillas_iguales(v.tab, V.pon_el_cursor(fila, col), 0x80)
    return (bc, bf), premio, puerta


def reparte_los_enemigos(rom, azar, cuantos):
    """`reparte_los_enemigos_de_la_fase` (0x459D): una de las cuatro esquinas
    de 0x45C6 por enemigo, al azar y sin mirar si ya esta ocupada."""
    fichas = []
    for _ in range(cuantos):
        k = azar() & 3
        fichas.append((rom.b(0x45C6 + 2 * k), rom.b(0x45C6 + 2 * k + 1)))
    return fichas


def marcador(rom, v, marca, bonus, fase, vidas):
    """`pinta_el_marcador` (0x4CE5) y `pinta_las_vidas` (0x4E00): la fila 0
    entera y la esquina de abajo a la derecha, encima del muro que acaba de
    pintar 0x4DB7."""
    def cifras(d, n):                               # 0x4F29: cinco y un cero
        for k in (10000, 1000, 100, 10):
            v.ram[d] = n // k % 10
            d += 1
        v.ram[d] = n % 10
        v.ram[d + 1] = 0                            # el cero de propina
        return d + 2
    V.suelta_un_texto(rom, v.ram, 0x001, 0x4D87)    # "SCORE:"
    V.suelta_un_texto(rom, v.ram, 0x00D, 0x4D8E)    # " BONUS:"
    V.suelta_un_texto(rom, v.ram, 0x019, 0x4D96)    # " STG:"
    if fase < 10:                                   # 0x4F19
        v.ram[0x01E] = fase
    else:
        v.ram[0x01E], v.ram[0x01F] = fase // 10, fase % 10
    cifras(0x007, marca)
    v.ram[cifras(0x014, bonus) - 1] = 0x20          # 0x4D2A: sin el cero de mas
    # OJO AL ORDEN, que es el del bucle principal: primero las vidas (0x40FF) y
    # DESPUES la firma (0x4102). La firma ocupa de la columna 1 a la 26 y el
    # rotulo de las vidas empieza justo en la 26, asi que el 3 de 1983 se come
    # el primer espacio del rotulo. Pintandolo al reves se pierde el 3.
    d = V.suelta_un_texto(rom, v.ram,               # 0x4E00: el rotulo de
                          V.pon_el_cursor(rom.b(0x4E0C), rom.b(0x4E0D)), 0x4E0E)
    v.ram[d - 1] = vidas                            # 0x4E07: las vidas, al hueco
    V.suelta_un_texto(rom, v.ram, 0x2E1, 0x4D9C)    # la firma de la fila 23


def partida(rom, semilla=1983, fase=3, marca=1240, bonus=740, vidas=3):
    """Una partida en marcha, montada con las rutinas del propio cartucho y en
    el orden del bucle principal de 0x40CC.

    No hay captura de pantalla que valga: la fase se REPARTE aqui, con el mismo
    sorteo de 0x4E35 y el mismo azar de 0x4EF9, y luego se pinta lo mismo que
    pinta el juego y en el mismo orden, que es lo que decide que tapa a que.
    """
    azar = RepartoCualquiera(semilla)
    v = V.Vram()
    V.borra_la_pantalla(v)                          # 0x40B6
    V.carga_los_graficos(rom, v, 0x514C)            # lo que dejo la portada
    V.carga_los_graficos(rom, v, 0x5B26)            # 0x4074: SCOREBONUS
    V.carga_los_graficos(rom, v, 0x5B7C)            # 0x407A: la partida
    V.borra_el_tablero(v)                           # 0x40BC
    V.pinta_el_tablero(v)                           # 0x40BF: marco y pilares
    (bc, bf), premio, puerta = siembra_la_fase(rom, v, azar)      # 0x40C2
    cuantos = rom.b(0x4217 + 2 * (min(fase, 5) - 1))             # 0x41FB
    enemigos = reparte_los_enemigos(rom, azar, cuantos)           # 0x40B0
    # La partida ya lleva un rato: los dos ladrillos que tapaban el premio y la
    # puerta ya han reventado, que es la unica forma de que se vean. Es lo que
    # comprueban 0x45CE y 0x465A antes de encenderlos.
    for col, fila in (premio, puerta):
        V.pinta_cuatro_casillas_iguales(v.tab, V.pon_el_cursor(fila, col), 0x20)

    # Y ahora DOS cuadros del bucle principal, en su orden exacto. Dos porque
    # las llamas se escriben en el TABLERO, no en la pantalla, y no se ven
    # hasta que el cuadro siguiente lo copia encima: es literalmente asi de
    # tarde como aparecen en la maquina.
    for _ in range(2):
        V.copia_el_tablero_a_la_pantalla(v)         # 0x40CF
        V.pinta_el_tablero(v)                       # 0x40D2
        for col, fila, estado in BOMBAS:            # 0x40D8
            pinta_una_bomba(rom, v, col, fila, estado)
        V.pinta_cuatro_casillas(v.ram, V.pon_el_cursor(premio[1], premio[0]),
                                0x0A)               # 0x40E4
        V.pinta_cuatro_casillas(v.ram, V.pon_el_cursor(puerta[1], puerta[0]),
                                0x0E)               # 0x40E7
        for k, (col, fila) in enumerate(enemigos):  # 0x40EA
            V.pinta_cuatro_casillas(v.ram, V.pon_el_cursor(fila, col),
                                    0xC0 + (k & 3) * 4)
        V.pinta_cuatro_casillas(v.ram, V.pon_el_cursor(bf, bc), 0xA4)     # 0x40F3
        marcador(rom, v, marca, bonus, fase, vidas)  # 0x40FF y 0x4102
    V.vuelca_la_pantalla(v)                         # 0x510E
    return v


def con_signo(b):
    return b - 256 if b > 127 else b


def pinta_una_bomba(rom, v, col, fila, estado):
    """`pinta_las_bombas_y_las_llamas` (0x4A08) para una ficha.

    Del 1 al 4 es la mecha, que se pinta en el tablero Y en la pantalla; del 5
    al 12, la explosion, que solo va al tablero. Los brazos salen de la tabla
    de 0x4F8D recorrida como la recorre 0x4AAC: ocho tiras de cuatro casillas,
    y en cuanto una da con algo que estorba se salta lo que queda de tira.
    """
    d = V.pon_el_cursor(fila, col)
    if estado < 5:                                  # 0x4A24: la mecha
        V.pinta_cuatro_casillas(v.tab, d, 0x60 + (estado - 1) * 4)
        V.pinta_cuatro_casillas(v.ram, d, 0x60 + (estado - 1) * 4)
        return
    centro = estado * 2 + 0xD6                      # 0x4A1C
    brazo = centro + 2 if centro + 2 < 0xF0 else 0x20   # 0x4A9E
    V.pinta_cuatro_casillas(v.tab, d, centro)       # 0x4A98, sin preguntar
    p = 0x4F8D
    while rom.b(p) != 0x80:                         # 0x4AB0: el cierre
        for k in range(4):
            f = fila + con_signo(rom.b(p))
            c = col + con_signo(rom.b(p + 1))
            p += 2
            e = V.pon_el_cursor(f, c)
            pantalla, tablero = v.ram[e], v.tab[e]
            if pantalla in (0x88, 0x89):            # el muro y el pilar solo
                visto = pantalla                    #   estan en la pantalla
            elif 0x80 <= tablero <= 0x89:           # un ladrillo
                if k < 2:                           # 0x4B21 lo gasta...
                    v.tab[e] = 0x20 if tablero + 1 == 0x88 else tablero + 1
                visto = tablero                     # ...y 0x4B5A ni lo toca
            else:
                v.tab[e] = brazo
                visto = tablero
            # Y cada casilla de la tira se para con una cosa distinta: la
            # primera solo con el muro -el `cp 089h` del pilar esta ahi pero
            # nadie lo ejecuta-, la segunda con cualquier ladrillo, y la
            # tercera y la cuarta con lo que haya en la PANTALLA.
            para = (visto == 0x88) if k == 0 else (
                0x80 <= (visto if k == 1 else pantalla) <= 0x89)
            if para:
                p += 2 * (3 - k)
                break


# Tres bombas puestas a mano para que la lamina ensene las tres cosas que
# hacen: una recien puesta, otra con la mecha acabandose y una tercera ya
# reventando. Son (columna, fila, estado) de la ficha de 0xE359.
BOMBAS = ((13, 11, 1), (21, 15, 4), (5, 7, 6))


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


def hoja_de_animacion(rom, v0, cols=8, sep=2):
    """LOS OCHO PREMIOS que 0x4167 va turnando desde la tabla de 0x419B.

    Cada una de las dieciseis palabras de la tabla apunta a un bloque de dos
    casillas, y los destinos lo dicen todo: las pares van a 0x0050 -o sea la
    casilla 0x0A- y las impares a 0x00D0 -la 0x1A-. Esas cuatro casillas son
    justo las que pinta `pinta_el_premio` (0x45F6). Asi que lo que cambia cada
    cuatro fases NO es el bicho: es el PREMIO que hay debajo de un ladrillo.

    0x4167 carga una PAREJA de palabras consecutivas, o sea una mitad de
    arriba y una de abajo, y por eso los dieciseis bloques son ocho premios
    enteros. Aqui se montan igual: se carga la pareja sobre la hoja de la
    partida y se dibujan las cuatro casillas resultantes.
    """
    premios = []
    for k in range(8):
        v = V.Vram()
        for p in (0x514C, 0x5B26, 0x5B7C):
            V.carga_los_graficos(rom, v, p)
        for j in (0, 1):                        # 0x4183 y 0x418D: la pareja
            V.carga_los_graficos(rom, v, rom.w(0x419B + 4 * k + 2 * j))
        premios.append(v)
    ancho, alto = 16, 16
    filas = (len(premios) + cols - 1) // cols
    cw, ch = ancho + sep, alto + sep
    lienzo = [[(0x18, 0x18, 0x20)] * (cols * cw + sep)
              for _ in range(filas * ch + sep)]
    for k, v in enumerate(premios):
        ox, oy = sep + (k % cols) * cw, sep + (k // cols) * ch
        for dy, dx, t in ((0, 0, 0x0A), (0, 1, 0x0B), (1, 0, 0x1A), (1, 1, 0x1B)):
            d = V.casilla(v, t, 0)
            for y in range(8):
                lienzo[oy + dy * 8 + y][ox + dx * 8:ox + dx * 8 + 8] = d[y]
    return lienzo


def hoja_de_bloques(v, casillas, cols=8, sep=2, banda=0):
    """Una fila de dibujos de DOS POR DOS, que es como esta hecho todo lo que
    se mueve.

    Y hay DOS formas de hacer uno, que no se pueden confundir:

      `pinta_cuatro_casillas` (0x4B7B) pinta n, n+1, n+0x10 y n+0x11, o sea
      cuatro casillas consecutivas de la hoja. Asi se pintan el bombero, el
      bicho, la bomba, la llama, el premio y la puerta.

      `pinta_cuatro_casillas_iguales` (0x4B8C) pinta la MISMA cuatro veces.
      Asi se pintan el ladrillo, el muro y el pilar, que son un patron que
      tesela consigo mismo.

    Dibujar un ladrillo como si fuera lo primero saca al lado suyo la casilla
    siguiente de la hoja, que es otra cosa: en el muro salian las letras H, D,
    F, A, M e I. Por eso cada entrada dice cual de las dos es, con un
    `(casilla, repetida)`.
    """
    entradas = [c if isinstance(c, tuple) else (c, False) for c in casillas]
    filas = (len(entradas) + cols - 1) // cols
    w, h = cols * (16 + sep) + sep, filas * (16 + sep) + sep
    lienzo = [[(0x18, 0x18, 0x20)] * w for _ in range(h)]
    for k, (base, repetida) in enumerate(entradas):
        ox, oy = sep + (k % cols) * (16 + sep), sep + (k // cols) * (16 + sep)
        cuatro = ((0, 0, base), (0, 1, base), (1, 0, base), (1, 1, base)) \
            if repetida else \
            ((0, 0, base), (0, 1, base + 1),
             (1, 0, base + 0x10), (1, 1, base + 0x11))
        for dy, dx, t in cuatro:
            d = V.casilla(v, t & 0xFF, banda)
            for y in range(8):
                lienzo[oy + dy * 8 + y][ox + dx * 8:ox + dx * 8 + 8] = d[y]
    return lienzo


def main():
    rom = V.Rom(sys.argv[1], int(sys.argv[2], 0))
    out = sys.argv[3]
    os.makedirs(out, exist_ok=True)

    v = titulo(rom)
    px = V.pinta_pantalla(v)
    guarda(px, os.path.join(out, "titulo.png"))

    # El logotipo de verdad: el rotulo GRANDE de la fila 2, el que 0x42AD monta
    # con las nueve ternas de 0x446E. Ocupa las filas 2 y 3 y de la columna 2 a
    # la 30, y se recorta de la propia pantalla ya montada.
    guarda(recorta(px, 2, 2, 2, 28), os.path.join(out, "rotulo.png"), 3)

    guarda(hoja_de_casillas(v, 0, 256), os.path.join(out, "casillas.png"), 3)
    guarda(hoja_de_casillas(v, 0x20, 62), os.path.join(out, "fuente.png"), 3)
    guarda(hoja_de_animacion(rom, v), os.path.join(out, "premios.png"), 4)

    p = partida(rom)
    guarda(V.pinta_pantalla(p), os.path.join(out, "partida.png"))
    guarda(hoja_de_casillas(p, 0, 256), os.path.join(out, "casillas_partida.png"), 3)

    # Los cuatro dibujos que mueve el juego, cada uno con sus cuadros. Las
    # cuentas salen del listado: 0x4B99 para el bombero, 0x4835 y 0x48DB para
    # el enemigo, 0x4A24 y 0x4A8C para la bomba.
    guarda(hoja_de_bloques(p, [0x8A, 0x8C] + [0xA0 + 4 * s + b
                               for s in range(4) for b in (0, 2)]),
           os.path.join(out, "bombero.png"), 4)
    guarda(hoja_de_bloques(p, [0x4E - 2 * k for k in range(8)]),
           os.path.join(out, "agonia.png"), 4)
    guarda(hoja_de_bloques(p, [0xC0 + 4 * f + b for f in range(4) for b in (0, 2)]),
           os.path.join(out, "enemigos.png"), 4)
    guarda(hoja_de_bloques(p, [0x22 + 2 * k for k in range(7)]),
           os.path.join(out, "enemigo_revienta.png"), 4)
    guarda(hoja_de_bloques(p, [0x60 + 4 * e + b for e in range(4) for b in (0, 2)]),
           os.path.join(out, "bombas.png"), 4)
    guarda(hoja_de_bloques(p, [2 * e + 0xD6 for e in range(5, 13)]),
           os.path.join(out, "llamas.png"), 4)
    # OJO: el ladrillo, el muro y el pilar los pinta 0x4B8C repitiendo la
    # MISMA casilla cuatro veces; el premio y la puerta, 0x4B7B con cuatro
    # consecutivas. Por eso van marcados.
    guarda(hoja_de_bloques(p, [(0x80 + k, True) for k in range(8)]
                              + [(0x88, True), (0x89, True), 0x0A, 0x0E],
                           cols=12),
           os.path.join(out, "casillas_del_tablero.png"), 4)


if __name__ == "__main__":
    main()

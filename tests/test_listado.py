#!/usr/bin/env python3
"""Comprobaciones sobre el listado de Bomber Man, y sobre lo que afirma.

Ninguna necesita el cartucho. Las que miran bytes los sacan de los `defb` del
propio listado, que es lo mismo que hay en la ROM: eso lo garantiza
`make verify`, que reensambla y compara el sha256.

La idea es que ninguna afirmacion de las notas o de la web se quede sin algo
que la sujete. Si el listado cambia y deja de ser verdad, esto se pone rojo.
"""
import os
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "bomberman.asm")
NOTES = os.path.join(RAIZ, "src", "bomberman.notes")
ENTRIES = os.path.join(RAIZ, "src", "bomberman.entries")
NOCODE = os.path.join(RAIZ, "src", "bomberman.nocode")
DOCS = os.path.join(RAIZ, "docs")
ORG, FIN = 0x4000, 0x6000

# La direccion que mkasm pega a cada instruccion y a cada fila de datos: un
# `;`, cuatro cifras hexadecimales y detras un espacio o el final de la linea.
# Las dos cosas importan: exigir el espacio de detras, y buscarla SOLO en las
# lineas que empiezan por tabulador. Sin lo segundo, la primera palabra de un
# comentario de bloque que empiece por letras que ademas son cifras se cuela
# como direccion -"cada" vale 0xCADA- y el test se pone rojo por una prosa
# perfectamente correcta. Como la direccion va siempre delante del comentario,
# en una linea de instruccion gana ella, que es la que esta mas a la izquierda.
DIRECCION = re.compile(r"; ?([0-9a-f]{4})(?:\s|$)")

# Los demas juegos de la serie. Que el nombre de otro salga en una pagina de
# este es casi siempre un copia y pega: ya paso con cinco ficheros LICENSE, con
# el pie de catorce paginas de otro proyecto y con los tests de Hyper Sports 3,
# que llegaron copiados de otro cartucho y apuntaban a su listado.
OTROS_JUEGOS = (
    "Tennis", "Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
    "Antarctic", "Athletic Land", "Monkey Academy", "F-1 Spirit", "Pippols",
    "Time Pilot", "Frogger", "Super Cobra", "Billiards", "Mahjong",
    "Hyper Rally", "Nemesis", "Demonia", "Cabbage", "Hole in One",
    "Casio World Open", "3D Golf", "Baseball", "Yie Ar Kung-Fu", "Boxing",
    "Kings Valley", "Sky Jaguar", "Mopi Ranger", "Descubrimiento",
    "War in Middle Earth", "Ping Pong", "Soccer", "Football", "Road Fighter",
    "Hyper Sports", "Hyper Olympic", "Goonies", "Knightmare", "Trailblazer",
    "Game Master",
)


def lee(ruta):
    with open(ruta, encoding="utf-8") as f:
        return f.read()


def lineas_del_asm():
    return lee(ASM).splitlines()


def bytes_de_los_defb():
    """Reconstruye los bloques de datos leyendo los `defb` del listado."""
    fuera = {}
    for ln in lineas_del_asm():
        m = re.match(r"^\tdef[bw] (.*?)\t*; ?([0-9a-f]{4})", ln)
        if not m:
            continue
        dire = int(m.group(2), 16)
        vals = []
        for tr in m.group(1).split(","):
            tr = tr.strip()
            if not tr:
                continue
            v = int(tr[:-1], 16) if tr.endswith("h") else int(tr, 0)
            if ln.lstrip().startswith("defw"):
                vals += [v & 0xFF, v >> 8]
            else:
                vals.append(v & 0xFF)
        for i, v in enumerate(vals):
            fuera[dire + i] = v
    return fuera


DATOS = bytes_de_los_defb()


def trozo(dire, n):
    fuera = []
    for k in range(n):
        if dire + k not in DATOS:
            raise AssertionError("0x%04X no esta en los datos del listado"
                                 % (dire + k))
        fuera.append(DATOS[dire + k])
    return fuera


def instruccion(dire):
    """La instruccion que el listado pone en una direccion, sin comentario."""
    for ln in lineas_del_asm():
        m = re.match(r"^\t([a-z].*?)\t+;%04x\b" % dire, ln)
        if m:
            return " ".join(m.group(1).split())
    raise AssertionError("0x%04X no es una instruccion del listado" % dire)


def texto(bs):
    """Los rotulos van en ASCII salvo las casillas del marco, que son codigos
    por debajo de 0x20 y aqui salen como un punto."""
    return "".join(chr(b) if 0x20 <= b < 0x7F else "." for b in bs)


class TestListado(unittest.TestCase):

    def test_el_encabezado_dice_de_que_cartucho_es(self):
        cab = "\n".join(lineas_del_asm()[:6])
        self.assertIn("BOMBER MAN", cab)
        self.assertIn("Hudson Soft", cab)

    def test_todas_las_instrucciones_llevan_su_direccion(self):
        malas = [ln for ln in lineas_del_asm()
                 if ln.startswith("\t") and not ln.lstrip().startswith(";")
                 and not DIRECCION.search(ln)
                 and "org" not in ln]
        self.assertEqual(malas, [], "lineas sin direccion: %s" % malas[:3])

    def test_las_direcciones_van_en_orden_y_dentro_del_cartucho(self):
        ant = ORG - 1
        for ln in lineas_del_asm():
            if not ln.startswith("\t"):
                continue
            m = DIRECCION.search(ln)
            if not m:
                continue
            a = int(m.group(1), 16)
            self.assertTrue(ORG <= a < FIN, "0x%04X se sale del cartucho" % a)
            self.assertGreater(a, ant, "0x%04X va detras de 0x%04X" % (a, ant))
            ant = a


class TestLaCabeceraEsCodigo(unittest.TestCase):
    """El hallazgo que separa a este cartucho de los demas de la serie."""

    def test_la_cabecera_declara_init_en_0x4004(self):
        b = trozo(0x4000, 4)
        self.assertEqual(b[:2], [0x41, 0x42], 'no empieza por "AB"')
        self.assertEqual(b[2] | (b[3] << 8), 0x4004)

    def test_init_cae_dentro_de_la_propia_cabecera(self):
        """0x4004 es donde el formato del MSX pone STATEMENT; o sea que ese
        campo y los dos siguientes ya son instrucciones."""
        self.assertLess(0x4004, 0x4010, "INIT ya no cae dentro de la cabecera")
        self.assertEqual(instruccion(0x4004), "ld sp,0f000h")
        for a, destino in ((0x4007, "pon_los_valores_de_partida"),
                           (0x400a, "monta_el_vdp"),
                           (0x400d, "vuelca_la_tabla_del_psg")):
            self.assertEqual(instruccion(a), "call %s" % destino)

    def test_solo_cuatro_bytes_son_cabecera_de_verdad(self):
        d = [ln for ln in lee(NOTES).splitlines()
             if ln.startswith("D 0x4000 ")]
        self.assertEqual(len(d), 1)
        self.assertTrue(d[0].startswith("D 0x4000 0x4004 "),
                        "la cabecera declarada ya no son cuatro bytes: %s" % d[0])


class TestLasTablasDelPsg(unittest.TestCase):
    """Las tres que van incrustadas detras de un `call 0x404E`."""

    TABLAS = ((0x4010, 0x4019), (0x4138, 0x4149), (0x49F3, 0x4A06))

    def test_las_tres_cierran_en_0xff_y_solo_al_final(self):
        for ini, fin in self.TABLAS:
            b = trozo(ini, fin - ini)
            self.assertEqual(b[-1], 0xFF,
                             "la tabla de 0x%04X no acaba en 0xFF" % ini)
            self.assertNotIn(0xFF, b[:-1],
                             "la tabla de 0x%04X tiene un 0xFF antes de tiempo"
                             % ini)
            self.assertEqual((fin - ini - 1) % 2, 0,
                             "la tabla de 0x%04X no son parejas" % ini)

    def test_los_registros_del_psg_existen(self):
        """El PSG tiene dieciseis registros; un byte de registro por encima de
        15 querria decir que el formato esta mal leido."""
        for ini, fin in self.TABLAS:
            b = trozo(ini, fin - ini)
            for k in range(0, len(b) - 1, 2):
                self.assertLess(b[k], 16,
                                "0x%04X pide el registro %d del PSG"
                                % (ini + k, b[k]))

    def test_la_del_arranque_apaga_el_sonido(self):
        """Registro 7 -el mezclador- y los tres volumenes a cero."""
        b = trozo(0x4010, 9)
        self.assertEqual(b, [0x07, 0xA8, 0x08, 0x00, 0x09, 0x00,
                             0x0A, 0x00, 0xFF])

    def test_las_tres_estan_declaradas_como_datos(self):
        """Si no lo estuvieran, el trazador las leeria como instrucciones."""
        t = lee(NOCODE)
        for ini, fin in self.TABLAS:
            self.assertIn("0x%04X 0x%04X" % (ini, fin), t,
                          "la tabla de 0x%04X no esta en el .nocode" % ini)

    def test_las_tres_continuaciones_son_puntos_de_entrada(self):
        t = lee(ENTRIES)
        for _, fin in self.TABLAS:
            self.assertRegex(t, r"0x%04X\b" % fin)


class TestLosRotulos(unittest.TestCase):
    """La tira de 0x4323: (fila, columna, texto cerrado por 0x00)."""

    def recorre(self):
        p, salida = 0x4323, []
        while trozo(p, 1)[0] != 0xFF:
            fila, col = trozo(p, 2)
            p += 2
            t = []
            while trozo(p, 1)[0] != 0x00:
                t.append(trozo(p, 1)[0])
                p += 1
            p += 1
            salida.append((fila, col, texto(t)))
        return salida, p + 1

    def test_la_tira_acaba_clavada_donde_dicen_las_notas(self):
        rotulos, fin = self.recorre()
        self.assertEqual(fin, 0x4442,
                         "la tira acaba en 0x%04X y no en 0x4442" % fin)
        self.assertEqual(len(rotulos), 19)

    def test_los_rotulos_dicen_lo_que_se_publica(self):
        dicen = [t for _, _, t in self.recorre()[0]]
        for esperado in ("UP", "HUDSON", "BOMB", "SOFT", "LEFT", "RIGHT",
                         "SPACE"):
            self.assertTrue(any(esperado in t for t in dicen),
                            "ningun rotulo dice %s" % esperado)

    def test_ninguno_se_sale_de_la_pantalla(self):
        """SCREEN 2 son 24 filas de 32 columnas."""
        for fila, col, t in self.recorre()[0]:
            self.assertLess(fila, 24, "la fila %d no existe" % fila)
            self.assertLess(col + len(t), 33,
                            "el rotulo %r se sale por la derecha" % t)


class TestLosGraficos(unittest.TestCase):
    """Los tres bloques que carga 0x5088 en los tres tercios de SCREEN 2."""

    def recorre(self, p):
        ini = p
        dst = trozo(p, 2)[0] | (trozo(p, 2)[1] << 8)
        p += 2
        n = trozo(p, 1)[0]
        p += 1
        casillas = n if n else 256
        p += casillas * 8
        tramos = 0
        while trozo(p, 1)[0] != 0xFF:
            p += 2
            tramos += 1
        return ini, p + 1, dst, casillas, tramos

    def test_los_tres_bloques_teselan_sin_hueco(self):
        """Esto es lo que prueba que el formato esta bien leido: si la cuenta
        de casillas o los tramos de color se leyeran mal, el bloque siguiente
        no empezaria donde empieza."""
        p = 0x514C
        limites = []
        for _ in range(3):
            ini, fin, dst, n, tramos = self.recorre(p)
            limites.append((ini, fin, dst, n, tramos))
            p = fin
        self.assertEqual([x[0] for x in limites], [0x514C, 0x5B26, 0x5B7C])
        self.assertEqual([x[1] for x in limites], [0x5B26, 0x5B7C, 0x5E38])
        self.assertEqual([x[2] for x in limites], [0x0000, 0x0080, 0x0100])
        self.assertEqual([x[3] for x in limites], [256, 10, 64])

    def test_el_cero_de_la_cuenta_vale_256(self):
        """0x50A2 hace `or a` y un `inc h` si sale cero, asi que un byte a
        cero son 256 casillas y no ninguna. El primer bloque lo usa."""
        self.assertEqual(trozo(0x514E, 1), [0x00])
        self.assertEqual(instruccion(0x50a2), "or a")
        self.assertEqual(instruccion(0x50a7), "inc h")

    def test_los_ocho_registros_del_vdp(self):
        self.assertEqual(trozo(0x5144, 8),
                         [0x02, 0xC2, 0x06, 0x7F, 0x07, 0x38, 0x07, 0xF0])

    def test_la_pantalla_es_screen_2_con_sprites_de_16(self):
        r = trozo(0x5144, 8)
        self.assertEqual(r[0] & 0x02, 0x02, "el bit M3 no esta puesto")
        self.assertEqual(r[1] & 0x02, 0x02, "los sprites no son de 16x16")
        self.assertEqual(r[2] * 0x400, 0x1800, "los nombres no van a 0x1800")
        self.assertEqual(r[5] * 0x80, 0x1C00, "los atributos no van a 0x1C00")
        self.assertEqual(r[6] * 0x800, 0x3800,
                         "los patrones de sprite no van a 0x3800")

    def test_la_lista_de_sprites_se_apaga_donde_dice_el_registro_5(self):
        """0x507C escribe 0xD0 en 0x1C00, que es justo lo que R5 declara."""
        self.assertEqual(instruccion(0x507c), "ld hl,01c00h")
        self.assertEqual(instruccion(0x507f), "ld a,0d0h")


class TestLosDibujosQueSeAniman(unittest.TestCase):

    def test_los_dieciseis_punteros_caen_en_el_ultimo_bloque(self):
        b = trozo(0x419B, 32)
        p = [b[2 * i] | (b[2 * i + 1] << 8) for i in range(16)]
        for x in p:
            self.assertTrue(0x5E38 <= x < 0x6000,
                            "0x%04X se sale del bloque de dibujos" % x)
        self.assertEqual(min(p), 0x5E38,
                         "el puntero mas bajo ya no es el principio del bloque")

    def test_la_tabla_se_indexa_con_el_contador_de_cuadros(self):
        self.assertEqual(instruccion(0x4171), "ld hl,0419bh")
        self.assertEqual(instruccion(0x4167), "ld a,(0e310h)")


class TestLosValoresDePartida(unittest.TestCase):

    def test_el_ldir_va_de_0x4fdd_a_la_ram(self):
        self.assertEqual(instruccion(0x4fd1), "ld hl,04fddh")
        self.assertEqual(instruccion(0x4fd4), "ld de,0e305h")
        self.assertEqual(instruccion(0x4fd7), "ld bc,00090h")
        self.assertEqual(instruccion(0x4fda), "ldir")

    def test_el_ldir_se_pasa_once_bytes_y_arrastra_la_rutina_de_al_lado(self):
        """0x4FDD + 0x90 = 0x506D, y `monta_el_vdp` empieza en 0x5062: los
        once ultimos bytes que van a la RAM son sus instrucciones. Por eso el
        bloque de datos se declara solo hasta 0x5062."""
        self.assertEqual(0x4FDD + 0x90, 0x506D)
        self.assertEqual(instruccion(0x5062), "di")
        self.assertIn("D 0x4fdd 0x5062 ", lee(NOTES))

    def test_los_dos_punteros_de_sonido_arrancan_apuntando_al_mismo_sitio(self):
        """Las dos primeras palabras del bloque van a (0xE305) y (0xE307)."""
        b = trozo(0x4FDD, 4)
        self.assertEqual(b[0] | (b[1] << 8), b[2] | (b[3] << 8))


class TestNoSeCuelaOtroJuego(unittest.TestCase):
    """Cinco LICENSE de la serie nombraban otro juego. No otra vez."""

    def test_el_encabezado_del_listado_es_de_este_juego(self):
        cab = "\n".join(lineas_del_asm()[:8])
        for otro in OTROS_JUEGOS:
            self.assertNotIn(otro, cab, "el listado nombra a %s" % otro)

    def test_ni_las_notas_ni_los_tests_apuntan_a_otro_fichero(self):
        for ruta in (NOTES, ENTRIES, NOCODE):
            t = lee(ruta)
            for m in re.findall(r"\b(?:src|tools|tests)/[\w./-]+", t):
                p = os.path.join(RAIZ, m)
                self.assertTrue(os.path.exists(p),
                                "%s nombra %s, que no existe"
                                % (os.path.basename(ruta), m))

    def test_ninguna_pagina_nombra_otro_juego_de_la_serie(self):
        """El andamiaje de la web se copia del proyecto anterior, y por eso
        llega con el nombre del juego anterior dentro. Ya paso con cinco
        ficheros LICENSE y con el pie de catorce paginas."""
        malas = []
        for carpeta in (DOCS, os.path.join(DOCS, "es")):
            for fn in sorted(os.listdir(carpeta)):
                if not fn.endswith((".md", ".html")):
                    continue
                t = lee(os.path.join(carpeta, fn))
                for otro in OTROS_JUEGOS:
                    if otro in t:
                        malas.append((fn, otro))
        for ruta in ("LICENSE", "AVISO-LEGAL.md", "LEGAL-NOTICE.md",
                     "tools/make_web.py", "tools/md2html.py"):
            t = lee(os.path.join(RAIZ, ruta))
            for otro in OTROS_JUEGOS:
                if otro in t:
                    malas.append((ruta, otro))
        self.assertEqual(malas, [], "nombran otro juego: %s" % malas[:5])

    def test_los_ficheros_del_repositorio_existen(self):
        for f in ("Makefile", "src/bomberman.asm", "src/bomberman.notes",
                  "src/bomberman.entries", "src/bomberman.nocode",
                  "tools/z80trace.py", "tools/mkasm.py"):
            self.assertTrue(os.path.exists(os.path.join(RAIZ, f)),
                            "falta %s" % f)


class TestElTablero(unittest.TestCase):
    """Quince por once casillas de dos por dos, y donde cae cada cosa."""

    def test_el_tablero_es_de_quince_por_once(self):
        # `una_casilla_al_azar` (0x4E15) sortea y repite lo que se salga: la
        # columna por encima de 15 y la fila por encima de 11.
        self.assertEqual(instruccion(0x4E1A), "cp 00fh")
        self.assertEqual(instruccion(0x4E24), "cp 00bh")

    def test_una_casilla_de_tablero_son_dos_de_pantalla(self):
        # `de_casilla_a_pantalla` (0x4E2A): por dos y una mas, en las dos
        # coordenadas. De ahi salen las columnas 1..29 y las filas 1..21.
        for d in (0x4E2B, 0x4E30):
            self.assertEqual(instruccion(d), "add a,a")
        for d in (0x4E2C, 0x4E31):
            self.assertEqual(instruccion(d), "add a,001h")

    def test_los_pilares_van_de_cuatro_en_cuatro(self):
        # `pinta_el_tablero` (0x4DB7): cinco filas de siete pilares, el primero
        # en 0xE063 -fila 3, columna 3- y luego 0x21 menos 0x1D, o sea cuatro
        # columnas, y 0x64 para bajar cuatro filas.
        self.assertEqual(instruccion(0x4DD9), "ld hl,0e063h")
        self.assertEqual(instruccion(0x4DDC), "ld c,005h")
        self.assertEqual(instruccion(0x4DE0), "ld b,007h")
        self.assertEqual(instruccion(0x4DE6), "ld de,0001dh")
        self.assertEqual(instruccion(0x4DED), "ld de,00064h")
        self.assertEqual(0xE063 - 0xE000, 3 * 32 + 3)

    def test_las_casillas_prohibidas_rodean_las_esquinas_de_salida(self):
        # Las ocho parejas de 0x4EDF son las vecinas de las cuatro esquinas por
        # donde salen los enemigos (0x45C6), para que no salgan tapiados.
        esquinas = set()
        for k in range(4):
            col, fila = trozo(0x45C6 + 2 * k, 2)
            esquinas.add((fila, col))
        prohibidas = []
        p = 0x4EDF
        while trozo(p, 1)[0] != 0xFF:
            prohibidas.append(tuple(trozo(p, 2)))
            p += 2
        self.assertEqual(len(prohibidas), 8)
        for fila, col in prohibidas:
            cerca = [1 for f, c in esquinas
                     if abs(f - fila) <= 2 and abs(c - col) <= 2]
            self.assertTrue(cerca, "(%d,%d) no toca ninguna esquina"
                            % (fila, col))


class TestLaExplosion(unittest.TestCase):
    """El alcance de la llama, que es lo que decide como se juega."""

    def test_la_tabla_son_ocho_tiras_de_cuatro_y_cierra_con_cuatro_0x80(self):
        pares = [tuple(trozo(0x4F8D + 2 * k, 2)) for k in range(32)]
        self.assertEqual(trozo(0x4FCD, 4), [0x80] * 4)
        # Cuatro lados, y de cada uno dos tiras: la fila -o columna- de arriba
        # y la de abajo, porque la explosion ocupa dos casillas de ancho.
        def sig(b):
            return b - 256 if b > 127 else b
        tiras = [pares[4 * t:4 * t + 4] for t in range(8)]
        esperado = [
            [(0, -1), (0, -2), (0, -3), (0, -4)],
            [(1, -1), (1, -2), (1, -3), (1, -4)],
            [(0, 2), (0, 3), (0, 4), (0, 5)],
            [(1, 2), (1, 3), (1, 4), (1, 5)],
            [(-1, 0), (-2, 0), (-3, 0), (-4, 0)],
            [(-1, 1), (-2, 1), (-3, 1), (-4, 1)],
            [(2, 0), (3, 0), (4, 0), (5, 0)],
            [(2, 1), (3, 1), (4, 1), (5, 1)],
        ]
        self.assertEqual([[(sig(f), sig(c)) for f, c in t] for t in tiras],
                         esperado)

    def test_solo_las_dos_primeras_casillas_de_cada_tira_gastan_ladrillo(self):
        # La primera y la segunda llaman a 0x4B21, que le suma uno al dibujo
        # del ladrillo; la tercera y la cuarta a 0x4B5A, que no. Por eso la
        # explosion alcanza dos casillas de tablero y solo tira los ladrillos
        # de la primera. Medido tambien en openMSX: tools/omsx_alcance.tcl.
        self.assertEqual(instruccion(0x4AC0), "call pinta_una_llama_y_gasta_el_ladrillo")
        self.assertEqual(instruccion(0x4AE1), "call pinta_una_llama_y_gasta_el_ladrillo")
        self.assertEqual(instruccion(0x4AFE), "call pinta_una_llama_sin_gastar")
        self.assertEqual(instruccion(0x4B1C), "call pinta_una_llama_sin_gastar")
        # y 0x4B5A se vuelve SIN escribir cuando lo que hay es un ladrillo
        self.assertEqual(instruccion(0x4B6D), "cp 08ah")
        self.assertEqual(instruccion(0x4B71), "cp 080h")
        self.assertEqual(instruccion(0x4B75), "ret")

    def test_el_pilar_de_la_primera_casilla_no_se_comprueba_nunca(self):
        # 0x4AC7 es un `jr` incondicional que cae en 0x4ACD, o sea que pasa por
        # encima del `cp 089h` de 0x4AC9. Se declara como codigo igual, porque
        # instrucciones son.
        self.assertEqual(instruccion(0x4AC3), "cp 088h")
        self.assertEqual(instruccion(0x4AC9), "cp 089h")
        salto = instruccion(0x4AC7)
        self.assertTrue(salto.startswith("jr "), salto)
        self.assertNotIn("nz", salto)
        self.assertNotIn(",", salto)


class TestLaPartida(unittest.TestCase):
    """Las cuentas del juego, que se publican y por tanto se comprueban."""

    def test_tres_vidas_y_mil_de_bonus(self):
        self.assertEqual(instruccion(0x4069), "ld a,003h")
        self.assertEqual(instruccion(0x406B), "ld (0e30fh),a")
        self.assertEqual(instruccion(0x4080), "ld hl,003e8h")

    def test_los_enemigos_de_las_cinco_primeras_fases(self):
        # La tabla de 0x4217, dos bytes por fase: cuantos y a que cadencia. La
        # cuarta fase tiene MENOS enemigos que la tercera.
        pares = [tuple(trozo(0x4217 + 2 * k, 2)) for k in range(5)]
        self.assertEqual([n for n, _ in pares], [1, 2, 3, 2, 4])
        self.assertEqual([c for _, c in pares], [0x10, 0x15, 0x1A, 0x1F, 0x24])
        # y de la sexta en adelante se juega con la quinta linea
        self.assertEqual(instruccion(0x41FE), "cp 006h")

    def test_la_bomba_automatica_y_su_aviso_llevan_la_misma_condicion(self):
        # `pon_una_bomba` deja de pedir el disparo y `pinta_el_aviso` enciende
        # el rotulo: los dos miran la fase con el mismo `and 003h`.
        self.assertEqual(instruccion(0x4922), "ld a,(0e310h)")
        self.assertEqual(instruccion(0x4925), "and 003h")
        self.assertEqual(instruccion(0x4D37), "ld a,(0e310h)")
        self.assertEqual(instruccion(0x4D3A), "and 003h")

    def test_el_enemigo_vale_entre_30_y_180_y_la_portada_dice_200_10(self):
        # 0x48A5: (cuadro de dibujo)*4 + 2, mas un numero al azar de 1 a 4. El
        # cuadro va de 0 a 3, asi que sale de 3 a 18, y el marcador se ensena
        # multiplicado por diez.
        self.assertEqual(instruccion(0x48AC), "add a,a")
        self.assertEqual(instruccion(0x48AD), "add a,a")
        self.assertEqual(instruccion(0x48B4), "and 003h")
        minimo, maximo = 3 * 10, 18 * 10
        self.assertEqual((minimo, maximo), (30, 180))
        # y en la portada el rotulo de al lado del bicho dice otra cosa
        self.assertIn("200-10", lee(NOTES))

    def test_el_marcador_se_ensena_multiplicado_por_diez(self):
        # `escribe_cinco_cifras_y_un_cero` (0x4F29) saca cinco cifras y pega un
        # cero detras; al bonus se lo quita quien llama.
        self.assertEqual(instruccion(0x4F44), "xor a")
        self.assertEqual(instruccion(0x4D2A), "dec bc")
        self.assertEqual(instruccion(0x4D2B), "ld a,020h")

    def test_el_bonus_agotado_borra_el_tablero_entero(self):
        self.assertEqual(instruccion(0x44A4), "call borra_el_tablero")
        self.assertEqual(instruccion(0x4F5E), "ld (hl),020h")

    def test_reventar_el_premio_o_la_puerta_saca_cuatro_enemigos(self):
        self.assertEqual(instruccion(0x4552), "ld a,(0e313h)")
        self.assertEqual(instruccion(0x4555), "add a,004h")
        self.assertEqual(instruccion(0x455E), "ld d,004h")


class TestCodigoQueNadieAlcanza(unittest.TestCase):
    """Las cuatro piezas muertas del cartucho, cada una con su prueba."""

    def test_nadie_llama_a_las_tres_rutinas_sueltas(self):
        cuerpo = "\n".join(lineas_del_asm())
        for dire in (0x4EF0, 0x4F84, 0x50D6):
            self.assertNotIn("call %05xh" % dire, cuerpo)
            self.assertNotIn("jp %05xh" % dire, cuerpo)
            self.assertNotIn("ld hl,%05xh" % dire, cuerpo)

    def test_las_cuatro_estan_declaradas_como_puntos_de_entrada(self):
        t = lee(ENTRIES)
        for dire in ("0x4AC9", "0x4EF0", "0x4F84", "0x50D6"):
            self.assertIn(dire, t)

    def test_los_seis_bytes_que_sobran_no_tocan_nada_que_se_lea(self):
        # 0x4864..0x4869: un `ld c,a` y cuatro `ld b,..`, y detras nadie vuelve
        # a leer B ni C antes de escribirlos. Leidos como texto son "OBADD".
        for dire in range(0x4864, 0x486A):
            ins = instruccion(dire)
            self.assertTrue(ins in ("ld c,a", "nop") or ins.startswith("ld b,"),
                            "0x%04X es %s" % (dire, ins))
        # el primero que vuelve a tocar BC lo escribe entero
        self.assertEqual(instruccion(0x4907), "ld bc,00007h")

    def test_los_dos_jr_que_van_al_mismo_sitio(self):
        # 0x49DB y 0x49DD: el `jr nc` y el `jr` de detras caen los dos en la
        # misma etiqueta, asi que la comparacion de 0x49D9 no decide nada.
        self.assertEqual(instruccion(0x49D6), "ld a,(0e30bh)")
        self.assertEqual(instruccion(0x49D9), "cp 006h")
        self.assertEqual(instruccion(0x49DB).split(",")[-1],
                         instruccion(0x49DD).split()[-1])


class TestElAzar(unittest.TestCase):
    """El generador se apoya en el registro R, y eso se puede demostrar."""

    def test_mezcla_el_registro_de_refresco(self):
        self.assertEqual(instruccion(0x4F08), "ld a,r")
        self.assertEqual(instruccion(0x4F0A), "xor l")

    def test_el_azar_del_cartucho_se_apoya_en_el_registro_r(self):
        # Si R avanzara siempre lo mismo entre dos sorteos, la serie de
        # casillas se cierra en un punado de valores y se repite. En la maquina
        # no pasa porque entre dos sorteos se ejecutan mas o menos
        # instrucciones segun cuantas veces haya habido que repetirlo.
        sys.path.insert(0, os.path.join(RAIZ, "tools"))
        import pantallas as P
        for paso in (1, 7, 23, 31):
            azar = P.AzarDelCartucho(paso=paso)
            casillas = {P.una_casilla_al_azar(azar) for _ in range(60)}
            self.assertLess(len(casillas), 8,
                            "con paso %d salen %d casillas distintas"
                            % (paso, len(casillas)))


class TestLoQueDicenLosTextos(unittest.TestCase):
    """La fuente no es ASCII, asi que los textos se leen DIBUJANDOLOS."""

    def test_la_firma_de_la_partida_va_sin_espacio_entre_hudson_y_soft(self):
        # 0x4D9C, con la hoja de casillas de la partida: la B, la O y la U
        # salen del bloque de 0x5B26, la T del de 0x5B7C y la H, la D, la F, la
        # A, la M y la I de la pantalla de titulo, que no se sobreescriben.
        fuente = {0x10: "S", 0x11: "C", 0x12: "O", 0x13: "R", 0x14: "E",
                  0x15: "B", 0x16: "O", 0x17: "N", 0x18: "U", 0x19: "S",
                  0x20: " ", 0x21: ":", 0x30: "T", 0x31: "G",
                  0x92: "H", 0x93: "D", 0x94: "F", 0x95: "A", 0x96: "M",
                  0x97: "I"}
        fuente.update({d: str(d) for d in range(10)})
        p, texto = 0x4D9C, ""
        while trozo(p, 1)[0]:
            texto += fuente[trozo(p, 1)[0]]
            p += 1
        self.assertEqual(texto, " BOMBERMAN HUDSONSOFT 1983")

    def test_el_aviso_de_bomba_automatica(self):
        fuente = {0x10: "S", 0x14: "E", 0x15: "B", 0x16: "O", 0x17: "N",
                  0x18: "U", 0x20: " ", 0x30: "T", 0x31: "G", 0x95: "A",
                  0x96: "M", 0x97: "I"}
        p, texto = 0x4D6C, ""
        while trozo(p, 1)[0]:
            texto += fuente[trozo(p, 1)[0]]
            p += 1
        self.assertEqual(texto, "  BOMB AUTO SETTING STAGE ")


class TestLaWeb(unittest.TestCase):
    """Las cifras que se publican tienen que ser las del listado de AHORA."""

    def setUp(self):
        sys.path.insert(0, os.path.join(RAIZ, "tools"))
        import make_web
        self.w = make_web

    def test_la_suma_de_bytes_da_el_cartucho(self):
        self.assertEqual(self.w.CODIGO + self.w.DATOS, FIN - ORG)

    def test_los_bytes_de_codigo_son_los_del_listado(self):
        codigo = 0
        for ln in lineas_del_asm():
            m = re.match(r"^; CODIGO 0x([0-9a-f]{4})\.\.0x([0-9a-f]{4})", ln)
            if m:
                codigo += int(m.group(2), 16) - int(m.group(1), 16)
        self.assertEqual(codigo, self.w.CODIGO,
                         "la portada dice %d bytes de codigo y el listado %d"
                         % (self.w.CODIGO, codigo))

    def test_la_densidad_declarada_cuadra_con_las_dos_cuentas(self):
        instrucciones = comentarios = 0
        for ln in lineas_del_asm():
            if not ln.startswith("\t") or ln.lstrip().startswith(";"):
                continue
            if ln.lstrip().startswith(("defb", "defw", "org")):
                continue
            instrucciones += 1
            if ln.count(";") > 1:
                comentarios += 1
        self.assertEqual(instrucciones, self.w.INSTRUCCIONES)
        self.assertEqual(comentarios, self.w.COMENTARIOS)
        self.assertEqual("%.1f" % (100.0 * comentarios / instrucciones),
                         "%.1f" % self.w.DENSIDAD)

    def test_las_catorce_paginas_estan_en_los_dos_idiomas(self):
        for carpeta, nombres in (
                (DOCS, ("GETTING-STARTED", "THE-GAME", "THE-CARTRIDGE",
                        "THE-CODE", "FINDINGS", "IN-THE-EMULATOR",
                        "OPEN-QUESTIONS")),
                (os.path.join(DOCS, "es"),
                 ("EMPEZAR", "EL-JUEGO", "EL-CARTUCHO", "EL-CODIGO",
                  "HALLAZGOS", "EN-EL-EMULADOR", "PREGUNTAS-ABIERTAS"))):
            for n in nombres:
                for ext in (".md", ".html"):
                    p = os.path.join(carpeta, n + ext)
                    self.assertTrue(os.path.exists(p), "falta %s" % p)
            self.assertTrue(os.path.exists(os.path.join(carpeta, "index.html")))

    def test_las_paginas_en_castellano_suben_un_nivel_para_las_imagenes(self):
        """docs/es vive un nivel mas abajo: las imagenes van a ../imagenes/."""
        malas = [fn for fn in sorted(os.listdir(os.path.join(DOCS, "es")))
                 if fn.endswith(".md")
                 and re.search(r"\]\(imagenes/",
                               lee(os.path.join(DOCS, "es", fn)))]
        self.assertEqual(malas, [], "imagenes sin subir un nivel: %s" % malas)

    def test_toda_imagen_citada_existe(self):
        faltan = []
        for carpeta in (DOCS, os.path.join(DOCS, "es")):
            for fn in sorted(os.listdir(carpeta)):
                if not fn.endswith(".md"):
                    continue
                for ruta in re.findall(r"!\[[^\]]*\]\(([^)]+)\)",
                                       lee(os.path.join(carpeta, fn))):
                    p = os.path.normpath(os.path.join(carpeta, ruta))
                    if not os.path.exists(p):
                        faltan.append((fn, ruta))
        self.assertEqual(faltan, [], "imagenes que no existen: %s" % faltan[:5])

    def test_las_catorce_laminas_estan_dibujadas(self):
        """Las dos pantallas, el rotulo, las cuatro hojas de casillas y las
        siete de lo que se mueve."""
        img = os.path.join(DOCS, "imagenes")
        self.assertTrue(os.path.isdir(img),
                        "no hay docs/imagenes: pasa make imagenes")
        pngs = sorted(f for f in os.listdir(img) if f.endswith(".png"))
        self.assertEqual(len(pngs), 14, "hay %d laminas y son 14" % len(pngs))
        for n in ("titulo.png", "partida.png", "rotulo.png", "bombero.png",
                  "agonia.png", "enemigos.png", "bombas.png", "llamas.png"):
            self.assertIn(n, pngs)
        for f in pngs:
            self.assertGreater(os.path.getsize(os.path.join(img, f)), 500,
                               "%s pesa demasiado poco para ser un dibujo" % f)

    def test_toda_lamina_dibujada_se_publica_en_alguna_pagina(self):
        """Una lamina que no sale en ninguna parte es trabajo tirado, y una
        pagina que cita una que no existe es una imagen rota."""
        img = os.path.join(DOCS, "imagenes")
        citadas = set()
        for carpeta in (DOCS, os.path.join(DOCS, "es")):
            for fn in sorted(os.listdir(carpeta)):
                if fn.endswith(".md"):
                    citadas |= {os.path.basename(r) for r in re.findall(
                        r"!\[[^\]]*\]\(([^)]+)\)",
                        lee(os.path.join(carpeta, fn)))}
        citadas |= {f for f, _, _ in self.w.GALERIA}
        citadas.add("rotulo.png")
        sueltas = sorted(set(os.listdir(img)) - citadas)
        self.assertEqual(sueltas, [], "laminas que no se publican: %s" % sueltas)

    def test_ninguna_pagina_dice_que_hay_capturas(self):
        for carpeta in (DOCS, os.path.join(DOCS, "es")):
            for fn in sorted(os.listdir(carpeta)):
                if not fn.endswith(".md"):
                    continue
                t = lee(os.path.join(carpeta, fn)).lower()
                for frase in ("captura de pantalla del emulador",
                              "screenshot from the emulator"):
                    self.assertNotIn(frase, t, "%s dice %r" % (fn, frase))


class TestLaDensidad(unittest.TestCase):
    """El liston de la serie, medido sobre el listado que se publica."""

    def test_todas_las_instrucciones_tienen_algo_que_decir(self):
        instrucciones = comentarios = 0
        for ln in lineas_del_asm():
            if not ln.startswith("\t") or ln.lstrip().startswith(";"):
                continue
            if ln.lstrip().startswith(("defb", "defw", "org")):
                continue
            instrucciones += 1
            if ln.count(";") > 1:
                comentarios += 1
        self.assertGreater(instrucciones, 1500)
        self.assertGreaterEqual(100 * comentarios / instrucciones, 22,
                                "la densidad ha bajado del liston de la serie")


if __name__ == "__main__":
    unittest.main()

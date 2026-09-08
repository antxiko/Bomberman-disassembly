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
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "bomberman.asm")
NOTES = os.path.join(RAIZ, "src", "bomberman.notes")
ENTRIES = os.path.join(RAIZ, "src", "bomberman.entries")
NOCODE = os.path.join(RAIZ, "src", "bomberman.nocode")
ORG, FIN = 0x4000, 0x6000

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
                 and not re.search(r"; ?[0-9a-f]{4}", ln)
                 and "org" not in ln]
        self.assertEqual(malas, [], "lineas sin direccion: %s" % malas[:3])

    def test_las_direcciones_van_en_orden_y_dentro_del_cartucho(self):
        ant = ORG - 1
        for ln in lineas_del_asm():
            m = re.search(r"; ?([0-9a-f]{4})", ln)
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

    def test_los_ficheros_del_repositorio_existen(self):
        for f in ("Makefile", "src/bomberman.asm", "src/bomberman.notes",
                  "src/bomberman.entries", "src/bomberman.nocode",
                  "tools/z80trace.py", "tools/mkasm.py"):
            self.assertTrue(os.path.exists(os.path.join(RAIZ, f)),
                            "falta %s" % f)


if __name__ == "__main__":
    unittest.main()

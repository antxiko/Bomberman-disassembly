#!/usr/bin/env python3
"""Genera la portada de la web de Bomber Man, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: las dibuja tools/pantallas.py a
partir de los propios bytes de la ROM, ejecutando en Python los mismos pasos
que corre el Z80, y estan cotejadas contra la VRAM de openMSX con
tools/coteja_vram.py. Ninguna se ha retocado.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas a ojo.
# CODIGO y DATOS los imprime tools/presupuesto.py (make sanity) y tienen que
# sumar los 8192 bytes del cartucho; RUTINAS y DENSIDAD, tools/densidad.py
# (make densidad).
CODIGO = 3557
DATOS = 4635
RUTINAS = 200
INSTRUCCIONES = 1836
COMENTARIOS = 921
DENSIDAD = 50.2
TESTS = 60


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Bomber Man — desensamblado comentado",
        aviso="<b>Aquí no hay ninguna ilustración ni captura.</b> El rótulo, "
              "la portada y la pantalla de partida están <b>dibujados desde "
              "los bytes de la ROM</b>, ejecutando en Python los mismos pasos "
              "que corre el Z80, y <b>cotejados contra la VRAM de openMSX: "
              "cero diferencias</b> en todo lo que no decide el azar. El "
              "listado y las cifras salen del binario y se reproducen con "
              "<code>make</code>.",
        claim="Ocho kilobytes de 1983, el cartucho más pequeño de la serie, y "
              "el juego entero cabe dentro sin usar <b>ni un solo sprite</b>: "
              "el bombero, los bichos, las bombas y las llamas son casillas de "
              "la tabla de nombres. Su cabecera de cartucho <b>es código</b>, "
              "y dentro van los nombres de sus dos programadores.",
        ficha=["Hudson Soft · <b>1983</b>",
               "Cartucho de <b>8 KB</b>",
               "MSX1 · <b>página 1</b>", "Volcado <b>eab39bab…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(DENSIDAD).replace(".", ",") + " %",
                 "de instrucciones comentadas"),
                ("0", "rutinas sin explicar"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                (str(TESTS), "comprobaciones automáticas")],
        nota_scr="Debajo de cada imagen está de dónde sale y qué se está "
                 "viendo.",
        pie_leg="Esto es trabajo de documentación y preservación: el código "
                "sigue siendo de sus autores y de Hudson Soft, y la imagen del "
                "cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Bomber Man — a commented disassembly",
        aviso="<b>There is not one illustration or capture here.</b> The "
              "wordmark, the title screen and the in-game screen are "
              "<b>drawn from the bytes of the ROM</b>, by running in Python "
              "the same steps the Z80 runs, and <b>checked against openMSX's "
              "VRAM: zero differences</b> in everything that is not left to "
              "chance. The listing and the numbers come from the binary and "
              "are reproducible with <code>make</code>.",
        claim="Eight kilobytes from 1983, the smallest cartridge in the "
              "series, and the whole game fits inside without using <b>a "
              "single sprite</b>: the bomber, the monsters, the bombs and the "
              "flames are all name-table tiles. Its cartridge header <b>is "
              "code</b>, and the names of its two programmers are inside.",
        ficha=["Hudson Soft · <b>1983</b>",
               "An <b>8 KB</b> cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>eab39bab…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(DENSIDAD) + "%", "of instructions commented"),
                ("0", "routines left unexplained"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                (str(TESTS), "automatic checks")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code still "
                "belongs to its authors and to Hudson Soft, and the cartridge "
                "image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("La cabecera del cartucho es código",
         "<p>Un cartucho de MSX empieza por <code>AB</code>, la dirección de "
         "INIT y luego STATEMENT, DEVICE, TEXT y seis bytes reservados. Aquí "
         "<b>INIT vale 0x4004</b>, que es justo donde deberían empezar esos "
         "campos. Leídos como instrucciones dan el arranque del juego:</p>"
         "<pre>4004  31 00 F0     ld sp,0F000h\n"
         "4007  CD D1 4F     call 4FD1h\n"
         "400A  CD 62 50     call 5062h\n"
         "400D  CD 4E 40     call 404Eh</pre>"
         "<p>Sólo los <b>cuatro primeros bytes</b> del cartucho son cabecera "
         "de verdad. Los otros nueve son las cuatro primeras instrucciones.</p>"),
        ("Dos programadores, y una errata de Hudson",
         "<p>La pantalla de título, dibujada desde la ROM, dice "
         "<b>PROGRAMMER:Y.TANAKA</b> y debajo <b>T.SASAGAWA</b>. Son dos, no "
         "uno. Y la última línea dice <b>PUSH SPACE-KEY OR TORIGER</b>: "
         "TORIGER, no TRIGGER.</p>"
         "<p>Los textos no se pueden leer mirando los bytes: la fuente del "
         "cartucho <b>no es ASCII del todo</b> y encima <b>cambia a mitad de "
         "juego</b>. El 0x21, que en ASCII sería un <code>!</code>, aquí son "
         "los dos puntos; por eso leyendo en crudo parecía poner "
         "«PROGRAMMER!». La única forma de citar un texto de este cartucho es "
         "<b>dibujarlo</b>.</p>"),
        ("Cada cuatro fases el juego pone las bombas por ti",
         "<p><code>pon_una_bomba</code> (0x491C) mira el número de fase con un "
         "<code>and 003h</code>: si es múltiplo de cuatro, <b>no pide el "
         "disparo</b> y la bomba cae sola. Y hay un rótulo que lo anuncia, "
         "parpadeando abajo dieciséis cuadros sí y ocho no, con exactamente la "
         "misma condición (0x4D37): <b>BOMB AUTO SETTING STAGE</b>.</p>"
         "<p>Es un modo de juego entero escondido en dos instrucciones.</p>"),
        ("La explosión alcanza dos casillas y sólo tira los ladrillos de una",
         "<p>Cada brazo de la explosión son cuatro casillas de pantalla, o sea "
         "<b>dos casillas de tablero</b>. Pero el bucle está desenrollado a "
         "propósito y no todas se tratan igual: las dos primeras llaman a "
         "<code>pinta_una_llama_y_gasta_el_ladrillo</code> (0x4B21), que "
         "desmorona el ladrillo en ocho cuadros; la tercera y la cuarta llaman "
         "a <code>pinta_una_llama_sin_gastar</code> (0x4B5A), que <b>se vuelve "
         "sin escribir</b> si lo que hay es un ladrillo.</p>"
         "<p>Medido en openMSX, no deducido: dos bombas metidas a mano en la "
         "lista, una con ladrillo pegado y otra con el ladrillo a dos "
         "casillas. Los dos de la primera <b>caen</b>; el de la segunda "
         "<b>sigue en pie</b>.</p>"),
        ("El bicho se pone rojo cuando va a por ti",
         "<p>El mismo byte de la ficha del enemigo hace dos cosas: elige el "
         "dibujo (<code>0xC0 + cuadro*4</code>) y decide el comportamiento. "
         "Cuando vale <b>cero</b>, el enemigo <b>persigue al bombero</b> "
         "(0x477B) en vez de andar a lo suyo. Y cero es justo el cuadro de "
         "dibujo <b>rojo</b>: los otros tres son morados.</p>"
         "<p>O sea que el juego te está avisando de cuándo te persiguen, y no "
         "hace falta ni un byte para ello.</p>"),
        ("Ni un sprite en todo el cartucho",
         "<p>0x5062 escribe un <code>0xD0</code> en el primer atributo de "
         "sprite —la marca de «no hay más»— y <b>no vuelve a tocar la lista "
         "nunca</b>. Todo lo que se mueve son casillas de la tabla de "
         "nombres, y todo ocupa <b>dos por dos</b>.</p>"
         "<p>Eso explica la arquitectura entera: el juego lleva <b>dos "
         "pantallas de 768 bytes en la RAM</b>, una para lo que se ve y otra "
         "para lo que permanece, y en vez de tener una estructura de datos del "
         "mapa <b>lee el número de casilla</b>. Las tres comparaciones que se "
         "repiten por todo el listado son <code>cp 020h</code> («libre»), "
         "<code>cp 0e0h</code> («hay llama») y <code>cp 0c0h</code> («hay algo "
         "que mata»), y esta última vale para las llamas y para los bichos "
         "porque están puestos <b>seguidos a propósito</b>.</p>"),
        ("El azar se apoya en el registro de refresco de la memoria",
         "<p><code>numero_al_azar</code> (0x4EF9) realimenta una semilla de "
         "dieciséis bits y le mezcla <b>el registro R del Z80</b>. No es un "
         "adorno: si R avanzara siempre lo mismo entre dos sorteos, la serie "
         "de casillas <b>se cierra en tres a cinco valores</b> y se repite —lo "
         "comprueba un test del repositorio, con cuatro pasos distintos—.</p>"
         "<p>En la máquina no pasa porque entre dos sorteos se ejecutan más o "
         "menos instrucciones según cuántas veces haya habido que repetir el "
         "sorteo. La consecuencia es que <b>el reparto de una fase no se puede "
         "reproducir desde fuera</b>: depende del instante en que se pulsó el "
         "disparo.</p>"),
        ("Cuatro trozos de código a los que no llega nadie",
         "<p>Tres rutinas enteras —<b>0x4EF0</b> (borrar una casilla del "
         "tablero), <b>0x4F84</b> (una espera corta) y <b>0x50D6</b> (escribir "
         "el registro 7 del VDP)— sin un solo <code>call</code> que las nombre "
         "en los 8 KB. Y un cuarto: el <code>cp 089h</code> de <b>0x4AC9</b>, "
         "que comprobaría el pilar en la primera casilla de cada brazo, y por "
         "encima del cual pasa un <code>jr</code> incondicional.</p>"
         "<p>Ese último no cambia nada, y por eso nadie lo arregló: la casilla "
         "siguiente da con la otra mitad del mismo pilar y la llama se para "
         "ahí igual. Se declaran como código, porque instrucciones son.</p>"
         "<p>Y hay seis bytes en 0x4864 que sí se ejecutan y no hacen nada: un "
         "<code>ld c,a</code> y cuatro <code>ld b,..</code> que nadie vuelve a "
         "leer. En la propia fuente del cartucho se leen <b>OBADD</b>.</p>"),
        ("Reventar la puerta sale caro, y quedarse sin bonus, más caro todavía",
         "<p>Si una llama alcanza la puerta o el premio, el juego apunta el "
         "sitio y <b>saca cuatro enemigos más</b> por ahí (0x453B) en cuanto la "
         "casilla queda limpia. La puerta se vuelve a descubrir; el premio se "
         "pierde.</p>"
         "<p>Y si el bonus llega a cero, <code>se_agoto_el_bonus</code> "
         "(0x449F) <b>borra el tablero entero</b>: los treinta y cinco "
         "ladrillos, el premio y la puerta desaparecen de golpe, y con las dos "
         "banderas de «ya está descubierto» puestas a uno ya no se vuelven a "
         "buscar. <b>La fase se queda sin salida</b> y sólo se puede terminar "
         "matándolos a todos.</p>"),
    ],
    "en": [
        ("The cartridge header is code",
         "<p>An MSX cartridge starts with <code>AB</code>, the INIT address, "
         "and then STATEMENT, DEVICE, TEXT and six reserved bytes. Here "
         "<b>INIT is 0x4004</b>, which is exactly where those fields should "
         "begin. Read as instructions they are the start of the game:</p>"
         "<pre>4004  31 00 F0     ld sp,0F000h\n"
         "4007  CD D1 4F     call 4FD1h\n"
         "400A  CD 62 50     call 5062h\n"
         "400D  CD 4E 40     call 404Eh</pre>"
         "<p>Only the <b>first four bytes</b> of the cartridge are really a "
         "header. The other nine are the first four instructions.</p>"),
        ("Two programmers, and a typo by Hudson",
         "<p>The title screen, drawn from the ROM, reads "
         "<b>PROGRAMMER:Y.TANAKA</b> and below it <b>T.SASAGAWA</b>. Two of "
         "them, not one. And the last line reads <b>PUSH SPACE-KEY OR "
         "TORIGER</b>: TORIGER, not TRIGGER.</p>"
         "<p>The texts cannot be read by looking at the bytes: the "
         "cartridge's font <b>is not quite ASCII</b> and, on top of that, "
         "<b>changes halfway through the game</b>. Byte 0x21, which in ASCII "
         "would be a <code>!</code>, is the colon here; that is why reading it "
         "raw looked like \"PROGRAMMER!\". The only way to quote a text out of "
         "this cartridge is to <b>draw it</b>.</p>"),
        ("Every fourth stage the game drops the bombs for you",
         "<p><code>pon_una_bomba</code> (0x491C) checks the stage number with "
         "an <code>and 003h</code>: on multiples of four it <b>does not ask "
         "for the trigger</b> and the bomb drops by itself. And there is a "
         "label announcing it, blinking at the bottom sixteen frames on and "
         "eight off, under exactly the same condition (0x4D37): <b>BOMB AUTO "
         "SETTING STAGE</b>.</p>"
         "<p>A whole game mode hidden in two instructions.</p>"),
        ("The blast reaches two cells and only breaks the bricks in one",
         "<p>Each arm of the blast is four screen tiles, that is <b>two board "
         "cells</b>. But the loop is unrolled on purpose and the four are not "
         "treated alike: the first two call "
         "<code>pinta_una_llama_y_gasta_el_ladrillo</code> (0x4B21), which "
         "crumbles the brick over eight frames; the third and fourth call "
         "<code>pinta_una_llama_sin_gastar</code> (0x4B5A), which <b>returns "
         "without writing</b> if what it finds is a brick.</p>"
         "<p>Measured in openMSX, not deduced: two bombs written by hand into "
         "the list, one with a brick right next to it and one with the brick "
         "two cells away. Both of the first one's <b>fall</b>; the second "
         "one's <b>is still standing</b>.</p>"),
        ("The monster turns red when it is coming for you",
         "<p>The same byte of the enemy's record does two things: it picks the "
         "drawing (<code>0xC0 + frame*4</code>) and it decides the behaviour. "
         "When it is <b>zero</b>, the enemy <b>chases the bomber</b> (0x477B) "
         "instead of wandering. And zero is precisely the <b>red</b> frame: "
         "the other three are purple.</p>"
         "<p>So the game is telling you when you are being hunted, and it does "
         "not spend one byte on saying it.</p>"),
        ("Not a single sprite in the whole cartridge",
         "<p>0x5062 writes a <code>0xD0</code> into the first sprite attribute "
         "— the \"no more\" marker — and <b>never touches the list again</b>. "
         "Everything that moves is a name-table tile, and everything is "
         "<b>two by two</b>.</p>"
         "<p>That explains the whole architecture: the game keeps <b>two "
         "768-byte screens in RAM</b>, one for what is seen and one for what "
         "stays, and instead of a map data structure it <b>reads the tile "
         "number</b>. The three comparisons that repeat all over the listing "
         "are <code>cp 020h</code> (\"free\"), <code>cp 0e0h</code> (\"there "
         "is a flame\") and <code>cp 0c0h</code> (\"there is something that "
         "kills\"), and the last one covers both flames and monsters because "
         "they are laid out <b>next to each other on purpose</b>.</p>"),
        ("The randomness leans on the memory refresh register",
         "<p><code>numero_al_azar</code> (0x4EF9) feeds back a sixteen-bit "
         "seed and mixes in <b>the Z80's R register</b>. That is not a "
         "decoration: if R advanced by the same amount between two draws, the "
         "series of cells <b>collapses into three to five values</b> and "
         "repeats — a test in the repository checks it, with four different "
         "steps.</p>"
         "<p>On the machine that does not happen, because between two draws a "
         "varying number of instructions runs depending on how many times the "
         "draw had to be repeated. The consequence is that <b>a stage's layout "
         "cannot be reproduced from outside</b>: it depends on the instant the "
         "trigger was pressed.</p>"),
        ("Four pieces of code nobody reaches",
         "<p>Three whole routines — <b>0x4EF0</b> (clear a board cell), "
         "<b>0x4F84</b> (a short wait) and <b>0x50D6</b> (write VDP register "
         "7) — without a single <code>call</code> naming them anywhere in the "
         "8 KB. And a fourth: the <code>cp 089h</code> at <b>0x4AC9</b>, which "
         "would check for the pillar on the first tile of each arm, and which "
         "an unconditional <code>jr</code> steps over.</p>"
         "<p>That last one changes nothing, and that is why nobody ever fixed "
         "it: the next tile hits the other half of the same pillar and the "
         "flame stops there anyway. They are declared as code, because "
         "instructions is what they are.</p>"
         "<p>And there are six bytes at 0x4864 that <i>do</i> run and do "
         "nothing: an <code>ld c,a</code> and four <code>ld b,..</code> that "
         "nobody reads back. In the cartridge's own font they read "
         "<b>OBADD</b>.</p>"),
        ("Blowing up the door is expensive, and running out of bonus worse",
         "<p>If a flame reaches the door or the prize, the game notes the spot "
         "and <b>brings out four more enemies</b> there (0x453B) as soon as "
         "the cell is clear. The door gets uncovered again; the prize is "
         "lost.</p>"
         "<p>And if the bonus reaches zero, <code>se_agoto_el_bonus</code> "
         "(0x449F) <b>wipes the whole board</b>: the thirty-five bricks, the "
         "prize and the door all vanish at once, and with both \"already "
         "found\" flags set they are never looked for again. <b>The stage is "
         "left with no way out</b> and can only be finished by killing "
         "everything.</p>"),
    ],
}

GALERIA = [
    ("titulo.png",
     "<b>La portada</b>, montada como la monta el cartucho y en su orden: seis "
     "filas de ladrillo, el rótulo GRANDE de la fila 2 —nueve ternas de "
     "(casilla, fila, columna) en 0x446E—, los diecinueve rótulos de 0x4323, "
     "el marcador y la fila de muestra con el bombero, el bicho, el premio y "
     "la puerta. Cotejada contra la VRAM de openMSX: <b>0 de 768 casillas "
     "distintas</b>",
     "<b>The title screen</b>, built the way the cartridge builds it and in "
     "its order: six rows of brick, the BIG wordmark on row 2 — nine (tile, "
     "row, column) triples at 0x446E —, the nineteen labels at 0x4323, the "
     "score and the sample row with the bomber, the monster, the prize and the "
     "door. Checked against openMSX's VRAM: <b>0 of 768 tiles differ</b>"),
    ("partida.png",
     "<b>Una partida</b>, repartida aquí con las tres reglas de "
     "<code>siembra_la_fase</code> (0x4E35) y pintada con las rutinas del "
     "cartucho, en el orden del bucle principal. El marco y los treinta y "
     "cinco pilares están donde 0x4DB7 los pone, comprobado contra el "
     "emulador; los ladrillos son <b>un reparto de los posibles</b>, porque el "
     "de verdad lo decide el registro R. Se ven una bomba con la mecha "
     "empezando, otra a punto y una explosión ya abierta",
     "<b>A game in progress</b>, dealt here with the three rules of "
     "<code>siembra_la_fase</code> (0x4E35) and painted with the cartridge's "
     "own routines, in the main loop's order. The frame and the thirty-five "
     "pillars are where 0x4DB7 puts them, checked against the emulator; the "
     "bricks are <b>one of the possible deals</b>, because the real one is "
     "decided by the R register. There is a bomb with its fuse starting, "
     "another about to go, and a blast already open"),
    ("bombero.png",
     "<b>El bombero.</b> Los dos primeros son estar quieto: el de la izquierda "
     "sale sólo el cuadro siguiente a soltar una bomba —lleva la bomba en la "
     "mano— y el otro el resto del tiempo. Los ocho siguientes son andar: "
     "cuatro sentidos por dos pasos, a partir de la casilla 0xA0. De espaldas "
     "cambia hasta el color del gorro",
     "<b>The bomber.</b> The first two are standing still: the left one shows "
     "only on the frame after dropping a bomb — it is holding one — and the "
     "other the rest of the time. The next eight are walking: four directions "
     "times two steps, starting at tile 0xA0. Seen from behind even the cap "
     "changes colour"),
    ("agonia.png",
     "<b>Los ocho cuadros de morir</b>, y van hacia ATRÁS: 0x4E, 0x4C, 0x4A… "
     "hasta 0x40. El último no es un dibujo del bombero, es un <b>OUT</b> "
     "verde encima de lo que queda de él",
     "<b>The eight frames of dying</b>, and they run BACKWARDS: 0x4E, 0x4C, "
     "0x4A… down to 0x40. The last one is not a drawing of the bomber, it is a "
     "green <b>OUT</b> on top of what is left of him"),
    ("enemigos.png",
     "<b>El bicho vivo</b>: cuatro cuadros por dos de parpadeo. Los dos "
     "primeros son el cuadro <b>0</b>, que es justo cuando el enemigo persigue "
     "al bombero — y es el único rojo",
     "<b>The monster alive</b>: four frames times two of blink. The first two "
     "are frame <b>0</b>, which is exactly when the enemy chases the bomber — "
     "and the only red one"),
    ("enemigo_revienta.png",
     "<b>Los siete cuadros de reventar</b>, casillas 0x22 a 0x2E. En la "
     "portada, con el otro bloque de gráficos cargado, esas mismas casillas "
     "son las letras del rótulo grande de BOMBER MAN",
     "<b>The seven frames of blowing up</b>, tiles 0x22 to 0x2E. On the title "
     "screen, with the other graphics block loaded, those same tiles are the "
     "letters of the big BOMBER MAN wordmark"),
    ("bombas.png",
     "<b>La bomba</b>: cuatro estados de mecha por dos de parpadeo, del 0x60 "
     "al 0x6E. Encoge según se le acaba la mecha",
     "<b>The bomb</b>: four fuse states times two of blink, from 0x60 to 0x6E. "
     "It shrinks as the fuse runs out"),
    ("llamas.png",
     "<b>La llama</b>, ocho estados del 0xE0 al 0xEE, que se van deshilachando "
     "hasta desaparecer. El brazo usa siempre el dibujo del centro <b>más "
     "dos</b>, así que se apaga un par de estados antes",
     "<b>The flame</b>, eight states from 0xE0 to 0xEE, thinning out until "
     "there is nothing left. The arms always use the centre's drawing "
     "<b>plus two</b>, so they go out a couple of states earlier"),
    ("casillas_del_tablero.png",
     "<b>El tablero</b>: el ladrillo entero y tres de sus ocho cuadros de "
     "desmoronarse, el muro del borde, el premio —que es un cofre— y la "
     "puerta, que lleva <b>EXIT</b> escrito encima",
     "<b>The board</b>: the whole brick and three of its eight crumbling "
     "frames, the border wall, the prize — a chest — and the door, with "
     "<b>EXIT</b> written on it"),
    ("fuente.png",
     "<b>La fuente de la portada</b>, de la casilla 0x20 a la 0x5D. Las letras "
     "grandes de en medio son el rótulo BOMBER MAN; en la partida, ese mismo "
     "sitio lo ocupan los bichos",
     "<b>The title screen's font</b>, from tile 0x20 to 0x5D. The big letters "
     "in the middle are the BOMBER MAN wordmark; during the game those same "
     "slots are taken by the monsters"),
    ("casillas.png",
     "<b>Las 256 casillas de la portada</b>, o sea el bloque de gráficos de "
     "0x514C entero. Es la hoja de la que sale todo lo demás",
     "<b>The 256 tiles of the title screen</b>, that is the whole graphics "
     "block at 0x514C. It is the sheet everything else comes from"),
    ("casillas_partida.png",
     "<b>Y las de la partida</b>, con los dos parches encima: el bloque de "
     "0x5B26 mete las letras de SCORE y BONUS en la casilla 0x10 y el de "
     "0x5B7C, las cifras, los bichos y el bombero a partir de la 0x20. Todo lo "
     "de 0x90 arriba <b>se queda de la portada</b>, y de ahí salen la H, la D, "
     "la F, la A, la M y la I que hacen falta abajo",
     "<b>And the in-game ones</b>, with the two patches on top: the block at "
     "0x5B26 puts the letters of SCORE and BONUS at tile 0x10, and the one at "
     "0x5B7C the digits, the monsters and the bomber from 0x20 on. Everything "
     "from 0x90 up <b>is left over from the title screen</b>, and that is "
     "where the H, D, F, A, M and I needed at the bottom come from"),
    ("animacion.png",
     "<b>Los dieciséis dibujos que cambian con la fase.</b> Cada cuatro fases, "
     "0x4167 saca DOS bloques de la tabla de 0x419B y los carga encima: lo que "
     "cambia es la cara del bicho y poco más. Aquí están las casillas que cada "
     "bloque redefine, dibujadas desde el propio bloque",
     "<b>The sixteen drawings that change with the stage.</b> Every four "
     "stages, 0x4167 takes TWO blocks from the table at 0x419B and loads them "
     "on top: what changes is the monster's face and little else. Here are the "
     "tiles each block redefines, drawn from the block itself"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es el rotulo
    # GRANDE que el propio cartucho pinta en la fila 2 de su portada, recortado
    # de la pantalla que monta pantallas.py. Si el PNG no esta, el trabajo NO
    # esta hecho: se cae al texto, y eso se ve.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Bomber Man">'
                if os.path.exists(ruta_logo) else "<h1>Bomber Man</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

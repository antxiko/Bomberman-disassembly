# Mide EN LA MAQUINA hasta donde tira ladrillos una explosion.
#
# Del listado sale que la llama ALCANZA dos casillas de tablero por lado pero
# solo GASTA los ladrillos de la primera: las dos primeras casillas de cada
# tira usan 0x4B21, que le suma uno al dibujo del ladrillo hasta hacerlo
# desaparecer, y la tercera y la cuarta usan 0x4B5A, que pinta la llama pero se
# vuelve sin escribir si lo que hay es un ladrillo. Eso es lo que se comprueba
# aqui, y no se comprueba mirando: se cuentan ladrillos antes y despues.
#
# El instante y el reparto son los mismos que en tools/omsx_vram.tcl -misma
# maquina, mismos tiempos, misma emulacion determinista-, asi que las dos
# casillas donde se ponen las bombas se eligieron leyendo el tablero de aquel
# volcado:
#
#     bomba A en la casilla (4,0), o sea columna 9 fila 1. Tiene ladrillo
#             PEGADO a la derecha y abajo: los dos tienen que caer.
#     bomba B en la casilla (13,0), columna 27 fila 1. La casilla de al lado
#             esta libre y el ladrillo esta a DOS: tiene que seguir en pie.
#
# Las fichas se escriben a mano en la lista de 0xE359: estado 1, columna, fila
# y cuenta a cero, que es exactamente lo que deja `pon_una_bomba` (0x491C).

set renderer none
set throttle off

set carpeta "work/omsx"

proc vuelca_tablero {num} {
    global carpeta
    set d [debug read_block memory 0xE38A 768]
    set f [open [file join $carpeta "tablero_$num.bin"] w]
    fconfigure $f -translation binary
    puts -nonewline $f $d
    close $f
}

proc espacio {} {
    keymatrixdown 8 0x01
    after time 0.2 {keymatrixup 8 0x01}
}

proc pon_las_bombas {} {
    debug write memory 0xE359 1     ;# ficha 1: encendida
    debug write memory 0xE35A 9     ;# columna
    debug write memory 0xE35B 1     ;# fila
    debug write memory 0xE35C 0     ;# cuenta
    debug write memory 0xE35D 1     ;# ficha 2
    debug write memory 0xE35E 27
    debug write memory 0xE35F 1
    debug write memory 0xE360 0
}

after time 10 espacio
after time 18 {vuelca_tablero antes}
after time 18.1 pon_las_bombas
after time 26 {vuelca_tablero despues}
after time 26.2 exit

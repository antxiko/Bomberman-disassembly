# Comprueba EN LA MAQUINA el modo de bomba automatica.
#
# Del listado sale que en las fases multiplos de cuatro `pon_una_bomba`
# (0x4922) deja de pedir el disparo y `pinta_el_aviso_de_bomba_automatica`
# (0x4D3A) enciende un rotulo con la misma condicion. Aqui se fuerza la fase a
# 4 escribiendo (0xE310) y se vuelca la tabla de nombres cuatro veces seguidas,
# para pillar el rotulo en las dos mitades de su parpadeo: dieciseis cuadros
# puesto y ocho quitado.
#
# Se vuelca la VRAM y NO la pantalla de la RAM: `vuelca_la_pantalla` (0x510E)
# la vuelca y la deja en blanco, asi que en cualquier instante esta a medio
# montar. La tabla de nombres guarda el ultimo cuadro entero.

set renderer none
set throttle off
proc espacio {} { keymatrixdown 8 0x01 ; after time 0.2 {keymatrixup 8 0x01} }
proc guarda {n} {
    set d [debug read_block VRAM 0x1800 768]
    set f [open "work/omsx/nombres_$n.bin" w]
    fconfigure $f -translation binary
    puts -nonewline $f $d
    close $f
}
after time 10 espacio
after time 16 {debug write memory 0xE310 4}
after time 20.0 {guarda a}
after time 20.1 {guarda b}
after time 20.2 {guarda c}
after time 20.3 {guarda d}
after time 20.5 exit

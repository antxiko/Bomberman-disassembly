# Vuelca la VRAM y la RAM de Bomber Man en los instantes que importan.
#
# La portada sale sola desde el encendido. Para entrar en la partida hay que
# pulsar el espacio, y eso aqui se hace con la matriz del teclado -fila 8,
# bit 0-, porque `lee_el_disparo` (0x50FC) usa GTTRIG, que en la entrada 0 es
# justo el espacio.
#
# Instantes:
#     t=8   la portada montada. Antes no vale: la BIOS del VG-8020 tarda mas
#           de cinco segundos en arrancar y llamar a INIT, y a los tres el
#           cartucho ni siquiera ha copiado los valores de partida de la RAM
#     t=10  se pulsa y se suelta el espacio
#     t=18  la partida en marcha, con la fase repartida
#
# De cada uno salen dos ficheros: vram_NN.bin con los 16 KB del VDP tal cual y
# ram_NN.bin con 0xE000..0xE700, que es donde viven LAS DOS pantallas de la
# RAM y las variables. Y un info_NN.txt con el estado, para poder decir contra
# que se compara.
#
# Trampas de la serie respetadas: nada de corchetes dentro de un `format`, el
# binario con -translation binary, y `debug read_block` en vez de
# `debug save_to_file`, que no existe.

set renderer none
set throttle off

set carpeta "work/omsx"

proc vuelca {num} {
    global carpeta
    set d [debug read_block VRAM 0 16384]
    set f [open [file join $carpeta "vram_$num.bin"] w]
    fconfigure $f -translation binary
    puts -nonewline $f $d
    close $f

    set d [debug read_block memory 0xE000 1792]
    set f [open [file join $carpeta "ram_$num.bin"] w]
    fconfigure $f -translation binary
    puts -nonewline $f $d
    close $f

    set f [open [file join $carpeta "info_$num.txt"] w]
    puts $f "tiempo [machine_info time]"
    puts $f "columna_bombero [debug read memory 0xE309]"
    puts $f "fila_bombero [debug read memory 0xE30A]"
    puts $f "estado_bombero [debug read memory 0xE30B]"
    puts $f "fase [debug read memory 0xE310]"
    puts $f "vidas [debug read memory 0xE30F]"
    puts $f "enemigos [debug read memory 0xE313]"
    puts $f "bonus_bajo [debug read memory 0xE30D]"
    puts $f "bonus_alto [debug read memory 0xE30E]"
    puts $f "premio_col [debug read memory 0xE37E]"
    puts $f "premio_fila [debug read memory 0xE37F]"
    puts $f "premio_puesto [debug read memory 0xE380]"
    puts $f "puerta_col [debug read memory 0xE381]"
    puts $f "puerta_fila [debug read memory 0xE382]"
    puts $f "puerta_puesta [debug read memory 0xE383]"
    close $f
}

proc espacio {} {
    keymatrixdown 8 0x01
    after time 0.2 {keymatrixup 8 0x01}
}

after time 8 {vuelca 08}
after time 10 espacio
after time 18 {vuelca 18}
after time 18.2 exit

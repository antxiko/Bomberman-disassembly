; ==========================================================================
; BOMBER MAN - Hudson Soft - MSX1 - cartucho de 8 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: "AB" y la direccion de INIT (0x4004), que cae
;   dentro de la propia cabecera: lo que deberian ser STATEMENT, DEVICE y TEXT
;   ya es codigo
;   0x4000..0x4004  (4 bytes)
DATA_cabecera_del_cartucho:
	defb 041h,042h,004h,040h	; 4000

; ======================================================================
; CODIGO 0x4004..0x4010  (12 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL ARRANQUE, que empieza DENTRO de la cabecera del cartucho.
; La BIOS llama aqui tras encontrar el "AB" de 0x4000. Lo primero es
; la pila, y luego tres llamadas: los valores de partida de la RAM,
; el VDP y el PSG. No vuelve nunca.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
INIT:
	ld sp,0f000h		;4004   ; la pila, arriba del todo de la RAM
	call pon_los_valores_de_partida		;4007   ; las variables del juego, con sus valores de partida
	call monta_el_vdp		;400a   ; los ocho registros del VDP y la pantalla
	call vuelca_la_tabla_del_psg		;400d   ; y el PSG, con la tabla que va aqui detras

; ----------------------------------------------------------------------
; DATOS tabla_del_psg_del_arranque: Cuatro parejas (registro, valor) y el 0xFF
;   que cierra: el registro 7 a 0xA8 -el mezclador- y los tres volumenes a
;   cero. O sea, apagar el sonido al arrancar
;   0x4010..0x4019  (9 bytes)
DATA_tabla_del_psg_del_arranque:
	defb 007h,0a8h	; 4010
	defb 008h,000h	; 4012
	defb 009h,000h	; 4014
	defb 00ah,000h	; 4016
	defb 0ffh	; 4018

; ======================================================================
; CODIGO 0x4019..0x4138  (287 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Sigue AQUI el arranque, detras de la tabla del PSG de 0x4010: es lo
; que hace el `push hl / ret` de 0x405C. Deja el marcador y el record
; a cero y se va a la portada, que es lo unico que ve INIT.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
borra_el_marcador_y_a_la_portada:
	ld hl,00000h		;4019   ; el marcador y el record, a cero
	ld (0e302h),hl		;401c   ; (0xE302), el record
	ld (0e300h),hl		;401f   ; (0xE300), el marcador
	jp la_portada		;4022   ; y a la pantalla de titulo

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Los efectos que duran mas de un cuadro: en vez de llevar la tabla
; incrustada, se guarda por donde va en (0xE305) y (0xE307), una
; pareja de punteros por voz. El 0xFF cierra la tabla igual, pero
; aqui marca el final del CUADRO, no el del guion: el guion se acaba
; cuando el primer byte de un cuadro ya es 0xFF, o sea con un 0xFF
; doble. Se llama una vez por cuadro desde 0x46C8.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
sigue_los_dos_guiones_de_sonido:
	ld iy,0e305h		;4025   ; el primero, en (0xE305)
	call sigue_un_guion_de_sonido		;4029   ; y el mismo codigo otra vez, pero cayendo dentro
	ld iy,0e307h		;402c   ; el segundo, en (0xE307)
sigue_un_guion_de_sonido:
	ld l,(iy+000h)		;4030   ; por donde iba
	ld h,(iy+001h)		;4033
	ld a,(hl)			;4036   ; con 0xFF no queda nada: el guion se ha acabado
	inc a			;4037
	jr z,apunta_donde_se_quedo		;4038   ; y se apunta el puntero sin tocarlo, o sea que se queda ahi
la_pareja_siguiente_del_guion:
	ld d,(hl)			;403a   ; el registro
	ld a,(hl)			;403b   ; el mismo byte otra vez, para poder probarlo
	inc hl			;403c
	inc a			;403d   ; con 0xFF se acaba el CUADRO, no el guion
	jr z,apunta_donde_se_quedo		;403e
	ld e,(hl)			;4040   ; y el valor
	call escribe_en_el_psg		;4041   ; al PSG
	inc hl			;4044   ; a la pareja siguiente
	jr la_pareja_siguiente_del_guion		;4045
apunta_donde_se_quedo:
	ld (iy+000h),l		;4047   ; se apunta por donde se ha quedado, que es el 0xFF o el byte de despues
	ld (iy+001h),h		;404a
	ret			;404d

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA TABLA DE REGISTROS DEL PSG QUE VA DETRAS DEL `call`.
; El `pop hl` no recoge un dato: recoge la DIRECCION DE RETORNO, que
; es donde empieza la tabla, porque la tabla va pegada detras del
; `call`. Se leen parejas (registro, valor) hasta el 0xFF, y el
; `push hl / ret` del final devuelve el control al byte de despues.
; Los tres sitios que la usan estan en el .nocode.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
vuelca_la_tabla_del_psg:
	pop hl			;404e   ; la direccion de retorno ES el puntero a la tabla
	jr lee_el_registro		;404f   ; al primer registro, saltandose el `dec d` de la vuelta
la_pareja_siguiente_de_la_tabla:
	dec d			;4051   ; deshace el `inc d` de la comprobacion
	ld e,(hl)			;4052   ; el valor
	call escribe_en_el_psg		;4053   ; al PSG
	inc hl			;4056   ; a la pareja siguiente
lee_el_registro:
	ld d,(hl)			;4057   ; el registro
	inc hl			;4058
	inc d			;4059   ; con 0xFF se acabo
	jr nz,la_pareja_siguiente_de_la_tabla		;405a
	push hl			;405c   ; y se sigue DETRAS de la tabla
	ret			;405d

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EMPIEZA UNA PARTIDA. Se llega desde la portada, en cuanto se suelta
; el disparo. Pone el marcador a cero, cinco vidas y la fase 1, y
; carga los dos bloques de graficos de la partida ENCIMA de los de la
; portada: el de 0x5B26 mete SCOREBONUS en las casillas 0x10..0x19 y
; el de 0x5B7C la T, la G, los enemigos y el bombero en 0x20..0x5F.
; Lo de 0x90 arriba se queda como estaba, y de ahi salen la H, la D,
; la F, la A, la M y la I que hacen falta abajo.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
empieza_una_partida:
	ld hl,00000h		;405e   ; el marcador a cero; el record NO se toca
	ld (0e300h),hl		;4061
	ld a,001h		;4064   ; la fase 1
	ld (0e310h),a		;4066
	ld a,003h		;4069   ; TRES vidas, no las cinco que dice la tabla de valores de partida
	ld (0e30fh),a		;406b
	call borra_la_pantalla		;406e   ; borra la pantalla de la RAM
	call vuelca_la_pantalla		;4071   ; la vuelca a la VRAM y la deja otra vez en blanco
	ld hl,05b26h		;4074   ; las letras de SCORE y BONUS
	call carga_los_graficos_en_los_tres_tercios		;4077
	ld hl,05b7ch		;407a   ; las cifras, los enemigos y el bombero
	call carga_los_graficos_en_los_tres_tercios		;407d

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; MONTA UNA FASE. Aqui se vuelve tambien despues de cada vida
; perdida, asi que todo lo que sea de la fase y no de la partida se
; pone a cero justo aqui: la puerta, el premio, los avisos y las
; banderas de "ya lo he encontrado".
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
monta_la_fase:
	ld hl,003e8h		;4080   ; el bonus arranca en 1000, y se ensena con cinco cifras
	ld (0e30dh),hl		;4083
	xor a			;4086   ; y todo lo demas de la fase, a cero:
	ld (0e319h),a		;4087   ; el bonus no se ha agotado
	ld (0e318h),a		;408a   ; quedan enemigos
	ld (0e380h),a		;408d   ; el premio no esta puesto
	ld (0e383h),a		;4090   ; ni la puerta
	ld (0e312h),a		;4093   ; el castigo no se ha cobrado
	ld (0e311h),a		;4096   ; ni esta pendiente
	ld (0e314h),a		;4099   ; el premio no esta descubierto
	ld (0e315h),a		;409c   ; ni la puerta
	ld (0e316h),a		;409f   ; no la ha pisado
	ld (0e37bh),a		;40a2   ; y el bombero esta vivo
	ld a,001h		;40a5   ; quieto
	ld (0e30bh),a		;40a7
	call pon_los_enemigos_de_la_fase		;40aa   ; cuantos enemigos y a que ritmo, segun la fase
	call borra_la_lista_de_enemigos		;40ad   ; la lista de enemigos, en blanco
	call reparte_los_enemigos_de_la_fase		;40b0   ; y se reparten los de esta fase por las cuatro esquinas
	call borra_la_lista_de_bombas		;40b3   ; la lista de bombas, en blanco
	call borra_la_pantalla		;40b6   ; la pantalla en blanco
	call vuelca_la_pantalla		;40b9   ; volcada y otra vez en blanco
	call borra_el_tablero		;40bc   ; el tablero tambien, entero a casillas vacias
	call pinta_el_tablero		;40bf   ; el marco y los pilares
	call siembra_la_fase		;40c2   ; y los treinta y cinco ladrillos, con el premio y la puerta debajo
	xor a			;40c5   ; `siembra_la_fase` los deja puestos, y aqui se quitan otra vez:
	ld (0e380h),a		;40c6   ; el premio, tapado
	ld (0e383h),a		;40c9   ; y la puerta. Los redescubren 0x45CE y 0x465A al reventar su ladrillo

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL BUCLE PRINCIPAL, y el indice del juego entero: VEINTE llamadas
; seguidas, una por sistema, en el orden en que se pintan encima
; unas de otras. Primero se cierra el cuadro anterior y se copia el
; tablero encima de la pantalla, luego el marco, y a partir de ahi
; cada cosa deja su rastro en las casillas para que la siguiente lo
; lea: por eso el bombero se pinta ANTES de mirar si le han matado.
; Se sale por tres puertas, que son las tres formas de acabar una
; vida: muerto (0xE37B), puerta pisada (0xE316) o fase limpia
; (0xE318).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
bucle_principal:
	call cierra_el_cuadro		;40cc   ; cierra el cuadro: los contadores, el volcado y el sonido
	call copia_el_tablero_a_la_pantalla		;40cf   ; copia el tablero encima de la pantalla
	call pinta_el_tablero		;40d2   ; el marco y los pilares, que solo viven en la pantalla
	call avanzan_las_bombas		;40d5   ; las bombas avanzan su cuenta atras
	call pinta_las_bombas_y_las_llamas		;40d8   ; y se pintan, con sus llamas
	call pon_una_bomba		;40db   ; mira si hay que poner una bomba
	call avanza_el_bombero		;40de   ; el bombero avanza su paso, o su agonia
	call mueve_los_enemigos		;40e1   ; los enemigos andan
	call pinta_el_premio		;40e4   ; el premio, si esta descubierto
	call pinta_la_puerta		;40e7   ; la puerta, si lo esta
	call pinta_los_enemigos		;40ea   ; los enemigos se pintan
	call descubre_el_premio		;40ed   ; mira si acaba de quedar el premio a la vista
	call descubre_la_puerta		;40f0   ; y lo mismo con la puerta
	call pinta_al_bombero		;40f3   ; el bombero, encima de todo
	call saca_los_enemigos_de_castigo		;40f6   ; los cuatro enemigos de castigo, si tocan
	call pisa_la_puerta_o_el_premio		;40f9   ; mira si pisa la puerta o recoge el premio
	call descuenta_el_bonus		;40fc   ; y el bonus, que baja de diez en diez
	call pinta_las_vidas		;40ff   ; el marcador de arriba
	call pinta_el_marcador		;4102   ; y el rotulo de abajo
	call pinta_el_aviso_de_bomba_automatica		;4105   ; el aviso de bomba automatica, si la fase lo lleva
	ld a,(0e37bh)		;4108   ; muerto?
	or a			;410b
	jp nz,pierde_una_vida		;410c
	ld a,(0e316h)		;410f   ; ha pisado la puerta?
	or a			;4112
	jp nz,sale_por_la_puerta		;4113
	ld a,(0e318h)		;4116   ; no queda ni un enemigo?
	or a			;4119
	jr z,bucle_principal		;411a   ; nada de eso: otro cuadro

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; FASE LIMPIA: no queda ni un enemigo. Veinte cuadros de respiro y a
; cambiar el bonus por puntos, de diez en diez, con un pitido por
; cada diez. Se hace con `un_cuadro_sin_mando`, que es el bucle
; principal sin lo que atiende al jugador: se sigue viendo todo
; moverse pero ya no se manda.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
limpia_la_fase:
	ld bc,00014h		;411c   ; veinte cuadros mirando
otro_cuadro_de_respiro:
	push bc			;411f
	call un_cuadro_sin_mando		;4120   ; un cuadro, sin hacer caso al mando
	pop bc			;4123
	dec bc			;4124
	ld a,b			;4125
	or c			;4126
	jp nz,otro_cuadro_de_respiro		;4127
	ld hl,(0e30dh)		;412a   ; lo que queda de bonus
	ld a,h			;412d
	or l			;412e
	jr z,$+56		;412f   ; si ya es cero, no hay nada que cobrar
cobra_diez_del_bonus:
	push hl			;4131
	call un_cuadro_de_adorno		;4132   ; un cuadro de adorno, mas corto todavia
	call vuelca_la_tabla_del_psg		;4135   ; y el pitido, con la tabla del PSG pegada detras

; ----------------------------------------------------------------------
; DATOS tabla_del_psg_1: Ocho parejas y el 0xFF: el tono de la voz A (0x020A),
;   los volumenes, y el periodo y la forma de la envolvente (0x0002 y 9). Es
;   el pitido de cada diez puntos de bonus
;   0x4138..0x4149  (17 bytes)
DATA_tabla_del_psg_1:
	defb 000h,00ah	; 4138
	defb 001h,002h	; 413a
	defb 008h,010h	; 413c
	defb 009h,000h	; 413e
	defb 00ah,000h	; 4140
	defb 00bh,000h	; 4142
	defb 00ch,002h	; 4144
	defb 00dh,009h	; 4146
	defb 0ffh	; 4148

; ======================================================================
; CODIGO 0x4149..0x419b  (82 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Sigue aqui, detras de la tabla del PSG de 0x4138. Diez menos de
; bonus y uno mas de marcador; como el marcador se ensena
; multiplicado por diez, cada vuelta son diez puntos de verdad.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
L_4149:
	pop hl			;4149   ; recupera el puntero que dejo el `push hl`
	ld bc,0000ah		;414a   ; diez menos de bonus
	or a			;414d
	sbc hl,bc		;414e
	ld (0e30dh),hl		;4150
	ld de,(0e300h)		;4153   ; y uno mas de marcador, que en pantalla son diez
	inc de			;4157
	ld (0e300h),de		;4158
	ld a,h			;415c   ; queda bonus?
	or l			;415d
	jp nz,cobra_diez_del_bonus		;415e
	call un_cuadro_de_adorno		;4161   ; dos cuadros mas y a la fase siguiente
	call un_cuadro_de_adorno		;4164

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; A LA FASE SIGUIENTE, y de paso a los dibujos que le tocan. La tabla
; de 0x419B tiene DIECISEIS punteros a bloques de graficos, y de ahi
; se sacan DOS por fase: el `and 003h` decide si se lee la primera
; mitad de la tabla o la segunda, y el `and 00Ch` cual de las cuatro
; parejas. Las cuatro primeras fases no cambian nada, que es lo que
; dice el `and 0FCh`.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
a_la_fase_siguiente:
	ld a,(0e310h)		;4167   ; una fase mas
	inc a			;416a
	ld (0e310h),a		;416b
	push af			;416e
	and 003h		;416f   ; cada cuatro fases
	ld hl,0419bh		;4171   ; la primera mitad de la tabla
	call z,la_otra_mitad_de_la_tabla		;4174   ; o la segunda, que es lo que hace 0x4197
	pop af			;4177
	and 0fch		;4178   ; las cuatro primeras fases se juegan con los mismos dibujos
	jp z,monta_la_fase		;417a
	and 00ch		;417d   ; cual de las cuatro parejas
	ld c,a			;417f
	ld b,000h		;4180
	add hl,bc			;4182
	ld e,(hl)			;4183   ; el primer bloque de la pareja
	inc hl			;4184
	ld d,(hl)			;4185
	inc hl			;4186
	push hl			;4187
	ex de,hl			;4188
	call carga_los_graficos_en_los_tres_tercios		;4189   ; cargado en los tres tercios
	pop hl			;418c
	ld e,(hl)			;418d   ; y el segundo
	inc hl			;418e
	ld d,(hl)			;418f
	ex de,hl			;4190
	call carga_los_graficos_en_los_tres_tercios		;4191
	jp monta_la_fase		;4194   ; a montar la fase, sin tocar vidas ni marcador
la_otra_mitad_de_la_tabla:
	ld hl,041abh		;4197   ; la segunda mitad de la tabla de punteros
	ret			;419a

; ----------------------------------------------------------------------
; DATOS punteros_de_los_dibujos: Dieciseis palabras, todas dentro de
;   0x5E38..0x5F9A. 0x4171 las indexa con el numero de fase: la mitad de
;   arriba o la de abajo segun `and 003h`, y la pareja segun `and 00Ch`
;   0x419b..0x41bb  (32 bytes)
DATA_punteros_de_los_dibujos:
	defw 05ec6h,05edeh,05e4eh,05e38h,05f54h,05f6eh,05f20h,05f38h	; 419b
	defw 05e9ah,05eb0h,05e6ch,05e84h,05f84h,05f9ah,05ef4h,05f0ah	; 41ab

; ======================================================================
; CODIGO 0x41bb..0x41d0  (21 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; HA PISADO LA PUERTA. Diez cuadros de fanfarria -el guion de sonido
; de 0x41D0, que sube el tono de la voz B- y a la fase siguiente.
; No se cobra el bonus: eso solo pasa limpiando la fase.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
sale_por_la_puerta:
	ld b,00ah		;41bb   ; diez vueltas
	ld hl,041d0h		;41bd   ; la fanfarria, en la voz B
	ld (0e307h),hl		;41c0
otro_cuadro_de_fanfarria:
	push bc			;41c3
	ld hl,00fa0h		;41c4   ; el argumento no lo usa nadie: `un_cuadro_sin_mando` no toca HL
	call un_cuadro_sin_mando		;41c7   ; un cuadro mirando
	pop bc			;41ca
	djnz otro_cuadro_de_fanfarria		;41cb
	jp monta_la_fase		;41cd   ; y a la fase siguiente

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_de_la_puerta: Ocho cuadros de parejas (registro,
;   valor) separados por 0xFF y cerrados por un 0xFF doble; lo instala 0x41BD
;   en (0xE307). Sube el tono de la voz B de 0xEE a 0x7E y apaga la voz C
;   0x41d0..0x41eb  (27 bytes)
DATA_guion_de_sonido_de_la_puerta:
	defb 004h,0eeh,00ah,00ch,0ffh,004h,0d4h,0ffh,004h,0bdh,0ffh,004h,0b2h,0ffh,004h,09fh	; 41d0  ................
	defb 0ffh,004h,08eh,0ffh,004h,07eh,0ffh,00ah,000h,0ffh,0ffh	; 41e0  .....~.....

; ======================================================================
; CODIGO 0x41eb..0x4217  (44 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; HA MUERTO. Una espera larga -0x5000 vueltas en vacio- y una vida
; menos. Si quedan, se vuelve a montar la fase entera: los ladrillos
; se sortean otra vez, y con ellos la puerta y el premio.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pierde_una_vida:
	call espera_larga		;41eb   ; una espera larga, para que se vea la agonia
	ld a,(0e30fh)		;41ee   ; una vida menos
	dec a			;41f1
	or a			;41f2
	ld (0e30fh),a		;41f3
	jr z,$+43		;41f6   ; si no quedan, se acabo la partida
	jp monta_la_fase		;41f8   ; y si quedan, la misma fase desde el principio

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; CUANTOS ENEMIGOS Y A QUE RITMO, segun la fase, de la tabla de
; 0x4217. De la sexta en adelante todas juegan con lo mismo, que es
; lo que dice el `cp 006h`.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pon_los_enemigos_de_la_fase:
	ld a,(0e310h)		;41fb   ; la fase
	cp 006h		;41fe   ; de la sexta en adelante
	jr c,la_linea_de_la_fase		;4200
	ld a,005h		;4202   ; se juega con la quinta linea de la tabla
la_linea_de_la_fase:
	dec a			;4204   ; la primera fase es la linea 0
	add a,a			;4205   ; dos bytes por linea
	ld hl,04217h		;4206
	ld c,a			;4209
	ld b,000h		;420a
	add hl,bc			;420c
	ld a,(hl)			;420d
	ld (0e313h),a		;420e   ; cuantos enemigos
	inc hl			;4211
	ld a,(hl)			;4212
	ld (0e317h),a		;4213   ; y su cadencia
	ret			;4216

; ----------------------------------------------------------------------
; DATOS enemigos_por_fase: Cinco parejas (cuantos enemigos, cadencia) que lee
;   0x41FB con la fase menos uno: 1 y 0x10, 2 y 0x15, 3 y 0x1A, 2 y 0x1F, 4 y
;   0x24. La cuarta fase tiene MENOS enemigos que la tercera, pero mas lentos
;   0x4217..0x4221  (10 bytes)
DATA_enemigos_por_fase:
	defb 001h,010h	; 4217
	defb 002h,015h	; 4219
	defb 003h,01ah	; 421b
	defb 002h,01fh	; 421d
	defb 004h,024h	; 421f

; ======================================================================
; CODIGO 0x4221..0x4323  (258 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; SE ACABO LA PARTIDA. Cinco cuadros mas para que se vea el ultimo
; golpe y a la portada. El marcador NO se borra aqui: lo borra
; 0x4019 al empezar la siguiente, y por eso la portada sigue
; ensenando lo que se hizo.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
fin_de_la_partida:
	ld bc,00005h		;4221   ; cinco cuadros
otro_cuadro_de_final:
	push bc			;4224
	call un_cuadro_sin_mando		;4225   ; sin hacer caso al mando
	pop bc			;4228
	dec bc			;4229
	ld a,b			;422a
	or c			;422b
	jr nz,otro_cuadro_de_final		;422c
	jp la_portada		;422e   ; y a la portada

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UN CUADRO SIN MANDO: el bucle principal recortado. Faltan las
; llamadas que leen el mando o cambian de fase -poner bombas, mover
; al bombero, el bonus, la puerta-, asi que todo se sigue viendo
; moverse pero ya no se puede jugar. Es lo que se usa en las
; celebraciones y en el fin de partida.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
un_cuadro_sin_mando:
	call cierra_el_cuadro		;4231   ; cierra el cuadro anterior
	call copia_el_tablero_a_la_pantalla		;4234   ; el tablero encima de la pantalla
	call pinta_el_tablero		;4237   ; el marco
	call pinta_las_bombas_y_las_llamas		;423a   ; las bombas y sus llamas
	call pinta_el_premio		;423d   ; el premio
	call pinta_la_puerta		;4240   ; la puerta
	call pinta_los_enemigos		;4243   ; los enemigos
	call pinta_al_bombero		;4246   ; el bombero
	call avanzan_las_bombas		;4249   ; las bombas avanzan
	call pinta_las_vidas		;424c   ; el marcador
	call pinta_el_marcador		;424f   ; y el rotulo de abajo
	ret			;4252

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UN CUADRO DE ADORNO: lo mismo, pero sin enemigos y sin que las
; bombas avancen. Es el que se usa mientras se cobra el bonus, para
; que la pantalla no se quede congelada pero tampoco pase nada.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
un_cuadro_de_adorno:
	call cierra_el_cuadro		;4253   ; cierra el cuadro anterior
	call copia_el_tablero_a_la_pantalla		;4256   ; el tablero encima de la pantalla
	call pinta_el_tablero		;4259   ; el marco
	call pinta_el_premio		;425c   ; el premio
	call pinta_la_puerta		;425f   ; la puerta
	call pinta_al_bombero		;4262   ; el bombero
	call pinta_las_vidas		;4265   ; el marcador
	call pinta_el_marcador		;4268   ; y el rotulo de abajo
	ret			;426b

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL DISPARO DE LA PORTADA. Se llama con A = lo que se acaba de leer
; y HL apuntando a (0xE304), que es lo que se leyo la vez anterior.
; Guarda lo nuevo; si no hay nada pulsado, se vuelve. Y si lo hay,
; se espera A QUE SE SUELTE y entonces se hace `pop hl` para tirar
; la direccion de retorno y saltar a la partida sin volver.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
mira_el_disparo_de_la_portada:
	ld (hl),a			;426c   ; apunta lo que se acaba de leer
	or a			;426d   ; si no hay nada pulsado, a seguir en la portada
	ret z			;426e
	call lee_el_disparo		;426f   ; y si lo hay, se espera a que lo suelte
	or a			;4272
	jr nz,mira_el_disparo_de_la_portada		;4273
	pop hl			;4275   ; tira la direccion de retorno: de aqui no se vuelve
	jp empieza_una_partida		;4276   ; y a jugar

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA PORTADA. Carga el bloque grande de graficos -las 256 casillas
; de 0x514C, que traen la fuente y el rotulo GRANDE- y deja puestos
; un enemigo y una bomba de muestra. El 0xFF de (0xE304) es para que
; la primera lectura del disparo no cuente como pulsacion.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
la_portada:
	call borra_la_pantalla		;4279   ; pantalla en blanco
	call vuelca_la_pantalla		;427c   ; volcada y en blanco otra vez
	ld hl,0514ch		;427f   ; las 256 casillas de la portada
	call carga_los_graficos_en_los_tres_tercios		;4282
	call pon_el_enemigo_del_titulo		;4285   ; un enemigo de muestra, en la fila 7
	call pon_la_bomba_del_titulo		;4288   ; y una bomba, en la fila 10
	ld a,0ffh		;428b   ; nada leido todavia: 0xFF no lo devuelve nunca `lee_el_disparo`
	ld (0e304h),a		;428d

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL BUCLE DE LA PORTADA. Se repinta entera cada cuadro, de arriba
; abajo: seis filas de ladrillo, el rotulo grande encima, los
; diecinueve rotulos pequenos, el marcador y el record, y el
; bombero, el premio y la puerta de muestra. Los enemigos y las
; bombas se PINTAN pero no se mueven: aqui no se llama a lo que los
; hace avanzar, asi que se quedan parpadeando en el sitio.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
bucle_de_la_portada:
	call lee_el_disparo		;4290   ; el disparo
	ld hl,0e304h		;4293   ; contra lo que se leyo la vez anterior
	cp (hl)			;4296
	call nz,mira_el_disparo_de_la_portada		;4297   ; si ha cambiado, a ver si toca empezar
	call cierra_el_cuadro		;429a   ; cierra el cuadro
	ld bc,0e000h		;429d   ; las seis filas de arriba
	ld d,0c0h		;42a0   ; 0xC0 casillas, o sea seis filas
	ld e,089h		;42a2   ; de ladrillo
otra_casilla_de_ladrillo:
	ld a,e			;42a4
	ld (bc),a			;42a5
	inc bc			;42a6
	dec d			;42a7   ; hasta acabar las seis filas
	jr nz,otra_casilla_de_ladrillo		;42a8
	ld hl,0446eh		;42aa   ; la tira del rotulo grande
pinta_el_rotulo_grande:
	ld a,(hl)			;42ad   ; con 0xFF se acabo
	inc a			;42ae
	jr z,L_42C5		;42af
	dec a			;42b1
	ld e,a			;42b2   ; la casilla de arriba a la izquierda
	inc hl			;42b3
	ld b,(hl)			;42b4   ; la fila
	inc hl			;42b5
	ld c,(hl)			;42b6   ; y la columna
	inc hl			;42b7
	call pon_el_cursor		;42b8   ; pone el cursor
	ld a,e			;42bb
	push hl			;42bc
	push de			;42bd
	call pinta_cuatro_casillas		;42be   ; y suelta las cuatro casillas
	pop de			;42c1
	pop hl			;42c2
	jr pinta_el_rotulo_grande		;42c3
L_42C5:
	ld hl,04323h		;42c5   ; los diecinueve rotulos de 0x4323
	call pinta_una_tira_de_rotulos		;42c8
	ld bc,0e216h		;42cb   ; el record, en la fila 8
	ld hl,(0e302h)		;42ce
	call escribe_cinco_cifras_y_un_cero		;42d1
	ld bc,0e256h		;42d4   ; y el marcador, en la fila 9
	ld hl,(0e300h)		;42d7
	call escribe_cinco_cifras_y_un_cero		;42da
	ld bc,0e0e1h		;42dd   ; el bombero de muestra, fila 7 columna 1
	ld a,08ch		;42e0
	call pinta_cuatro_casillas		;42e2
	call pinta_las_bombas_y_las_llamas		;42e5   ; la bomba, que solo se pinta
	call pinta_los_enemigos		;42e8   ; y el enemigo, igual
	ld a,(0e36fh)		;42eb   ; cada cuatro cuadros
	or a			;42ee
	jr nz,pinta_el_premio_y_la_puerta_de_muestra		;42ef
	ld a,(0e36eh)		;42f1   ; cambia el paso de la bomba
	xor 002h		;42f4
	ld (0e36eh),a		;42f6
	ld a,(0e358h)		;42f9   ; y el del enemigo
	xor 002h		;42fc
	ld (0e358h),a		;42fe
pinta_el_premio_y_la_puerta_de_muestra:
	ld bc,0e0f1h		;4301   ; el premio, fila 7 columna 17
	ld a,00ah		;4304
	call pinta_cuatro_casillas		;4306
	ld bc,0e0f9h		;4309   ; y la puerta, fila 7 columna 25
	ld a,00eh		;430c
	call pinta_cuatro_casillas		;430e
	jp bucle_de_la_portada		;4311   ; otro cuadro

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Pinta una tira de rotulos: por cada uno, la fila y la columna y
; luego el texto cerrado por 0x00. La tira entera acaba en 0xFF.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_una_tira_de_rotulos:
	ld a,(hl)			;4314   ; con 0xFF se acabo la tira
	inc a			;4315
	ret z			;4316
	ld b,(hl)			;4317   ; la fila
	inc hl			;4318
	ld c,(hl)			;4319   ; y la columna
	inc hl			;431a
	call pon_el_cursor		;431b   ; pone el cursor
	call suelta_un_texto		;431e   ; y suelta el texto hasta el 0x00
	jr pinta_una_tira_de_rotulos		;4321   ; y a por el rotulo siguiente

; ----------------------------------------------------------------------
; DATOS rotulos_de_la_pantalla_de_titulo: Diecinueve rotulos (fila, columna,
;   texto cerrado por 0x00) y el 0xFF que cierra la tira. Dibujados desde la
;   ROM dicen: BOMBER MAN, 200-10, BONUS ?PTS, EXIT, el mando con
;   UP/DOWN/LEFT/RIGHT y BOMB/SPACE, HUDSON SOFT 1983, HI-SCORE y SCORE,
;   PROGRAMMER:Y.TANAKA y T.SASAGAWA, y PUSH SPACE-KEY OR TORIGER, con la
;   errata incluida
;   0x4323..0x4442  (287 bytes)
DATA_rotulos_de_la_pantalla_de_titulo:
	defb 00ah,005h,055h,050h,000h,00ah,017h,048h,055h,044h,053h,04fh,04eh,000h,00bh,005h	; 4323  ..UP...HUDSON...
	defb 010h,014h,011h,000h,00bh,010h,042h,04fh,04dh,042h,000h,00ch,005h,015h,00ch,016h	; 4333  ......BOMB......
	defb 000h,00ch,00eh,010h,014h,014h,014h,014h,014h,011h,020h,020h,020h,053h,04fh,046h	; 4343  ..........   SOF
	defb 054h,000h,00dh,001h,04ch,045h,046h,054h,012h,014h,013h,052h,049h,047h,048h,054h	; 4353  T...LEFT...RIGHT
	defb 020h,015h,053h,050h,041h,043h,045h,016h,000h,00eh,002h,010h,014h,011h,020h,020h	; 4363   .SPACE.......  
	defb 020h,010h,014h,011h,020h,020h,020h,012h,014h,014h,014h,014h,014h,013h,020h,020h	; 4373   ...   .......  
	defb 020h,001h,009h,008h,003h,000h,00fh,002h,015h,01dh,016h,020h,020h,020h,015h,00dh	; 4383   ..........   ..
	defb 016h,000h,010h,002h,012h,014h,013h,020h,020h,020h,012h,014h,013h,020h,020h,048h	; 4393  .......   ...  H
	defb 049h,040h,053h,043h,04fh,052h,045h,021h,000h,011h,005h,010h,014h,011h,000h,012h	; 43a3  I@SCORE!........
	defb 005h,015h,01ch,016h,000h,012h,010h,053h,043h,04fh,052h,045h,021h,000h,013h,005h	; 43b3  .......SCORE!...
	defb 012h,014h,013h,000h,014h,004h,044h,04fh,057h,04eh,020h,020h,050h,052h,04fh,047h	; 43c3  ......DOWN  PROG
	defb 052h,041h,04dh,04dh,045h,052h,021h,059h,019h,054h,041h,04eh,041h,04bh,041h,000h	; 43d3  RAMMER!Y.TANAKA.
	defb 017h,003h,050h,055h,053h,048h,020h,053h,050h,041h,043h,045h,040h,04bh,045h,059h	; 43e3  ..PUSH SPACE@KEY
	defb 020h,04fh,052h,020h,054h,04fh,052h,049h,047h,045h,052h,000h,015h,015h,054h,019h	; 43f3   OR TORIGER...T.
	defb 053h,041h,053h,041h,047h,041h,057h,041h,000h,007h,003h,042h,04fh,04dh,042h,045h	; 4403  SASAGAWA...BOMBE
	defb 052h,020h,020h,020h,002h,030h,030h,040h,020h,020h,020h,042h,04fh,04eh,055h,053h	; 4413  R   .00@   BONUS
	defb 020h,020h,020h,045h,058h,049h,054h,000h,008h,005h,04dh,041h,04eh,020h,020h,020h	; 4423     EXIT...MAN   
	defb 020h,020h,001h,030h,020h,020h,020h,020h,020h,031h,050h,054h,053h,000h,0ffh	; 4433    .0     1PTS..

; ======================================================================
; CODIGO 0x4442..0x446e  (44 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; La bomba de muestra de la portada: la primera ficha de la lista,
; encendida, en la fila 10 columna 14.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pon_la_bomba_del_titulo:
	call borra_la_lista_de_bombas		;4442   ; la lista, en blanco
	ld ix,0e359h		;4445   ; la primera ficha
	ld (ix+000h),001h		;4449   ; encendida
	ld (ix+001h),00eh		;444d   ; columna 14
	ld (ix+002h),00ah		;4451   ; fila 10
	ret			;4455

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Y el enemigo de muestra: la primera ficha de la lista de enemigos,
; viva, en la fila 7 columna 10, con el cuadro de dibujo 1.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pon_el_enemigo_del_titulo:
	call borra_la_lista_de_enemigos		;4456   ; la lista, en blanco
	ld ix,0e31ch		;4459   ; la primera ficha
	ld (ix+000h),001h		;445d   ; viva
	ld (ix+001h),00ah		;4461   ; columna 10
	ld (ix+002h),007h		;4465   ; fila 7
	ld (ix+003h),001h		;4469   ; y el cuadro de dibujo
	ret			;446d

; ----------------------------------------------------------------------
; DATOS rotulo_grande_de_la_portada: Nueve ternas (casilla, fila, columna) y
;   el 0xFF que cierra, que lee 0x42AD. Cada casilla se pinta con sus tres
;   vecinas, o sea una letra de dos por dos: 0x22 B, 0x24 O, 0x26 M, 0x22 B,
;   0x28 E, 0x2A R y luego 0x26 M, 0x2C A, 0x2E N. Es el rotulo BOMBER MAN
;   grande de la fila 2, y las casillas que usa son las mismas que en la
;   partida son el enemigo reventando
;   0x446e..0x448a  (28 bytes)
DATA_rotulo_grande_de_la_portada:
	defb 022h,002h,002h	; 446e
	defb 024h,002h,005h	; 4471
	defb 026h,002h,008h	; 4474
	defb 022h,002h,00bh	; 4477
	defb 028h,002h,00eh	; 447a
	defb 02ah,002h,011h	; 447d
	defb 026h,002h,016h	; 4480
	defb 02ch,002h,019h	; 4483
	defb 02eh,002h,01ch	; 4486
	defb 0ffh	; 4489

; ======================================================================
; CODIGO 0x448a..0x450f  (133 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL BONUS, que baja de diez en diez cada cincuenta cuadros. Cuando
; llega a cero no pasa nada bueno: se BORRA EL TABLERO ENTERO. Los
; treinta y cinco ladrillos, el premio y la puerta desaparecen de
; golpe, y con las dos banderas de "ya esta descubierto" puestas a
; uno ya no se vuelven a buscar. La fase se queda sin salida y solo
; se puede terminar matandolos a todos.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
descuenta_el_bonus:
	ld a,(0e379h)		;448a   ; la cuenta de cincuenta cuadros
	or a			;448d
	ret nz			;448e
	ld hl,(0e30dh)		;448f   ; lo que queda
	ld a,h			;4492   ; si ya es cero, se acabo
	or l			;4493
	jr z,se_agoto_el_bonus		;4494
	ld bc,0000ah		;4496   ; y si no, diez menos
	sbc hl,bc		;4499   ; el `or a` de dos lineas antes ha dejado el acarreo a cero
	ld (0e30dh),hl		;449b
	ret			;449e
se_agoto_el_bonus:
	ld a,(0e319h)		;449f   ; esto solo pasa una vez
	or a			;44a2
	ret nz			;44a3
	call borra_el_tablero		;44a4   ; el tablero entero a casillas vacias: adios ladrillos
	ld a,001h		;44a7   ; y apuntado, para no repetirlo
	ld (0e319h),a		;44a9
	xor a			;44ac   ; la puerta, quitada
	ld (0e383h),a		;44ad
	ld (0e380h),a		;44b0   ; y el premio
	ld a,001h		;44b3   ; pero marcados como YA descubiertos
	ld (0e314h),a		;44b5
	ld (0e315h),a		;44b8   ; para que 0x45CE y 0x465A no vuelvan a buscarlos
	xor a			;44bb
	ld (0e37fh),a		;44bc   ; y las dos coordenadas que quedaban, a cero
	ld (0e381h),a		;44bf
	ret			;44c2

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; MIRA SI PISA LA PUERTA O RECOGE EL PREMIO. Las dos cosas se hacen
; comparando la casilla del bombero con la de cada una, no leyendo
; lo que hay pintado. La puerta acaba la fase; el premio da entre
; 0x10 y 0x7E de marcador -o sea entre 160 y 1260 puntos- sorteados
; al azar, siempre pares y siempre con el bit 4 puesto.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pisa_la_puerta_o_el_premio:
	ld bc,(0e309h)		;44c3   ; C la columna del bombero y B su fila
	ld a,(0e383h)		;44c7   ; la puerta esta puesta?
	or a			;44ca
	jr z,mira_si_recoge_el_premio		;44cb
	ld a,(0e382h)		;44cd   ; su fila
	cp b			;44d0
	jr nz,mira_si_recoge_el_premio		;44d1
	ld a,(0e381h)		;44d3   ; y su columna
	cp c			;44d6
	jr nz,mira_si_recoge_el_premio		;44d7
	xor a			;44d9   ; la puerta se apaga
	ld (0e383h),a		;44da
	ld a,001h		;44dd   ; y se apunta que hay que cambiar de fase
	ld (0e316h),a		;44df
	ret			;44e2
mira_si_recoge_el_premio:
	ld a,(0e380h)		;44e3   ; el premio esta puesto?
	or a			;44e6
	ret z			;44e7
	ld a,(0e37fh)		;44e8   ; su fila
	cp b			;44eb
	ret nz			;44ec
	ld a,(0e37eh)		;44ed   ; y su columna
	cp c			;44f0
	ret nz			;44f1
	xor a			;44f2   ; recogido
	ld (0e380h),a		;44f3
	call numero_al_azar		;44f6   ; un numero al azar
	and 03fh		;44f9   ; entre 0x10 y 0x7E, par: en pantalla, entre 160 y 1260 puntos
	add a,a			;44fb
	set 4,a		;44fc
	ld c,a			;44fe
	ld b,000h		;44ff
	ld hl,(0e300h)		;4501   ; al marcador
	add hl,bc			;4504
	ld (0e300h),hl		;4505
	ld hl,0450fh		;4508   ; y el sonidito de recoger, en la voz A
	ld (0e305h),hl		;450b
	ret			;450e

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_del_premio: Lo instala 0x4508 en (0xE305) al recoger
;   el premio: nueve cuadros bajando el tono de la voz A de 0xD4 a 0x8E y el
;   volumen con ellos, cerrado por un 0xFF doble
;   0x450f..0x453b  (44 bytes)
DATA_guion_de_sonido_del_premio:
	defb 000h,0d4h,008h,00dh,0ffh,000h,0d4h,008h,009h,0ffh,001h,000h,000h,0b2h,001h,000h	; 450f  ................
	defb 008h,00ch,0ffh,000h,0b2h,001h,000h,008h,007h,0ffh,000h,08eh,001h,000h,008h,00ch	; 451f  ................
	defb 0ffh,000h,08eh,001h,000h,008h,006h,0ffh,008h,000h,0ffh,0ffh	; 452f  ............

; ======================================================================
; CODIGO 0x453b..0x45c6  (139 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS CUATRO ENEMIGOS DE CASTIGO. Si una llama alcanza al premio o
; a la puerta, salen CUATRO enemigos mas por donde estaban. Lo
; apunta 0x461E -o 0x463C- poniendo (0xE311) y la coordenada, y
; aqui se espera a que esa casilla quede libre para meterlos: si
; sigue habiendo llama, no se hace nada y se vuelve el cuadro
; siguiente.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
saca_los_enemigos_de_castigo:
	ld a,(0e311h)		;453b   ; hay castigo pendiente?
	or a			;453e
	ret z			;453f
	ld a,(0e312h)		;4540   ; y no cobrado ya
	or a			;4543
	ret nz			;4544
	ld bc,(0e31ah)		;4545   ; la casilla donde estaba lo que reventaron
	call pon_el_cursor_en_el_tablero		;4549   ; en el tablero
	call estan_libres_las_cuatro		;454c   ; tiene que estar limpia: si aun hay llama, se espera
	cp 020h		;454f
	ret nz			;4551
	ld a,(0e313h)		;4552   ; cuatro enemigos mas vivos
	add a,004h		;4555
	ld (0e313h),a		;4557
	ld ix,0e31ch		;455a   ; la lista, y cuatro por poner
	ld d,004h		;455e
busca_una_ficha_libre:
	ld a,(ix+000h)		;4560   ; el final de la lista
	inc a			;4563
	jr z,castigo_cobrado		;4564
	dec a			;4566   ; esta ficha esta libre?
	jr nz,a_la_ficha_siguiente_del_castigo		;4567
	ld (ix+000h),001h		;4569   ; pues se ocupa
	ld a,(0e31ah)		;456d   ; con la columna
	ld (ix+001h),a		;4570
	ld a,(0e31bh)		;4573   ; y la fila del castigo
	ld (ix+002h),a		;4576
	dec d			;4579   ; puestos los cuatro
	jr z,castigo_cobrado		;457a
a_la_ficha_siguiente_del_castigo:
	ld bc,00007h		;457c   ; siete bytes por ficha
	add ix,bc		;457f
	jr busca_una_ficha_libre		;4581
castigo_cobrado:
	ld a,001h		;4583   ; castigo cobrado: no se repite
	ld (0e312h),a		;4585
	ret			;4588

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Vacia la lista de enemigos: pone a cero el primer byte de cada
; ficha hasta el 0xFF que la cierra. Las otras seis columnas se
; quedan como estaban, porque solo cuenta la primera.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
borra_la_lista_de_enemigos:
	ld ix,0e31ch		;4589   ; la lista, ocho fichas de siete bytes
borra_una_ficha_de_enemigo:
	ld a,(ix+000h)		;458d   ; con 0xFF se acaba la lista
	inc a			;4590
	ret z			;4591
	ld (ix+000h),000h		;4592   ; ficha libre
	ld bc,00007h		;4596   ; siete bytes a la siguiente
	add ix,bc		;4599
	jr borra_una_ficha_de_enemigo		;459b

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; REPARTE LOS ENEMIGOS DE LA FASE por las cuatro esquinas, una al
; azar por cada uno. No mira si la esquina ya esta ocupada, asi que
; dos enemigos pueden salir encima del otro; se separan solos en
; cuanto empiezan a andar.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
reparte_los_enemigos_de_la_fase:
	ld a,(0e313h)		;459d   ; cuantos toca poner
	ld b,a			;45a0
	ld ix,0e31ch		;45a1   ; la primera ficha
reparte_un_enemigo:
	ld hl,045c6h		;45a5   ; las cuatro esquinas
	call numero_al_azar		;45a8   ; una al azar
	and 003h		;45ab   ; de las cuatro
	add a,a			;45ad   ; dos bytes por esquina
	add a,l			;45ae
	ld l,a			;45af
	ld a,(hl)			;45b0   ; la columna
	ld (ix+001h),a		;45b1
	inc hl			;45b4
	ld a,(hl)			;45b5   ; y la fila
	ld (ix+002h),a		;45b6
	ld (ix+000h),001h		;45b9   ; vivo
	ld de,00007h		;45bd   ; siete bytes a la ficha siguiente
	add ix,de		;45c0
	dec b			;45c2   ; hasta ponerlos todos
	jr nz,reparte_un_enemigo		;45c3
	ret			;45c5

; ----------------------------------------------------------------------
; DATOS esquinas_de_salida: Las cuatro esquinas del tablero en parejas
;   (columna, fila), que sortea 0x45A8: (1,1), (29,1), (1,19) y (29,19). Son
;   las cuatro casillas de dos por dos de las puntas, dentro del marco
;   0x45c6..0x45ce  (8 bytes)
DATA_esquinas_de_salida:
	defb 001h,001h	; 45c6
	defb 01dh,001h	; 45c8
	defb 001h,013h	; 45ca
	defb 01dh,013h	; 45cc

; ======================================================================
; CODIGO 0x45ce..0x481d  (591 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; DESCUBRE EL PREMIO. Se mira cada cuadro hasta que sale: cuando
; las cuatro casillas donde esta escondido quedan vacias EN LAS DOS
; PANTALLAS -en el tablero, o sea que el ladrillo ya reventó, y en
; la pantalla, o sea que ahora mismo no hay nadie encima- se
; enciende y ya no se vuelve a mirar.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
descubre_el_premio:
	ld a,(0e314h)		;45ce   ; ya esta a la vista?
	or a			;45d1
	ret nz			;45d2
	ld bc,(0e37eh)		;45d3   ; su columna y su fila
	ld d,b			;45d7   ; guardadas, que `pon_el_cursor` machaca BC
	ld e,c			;45d8
	call pon_el_cursor_en_el_tablero		;45d9   ; en el tablero
	call estan_libres_las_cuatro		;45dc   ; las cuatro casillas libres?
	cp 020h		;45df
	ret nz			;45e1
	ld b,d			;45e2   ; y ahora en la pantalla
	ld c,e			;45e3
	call pon_el_cursor		;45e4
	call estan_libres_las_cuatro		;45e7   ; tambien: nada encima
	cp 020h		;45ea
	ret nz			;45ec
	ld a,001h		;45ed   ; premio a la vista
	ld (0e380h),a		;45ef
	ld (0e314h),a		;45f2   ; y no se vuelve a mirar
	ret			;45f5

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; PINTA EL PREMIO, cuatro casillas: 0x0A y 0x0B arriba, 0x1A y 0x1B
; abajo. El `add a,00fh` del medio es lo que salta de 0x0B a 0x1A,
; o sea una fila entera de la hoja de casillas.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_el_premio:
	ld a,(0e380h)		;45f6   ; esta puesto?
	or a			;45f9
	ret z			;45fa
	ld de,(0e37eh)		;45fb   ; columna y fila
	ld b,d			;45ff
	ld c,e			;4600
	call pon_el_cursor		;4601   ; el cursor, en la PANTALLA
	ld a,00ah		;4604   ; arriba a la izquierda
	call pinta_una_casilla_del_premio		;4606
	inc bc			;4609   ; arriba a la derecha
	inc a			;460a
	call pinta_una_casilla_del_premio		;460b
	ld hl,0001fh		;460e   ; una fila mas abajo, misma columna
	add hl,bc			;4611
	ld b,h			;4612
	ld c,l			;4613
	add a,00fh		;4614   ; y las dos casillas de abajo, 0x1A y 0x1B
	call pinta_una_casilla_del_premio		;4616
	inc bc			;4619
	inc a			;461a
	jp pinta_una_casilla_del_premio		;461b   ; la ultima, y se vuelve desde ahi

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Pinta una casilla del premio Y MIRA LO QUE HABIA DEBAJO. Si era
; una llama (0xE0 para arriba) el premio se destruye, y ahi empieza
; el castigo: se apunta su sitio en (0xE31A) y (0xE31B) y se pide
; que salgan cuatro enemigos.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_una_casilla_del_premio:
	push af			;461e
	ld a,(bc)			;461f   ; lo que ya habia ahi
	cp 0e0h		;4620   ; una llama?
	jr c,escribe_la_casilla_del_premio		;4622
	xor a			;4624   ; el premio se ha ido
	ld (0e380h),a		;4625
	ld a,(0e37eh)		;4628   ; su columna
	ld (0e31ah),a		;462b   ; como sitio del castigo
	ld a,(0e37fh)		;462e   ; y su fila
	ld (0e31bh),a		;4631
	ld a,001h		;4634   ; castigo pendiente
	ld (0e311h),a		;4636
escribe_la_casilla_del_premio:
	pop af			;4639
	ld (bc),a			;463a   ; y la casilla se pinta igual
	ret			;463b

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Lo mismo con la puerta: si le entra una llama, se apaga y salen
; cuatro enemigos por donde estaba. La fase no se queda sin salida:
; 0x465A la vuelve a descubrir en cuanto la casilla queda limpia.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_una_casilla_de_la_puerta:
	push af			;463c
	ld a,(bc)			;463d   ; lo que ya habia ahi
	cp 0e0h		;463e   ; una llama?
	jr c,escribe_la_casilla_de_la_puerta		;4640
	xor a			;4642   ; la puerta se ha ido
	ld (0e383h),a		;4643
	ld a,(0e381h)		;4646   ; su columna
	ld (0e31ah),a		;4649   ; como sitio del castigo
	ld a,(0e382h)		;464c   ; y su fila
	ld (0e31bh),a		;464f
	ld a,001h		;4652   ; castigo pendiente
	ld (0e311h),a		;4654
escribe_la_casilla_de_la_puerta:
	pop af			;4657
	ld (bc),a			;4658   ; y la casilla se pinta igual
	ret			;4659

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; DESCUBRE LA PUERTA. Igual que el premio, pero mirando solo la
; PANTALLA: no le importa que en el tablero siga habiendo algo,
; porque la puerta se dibuja encima.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
descubre_la_puerta:
	ld a,(0e315h)		;465a   ; ya esta a la vista?
	or a			;465d
	ret nz			;465e
	ld bc,(0e381h)		;465f   ; su columna y su fila
	ld d,b			;4663   ; guardadas, que `pon_el_cursor` machaca BC
	ld e,c			;4664
	call pon_el_cursor_en_el_tablero		;4665   ; en el tablero
	call estan_libres_las_cuatro		;4668   ; las cuatro casillas libres?
	cp 020h		;466b
	ret nz			;466d
	ld b,d			;466e   ; y en la pantalla
	ld c,e			;466f
	call pon_el_cursor		;4670
	call estan_libres_las_cuatro		;4673   ; tambien
	cp 020h		;4676
	ret nz			;4678
	ld a,001h		;4679   ; puerta a la vista
	ld (0e383h),a		;467b
	ld (0e315h),a		;467e   ; y no se vuelve a mirar

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; PINTA LA PUERTA, las casillas 0x0E, 0x0F, 0x1E y 0x1F, con el
; mismo salto de fila que el premio.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_la_puerta:
	ld a,(0e383h)		;4681   ; esta puesta?
	or a			;4684
	ret z			;4685
	ld bc,(0e381h)		;4686   ; columna y fila
	call pon_el_cursor		;468a   ; el cursor, en la PANTALLA
	ld a,00eh		;468d   ; arriba a la izquierda
	call pinta_una_casilla_de_la_puerta		;468f
	inc bc			;4692   ; arriba a la derecha
	inc a			;4693
	call pinta_una_casilla_de_la_puerta		;4694
	ld hl,0001fh		;4697   ; una fila mas abajo
	add hl,bc			;469a
	ld b,h			;469b
	ld c,l			;469c
	add a,00fh		;469d   ; y las dos de abajo, 0x1E y 0x1F
	call pinta_una_casilla_de_la_puerta		;469f
	inc bc			;46a2
	inc a			;46a3
	call pinta_una_casilla_de_la_puerta		;46a4
	ret			;46a7

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Las cuatro casillas de una posicion, todas vacias? Se vuelve con
; la PRIMERA que no lo este, asi que el que llama comprueba con un
; `cp 020h`. BC queda apuntando a la ultima que se ha mirado.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
estan_libres_las_cuatro:
	ld a,(bc)			;46a8   ; arriba a la izquierda
	cp 020h		;46a9
	ret nz			;46ab
	inc bc			;46ac   ; arriba a la derecha
	ld a,(bc)			;46ad
	cp 020h		;46ae
	ret nz			;46b0
	ld hl,0001fh		;46b1   ; una fila mas abajo
	add hl,bc			;46b4
	ld b,h			;46b5
	ld c,l			;46b6
	ld a,(bc)			;46b7   ; abajo a la izquierda
	cp 020h		;46b8
	ret nz			;46ba
	inc bc			;46bb   ; y abajo a la derecha, que es la que se devuelve
	ld a,(bc)			;46bc
	ret			;46bd

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL CONTADOR CON TOPE, que es como se mide TODO el tiempo del
; juego. HL apunta a una pareja (cuenta, tope): se suma uno y al
; llegar al tope se vuelve a cero. Hay seis parejas seguidas en
; 0xE36F, y quien quiere hacer algo "de vez en cuando" mira si su
; cuenta vale cero.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
avanza_un_contador:
	ld a,(hl)			;46be   ; la cuenta
	inc a			;46bf
	inc hl			;46c0   ; contra el tope, que va justo detras
	cp (hl)			;46c1
	jr c,guarda_la_cuenta		;46c2   ; si no llega, se queda
	xor a			;46c4   ; y si llega, vuelta a empezar
guarda_la_cuenta:
	dec hl			;46c5
	ld (hl),a			;46c6   ; guardada
	ret			;46c7

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; CIERRA EL CUADRO: los cinco contadores, el volcado a la VRAM y el
; sonido. La espera del final es lo unico que marca el ritmo del
; juego, porque el cartucho DESENGANCHA la interrupcion de la BIOS
; (el `ret` que 0x5065 mete en H.TIMI) y no espera al barrido: la
; pantalla se vuelca cuando toca, no cuando el VDP esta a salvo.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
cierra_el_cuadro:
	ld hl,0e36fh		;46c8   ; el paso del bombero, cada 4
	call avanza_un_contador		;46cb
	ld hl,0e375h		;46ce   ; el paso de los enemigos, cada 5
	call avanza_un_contador		;46d1
	ld hl,0e379h		;46d4   ; el bonus, cada 50
	call avanza_un_contador		;46d7
	ld hl,0e377h		;46da   ; la bomba y el ladrillo, cada 3
	call avanza_un_contador		;46dd
	call vuelca_la_pantalla		;46e0   ; la pantalla entera a la VRAM, y en blanco para el cuadro siguiente
	call sigue_los_dos_guiones_de_sonido		;46e3   ; los dos guiones de sonido avanzan un cuadro
	ld hl,00500h		;46e6   ; y la espera que marca el ritmo
	jp espera		;46e9   ; 0x500 vueltas en vacio

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; MUEVE LOS ENEMIGOS, uno por ficha. Solo corre cuando el contador
; de 0xE375 vuelve a cero, o sea un cuadro de cada cinco.
; OJO: el `and 003h` de 0x472F mira ese MISMO contador, que aqui
; vale cero a la fuerza -si no, se habria vuelto en 0x46F0-, asi
; que ese `jp nz` no se toma nunca. Codigo muerto.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
mueve_los_enemigos:
	ld a,(0e375h)		;46ec   ; un cuadro de cada cinco
	or a			;46ef
	ret nz			;46f0
	ld a,(0e358h)		;46f1   ; cambia el parpadeo de todos, que es el mismo para los ocho
	xor 002h		;46f4
	ld (0e358h),a		;46f6
	ld ix,0e31ch		;46f9   ; la primera ficha
mueve_un_enemigo:
	ld a,(ix+000h)		;46fd   ; con 0xFF se acaba la lista
	inc a			;4700
	ret z			;4701
	dec a			;4702
	cp 001h		;4703   ; solo andan los vivos
	jp nz,al_enemigo_siguiente		;4705
	ld a,(ix+004h)		;4708   ; la cuenta atras
	dec a			;470b
	ld d,a			;470c
	cp 0ffh		;470d   ; ha dado la vuelta?
	jr nz,guarda_la_cuenta_atras		;470f
	ld a,(ix+003h)		;4711   ; pues un cuadro de dibujo menos
	dec a			;4714
	cp 0ffh		;4715   ; y de 0 se pasa a 3
	jr nz,L_471B		;4717
	ld a,003h		;4719
L_471B:
	ld (ix+003h),a		;471b
	ld a,(0e317h)		;471e   ; la cuenta se recarga con la cadencia de la fase
	ld d,a			;4721
guarda_la_cuenta_atras:
	ld a,d			;4722
	ld (ix+004h),a		;4723   ; guardada
	ld a,(ix+003h)		;4726   ; en el cuadro 0 no se filtra nada
	or a			;4729
	jr z,decide_a_donde_va		;472a
	ld a,(0e375h)		;472c   ; MUERTO: (0xE375) vale cero aqui a la fuerza
	and 003h		;472f
	jp nz,al_enemigo_siguiente		;4731
decide_a_donde_va:
	ld a,(ix+003h)		;4734   ; cuadro 0: a por el bombero
	or a			;4737
	jr z,va_a_por_el_bombero		;4738
	ld a,(ix+004h)		;473a   ; y una vez de cada dieciseis, tambien
	and 00fh		;473d
	or a			;473f
	jr z,va_a_por_el_bombero		;4740
	and 003h		;4742   ; una de cada cuatro, cambio de idea
	or a			;4744
	jr z,cambia_de_sentido_por_gusto		;4745
	call mira_lo_que_hay_delante		;4747   ; lo que hay delante
	cp 080h		;474a   ; si estorba, hay que buscar otro sitio
	jr nc,prueba_otro_sentido		;474c
	call da_un_paso		;474e   ; y si no, un paso
	jr al_enemigo_siguiente		;4751
prueba_otro_sentido:
	call numero_al_azar		;4753   ; un sentido al azar
	and 003h		;4756
	ld (ix+005h),a		;4758
	call mira_lo_que_hay_delante		;475b   ; si tambien estorba, este cuadro no se mueve
	cp 080h		;475e
	jr nc,al_enemigo_siguiente		;4760
	call da_un_paso		;4762   ; y si no, un paso
	jr al_enemigo_siguiente		;4765
cambia_de_sentido_por_gusto:
	call numero_al_azar		;4767   ; un sentido al azar, por gusto
	and 003h		;476a
	ld (ix+005h),a		;476c
	call mira_lo_que_hay_delante		;476f   ; si estorba, no se mueve
	cp 080h		;4772
	jr nc,al_enemigo_siguiente		;4774
	call da_un_paso		;4776   ; y si no, un paso
	jr al_enemigo_siguiente		;4779
va_a_por_el_bombero:
	ld a,(0e309h)		;477b   ; la columna del bombero
	ld b,a			;477e
	ld a,(ix+001h)		;477f   ; contra la del enemigo
	cp b			;4782
	jr z,prueba_en_vertical		;4783   ; misma columna: se prueba en vertical
	jr nc,hacia_la_izquierda		;4785   ; el bombero esta a la izquierda
	ld (ix+005h),001h		;4787   ; y si no, a la derecha
	jr prueba_en_horizontal		;478b
hacia_la_izquierda:
	ld (ix+005h),000h		;478d   ; izquierda
prueba_en_horizontal:
	call mira_lo_que_hay_delante		;4791   ; se puede?
	cp 080h		;4794
	jr c,pues_un_paso		;4796   ; pues por ahi
prueba_en_vertical:
	ld a,(0e30ah)		;4798   ; la fila del bombero
	ld b,a			;479b
	ld a,(ix+002h)		;479c   ; contra la del enemigo
	cp b			;479f
	jr z,al_enemigo_siguiente		;47a0   ; misma casilla: no hay a donde ir
	jr nc,hacia_arriba		;47a2   ; el bombero esta arriba
	ld (ix+005h),003h		;47a4   ; y si no, abajo
	jr se_puede_en_vertical		;47a8
hacia_arriba:
	ld (ix+005h),002h		;47aa   ; arriba
se_puede_en_vertical:
	call mira_lo_que_hay_delante		;47ae   ; se puede?
	cp 080h		;47b1
	jp nc,al_enemigo_siguiente		;47b3
pues_un_paso:
	call da_un_paso		;47b6   ; un paso
al_enemigo_siguiente:
	ld bc,00007h		;47b9   ; siete bytes por ficha
	add ix,bc		;47bc
	jp mueve_un_enemigo		;47be

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UN PASO, con la tabla de 0x482D: dos bytes por sentido, la fila y
; la columna que hay que sumar. Se anda de casilla en casilla de la
; PANTALLA, no de dos en dos, asi que un enemigo puede quedarse a
; medio camino entre dos casillas del tablero.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
da_un_paso:
	ld a,(ix+005h)		;47c1   ; el sentido
	add a,a			;47c4   ; dos bytes por sentido
	ld hl,0482dh		;47c5
	ld b,000h		;47c8
	ld c,a			;47ca
	add hl,bc			;47cb
	ld a,(ix+002h)		;47cc   ; la fila
	add a,(hl)			;47cf
	ld (ix+002h),a		;47d0
	inc hl			;47d3   ; y la columna
	ld a,(ix+001h)		;47d4
	add a,(hl)			;47d7
	ld (ix+001h),a		;47d8
	ret			;47db
mira_lo_que_hay_delante:
	ld hl,0481dh		;47dc   ; la tabla de sondas, cuatro bytes por sentido
	ld a,(ix+005h)		;47df   ; el sentido
	add a,a			;47e2
	add a,a			;47e3
	ld c,a			;47e4
	ld b,000h		;47e5
	add hl,bc			;47e7
	ld a,(ix+002h)		;47e8   ; la fila de la primera casilla
	add a,(hl)			;47eb
	ld b,a			;47ec
	inc hl			;47ed
	ld a,(ix+001h)		;47ee   ; y su columna
	add a,(hl)			;47f1
	ld c,a			;47f2
	push bc			;47f3
	call pon_el_cursor		;47f4   ; en la PANTALLA
	ld a,(bc)			;47f7
	pop bc			;47f8
	cp 080h		;47f9   ; de 0x80 para arriba estorba: ladrillo, muro, pilar, bombero,
	ret nc			;47fb   ; enemigo o llama
	call pon_el_cursor_en_el_tablero		;47fc   ; y ahora en el TABLERO, donde estan los ladrillos
	ld a,(bc)			;47ff
	cp 080h		;4800
	ret nc			;4802
	inc hl			;4803   ; la segunda casilla, que el bicho ocupa dos
	ld a,(ix+002h)		;4804
	add a,(hl)			;4807
	ld b,a			;4808
	inc hl			;4809
	ld a,(ix+001h)		;480a
	add a,(hl)			;480d
	ld c,a			;480e
	push bc			;480f   ; en la pantalla
	call pon_el_cursor		;4810
	ld a,(bc)			;4813
	pop bc			;4814
	cp 080h		;4815
	ret nc			;4817
	call pon_el_cursor_en_el_tablero		;4818   ; y en el tablero
	ld a,(bc)			;481b   ; lo que se devuelve
	ret			;481c

; ----------------------------------------------------------------------
; DATOS sondas_de_los_enemigos: Cuatro bytes por sentido -0 izquierda, 1
;   derecha, 2 arriba, 3 abajo-, que son las dos casillas de delante en
;   parejas (fila, columna): a la izquierda mira (0,-1) y (1,-1), a la derecha
;   (0,+2) y (1,+2), arriba (-1,0) y (-1,+1), y abajo (+2,0) y (+2,+1). Son
;   dos porque el enemigo ocupa dos casillas de ancho y de alto
;   0x481d..0x482d  (16 bytes)
DATA_sondas_de_los_enemigos:
	defb 000h,0ffh,001h,0ffh	; 481d
	defb 000h,002h,001h,002h	; 4821
	defb 0ffh,000h,0ffh,001h	; 4825
	defb 002h,000h,002h,001h	; 4829

; ----------------------------------------------------------------------
; DATOS pasos_de_los_enemigos: Dos bytes por sentido, la fila y la columna que
;   se le suman a la ficha: (0,-1), (0,+1), (-1,0) y (+1,0). El mismo orden
;   que las sondas
;   0x482d..0x4835  (8 bytes)
DATA_pasos_de_los_enemigos:
	defb 000h,0ffh	; 482d
	defb 000h,001h	; 482f
	defb 0ffh,000h	; 4831
	defb 001h,000h	; 4833

; ======================================================================
; CODIGO 0x4835..0x4892  (93 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; PINTA LOS ENEMIGOS y les lleva la agonia. El estado de la ficha
; hace de indice: 1 es el bicho vivo, y de 2 a 9 los siete cuadros
; en que revienta, casillas 0x22, 0x24, 0x26... hasta que el
; `cp 030h` dice que ya no queda dibujo y solo se borra. Esos son
; los mismos dibujos que en la portada forman el rotulo grande de
; BOMBER MAN, porque alli el bloque de graficos es otro.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_los_enemigos:
	ld ix,0e31ch		;4835   ; la primera ficha
pinta_un_enemigo:
	ld a,(ix+000h)		;4839   ; con 0xFF se acaba la lista
	inc a			;483c
	ret z			;483d
	dec a			;483e   ; libre: a la siguiente
	jp z,a_la_ficha_siguiente		;483f
	cp 001h		;4842   ; vivo: se pinta y ya
	jp z,pinta_un_enemigo_vivo		;4844
	ld c,(ix+001h)		;4847   ; reventando: su columna
	ld b,(ix+002h)		;484a   ; y su fila
	call pon_el_cursor		;484d
	ld a,(ix+000h)		;4850   ; el estado por dos y mas 0x1E: 2 da 0x22, 3 da 0x24...
	add a,a			;4853
	add a,01eh		;4854
	cp 030h		;4856   ; pasado el ultimo dibujo
	jr c,pinta_el_cuadro_de_la_agonia		;4858
	ld a,020h		;485a   ; solo queda borrarlo
	call pinta_cuatro_casillas_iguales		;485c
	jr avanza_la_agonia_del_enemigo		;485f
pinta_el_cuadro_de_la_agonia:
	call pinta_cuatro_casillas		;4861   ; y si no, las cuatro casillas del cuadro que toque
	ld c,a			;4864   ; SEIS BYTES QUE SOBRAN: se ejecutan, y no hacen nada, porque
	ld b,d			;4865   ; nadie vuelve a leer B ni C. Son un `ld c,a` y cuatro `ld b,..`
	ld b,c			;4866   ; inofensivos; leidos como texto, y con la fuente del propio
	ld b,h			;4867   ; cartucho, dicen "OBADD". Es lo unico de los 8 KB que no sirve
	ld b,h			;4868   ; para nada, ni de dato ni de instruccion
	nop			;4869   ; y el `nop` que los cierra
avanza_la_agonia_del_enemigo:
	push hl			;486a
	ld hl,0e373h		;486b   ; la cuenta de la agonia, cada 7 cuadros
	call avanza_un_contador		;486e
	pop hl			;4871
	ld a,(0e373h)		;4872   ; si no toca, se queda en este dibujo
	or a			;4875
	jp nz,a_la_ficha_siguiente		;4876
	ld a,(ix+000h)		;4879   ; un cuadro mas
	inc a			;487c
	cp 00ah		;487d   ; pasado el ultimo, se apunta el muerto
	jr z,$+38		;487f
	ld (ix+000h),a		;4881
	ld e,a			;4884   ; el estado, de 2 a 9
	ld d,001h		;4885   ; al registro 1 del PSG: el tono grueso de la voz A, que sube
	call escribe_en_el_psg		;4887   ; con cada cuadro de la agonia
	ld hl,04892h		;488a   ; y el guion que va detras
	ld (0e305h),hl		;488d
	jr $+119		;4890   ; a la ficha siguiente

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_del_enemigo: Lo instala 0x488A en (0xE305) cuando un
;   enemigo revienta: tres cuadros subiendo el tono de la voz A de 0x0000 a
;   0x00FA mientras baja el volumen, cerrado por un 0xFF doble
;   0x4892..0x48a5  (19 bytes)
DATA_guion_de_sonido_del_enemigo:
	defb 000h,000h,008h,00dh,0ffh,000h,064h,008h,00ah,0ffh,000h,0fah,008h,007h,0ffh,008h	; 4892  ......d.........
	defb 000h,0ffh,0ffh	; 48a2

; ======================================================================
; CODIGO 0x48a5..0x49f3  (334 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; SE ACABO EL ENEMIGO: la ficha queda libre y se cobra. Los puntos
; salen del cuadro de dibujo en que estaba mas un numero al azar de
; 0 a 3, o sea entre 3 y 18, que en pantalla son de 30 a 180. Si el
; bombero se esta muriendo (estado 6 o mas) no se cuenta como
; enemigo eliminado, para que morir a la vez que el ultimo bicho no
; de la fase por limpia.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
se_acabo_el_enemigo:
	xor a			;48a5   ; ficha libre
	ld (ix+000h),a		;48a6
	ld a,(ix+003h)		;48a9   ; el cuadro de dibujo en que se quedo
	add a,a			;48ac   ; por cuatro
	add a,a			;48ad
	inc a			;48ae   ; y dos mas
	inc a			;48af
	ld b,a			;48b0
	call numero_al_azar		;48b1   ; un numero al azar
	and 003h		;48b4   ; de 0 a 3
	inc a			;48b6   ; o sea de 1 a 4
	add a,b			;48b7   ; sumado a lo anterior: entre 3 y 18
	ld c,a			;48b8
	ld b,000h		;48b9
	ld hl,(0e300h)		;48bb   ; al marcador, que en pantalla son de 30 a 180 puntos
	add hl,bc			;48be
	ld (0e300h),hl		;48bf
	ld a,(0e30bh)		;48c2   ; si el bombero se esta muriendo, no cuenta
	cp 006h		;48c5
	jr nc,a_la_ficha_siguiente		;48c7
	ld a,(0e313h)		;48c9   ; un enemigo menos
	dec a			;48cc
	ld (0e313h),a		;48cd
	jr nz,a_la_ficha_siguiente		;48d0   ; quedan?
	ld a,(0e318h)		;48d2   ; no queda ninguno: fase limpia
	inc a			;48d5
	ld (0e318h),a		;48d6
	jr a_la_ficha_siguiente		;48d9

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; PINTA UN ENEMIGO VIVO: cuatro casillas a partir de 0xC0 mas el
; cuadro de dibujo por cuatro, mas el parpadeo de (0xE358). Que
; empiecen en 0xC0 no es casualidad: es justo el limite que usa
; 0x4BEB para saber que el bombero ha tocado algo que mata.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_un_enemigo_vivo:
	ld c,(ix+001h)		;48db   ; su columna
	ld b,(ix+002h)		;48de   ; y su fila
	call pon_el_cursor		;48e1   ; el cursor, en la PANTALLA
	ld a,(ix+003h)		;48e4   ; el cuadro de dibujo
	add a,a			;48e7   ; por cuatro
	add a,a			;48e8
	add a,0c0h		;48e9   ; a partir de 0xC0
	ld hl,0e358h		;48eb   ; mas el parpadeo, que vale 0 o 2
	add a,(hl)			;48ee
	call pinta_una_casilla_del_enemigo		;48ef   ; arriba a la izquierda
	inc a			;48f2   ; arriba a la derecha
	inc bc			;48f3
	call pinta_una_casilla_del_enemigo		;48f4
	ld hl,0001fh		;48f7   ; una fila mas abajo
	add hl,bc			;48fa
	ld b,h			;48fb
	ld c,l			;48fc
	add a,00fh		;48fd   ; y las dos de abajo
	call pinta_una_casilla_del_enemigo		;48ff
	inc bc			;4902
	inc a			;4903
	call pinta_una_casilla_del_enemigo		;4904
a_la_ficha_siguiente:
	ld bc,00007h		;4907   ; siete bytes por ficha
	add ix,bc		;490a
	jp pinta_un_enemigo		;490c

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Pinta una casilla del enemigo y mira lo que habia debajo: si era
; una llama, el enemigo pasa al estado 2 y empieza a reventar.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_una_casilla_del_enemigo:
	push af			;490f
	ld a,(bc)			;4910   ; lo que ya habia ahi
	cp 0e0h		;4911   ; una llama?
	jr c,escribe_la_casilla_del_enemigo		;4913
	ld (ix+000h),002h		;4915   ; pues a reventar
escribe_la_casilla_del_enemigo:
	pop af			;4919
	ld (bc),a			;491a   ; y la casilla se pinta igual
	ret			;491b

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; PON UNA BOMBA. Y aqui esta la particularidad del cartucho: en las
; fases MULTIPLOS DE CUATRO no hace falta pulsar nada, las bombas
; caen solas. Es lo que dice el `and 003h`, y lo que anuncia el
; rotulo parpadeante de abajo -"BOMB AUTO SETTING STAGE"- que pinta
; 0x4D37 con exactamente la misma condicion.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pon_una_bomba:
	ld a,(0e30bh)		;491c   ; si el bombero se esta muriendo, no
	cp 006h		;491f
	ret nc			;4921
	ld a,(0e310h)		;4922   ; la fase
	and 003h		;4925   ; en las fases 4, 8, 12... la bomba cae sola
	jr z,busca_una_ficha_de_bomba_libre		;4927
	call lee_el_disparo		;4929   ; y si no, hay que tener el disparo pulsado
	inc a			;492c
	ret nz			;492d
busca_una_ficha_de_bomba_libre:
	ld ix,0e359h		;492e   ; la lista de bombas
mira_esta_ficha_de_bomba:
	ld a,(ix+000h)		;4932   ; con 0xFF se acaba la lista
	inc a			;4935
	ret z			;4936
	dec a			;4937   ; ocupada: a la siguiente
	or a			;4938
	jr nz,a_la_ficha_de_bomba_siguiente		;4939
	ld bc,(0e309h)		;493b   ; la casilla del bombero
	ld (ix+001h),c		;493f   ; su columna
	ld (ix+002h),b		;4942   ; y su fila
	call pon_el_cursor_en_el_tablero		;4945   ; el cursor, en el TABLERO
	ld d,b			;4948   ; guardado, que hace falta otra vez al final
	ld e,c			;4949
	call esta_vacia		;494a   ; la casilla de arriba a la izquierda tiene que estar vacia
	ret nz			;494d
	inc bc			;494e   ; y las otras tres
	call esta_vacia		;494f
	ret nz			;4952
	ld hl,0001fh		;4953
	add hl,bc			;4956
	ld b,h			;4957
	ld c,l			;4958
	call esta_vacia		;4959
	ret nz			;495c
	inc bc			;495d
	call esta_vacia		;495e
	ret nz			;4961
	ld b,d			;4962   ; el sitio otra vez
	ld c,e			;4963
	ld a,060h		;4964   ; la bomba, casillas 0x60, 0x61, 0x70 y 0x71
	call pinta_cuatro_casillas		;4966
	ld a,001h		;4969   ; mecha encendida
	ld (ix+000h),a		;496b
	xor a			;496e   ; la cuenta, a cero
	ld (ix+003h),a		;496f
	ld (0e30bh),a		;4972   ; y el bombero se queda quieto: el cuadro 0x8A, con la bomba en la mano
	ret			;4975
a_la_ficha_de_bomba_siguiente:
	ld bc,00004h		;4976   ; cuatro bytes por ficha
	add ix,bc		;4979
	jp mira_esta_ficha_de_bomba		;497b
esta_vacia:
	ld a,(bc)			;497e   ; vacia es 0x20, y lo mira quien llama
	cp 020h		;497f
	ret			;4981

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Vacia la lista de bombas, igual que 0x4589 con la de enemigos.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
borra_la_lista_de_bombas:
	ld ix,0e359h		;4982   ; la lista, cinco fichas de cuatro bytes
borra_una_ficha_de_bomba:
	ld a,(ix+000h)		;4986   ; con 0xFF se acaba
	inc a			;4989
	ret z			;498a
	ld (ix+000h),000h		;498b   ; ficha libre
	ld bc,00004h		;498f   ; cuatro bytes a la siguiente
	add ix,bc		;4992
	jr borra_una_ficha_de_bomba		;4994

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS BOMBAS AVANZAN. La mecha son cuatro estados que tardan siete
; cuadros cada uno; la explosion, ocho estados mas que van uno cada
; vez que el contador de 0xE377 vuelve a cero, o sea uno cada tres
; cuadros. Al llegar al catorce la ficha se apaga y se calla la voz.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
avanzan_las_bombas:
	ld a,(0e36eh)		;4996   ; el parpadeo de todas las bombas, que es el mismo
	xor 002h		;4999
	ld (0e36eh),a		;499b
	ld ix,0e359h		;499e   ; la primera ficha
avanza_una_bomba:
	ld a,(ix+000h)		;49a2   ; con 0xFF se acaba la lista
	inc a			;49a5
	ret z			;49a6
	dec a			;49a7   ; libre: a la siguiente
	jr z,a_la_bomba_siguiente_de_la_cuenta		;49a8
	cp 005h		;49aa   ; del cinco para arriba ya esta explotando
	jr nc,cambia_de_estado_la_bomba		;49ac
	ld a,(ix+003h)		;49ae   ; y con la mecha, una cuenta de siete cuadros
	inc a			;49b1
	ld (ix+003h),a		;49b2
	cp 007h		;49b5   ; hasta que cuadra
	jr nz,a_la_bomba_siguiente_de_la_cuenta		;49b7
cambia_de_estado_la_bomba:
	xor a			;49b9   ; la cuenta se reinicia
	ld (ix+003h),a		;49ba
	ld a,(0e377h)		;49bd   ; y solo se avanza un cuadro de cada tres
	or a			;49c0
	jr nz,a_la_bomba_siguiente_de_la_cuenta		;49c1
	ld a,(ix+000h)		;49c3   ; un estado mas
	inc a			;49c6
	cp 00eh		;49c7   ; pasado el catorce, la bomba se acabo
	jr z,apaga_la_bomba		;49c9
	ld (ix+000h),a		;49cb
	cp 005h		;49ce   ; del cinco para abajo, la mecha sigue
	jr c,a_la_bomba_siguiente_de_la_cuenta		;49d0
	cp 006h		;49d2   ; justo al empezar la explosion, el ruido
	jr z,L_49F0		;49d4
	ld a,(0e30bh)		;49d6   ; MUERTO: las dos salidas de este `cp` van al mismo sitio
	cp 006h		;49d9
	jr nc,a_la_bomba_siguiente_de_la_cuenta		;49db
	jr a_la_bomba_siguiente_de_la_cuenta		;49dd
apaga_la_bomba:
	xor a			;49df   ; ficha libre
	ld (ix+000h),a		;49e0
	ld de,00900h		;49e3   ; registro 9 a cero: se calla la voz B
	call escribe_en_el_psg		;49e6
a_la_bomba_siguiente_de_la_cuenta:
	ld bc,00004h		;49e9   ; cuatro bytes por ficha
	add ix,bc		;49ec
	jr avanza_una_bomba		;49ee
L_49F0:
	call vuelca_la_tabla_del_psg		;49f0

; ----------------------------------------------------------------------
; DATOS tabla_del_psg_del_estallido: Nueve parejas y el 0xFF: pone el ruido en
;   0x1F, lo mete en el mezclador con el registro 7 y arranca la envolvente.
;   Es el trueno de la explosion, y va pegado detras del `call` de 0x49F0
;   0x49f3..0x4a06  (19 bytes)
DATA_tabla_del_psg_del_estallido:
	defb 002h,000h	; 49f3
	defb 003h,00eh	; 49f5
	defb 006h,01fh	; 49f7
	defb 008h,000h	; 49f9
	defb 009h,010h	; 49fb
	defb 00ah,000h	; 49fd
	defb 00bh,000h	; 49ff
	defb 00ch,040h	; 4a01
	defb 00dh,009h	; 4a03
	defb 0ffh	; 4a05

; ======================================================================
; CODIGO 0x4a06..0x4c01  (507 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Y sigue aqui, detras de la tabla, con el `push hl / ret` de 0x405C.
; Un `jr` de dos bytes para volver al bucle de las fichas.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
L_4A06:
	jr $-29		;4a06   ; a la ficha siguiente

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; PINTA LAS BOMBAS Y LAS LLAMAS. Tres cosas segun el estado: del 1
; al 4 la bomba, que encoge segun se le acaba la mecha; del 5 al 12
; la explosion; y el 13 borra lo que quedaba.
; La bomba se pinta en el TABLERO y en la PANTALLA a la vez, y por
; eso se usa el juego alternativo de registros: BC y D llevan la
; misma casilla y el mismo dibujo dos veces, una para cada pantalla.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_las_bombas_y_las_llamas:
	ld ix,0e359h		;4a08   ; la primera ficha
pinta_una_bomba:
	ld a,(ix+000h)		;4a0c   ; con 0xFF se acaba la lista
	inc a			;4a0f
	ret z			;4a10
	dec a			;4a11   ; libre: a la siguiente
	jr z,a_la_bomba_siguiente		;4a12
	cp 00dh		;4a14   ; el 13 solo borra
	jr z,borra_lo_que_quedaba		;4a16
	cp 005h		;4a18   ; del 5 para arriba, explosion
	jr c,pinta_la_bomba		;4a1a
	add a,a			;4a1c   ; el estado por dos mas 0xD6: el 5 da 0xE0, el 6 0xE2...
	add a,0d6h		;4a1d
	exx			;4a1f   ; guardado en el otro juego de registros
	ld d,a			;4a20
	exx			;4a21
	jr pinta_la_explosion		;4a22
pinta_la_bomba:
	dec a			;4a24   ; el estado menos uno
	add a,a			;4a25   ; por cuatro
	add a,a			;4a26
	ld d,a			;4a27
	ld a,(0e36eh)		;4a28   ; mas el parpadeo, que vale 0 o 2
	add a,d			;4a2b
	add a,060h		;4a2c   ; a partir de 0x60
	ld d,a			;4a2e
	exx			;4a2f
	ld d,a			;4a30
	exx			;4a31
	ld a,(ix+001h)		;4a32   ; la columna, en los dos juegos de registros
	ld c,a			;4a35
	exx			;4a36
	ld c,a			;4a37
	exx			;4a38
	ld a,(ix+002h)		;4a39   ; y la fila
	ld b,a			;4a3c
	exx			;4a3d
	ld b,a			;4a3e
	exx			;4a3f
	call pon_el_cursor_en_el_tablero		;4a40   ; el cursor, en el TABLERO
	call mira_si_la_alcanza_otra_llama		;4a43   ; arriba a la izquierda
	inc bc			;4a46   ; arriba a la derecha
	inc d			;4a47
	call mira_si_la_alcanza_otra_llama		;4a48
	ld hl,0001fh		;4a4b   ; una fila mas abajo
	add hl,bc			;4a4e
	ld b,h			;4a4f
	ld c,l			;4a50
	ld a,00fh		;4a51   ; el salto de 0x0B a 0x1A de la hoja de casillas
	add a,d			;4a53
	ld d,a			;4a54
	call mira_si_la_alcanza_otra_llama		;4a55   ; y las dos de abajo
	inc bc			;4a58
	inc d			;4a59
	call mira_si_la_alcanza_otra_llama		;4a5a
	exx			;4a5d   ; y ahora la misma casilla en la PANTALLA
	call pon_el_cursor		;4a5e   ; el cursor
	ld a,d			;4a61   ; con el mismo dibujo, y sin mirar nada
	call pinta_cuatro_casillas		;4a62
	exx			;4a65
a_la_bomba_siguiente:
	ld bc,00004h		;4a66   ; cuatro bytes por ficha
	add ix,bc		;4a69
	jr pinta_una_bomba		;4a6b

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA REACCION EN CADENA. Al escribir la bomba en el tablero se mira
; lo que habia debajo: si es una llama, la bomba salta al estado 4
; con la cuenta en 6, o sea que el cuadro siguiente ya explota.
; Asi es como una bomba enciende a la de al lado.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
mira_si_la_alcanza_otra_llama:
	ld a,(bc)			;4a6d   ; lo que habia
	cp 0e0h		;4a6e   ; una llama?
	ret c			;4a70
	ld (ix+000h),004h		;4a71   ; pues al ultimo estado de la mecha
	ld (ix+003h),006h		;4a75   ; con la cuenta casi llena: revienta al cuadro siguiente
	ret			;4a79

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Estado 13: borra del tablero las cuatro casillas que ocupaba la
; explosion. La ficha ya se apago en 0x49DF.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
borra_lo_que_quedaba:
	ld a,(ix+001h)		;4a7a   ; su columna
	ld c,a			;4a7d
	ld a,(ix+002h)		;4a7e   ; y su fila
	ld b,a			;4a81
	call pon_el_cursor_en_el_tablero		;4a82   ; en el TABLERO
	ld a,020h		;4a85   ; casillas vacias
	call pinta_cuatro_casillas_iguales		;4a87   ; las cuatro
	jr a_la_bomba_siguiente		;4a8a

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA EXPLOSION. El centro se pinta a lo bruto, sin mirar lo que hay
; debajo, y los cuatro brazos se recorren con la tabla de 0x4F8D.
; El dibujo del brazo es el del centro MAS DOS, y cuando eso llega
; a 0xF0 se cambia por la casilla vacia: por eso los brazos se
; apagan un par de estados antes que el centro.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_la_explosion:
	ld c,(ix+001h)		;4a8c   ; su columna
	ld b,(ix+002h)		;4a8f   ; y su fila
	call pon_el_cursor_en_el_tablero		;4a92   ; el cursor, en el TABLERO
	exx			;4a95   ; el dibujo del centro
	ld a,d			;4a96
	exx			;4a97
	call pinta_cuatro_casillas		;4a98   ; las cuatro casillas, sin preguntar
	exx			;4a9b   ; el dibujo otra vez
	ld a,d			;4a9c
	exx			;4a9d
	inc a			;4a9e   ; mas dos: ese es el de los brazos
	inc a			;4a9f
	cp 0f0h		;4aa0   ; pasado el ultimo
	jr c,guarda_el_dibujo_del_brazo		;4aa2
	ld a,020h		;4aa4   ; los brazos se apagan
guarda_el_dibujo_del_brazo:
	exx			;4aa6
	ld e,a			;4aa7   ; guardado para las cuarenta casillas del brazo
	exx			;4aa8
	ld hl,04f8dh		;4aa9   ; la tabla de los cuatro brazos

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS CUATRO BRAZOS, en OCHO tiras de cuatro casillas: una tira por
; cada lado y cada una de las dos filas -o columnas- que ocupa la
; explosion. El bucle esta desenrollado a proposito, con una copia
; por casilla, porque cada una se para de una forma distinta:
;
; 1a  se para solo con el muro (0x88), y salta las tres que quedan
; 2a  se para con ladrillo, muro o pilar (0x80..0x89), dos menos
; 3a  igual, una menos
; 4a  igual, y al acabar se vuelve al principio del bucle
;
; Y LA DIFERENCIA QUE IMPORTA: la primera y la segunda usan 0x4B21,
; que GASTA el ladrillo -le suma uno al dibujo cada tres cuadros
; hasta hacerlo desaparecer-. La tercera y la cuarta usan 0x4B5A,
; que pinta pero NO gasta. Como las dos primeras casillas son la
; casilla de tablero pegada a la bomba y las dos ultimas la
; siguiente, el resultado es que la explosion ALCANZA dos casillas
; pero solo TIRA los ladrillos de la primera.
; El 0x80 cuadruplicado del final de la tabla es lo que la cierra:
; 0x4AB0 lo caza porque es el unico byte que al sumarse consigo
; mismo da cero.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
recorre_los_cuatro_brazos:
	ld a,(hl)			;4aac   ; el primer byte de la pareja
	or a			;4aad   ; si es cero no puede ser el cierre
	jr z,la_primera_casilla_de_la_tira		;4aae
	add a,a			;4ab0   ; y 0x80 mas 0x80 da cero: fin de la tabla
	or a			;4ab1
	jr z,a_la_bomba_siguiente		;4ab2
la_primera_casilla_de_la_tira:
	ld a,(hl)			;4ab4   ; la fila
	inc hl			;4ab5
	add a,(ix+002h)		;4ab6   ; sumada a la de la bomba
	ld b,a			;4ab9
	ld a,(hl)			;4aba   ; y la columna
	inc hl			;4abb
	add a,(ix+001h)		;4abc
	ld c,a			;4abf
	call pinta_una_llama_y_gasta_el_ladrillo		;4ac0   ; pinta la llama y devuelve lo que habia
	cp 088h		;4ac3   ; el muro?
	jr nz,la_segunda_casilla_de_la_tira		;4ac5   ; no: a la casilla siguiente
	jr salta_lo_que_queda_de_tira		;4ac7   ; si: las tres que quedan de la tira no se pintan

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA COMPROBACION QUE NO SE EJECUTA. Estos dos son el `cp 089h` del
; pilar, y el `jr $+6` de dos lineas mas arriba pasa por encima de
; ellos: no hay forma de llegar aqui. Si se ejecutara, la primera
; casilla de la tira se pararia tambien con el pilar; como no lo
; hace, sigue a la segunda, que da con la otra mitad del mismo
; pilar y para la tira ahi. O sea que el resultado en pantalla es
; el mismo, y por eso nadie lo arreglo nunca.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
el_pilar_que_no_se_comprueba:
	cp 089h		;4ac9   ; el pilar
	jr nz,la_segunda_casilla_de_la_tira		;4acb   ; no lo es: a la casilla siguiente de la tira
salta_lo_que_queda_de_tira:
	inc hl			;4acd   ; tres parejas de dos bytes, o sea las tres casillas
	inc hl			;4ace   ; que quedan de esta tira, que no se van a pintar
	inc hl			;4acf   ; porque algo las tapa
	inc hl			;4ad0
	inc hl			;4ad1
	inc hl			;4ad2
	jr recorre_los_cuatro_brazos		;4ad3   ; y a la tira siguiente

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA SEGUNDA CASILLA de la tira, la que completa la casilla de
; tablero pegada a la bomba. Es la ultima que gasta ladrillos.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
la_segunda_casilla_de_la_tira:
	ld a,(hl)			;4ad5   ; la fila
	inc hl			;4ad6
	add a,(ix+002h)		;4ad7   ; sumada a la de la bomba
	ld b,a			;4ada
	ld a,(hl)			;4adb   ; y la columna
	inc hl			;4adc
	add a,(ix+001h)		;4add
	ld c,a			;4ae0
	call pinta_una_llama_y_gasta_el_ladrillo		;4ae1   ; pinta la llama y devuelve lo que habia
	cp 080h		;4ae4   ; por debajo de 0x80 no estorba nada
	jr c,la_tercera_casilla_de_la_tira		;4ae6
	cp 08ah		;4ae8   ; y de 0x8A para arriba, tampoco: eso ya es gente
	jr nc,la_tercera_casilla_de_la_tira		;4aea
	inc hl			;4aec   ; ladrillo, muro o pilar: las dos que quedan no se pintan
	inc hl			;4aed
	inc hl			;4aee
	inc hl			;4aef
	jr recorre_los_cuatro_brazos		;4af0

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA TERCERA, que ya es la casilla de tablero siguiente. De aqui en
; adelante se usa 0x4B5A, que pinta la llama pero NO gasta el
; ladrillo, asi que un ladrillo a dos casillas para la llama y se
; queda entero.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
la_tercera_casilla_de_la_tira:
	ld a,(hl)			;4af2   ; la fila
	inc hl			;4af3
	add a,(ix+002h)		;4af4   ; sumada a la de la bomba
	ld b,a			;4af7
	ld a,(hl)			;4af8   ; y la columna
	inc hl			;4af9
	add a,(ix+001h)		;4afa
	ld c,a			;4afd
	call pinta_una_llama_sin_gastar		;4afe   ; pinta, y devuelve DOS cosas: lo que hay en la pantalla en A'
	ex af,af'			;4b01   ; y esa es la que se mira
	cp 080h		;4b02   ; por debajo de 0x80 no estorba
	jr c,la_cuarta_casilla_de_la_tira		;4b04
	cp 08ah		;4b06   ; de 0x8A para arriba, tampoco
	jr nc,la_cuarta_casilla_de_la_tira		;4b08
	ex af,af'			;4b0a
	inc hl			;4b0b   ; ladrillo, muro o pilar: la ultima no se pinta
	inc hl			;4b0c
	jr recorre_los_cuatro_brazos		;4b0d
la_cuarta_casilla_de_la_tira:
	ex af,af'			;4b0f   ; el acarreo, como estaba
	ld a,(hl)			;4b10   ; la fila
	inc hl			;4b11
	add a,(ix+002h)		;4b12   ; sumada a la de la bomba
	ld b,a			;4b15
	ld a,(hl)			;4b16   ; y la columna
	inc hl			;4b17
	add a,(ix+001h)		;4b18
	ld c,a			;4b1b
	call pinta_una_llama_sin_gastar		;4b1c   ; la ultima de la tira
	jr recorre_los_cuatro_brazos		;4b1f   ; y a la tira siguiente

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; PINTA UNA LLAMA Y GASTA EL LADRILLO. Mira las DOS pantallas: el
; muro y el pilar solo estan en la de arriba, los ladrillos solo en
; el tablero. Si lo que hay es un ladrillo (0x80..0x89) se le suma
; uno al dibujo -cada tres cuadros, que es lo que decide 0x4B4E- y
; al llegar al 0x88 se cambia por casilla vacia: ocho cuadros de
; desmoronarse. Y si no hay ladrillo, se pinta la llama.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_una_llama_y_gasta_el_ladrillo:
	push bc			;4b21
	call pon_el_cursor		;4b22   ; el cursor, en la PANTALLA
	ld a,(bc)			;4b25   ; lo que hay
	pop bc			;4b26
	cp 088h		;4b27   ; el muro para la llama
	ret z			;4b29
	cp 089h		;4b2a   ; y el pilar tambien
	ret z			;4b2c
	call pon_el_cursor_en_el_tablero		;4b2d   ; y ahora la misma casilla en el TABLERO
	ld a,(bc)			;4b30
	cp 088h		;4b31   ; el muro, otra vez
	ret z			;4b33
	cp 080h		;4b34   ; por debajo de 0x80 no hay ladrillo
	jr c,no_hay_ladrillo		;4b36
	cp 08ah		;4b38   ; y de 0x8A para arriba, tampoco
	jr nc,no_hay_ladrillo		;4b3a
	jr hay_ladrillo		;4b3c   ; o sea que 0x80..0x89 es ladrillo
no_hay_ladrillo:
	exx			;4b3e   ; no hay ladrillo: se pinta la llama
	ld a,e			;4b3f
	exx			;4b40
	jr escribe_la_casilla		;4b41
hay_ladrillo:
	call si_toca_gasta_el_ladrillo		;4b43   ; un cuadro mas de desmoronarse, si toca
	cp 088h		;4b46   ; pasado el ultimo
	jr nz,escribe_la_casilla		;4b48
	ld a,020h		;4b4a   ; la casilla se queda vacia
escribe_la_casilla:
	ld (bc),a			;4b4c   ; y se escribe
	ret			;4b4d

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; SUMARLE UNO A A, PERO SOLO CADA TRES CUADROS. El truco: `push af`
; y `ex (sp),hl` meten AF en HL, asi que el `inc h` incrementa la A
; guardada, y el `pop af` la recoge ya cambiada. Se hace asi para
; no gastar un registro, que en esta rutina no queda ninguno libre.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
si_toca_gasta_el_ladrillo:
	push af			;4b4e   ; A a la pila
	ex (sp),hl			;4b4f   ; y de la pila a H, que es donde va la A
	ld a,(0e377h)		;4b50   ; la cuenta de tres cuadros
	or a			;4b53
	jr nz,devuelve_la_a_cambiada		;4b54   ; si no toca, se deja como estaba
	inc h			;4b56   ; y si toca, un cuadro mas de desmoronarse
devuelve_la_a_cambiada:
	ex (sp),hl			;4b57   ; H otra vez a la pila
	pop af			;4b58   ; y de ahi a A, ya cambiada
	ret			;4b59

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; PINTA UNA LLAMA, PERO SIN GASTAR EL LADRILLO. La usan la tercera
; y la cuarta casilla de cada tira. Devuelve dos cosas: en A' lo
; que hay en la PANTALLA, que es lo que mira quien llama para
; saber si la tira se para, y en A lo que se ha encontrado por el
; camino. Si hay ladrillo se vuelve SIN ESCRIBIR, y por eso un
; ladrillo a dos casillas de la bomba no se rompe.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_una_llama_sin_gastar:
	push bc			;4b5a
	call pon_el_cursor		;4b5b   ; el cursor, en la PANTALLA
	ld a,(bc)			;4b5e   ; lo que hay
	ex af,af'			;4b5f   ; guardado en A', que es lo que mira quien llama
	ld a,(bc)			;4b60
	ex af,af'			;4b61
	pop bc			;4b62
	cp 088h		;4b63   ; el muro para la llama
	ret z			;4b65
	cp 089h		;4b66   ; y el pilar tambien
	ret z			;4b68
	call pon_el_cursor_en_el_tablero		;4b69   ; la misma casilla en el TABLERO
	ld a,(bc)			;4b6c
	cp 08ah		;4b6d   ; de 0x8A para arriba no hay ladrillo
	jr nc,escribe_la_llama		;4b6f
	cp 080h		;4b71   ; ni por debajo de 0x80
	jr c,escribe_la_llama		;4b73
	ret			;4b75   ; hay ladrillo: se vuelve sin pintar nada
escribe_la_llama:
	exx			;4b76   ; la llama
	ld a,e			;4b77
	exx			;4b78
	ld (bc),a			;4b79   ; escrita
	ret			;4b7a

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS DOS RUTINAS QUE PINTAN UNA COSA DE DOS POR DOS, que es como
; esta hecho TODO lo que se mueve en este juego. La primera pinta
; A, A+1, A+0x10 y A+0x11 -o sea cuatro casillas seguidas de la
; hoja, dos arriba y dos abajo-; la segunda pinta la misma cuatro
; veces. El 0x1F del medio es 32 menos el `inc bc` que ya se hizo,
; y el 0x0F, 0x10 menos el `inc a`.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_cuatro_casillas:
	ld (bc),a			;4b7b   ; arriba a la izquierda
	inc bc			;4b7c   ; arriba a la derecha
	inc a			;4b7d
	ld (bc),a			;4b7e
	ld hl,0001fh		;4b7f   ; una fila mas abajo
	add hl,bc			;4b82
	ld b,h			;4b83
	ld c,l			;4b84
	add a,00fh		;4b85   ; y el salto de dibujo que le corresponde
	ld (bc),a			;4b87   ; abajo a la izquierda
	inc bc			;4b88
	inc a			;4b89
	ld (bc),a			;4b8a   ; y abajo a la derecha
	ret			;4b8b
pinta_cuatro_casillas_iguales:
	ld (bc),a			;4b8c   ; arriba a la izquierda
	inc bc			;4b8d
	ld (bc),a			;4b8e   ; arriba a la derecha
	ld hl,0001fh		;4b8f   ; una fila mas abajo
	add hl,bc			;4b92
	ld b,h			;4b93
	ld c,l			;4b94
	ld (bc),a			;4b95   ; abajo a la izquierda
	inc bc			;4b96
	ld (bc),a			;4b97   ; y abajo a la derecha
	ret			;4b98

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; PINTA AL BOMBERO. El estado de (0xE30B) hace de indice de dibujo,
; y son tres tramos:
;
; 0        acaba de soltar una bomba: casilla 0x8A, con la bomba
; en la mano. Se pasa a 1 aqui mismo
; 1        quieto: casilla 0x8C
; 2..5     andando: 0xA0 mas el sentido por cuatro, mas el paso
; 6..13    muriendose: 0x4E hacia ATRAS de dos en dos, hasta el
; 0x40, que es un OUT verde encima de los restos
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_al_bombero:
	ld a,(0e30bh)		;4b99   ; el estado
	cp 006h		;4b9c   ; del seis para arriba, muriendose
	jr nc,el_bombero_muriendose		;4b9e
	cp 002h		;4ba0   ; del dos para arriba, andando
	jr nc,el_bombero_andando		;4ba2
	or a			;4ba4   ; el cero solo dura un cuadro
	jr nz,el_bombero_quieto		;4ba5
	inc a			;4ba7   ; y pasa a uno
	ld (0e30bh),a		;4ba8
	ld e,08ah		;4bab   ; el dibujo de la bomba en la mano
	jr y_a_pintarlo		;4bad
el_bombero_quieto:
	ld e,08ch		;4baf   ; quieto
	jr y_a_pintarlo		;4bb1
el_bombero_andando:
	dec a			;4bb3   ; el sentido, de 0 a 3
	dec a			;4bb4
	add a,a			;4bb5   ; por cuatro
	add a,a			;4bb6
	add a,0a0h		;4bb7   ; a partir de 0xA0
	ld e,a			;4bb9
	ld a,(0e30ch)		;4bba   ; mas el paso, que vale 0 o 2
	add a,e			;4bbd
	ld e,a			;4bbe
	jr y_a_pintarlo		;4bbf
el_bombero_muriendose:
	sub 006h		;4bc1   ; el cuadro de la agonia, de 0 a 7
	add a,a			;4bc3   ; por dos
	ld e,a			;4bc4
	ld a,04eh		;4bc5   ; y hacia atras desde 0x4E: el ultimo es el 0x40
	sub e			;4bc7
	ld e,a			;4bc8
y_a_pintarlo:
	ld a,(0e30ah)		;4bc9   ; su fila
	ld b,a			;4bcc
	ld a,(0e309h)		;4bcd   ; y su columna
	ld c,a			;4bd0
	call pon_el_cursor		;4bd1   ; el cursor, en la PANTALLA
	call pinta_una_casilla_del_bombero		;4bd4   ; arriba a la izquierda
	call pinta_una_casilla_del_bombero		;4bd7   ; arriba a la derecha
	ld hl,0001eh		;4bda   ; una fila mas abajo, y 0x1E porque ya se avanzo dos
	add hl,bc			;4bdd
	ld b,h			;4bde
	ld c,l			;4bdf
	ld a,e			;4be0
	add a,00eh		;4be1   ; el salto de dibujo, 0x0E por lo mismo
	ld e,a			;4be3
	call pinta_una_casilla_del_bombero		;4be4   ; abajo a la izquierda
	call pinta_una_casilla_del_bombero		;4be7   ; y abajo a la derecha
	ret			;4bea

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; PINTA UNA CASILLA DEL BOMBERO Y MIRA SI LO MATAN. Lo que habia
; debajo decide: de 0xC0 para arriba estan los enemigos y las
; llamas, en ese orden y pegados a proposito, asi que con una sola
; comparacion se cubren las dos formas de morir. Y como el bombero
; se pinta DESPUES de los enemigos y de las llamas, lo que lee es
; lo de este mismo cuadro.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_una_casilla_del_bombero:
	ld a,(bc)			;4beb   ; lo que habia
	ld d,a			;4bec
	ld a,e			;4bed   ; y encima se pinta el bombero
	ld (bc),a			;4bee
	inc bc			;4bef   ; la casilla siguiente y el dibujo siguiente
	inc e			;4bf0
	ld a,d			;4bf1   ; lo que habia
	cp 0c0h		;4bf2   ; por debajo de 0xC0 no mata
	ret c			;4bf4
	ld a,(0e30bh)		;4bf5   ; y si ya se estaba muriendo, tampoco
	cp 006h		;4bf8
	ret nc			;4bfa
	ld a,006h		;4bfb   ; muerto: empieza la agonia
	ld (0e30bh),a		;4bfd
	ret			;4c00

; ----------------------------------------------------------------------
; DATOS pasos_del_bombero: Cuatro parejas (columna, fila) que suma 0x4C78
;   segun el estado menos dos: abajo (0,+1), izquierda (-1,0), derecha (+1,0)
;   y arriba (0,-1). El orden es el que dejan las cuatro comparaciones de
;   0x4C52 contra lo que devuelve GTSTCK
;   0x4c01..0x4c09  (8 bytes)
DATA_pasos_del_bombero:
	defb 000h,001h	; 4c01
	defb 0ffh,000h	; 4c03
	defb 001h,000h	; 4c05
	defb 000h,0ffh	; 4c07

; ======================================================================
; CODIGO 0x4c09..0x4c3b  (50 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL BOMBERO AVANZA: o anda, o se muere. Un cuadro de cada cuatro.
; La agonia son ocho cuadros mas, uno cada cuatro cuadros de los
; que llegan aqui, con un pitido que baja de tono en cada uno
; -escribiendo el estado por ocho en el registro 4 del PSG, que es
; el tono fino de la voz C-.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
avanza_el_bombero:
	ld a,(0e36fh)		;4c09   ; un cuadro de cada cuatro
	or a			;4c0c
	ret nz			;4c0d
	ld a,(0e30bh)		;4c0e   ; el estado
	cp 006h		;4c11   ; por debajo del seis esta vivo
	jr c,$+58		;4c13   ; y anda
	cp 00dh		;4c15   ; el trece es el ultimo cuadro de la agonia
	jr z,$+48		;4c17   ; y ahi se acabo
	ld hl,0e371h		;4c19   ; la cuenta de la agonia, cada 4
	call avanza_un_contador		;4c1c
	ld a,(0e371h)		;4c1f   ; si no toca, se queda en este cuadro
	or a			;4c22
	ret nz			;4c23
	ld a,(0e30bh)		;4c24   ; un cuadro mas de agonia
	inc a			;4c27
	ld (0e30bh),a		;4c28
	add a,a			;4c2b   ; por ocho
	add a,a			;4c2c
	add a,a			;4c2d
	ld e,a			;4c2e
	ld d,004h		;4c2f   ; al registro 4 del PSG: el tono baja segun se muere
	call escribe_en_el_psg		;4c31
	ld hl,04c3bh		;4c34   ; y el guion que va detras
	ld (0e307h),hl		;4c37
	ret			;4c3a

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_de_la_agonia: Lo instala 0x4C34 en (0xE307) en cada
;   cuadro de la agonia: enciende la voz C en el mezclador y baja el volumen
;   en tres cuadros
;   0x4c3b..0x4c47  (12 bytes)
DATA_guion_de_sonido_de_la_agonia:
	defb 005h,001h,00ah,00dh,0ffh,00ah,009h,0ffh,00ah,000h,0ffh,0ffh	; 4c3b  ............

; ======================================================================
; CODIGO 0x4c47..0x4cc7  (128 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Fin de la agonia. Solo se enciende la bandera; el bucle principal
; la ve en 0x4108 y descuenta la vida.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
se_acabo_el_bombero:
	ld a,001h		;4c47   ; y el bucle principal se encarga
	ld (0e37bh),a		;4c49
	ret			;4c4c

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; MUEVE AL BOMBERO. Se lee el mando una sola vez por cuadro, asi
; que no hay diagonales. Las cuatro comparaciones contra lo que
; devuelve GTSTCK -5 abajo, 7 izquierda, 3 derecha, 1 arriba- son
; las que fijan el orden de la tabla de 0x4C01 y, de paso, el de
; los dibujos de andar.
; Y la comprobacion de lo que estorba es corta a proposito: solo
; paran el muro, el pilar y el ladrillo ENTERO. Un ladrillo a
; medio desmoronar (0x81..0x87) se puede pisar, y una bomba y un
; enemigo tambien: por eso se puede andar encima de la bomba que
; acabas de poner, y por eso se muere uno al meterse en un bicho.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
mueve_al_bombero:
	ld b,002h		;4c4d   ; el primer sentido, abajo
	call lee_la_cruceta		;4c4f   ; el mando, o las teclas
	cp 005h		;4c52   ; abajo
	jr z,hay_sentido_nuevo		;4c54
	inc b			;4c56
	cp 007h		;4c57   ; izquierda
	jr z,hay_sentido_nuevo		;4c59
	inc b			;4c5b
	cp 003h		;4c5c   ; derecha
	jr z,hay_sentido_nuevo		;4c5e
	inc b			;4c60
	cp 001h		;4c61   ; arriba; y si no es ninguno, no se mueve
	ret nz			;4c63
hay_sentido_nuevo:
	ld a,(0e30ch)		;4c64   ; cambia el paso, que vale 0 o 2
	xor 002h		;4c67
	ld (0e30ch),a		;4c69
	ld hl,04c01h		;4c6c   ; la tabla de los cuatro pasos
	ld a,b			;4c6f
	ld e,a			;4c70   ; el sentido nuevo, que sera el estado
	dec a			;4c71   ; menos dos
	dec a			;4c72
	add a,a			;4c73   ; por dos
	ld b,000h		;4c74
	ld c,a			;4c76
	add hl,bc			;4c77
	ld a,(0e309h)		;4c78   ; la columna nueva
	add a,(hl)			;4c7b
	ld c,a			;4c7c
	ld a,(0e30ah)		;4c7d   ; y la fila nueva
	inc hl			;4c80
	add a,(hl)			;4c81
	ld b,a			;4c82
	push bc			;4c83   ; guardadas, que `pon_el_cursor` machaca BC
	call pon_el_cursor		;4c84
	ld d,000h		;4c87   ; nada estorba, de momento
	call mira_si_la_casilla_estorba		;4c89   ; arriba a la izquierda
	call mira_si_la_casilla_estorba		;4c8c   ; arriba a la derecha
	ld hl,0001eh		;4c8f   ; una fila mas abajo, y 0x1E porque ya se avanzo dos
	add hl,bc			;4c92
	ld b,h			;4c93
	ld c,l			;4c94
	call mira_si_la_casilla_estorba		;4c95   ; abajo a la izquierda
	call mira_si_la_casilla_estorba		;4c98   ; y abajo a la derecha
	ld a,d			;4c9b   ; algo estorba?
	or a			;4c9c
	pop bc			;4c9d
	ret nz			;4c9e   ; pues no se mueve
	ld a,b			;4c9f   ; la fila nueva
	ld (0e30ah),a		;4ca0
	ld a,c			;4ca3   ; la columna nueva
	ld (0e309h),a		;4ca4
	ld a,e			;4ca7   ; y el sentido, que tambien es el dibujo
	ld (0e30bh),a		;4ca8
	ld b,008h		;4cab   ; MUERTO: nadie lee B despues de esto
	ld a,(0e30ch)		;4cad   ; el paso, 0 o 2
	sla a		;4cb0   ; por dieciseis
	sla a		;4cb2
	sla a		;4cb4
	sla a		;4cb6
	or 080h		;4cb8   ; mas 0x80: sale 0x80 o 0xA0
	ld e,a			;4cba
	ld d,004h		;4cbb   ; al registro 4 del PSG: el tono fino de la voz C
	call escribe_en_el_psg		;4cbd
	ld hl,04cc7h		;4cc0   ; y el guion que va detras: el ruidito del paso
	ld (0e307h),hl		;4cc3
	ret			;4cc6

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_del_paso: Lo instala 0x4CC0 en (0xE307) en cada paso:
;   la voz C, tres cuadros bajando el volumen de 0x0D a 0. El 0xC9 que sobra
;   al final del bloque no lo lee nadie: el guion se acaba en el 0xFF doble de
;   dos bytes antes
;   0x4cc7..0x4cd4  (13 bytes)
DATA_guion_de_sonido_del_paso:
	defb 005h,000h,00ah,00dh,0ffh,00ah,009h,0ffh,00ah,000h,0ffh,0ffh,0c9h	; 4cc7  .............

; ======================================================================
; CODIGO 0x4cd4..0x4d6c  (152 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Mira si una casilla estorba, y lleva la cuenta en D. Estorban el
; muro, el pilar y el ladrillo ENTERO -0x80 clavado-, y nada mas.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
mira_si_la_casilla_estorba:
	ld a,(bc)			;4cd4   ; lo que hay, y a la casilla siguiente
	inc bc			;4cd5
	cp 088h		;4cd6   ; el muro
	jr nz,L_4CDB		;4cd8
	inc d			;4cda
L_4CDB:
	cp 089h		;4cdb   ; el pilar
	jr nz,L_4CE0		;4cdd
	inc d			;4cdf
L_4CE0:
	cp 080h		;4ce0   ; y el ladrillo entero, no el que se esta cayendo
	ret nz			;4ce2
	inc d			;4ce3
	ret			;4ce4

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL MARCADOR DE ARRIBA, que ocupa la fila 0 entera y se reescribe
; cada cuadro encima del muro que acaba de pintar 0x4DB7:
;
; SCORE:nnnnnn BONUS:nnnnn STG:nn
;
; El marcador lleva SEIS cifras porque 0x4F29 saca cinco y le pega
; un cero detras: los puntos se ensenan multiplicados por diez. Al
; bonus se le quita ese cero de mas -el `dec bc` de 0x4D2A- y en su
; sitio queda el espacio con el que empieza " STG:", que se escribe
; ANTES a proposito para que encaje.
; Aqui se actualiza tambien el record. El `sbc hl,bc` va sin borrar
; el acarreo, y en las fases de una cifra viene puesto de 0x4F19,
; asi que la comparacion sale una unidad corrida: el record se
; reescribe tambien cuando es igual al marcador, que da lo mismo.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_el_marcador:
	ld bc,0e001h		;4ce5   ; fila 0, columna 1
	ld hl,04d87h		;4ce8   ; "SCORE:"
	call suelta_un_texto		;4ceb
	ld bc,0e00dh		;4cee   ; columna 13
	ld hl,04d8eh		;4cf1   ; " BONUS:"
	call suelta_un_texto		;4cf4
	ld bc,0e019h		;4cf7   ; columna 25
	ld hl,04d96h		;4cfa   ; " STG:"
	call suelta_un_texto		;4cfd
	ld bc,0e01eh		;4d00   ; columna 30
	ld a,(0e310h)		;4d03   ; la fase
	call escribe_un_numero_corto		;4d06   ; una o dos cifras
	ld bc,(0e300h)		;4d09   ; el marcador
	ld hl,(0e302h)		;4d0d   ; contra el record
	sbc hl,bc		;4d10
	jr nc,pinta_las_cifras		;4d12   ; si el record es mayor, se queda
	ld (0e302h),bc		;4d14   ; y si no, marca nueva
pinta_las_cifras:
	ld bc,0e007h		;4d18   ; columna 7
	ld hl,(0e300h)		;4d1b   ; el marcador
	call escribe_cinco_cifras_y_un_cero		;4d1e   ; cinco cifras y un cero
	ld bc,0e014h		;4d21   ; columna 20
	ld hl,(0e30dh)		;4d24   ; el bonus
	call escribe_cinco_cifras_y_un_cero		;4d27   ; lo mismo
	dec bc			;4d2a   ; pero al bonus se le quita el cero de mas
	ld a,020h		;4d2b   ; y se deja el espacio de " STG:"
	ld (bc),a			;4d2d
	ld bc,0e2e1h		;4d2e   ; fila 23, columna 1
	ld hl,04d9ch		;4d31   ; " BOMBERMAN HUDSON SOFT 1983"
	jp suelta_un_texto		;4d34

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL AVISO DE BOMBA AUTOMATICA, que solo sale en las fases
; multiplos de cuatro: la misma condicion que 0x4922, donde el
; juego deja de pedir el disparo. Parpadea encima del rotulo de
; abajo, dieciseis cuadros puesto y ocho quitado.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_el_aviso_de_bomba_automatica:
	ld a,(0e310h)		;4d37   ; la fase
	and 003h		;4d3a   ; solo las multiplos de cuatro
	ret nz			;4d3c
	ld bc,0e2e1h		;4d3d   ; fila 23, columna 1
	ld a,(0e386h)		;4d40   ; toca ensenarlo?
	or a			;4d43
	jr z,quita_el_aviso		;4d44
	ld hl,0e386h		;4d46   ; la cuenta de dieciseis cuadros
	call avanza_un_contador		;4d49
	ld hl,04d6ch		;4d4c   ; "  BOMB AUTO SETTING STAGE "
	jp suelta_un_texto		;4d4f
quita_el_aviso:
	ld h,b			;4d52   ; y si no toca, veintiseis columnas
	ld l,c			;4d53
	ld b,01ah		;4d54
L_4D56:
	ld (hl),020h		;4d56   ; en blanco
	inc hl			;4d58
	djnz L_4D56		;4d59
	ld hl,0e388h		;4d5b   ; la cuenta de ocho cuadros
	call avanza_un_contador		;4d5e
	ld a,(0e388h)		;4d61   ; si no cuadra, sigue quitado
	or a			;4d64
	ret nz			;4d65
	ld hl,0e386h		;4d66   ; y cuando cuadra, vuelve a ponerse
	jp avanza_un_contador		;4d69

; ----------------------------------------------------------------------
; DATOS texto_bomba_automatica: El rotulo que parpadea en la fila 23 en las
;   fases multiplos de cuatro. Dibujado desde la ROM dice "  BOMB AUTO SETTING
;   STAGE ", y esta escrito con casillas de tres bloques de graficos
;   distintos: la B, la O y la U de 0x5B26, la T y la G de 0x5B7C, y la M, la
;   A, la I y la N de la pantalla de titulo, que en la partida no se
;   sobreescriben
;   0x4d6c..0x4d87  (27 bytes)
DATA_texto_bomba_automatica:
	defb 020h,020h,015h,016h,096h,015h,020h,095h,018h,030h,016h,020h,010h,014h,030h,030h	; 4d6c    .... ..0. ..00
	defb 097h,017h,031h,020h,010h,030h,095h,031h,014h,020h,000h	; 4d7c  ..1 .0.1. .

; ----------------------------------------------------------------------
; DATOS texto_score: "SCORE:", en la fila 0 columna 1
;   0x4d87..0x4d8e  (7 bytes)
DATA_texto_score:
	defb 010h,011h,012h,013h,014h,021h,000h	; 4d87

; ----------------------------------------------------------------------
; DATOS texto_bonus: " BONUS:", en la fila 0 columna 13
;   0x4d8e..0x4d96  (8 bytes)
DATA_texto_bonus:
	defb 020h,015h,016h,017h,018h,019h,021h,000h	; 4d8e   .....!.

; ----------------------------------------------------------------------
; DATOS texto_stg: " STG:", en la fila 0 columna 25. El espacio del principio
;   es el que tapa el cero de mas del bonus
;   0x4d96..0x4d9c  (6 bytes)
DATA_texto_stg:
	defb 020h,010h,030h,031h,021h,000h	; 4d96

; ----------------------------------------------------------------------
; DATOS texto_de_la_firma: " BOMBERMAN HUDSON SOFT 1983", en la fila 23, y el
;   unico sitio donde el juego se firma mientras se juega
;   0x4d9c..0x4db7  (27 bytes)
DATA_texto_de_la_firma:
	defb 020h,015h,016h,096h,015h,014h,013h,096h,095h,017h,020h,092h,018h,093h,010h,012h	; 4d9c   ......... .....
	defb 017h,010h,012h,094h,030h,020h,001h,009h,008h,003h,000h	; 4dac  ....0 .....

; ======================================================================
; CODIGO 0x4db7..0x4e0c  (85 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL TABLERO: el marco y los pilares. Se repinta ENTERO cada cuadro
; y solo en la pantalla de arriba, nunca en el tablero de abajo, y
; por eso el muro y el pilar no se pueden romper: no estan donde
; las llamas escriben.
; El marco son la fila 0, la 23 y las dos columnas de los lados; los
; pilares, treinta y cinco cuadrados de dos por dos cada cuatro
; filas y cada cuatro columnas, o sea las casillas de tablero con
; las DOS coordenadas impares. El area de juego que queda son 22
; filas por 30 columnas, o sea 11 por 15 casillas de tablero.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_el_tablero:
	ld a,088h		;4db7   ; el muro
	ld b,020h		;4db9   ; treinta y dos casillas
	ld hl,0e000h		;4dbb   ; la fila 0 entera
otra_casilla_de_la_fila_0:
	ld (hl),a			;4dbe
	inc hl			;4dbf
	djnz otra_casilla_de_la_fila_0		;4dc0   ; hasta acabarla
	ld b,020h		;4dc2   ; otras treinta y dos
	ld hl,0e2e0h		;4dc4   ; la fila 23
otra_casilla_de_la_fila_23:
	ld (hl),a			;4dc7
	inc hl			;4dc8
	djnz otra_casilla_de_la_fila_23		;4dc9   ; hasta acabarla
	ld b,017h		;4dcb   ; veintitres filas
	ld hl,0e01fh		;4dcd   ; empezando por la columna 31 de la fila 0
	ld de,0001fh		;4dd0   ; y de dos en dos, saltando 31: cae en la 31 y en la 0 de la siguiente
otra_pareja_de_los_lados:
	ld (hl),a			;4dd3   ; la columna 31
	inc hl			;4dd4
	ld (hl),a			;4dd5   ; y la 0 de la fila de abajo
	add hl,de			;4dd6   ; a la pareja siguiente
	djnz otra_pareja_de_los_lados		;4dd7
	ld hl,0e063h		;4dd9   ; el primer pilar: fila 3, columna 3
	ld c,005h		;4ddc   ; cinco filas de pilares
	ld a,089h		;4dde   ; el pilar
otra_fila_de_pilares:
	ld b,007h		;4de0   ; siete por fila
otro_pilar_de_la_fila:
	call pinta_un_pilar		;4de2   ; el cuadrado de dos por dos
	or a			;4de5
	ld de,0001dh		;4de6   ; y cuatro columnas a la derecha: 0x21 menos 0x1D
	sbc hl,de		;4de9
	djnz otro_pilar_de_la_fila		;4deb
	ld de,00064h		;4ded   ; al primero de la fila siguiente, cuatro filas mas abajo
	add hl,de			;4df0
	dec c			;4df1   ; hasta las cinco filas
	jr nz,otra_fila_de_pilares		;4df2
	ret			;4df4
pinta_un_pilar:
	ld (hl),a			;4df5   ; arriba a la izquierda
	inc hl			;4df6
	ld (hl),a			;4df7   ; arriba a la derecha
	ld de,0001fh		;4df8   ; una fila mas abajo
	add hl,de			;4dfb
	ld (hl),a			;4dfc   ; abajo a la izquierda
	inc hl			;4dfd
	ld (hl),a			;4dfe   ; y abajo a la derecha
	ret			;4dff

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS VIDAS, abajo a la derecha: una tira de un solo rotulo con el
; dibujo del bombero y los dos puntos, y detras la cifra. El truco
; es que `pinta_una_tira_de_rotulos` deja BC apuntando al byte de
; despues del texto, asi que con un `dec bc` se cae justo en el
; espacio que el rotulo dejo reservado.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pinta_las_vidas:
	ld hl,04e0ch		;4e00   ; la tira, de un solo rotulo
	call pinta_una_tira_de_rotulos		;4e03
	dec bc			;4e06   ; el hueco que quedo detras de los dos puntos
	ld a,(0e30fh)		;4e07   ; las vidas que quedan
	ld (bc),a			;4e0a   ; puestas ahi como cifra
	ret			;4e0b

; ----------------------------------------------------------------------
; DATOS rotulo_de_las_vidas: Un solo rotulo (fila 23, columna 26) con el texto
;   "  " + la casilla 0x90 -el bombero- + ":" + un espacio, cerrado por 0x00,
;   y el 0xFF que cierra la tira. En ese espacio del final escribe 0x4E07 el
;   numero de vidas
;   0x4e0c..0x4e15  (9 bytes)
DATA_rotulo_de_las_vidas:
	defb 017h,01ah,020h,020h,090h,021h,020h,000h,0ffh	; 4e0c  ..  .! ..

; ======================================================================
; CODIGO 0x4e15..0x4edf  (202 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UNA CASILLA DE TABLERO AL AZAR: columna de 0 a 14 y fila de 0 a
; 10, sorteando otra vez lo que se salga. Las quince por once son
; el tablero entero.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
una_casilla_al_azar:
	call numero_al_azar		;4e15   ; un numero al azar
	and 01fh		;4e18   ; de 0 a 31
	cp 00fh		;4e1a   ; de 15 para arriba no vale
	jr nc,una_casilla_al_azar		;4e1c
	ld c,a			;4e1e   ; la columna
sortea_la_fila:
	call numero_al_azar		;4e1f   ; otro
	and 01fh		;4e22   ; de 0 a 31
	cp 00bh		;4e24   ; de 11 para arriba no vale
	jr nc,sortea_la_fila		;4e26
	ld b,a			;4e28   ; y la fila
	ret			;4e29

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; DE CASILLA DE TABLERO A CASILLA DE PANTALLA: por dos y uno mas.
; Aqui es donde se ve que el tablero de 15 por 11 esta metido en
; una pantalla de 32 por 24 dejando el marco fuera.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
de_casilla_a_pantalla:
	ld a,b			;4e2a   ; la fila por dos
	add a,a			;4e2b
	add a,001h		;4e2c   ; y una mas
	ld b,a			;4e2e
	ld a,c			;4e2f   ; la columna por dos
	add a,a			;4e30
	add a,001h		;4e31   ; y una mas
	ld c,a			;4e33
	ret			;4e34

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; SIEMBRA LA FASE: primero el sitio del bombero y luego los treinta
; y cinco ladrillos. El bombero se sortea entre las casillas 2 y 12
; de ancho y 2 y 8 de alto -o sea nunca en el borde- y tiene que
; caer en una casilla vacia, que es como se evita que salga dentro
; de un pilar.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
siembra_la_fase:
	call una_casilla_al_azar		;4e35   ; una casilla al azar
	ld a,c			;4e38   ; la columna
	ld (0e37ch),a		;4e39   ; guardada: es la referencia de la que se separan los ladrillos
	cp 002h		;4e3c   ; de la 2 a la 12
	jr c,siembra_la_fase		;4e3e
	cp 00dh		;4e40
	jr nc,siembra_la_fase		;4e42
	ld a,b			;4e44   ; la fila
	ld (0e37dh),a		;4e45   ; guardada por lo mismo
	cp 002h		;4e48   ; de la 2 a la 8
	jr c,siembra_la_fase		;4e4a
	cp 009h		;4e4c
	jr nc,siembra_la_fase		;4e4e
	call de_casilla_a_pantalla		;4e50   ; a casillas de pantalla
	push bc			;4e53
	call pon_el_cursor		;4e54   ; el cursor
	ld a,(bc)			;4e57   ; tiene que estar vacia: si hay pilar, otra vez
	cp 020h		;4e58
	pop bc			;4e5a
	jr nz,siembra_la_fase		;4e5b
	ld a,c			;4e5d   ; la columna del bombero
	ld (0e309h),a		;4e5e
	ld a,b			;4e61   ; y su fila
	ld (0e30ah),a		;4e62
	ld a,023h		;4e65   ; y treinta y cinco ladrillos
otro_ladrillo:
	ex af,af'			;4e67   ; la cuenta, guardada en A'
busca_sitio_para_un_ladrillo:
	call una_casilla_al_azar		;4e68   ; una casilla al azar
	ld d,b			;4e6b   ; guardada
	ld e,c			;4e6c
	ld a,(0e37ch)		;4e6d   ; contra la columna del bombero
	sub e			;4e70
	jr nc,mira_la_distancia_en_columna		;4e71   ; en valor absoluto
	neg		;4e73
mira_la_distancia_en_columna:
	cp 002h		;4e75   ; a dos o mas de distancia vale
	jr nc,mira_las_paridades		;4e77
	ld a,(0e37dh)		;4e79   ; y si no, se mira la fila
	sub d			;4e7c
	jr nc,mira_la_distancia_en_fila		;4e7d   ; en valor absoluto
	neg		;4e7f
mira_la_distancia_en_fila:
	cp 002h		;4e81   ; a dos o mas vale
	jr nc,mira_las_paridades		;4e83
	jr busca_sitio_para_un_ladrillo		;4e85   ; y si no, otra casilla
mira_las_paridades:
	ld a,c			;4e87   ; la columna
	bit 0,a		;4e88   ; impar?
	jr z,columna_par		;4e8a
	ld a,b			;4e8c   ; pues la fila tiene que ser par
	bit 0,a		;4e8d
	jr nz,busca_sitio_para_un_ladrillo		;4e8f   ; las dos impares es un pilar: otra casilla
	jr pon_el_ladrillo		;4e91
columna_par:
	ld a,b			;4e93   ; columna par: la fila tiene que ser impar
	bit 0,a		;4e94
	jr z,busca_sitio_para_un_ladrillo		;4e96   ; las dos pares no se usan: otra casilla
pon_el_ladrillo:
	call de_casilla_a_pantalla		;4e98   ; a casillas de pantalla
	ld hl,04edfh		;4e9b   ; la lista de casillas prohibidas
mira_la_lista_de_prohibidas:
	ld a,(hl)			;4e9e   ; con 0xFF se acabo la lista
	inc a			;4e9f
	jr z,apunta_el_premio		;4ea0
	dec a			;4ea2
	cp b			;4ea3   ; la fila
	jr nz,solo_coincidia_la_fila		;4ea4
	inc hl			;4ea6
	ld a,(hl)			;4ea7
	cp c			;4ea8   ; y la columna
	jr z,busca_sitio_para_un_ladrillo		;4ea9   ; prohibida: otra casilla
	jr a_la_pareja_siguiente		;4eab
solo_coincidia_la_fila:
	inc hl			;4ead   ; solo coincidia la fila
a_la_pareja_siguiente:
	inc hl			;4eae   ; a la pareja siguiente
	jr mira_la_lista_de_prohibidas		;4eaf
apunta_el_premio:
	ld a,(0e380h)		;4eb1   ; el premio ya esta puesto?
	or a			;4eb4
	jr nz,apunta_la_puerta		;4eb5   ; pues este ladrillo solo lleva puerta
	ld a,b			;4eb7   ; y si no, este es el primero: aqui va el premio
	ld (0e37fh),a		;4eb8
	ld a,c			;4ebb
	ld (0e37eh),a		;4ebc
	ld a,001h		;4ebf   ; puesto
	ld (0e380h),a		;4ec1
apunta_la_puerta:
	ld a,b			;4ec4   ; la puerta se apunta SIEMPRE, asi que se queda en el ultimo
	ld (0e382h),a		;4ec5
	ld a,c			;4ec8
	ld (0e381h),a		;4ec9
	ld a,001h		;4ecc   ; puesta
	ld (0e383h),a		;4ece
	call pon_el_cursor_en_el_tablero		;4ed1   ; el cursor, en el TABLERO
	ld a,080h		;4ed4   ; el ladrillo entero
	call pinta_cuatro_casillas_iguales		;4ed6   ; las cuatro casillas
	ex af,af'			;4ed9   ; la cuenta
	dec a			;4eda   ; hasta los treinta y cinco
	jp nz,otro_ladrillo		;4edb
	ret			;4ede

; ----------------------------------------------------------------------
; DATOS casillas_prohibidas: Ocho parejas (fila, columna) de pantalla y el
;   0xFF que cierra, que mira 0x4E9E antes de poner un ladrillo: (1,3), (3,1),
;   (19,1), (21,3), (1,27), (3,29), (21,27) y (19,29). Son las vecinas de las
;   cuatro esquinas por donde salen los enemigos -las de 0x45C6-, para que no
;   salgan tapiados
;   0x4edf..0x4ef0  (17 bytes)
DATA_casillas_prohibidas:
	defb 001h,003h	; 4edf
	defb 003h,001h	; 4ee1
	defb 013h,001h	; 4ee3
	defb 015h,003h	; 4ee5
	defb 001h,01bh	; 4ee7
	defb 003h,01dh	; 4ee9
	defb 015h,01bh	; 4eeb
	defb 013h,01dh	; 4eed
	defb 0ffh	; 4eef

; ======================================================================
; CODIGO 0x4ef0..0x4f8d  (157 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; BORRA UNA CASILLA DE TABLERO. Nueve bytes que SON INSTRUCCIONES y
; que no llama nadie: no hay un solo `call 4EF0h` en los 8 KB. Es
; lo mismo que hace 0x4A7A dentro de otra rutina, asi que lo que
; queda aqui es la version suelta que dejo de usarse. Se declara
; como codigo porque eso es lo que es, no porque se ejecute.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
borra_una_casilla_de_tablero:
	call pon_el_cursor_en_el_tablero		;4ef0   ; el cursor, en el TABLERO
	ld a,020h		;4ef3   ; casilla vacia
	call pinta_cuatro_casillas_iguales		;4ef5   ; las cuatro
	ret			;4ef8

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL AZAR. Una realimentacion de dieciseis bits sobre (0xE384) que
; ADEMAS mezcla el registro R, o sea el contador de refresco de la
; memoria. Eso hace que la serie no dependa solo de la semilla:
; depende de cuantas instrucciones se hayan ejecutado antes, y por
; tanto de cuando se pulso el disparo. Dos partidas no reparten los
; mismos ladrillos ni aunque se arranque igual.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
numero_al_azar:
	push hl			;4ef9
	push de			;4efa
	push bc			;4efb
	ld hl,(0e384h)		;4efc   ; la semilla
	ld a,h			;4eff   ; el bit que va a entrar, de mezclar H con L
	rla			;4f00
	rla			;4f01
	xor l			;4f02
	rra			;4f03
	push af			;4f04   ; guardado en el acarreo
	ld a,h			;4f05   ; H se mezcla con L
	xor l			;4f06
	ld h,a			;4f07
	ld a,r		;4f08   ; y L con el contador de refresco de la memoria
	xor l			;4f0a
	ld l,a			;4f0b
	pop af			;4f0c   ; el bit guardado
	rl l		;4f0d   ; y entra por abajo
	rl h		;4f0f
	ld (0e384h),hl		;4f11   ; la semilla nueva
	ld a,l			;4f14   ; lo que se devuelve es el byte de abajo
	pop bc			;4f15
	pop de			;4f16
	pop hl			;4f17
	ret			;4f18

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UN NUMERO DE UNA O DOS CIFRAS en (BC). Por debajo de diez cabe en
; una casilla; a partir de ahi se saca la decena con la division
; por restas de 0x4F48 y la unidad se escribe detras.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
escribe_un_numero_corto:
	cp 00ah		;4f19   ; menos de diez
	jr c,escribe_la_cifra		;4f1b
	ld h,000h		;4f1d   ; el numero, en HL
	ld l,a			;4f1f
	ld de,0000ah		;4f20   ; dividido entre diez: la decena se escribe sola
	call saca_una_cifra		;4f23
	ld a,l			;4f26   ; y lo que sobra es la unidad
escribe_la_cifra:
	ld (bc),a			;4f27   ; a la pantalla
	ret			;4f28

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; CINCO CIFRAS Y UN CERO en (BC), que es como se ensenan el
; marcador y el bonus. Las cuatro primeras salen de restar 10000,
; 1000, 100 y 10; la quinta es lo que sobra; y el cero del final se
; pone a mano, o sea que el marcador de verdad va multiplicado por
; diez. Al bonus ese cero se lo quita quien llama.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
escribe_cinco_cifras_y_un_cero:
	ld de,02710h		;4f29   ; las decenas de millar
	call saca_una_cifra		;4f2c
	ld de,003e8h		;4f2f   ; los millares
	call saca_una_cifra		;4f32
	ld de,00064h		;4f35   ; las centenas
	call saca_una_cifra		;4f38
	ld de,0000ah		;4f3b   ; las decenas
	call saca_una_cifra		;4f3e
	ld a,l			;4f41   ; y lo que queda son las unidades
	ld (bc),a			;4f42
	inc bc			;4f43
	xor a			;4f44   ; y un cero de propina
	ld (bc),a			;4f45
	inc bc			;4f46
	ret			;4f47
saca_una_cifra:
	xor a			;4f48   ; la cifra empieza en cero
resta_hasta_pasarse:
	or a			;4f49
	sbc hl,de		;4f4a   ; se resta hasta pasarse
	jr c,devuelve_lo_que_sobra		;4f4c
	inc a			;4f4e   ; y cada resta es una unidad
	jr resta_hasta_pasarse		;4f4f
devuelve_lo_que_sobra:
	add hl,de			;4f51   ; se devuelve lo que se paso
	ld (bc),a			;4f52   ; la cifra, a la pantalla
	inc bc			;4f53
	ret			;4f54

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS DOS PANTALLAS EN LA RAM, y las tres rutinas que las manejan.
; 0x4F55 deja el TABLERO en blanco, 0x4F63 lo copia encima de la
; PANTALLA -es la primera cosa que hace cada cuadro- y 0x4F6F da la
; direccion de una casilla del tablero sumandole 0x38A a la de la
; pantalla, que es lo que separa las dos.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
borra_el_tablero:
	ld hl,0e38ah		;4f55   ; el tablero
	ld de,0e38bh		;4f58   ; y su copia desplazada uno, que es como se rellena con LDIR
	ld bc,002ffh		;4f5b   ; 767 bytes
	ld (hl),020h		;4f5e   ; la casilla vacia en el primero
	ldir		;4f60
	ret			;4f62
copia_el_tablero_a_la_pantalla:
	ld de,0e000h		;4f63   ; la pantalla
	ld hl,0e38ah		;4f66   ; desde el tablero
	ld bc,00300h		;4f69   ; los 768 bytes de golpe
	ldir		;4f6c
	ret			;4f6e
pon_el_cursor_en_el_tablero:
	push hl			;4f6f
	call pon_el_cursor		;4f70   ; la casilla en la pantalla
	ld hl,0038ah		;4f73   ; y 0x38A mas alla esta la misma en el tablero
	add hl,bc			;4f76
	ld b,h			;4f77
	ld c,l			;4f78
	pop hl			;4f79
	ret			;4f7a

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA ESPERA, que es lo unico que marca el ritmo del juego: no hay
; sincronismo con el barrido de la pantalla, solo un bucle en
; vacio. 0x4F7B es la larga, la de la muerte; el bucle de dentro lo
; usa tambien 0x46C8 con 0x500, que es el paso normal.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
espera_larga:
	ld hl,05000h		;4f7b   ; 0x5000 vueltas
espera:
	dec hl			;4f7e   ; una menos
	ld a,h			;4f7f   ; hasta cero
	or l			;4f80
	jr nz,espera		;4f81
	ret			;4f83

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; OTRA ESPERA, de 0x400 vueltas, que no llama nadie: no hay un solo
; `call 4F84h` en los 8 KB. Es la hermana pequena de 0x4F7B y se
; quedo dentro. Se declara como codigo porque son instrucciones,
; no porque se ejecute.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
espera_corta_que_no_usa_nadie:
	ld hl,00400h		;4f84   ; 0x400 vueltas
L_4F87:
	dec hl			;4f87   ; una menos
	ld a,h			;4f88   ; hasta cero
	or l			;4f89
	jr nz,L_4F87		;4f8a
	ret			;4f8c

; ----------------------------------------------------------------------
; DATOS brazos_de_la_explosion: Los cuatro brazos de la explosion, en OCHO
;   tiras de cuatro parejas (fila, columna) que suma 0x4AB4 a la casilla de la
;   bomba, y cuatro 0x80 que cierran la tabla. Izquierda:
;   (0,-1)(0,-2)(0,-3)(0,-4) y la misma tira una fila mas abajo. Derecha:
;   (0,+2)..(0,+5) y su pareja. Arriba: (-1,0)..(-4,0) y la misma una columna
;   a la derecha. Abajo: (+2,0)..(+5,0) y su pareja. Cuatro casillas de
;   pantalla por lado son DOS casillas de tablero, que es el alcance de la
;   explosion
;   0x4f8d..0x4fd1  (68 bytes)
DATA_brazos_de_la_explosion:
	defb 000h,0ffh,000h,0feh,000h,0fdh,000h,0fch	; 4f8d  ........
	defb 001h,0ffh,001h,0feh,001h,0fdh,001h,0fch	; 4f95  ........
	defb 000h,002h,000h,003h,000h,004h,000h,005h	; 4f9d  ........
	defb 001h,002h,001h,003h,001h,004h,001h,005h	; 4fa5  ........
	defb 0ffh,000h,0feh,000h,0fdh,000h,0fch,000h	; 4fad  ........
	defb 0ffh,001h,0feh,001h,0fdh,001h,0fch,001h	; 4fb5  ........
	defb 002h,000h,003h,000h,004h,000h,005h,000h	; 4fbd  ........
	defb 002h,001h,003h,001h,004h,001h,005h,001h	; 4fc5  ........
	defb 080h,080h,080h,080h	; 4fcd

; ======================================================================
; CODIGO 0x4fd1..0x4fdd  (12 bytes)
; ======================================================================


pon_los_valores_de_partida:
	ld hl,04fddh		;4fd1   ; la tabla
	ld de,0e305h		;4fd4   ; a las variables del juego
	ld bc,00090h		;4fd7   ; 0x90 bytes, once mas de los que son datos
	ldir		;4fda
	ret			;4fdc

; ----------------------------------------------------------------------
; DATOS valores_de_partida_de_la_ram: Lo que 0x4FD1 vuelca en 0xE305 con un
;   `ldir` de 0x90 bytes. Las dos primeras palabras son 0x4539 repetido, que
;   son los punteros de sonido de arranque; los seis topes de los contadores
;   estan en 0xE370, 72, 74, 76, 78 y 7A, y los dos 0xFF de 0xE354 y 0xE36D
;   cierran las listas de enemigos y de bombas. El `ldir` se pasa once bytes y
;   arrastra el principio de `monta_el_vdp`
;   0x4fdd..0x5062  (133 bytes)
DATA_valores_de_partida_de_la_ram:
	defb 039h,045h,039h,045h,001h,001h,002h,000h,000h,000h,005h,001h,000h,002h,001h,000h	; 4fdd  9E9E............
	defb 000h,000h,01fh,000h,000h,000h,000h,000h,003h,001h,003h,005h,000h,000h,000h,001h	; 4fed  ................
	defb 00bh,002h,009h,000h,000h,001h,001h,001h,001h,009h,000h,000h,000h,007h,001h,003h	; 4ffd  ................
	defb 005h,000h,000h,000h,000h,000h,002h,009h,000h,000h,000h,000h,000h,001h,009h,000h	; 500d  ................
	defb 000h,000h,000h,000h,003h,005h,000h,000h,000h,000h,000h,002h,003h,000h,000h,0ffh	; 501d  ................
	defb 0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 502d  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0ffh,000h,000h,004h,000h,004h,000h,007h	; 503d  ................
	defb 000h,005h,000h,003h,000h,032h,000h,000h,000h,001h,001h,000h,001h,001h,000h,0ffh	; 504d  .....2..........
	defb 0ffh,000h,010h,000h,008h	; 505d

; ======================================================================
; CODIGO 0x5062..0x5144  (226 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Deja la maquina lista: quita el gancho de la BIOS, vuelca los ocho
; registros del VDP desde 0x5144 y apaga la lista de sprites. Ese
; 0xD0 es lo unico que el cartucho hace con los sprites en toda su
; vida: no usa ni uno.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
monta_el_vdp:
	di			;5062   ; sin interrupciones mientras se toca el VDP
	im 1		;5063
	ld a,0c9h		;5065   ; un `ret` en H.TIMI: la BIOS deja de meter mano cada interrupcion
	ld (0fd9fh),a		;5067
	ld d,008h		;506a   ; los ocho registros
	ld c,000h		;506c   ; empezando por el 0
	ld hl,05144h		;506e   ; la tabla de 0x5144
vuelca_un_registro:
	ld b,(hl)			;5071   ; el valor
	call 00047h		;5072   ; BIOS WRTVDP - Writes data in the VDP-register | BIOS WRTVDP
	push hl			;5075   ; un `push hl / pop hl` que no hace nada: sobra
	pop hl			;5076
	inc hl			;5077   ; al registro siguiente
	inc c			;5078
	dec d			;5079
	jr nz,vuelca_un_registro		;507a
	ld hl,01c00h		;507c   ; los atributos de sprite, en 0x1C00
	ld a,0d0h		;507f   ; un 0xD0 en el primero: no hay ni un sprite
	call 0004dh		;5081   ; BIOS WRTVRM - Writes data in VRAM | BIOS WRTVRM
	im 1		;5084   ; y ya se puede interrumpir
	ei			;5086
	ret			;5087

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; CARGA UN BLOQUE DE GRAFICOS EN LOS TRES TERCIOS.
; SCREEN 2 tiene tres juegos de patrones y de color, uno por tercio
; de pantalla, y aqui se cargan los tres con lo mismo: A vale 0, 8 y
; 0x10, que sumados al byte alto del destino dan 0x000, 0x800 y
; 0x1000. El formato del bloque esta arriba, en la cabecera.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
carga_los_graficos_en_los_tres_tercios:
	xor a			;5088   ; el primer tercio
	call carga_un_tercio		;5089
	ld a,008h		;508c   ; el segundo, 0x800 mas alla
	call carga_un_tercio		;508e
	ld a,010h		;5091   ; y el tercero, cayendo dentro
carga_un_tercio:
	push hl			;5093   ; el principio del bloque, para las tres vueltas
	ld e,(hl)			;5094   ; el destino en la VRAM
	inc hl			;5095
	ld d,(hl)			;5096
	inc hl			;5097
	add a,d			;5098   ; mas el tercio que toque
	ld d,a			;5099
	push de			;509a
	add a,020h		;509b   ; y 0x2000 mas arriba, la tabla de color
	ld d,a			;509d
	ld a,(hl)			;509e   ; cuantas casillas
	inc hl			;509f
	push hl			;50a0
	ld l,a			;50a1
	or a			;50a2   ; el cero vale 256
	ld h,000h		;50a3
	jr nz,L_50A8		;50a5
	inc h			;50a7
L_50A8:
	add hl,hl			;50a8   ; por ocho, que es lo que ocupa una casilla
	add hl,hl			;50a9
	add hl,hl			;50aa
	ld c,l			;50ab
	ld b,h			;50ac
	pop hl			;50ad
	push hl			;50ae
	add hl,bc			;50af
	ex (sp),hl			;50b0
	call 0005ch		;50b1   ; BIOS LDIRVM - Block transfers to VRAM from memory | BIOS LDIRVM: los patrones de golpe
	pop de			;50b4
	pop hl			;50b5
rellena_el_color:
	ld a,(de)			;50b6   ; el color
	inc de			;50b7
	cp 0ffh		;50b8   ; con 0xFF se acabo
	jr z,y_al_tercio_siguiente		;50ba
	push af			;50bc
	ld a,(de)			;50bd   ; cuantas casillas del mismo color
	inc de			;50be
	ld c,a			;50bf
	ld b,000h		;50c0
	dec c			;50c2   ; y aqui el cero tambien vale 256
	inc bc			;50c3
	pop af			;50c4
	push bc			;50c5
	call 00056h		;50c6   ; BIOS FILVRM - Fills VRAM with value | BIOS FILVRM
	pop bc			;50c9
	add hl,bc			;50ca   ; y a por el tramo siguiente
	jr rellena_el_color		;50cb
y_al_tercio_siguiente:
	pop hl			;50cd   ; el principio del bloque, para el tercio siguiente
	ret			;50ce

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Un registro del PSG: D el registro y E el valor. La BIOS pide el
; registro en A, y por eso hace falta el `ld a,d`.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
escribe_en_el_psg:
	push af			;50cf   ; D es el registro y E el valor
	ld a,d			;50d0   ; la BIOS lo quiere en A
	call 00093h		;50d1   ; BIOS WRTPSG - Writes data to PSG-register | BIOS WRTPSG
	pop af			;50d4
	ret			;50d5

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL REGISTRO 7 DEL VDP, que es el color de la tinta y el del borde.
; Once bytes que SON INSTRUCCIONES y que no llama nadie: no hay un
; solo `call 50D6h` en los 8 KB. El registro 7 se pone una vez, al
; arrancar, desde la tabla de 0x5144, y no se vuelve a tocar; esta
; rutina es lo que se dejo dentro de cuando se pensaba cambiarlo.
; Se declara como codigo porque eso es lo que es.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pon_el_registro_7_que_no_usa_nadie:
	push bc			;50d6   ; el valor, que la BIOS quiere en B
	ld b,a			;50d7
	ld c,007h		;50d8   ; el registro 7
	di			;50da   ; sin interrupciones
	call 00047h		;50db   ; BIOS WRTVDP - Writes data in the VDP-register | BIOS WRTVDP
	ei			;50de   ; y ya se puede interrumpir
	pop bc			;50df
	ret			;50e0

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL MANDO. Se prueban las tres entradas de GTSTCK -0 el teclado, 1
; y 2 los dos mandos- y se devuelve la primera que diga algo. La
; misma idea con GTTRIG para el disparo, y por eso vale igual el
; espacio que el boton.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
lee_la_cruceta:
	push bc			;50e1
	push de			;50e2
	push hl			;50e3
	xor a			;50e4   ; el teclado
	call 000d5h		;50e5   ; BIOS GTSTCK - Returns the joystick status | BIOS GTSTCK
	or a			;50e8   ; si dice algo, ya esta
	jr nz,L_50F8		;50e9
	ld a,001h		;50eb   ; el mando 1
	call 000d5h		;50ed   ; BIOS GTSTCK - Returns the joystick status
	or a			;50f0
	jr nz,L_50F8		;50f1
	ld a,002h		;50f3   ; y el mando 2
	call 000d5h		;50f5   ; BIOS GTSTCK - Returns the joystick status
L_50F8:
	pop hl			;50f8
	pop de			;50f9
	pop bc			;50fa
	ret			;50fb
lee_el_disparo:
	xor a			;50fc   ; el teclado
	call 000d8h		;50fd   ; BIOS GTTRIG - Returns current trigger status | BIOS GTTRIG, que devuelve 0xFF si esta pulsado
	or a			;5100   ; si dice algo, ya esta
	ret nz			;5101
	ld a,001h		;5102   ; el mando 1
	call 000d8h		;5104   ; BIOS GTTRIG - Returns current trigger status
	or a			;5107
	ret nz			;5108
	ld a,002h		;5109   ; y el mando 2, con el `ret` de la BIOS
	jp 000d8h		;510b   ; BIOS GTTRIG - Returns current trigger status

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; VUELCA LA PANTALLA Y LA DEJA EN BLANCO, en ese orden: LDIRVM de
; los 768 bytes de 0xE000 a la tabla de nombres, y despues un
; `ldir` que la rellena de casilla vacia. Por eso el bucle
; principal puede repintarlo todo desde cero cada cuadro sin
; borrar nada a mano. La segunda mitad tiene etiqueta propia
; porque tambien se llama sola.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
vuelca_la_pantalla:
	ld hl,0e000h		;510e   ; la pantalla de la RAM
	ld de,01800h		;5111   ; a la tabla de nombres
	ld bc,00300h		;5114   ; los 768 bytes
	call 0005ch		;5117   ; BIOS LDIRVM - Block transfers to VRAM from memory | BIOS LDIRVM
borra_la_pantalla:
	ld hl,0e000h		;511a   ; la pantalla
	ld de,0e001h		;511d   ; y su copia desplazada uno
	ld bc,002ffh		;5120   ; 767 bytes
	ld (hl),020h		;5123   ; la casilla vacia en el primero
	ldir		;5125
	ret			;5127

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL CURSOR: fila por 32 mas columna, sobre 0xE000. Los cinco
; `add hl,hl` son la multiplicacion por 32. Devuelve la direccion
; en BC, que es lo que esperan todas las rutinas de pintar.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
pon_el_cursor:
	push hl			;5128
	ld l,b			;5129   ; la fila
	ld h,000h		;512a
	add hl,hl			;512c   ; por 32
	add hl,hl			;512d
	add hl,hl			;512e
	add hl,hl			;512f
	add hl,hl			;5130
	ld b,000h		;5131   ; mas la columna
	add hl,bc			;5133
	ld bc,0e000h		;5134   ; sobre la pantalla de la RAM
	add hl,bc			;5137
	ld c,l			;5138   ; y se devuelve en BC
	ld b,h			;5139
	pop hl			;513a
	ret			;513b

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; SUELTA UN TEXTO en (BC) hasta el 0x00. Los codigos NO son ASCII:
; son casillas de la hoja que este cargada, y cambian entre la
; portada y la partida. Al volver, BC apunta al byte de despues del
; ultimo, que es de lo que se aprovecha 0x4E00 para las vidas.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
suelta_un_texto:
	ld a,(hl)			;513c   ; la casilla
	inc hl			;513d
	or a			;513e   ; con 0x00 se acabo
	ret z			;513f
	ld (bc),a			;5140   ; a la pantalla
	inc bc			;5141
	jr suelta_un_texto		;5142   ; y a la siguiente

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho registros que 0x5062 vuelca del 0 al 7:
;   SCREEN 2, sprites de 16x16, nombres en 0x1800, atributos en 0x1C00 y
;   patrones de sprite en 0x3800. Los de sprite se declaran y no se usan: el
;   juego no pinta ni uno
;   0x5144..0x514c  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0c2h,006h,07fh,007h,038h,007h,0f0h	; 5144  .....8..

; ----------------------------------------------------------------------
; DATOS graficos_de_la_portada: El bloque que carga 0x427F: destino 0x0000,
;   256 casillas de patrones y 235 tramos de color, o sea la hoja entera. Trae
;   la fuente, el rotulo grande de BOMBER MAN de la fila 2 -casillas 0x22 a
;   0x2F- y los dibujos del bombero, la bomba, el premio y la puerta. Lo
;   vuelca 0x5088 en los tres tercios
;   0x514c..0x5b26  (2522 bytes)
DATA_graficos_de_la_portada:
	defb 000h,000h,000h,03ch,042h,046h,05ah,062h,042h,03ch,000h,010h,030h,050h,010h,010h	; 514c  ...<BFZbB<..0P..
	defb 010h,07ch,000h,03ch,042h,002h,00ch,030h,040h,07eh,000h,03ch,042h,002h,01ch,002h	; 515c  .|.<B..0@~.<B...
	defb 042h,03ch,000h,004h,00ch,014h,024h,07eh,004h,004h,000h,07eh,040h,078h,004h,002h	; 516c  B<....$~...~@x..
	defb 044h,038h,000h,01ch,020h,040h,07ch,042h,042h,03ch,000h,07eh,042h,004h,008h,010h	; 517c  D8.. @|BB<.~B...
	defb 010h,010h,000h,03ch,042h,042h,03ch,042h,042h,03ch,000h,03ch,042h,042h,03eh,002h	; 518c  ...<BB<BB<.<BB>.
	defb 004h,038h,000h,03fh,0ffh,040h,02fh,010h,00fh,055h,031h,0fch,0f2h,009h,0f5h,003h	; 519c  .8.?.@/..U1.....
	defb 0feh,06bh,015h,008h,01ch,03eh,049h,008h,008h,008h,008h,008h,004h,006h,0ffh,006h	; 51ac  .k...>I.........
	defb 004h,008h,000h,003h,00dh,011h,02dh,05dh,05dh,0b9h,0bdh,0c0h,0b0h,088h,0b4h,0bah	; 51bc  ......-]].......
	defb 0bah,09dh,0bdh,000h,000h,000h,00fh,008h,008h,008h,008h,000h,000h,000h,0f0h,010h	; 51cc  ................
	defb 010h,010h,010h,008h,008h,008h,00fh,000h,000h,000h,000h,010h,010h,010h,0f0h,000h	; 51dc  ................
	defb 000h,000h,000h,000h,000h,000h,0ffh,000h,000h,000h,000h,008h,008h,008h,008h,008h	; 51ec  ................
	defb 008h,008h,008h,010h,010h,010h,010h,010h,010h,010h,010h,004h,008h,010h,010h,010h	; 51fc  ................
	defb 008h,004h,000h,020h,010h,008h,008h,008h,010h,020h,000h,000h,000h,000h,000h,030h	; 520c  ... ..... .....0
	defb 030h,000h,000h,044h,0ffh,080h,0bfh,0b6h,0bfh,080h,0ffh,0a9h,0f5h,015h,0d5h,0d2h	; 521c  0..D............
	defb 0d4h,018h,0f0h,008h,008h,008h,008h,049h,03eh,01ch,008h,010h,020h,060h,0ffh,060h	; 522c  .......I>... `.`
	defb 020h,010h,000h,0bdh,0bdh,0ffh,075h,045h,072h,045h,075h,0bdh,0bfh,0ffh,077h,022h	; 523c   .....uErEu...w"
	defb 022h,022h,072h,000h,000h,000h,000h,000h,000h,000h,000h,018h,018h,018h,000h,018h	; 524c  ""r.............
	defb 018h,018h,000h,000h,07fh,07fh,060h,060h,060h,060h,07fh,000h,0f8h,0f8h,006h,006h	; 525c  ......````......
	defb 006h,006h,0f8h,000h,01fh,01fh,060h,060h,060h,060h,060h,000h,0f8h,0f8h,006h,006h	; 526c  ......`````.....
	defb 006h,006h,006h,000h,060h,060h,078h,078h,066h,066h,061h,000h,006h,006h,01eh,01eh	; 527c  ....``xxffa.....
	defb 066h,066h,086h,000h,07fh,07fh,060h,060h,060h,060h,07fh,000h,0feh,0feh,000h,000h	; 528c  ff....````......
	defb 000h,000h,0f8h,000h,07fh,07fh,060h,060h,060h,060h,07fh,000h,0f8h,0f8h,006h,006h	; 529c  ......````......
	defb 006h,006h,0f8h,000h,007h,007h,018h,018h,060h,060h,07fh,000h,0e0h,0e0h,018h,018h	; 52ac  ........``......
	defb 006h,006h,0feh,000h,060h,060h,078h,078h,066h,066h,061h,000h,006h,006h,006h,006h	; 52bc  ....``xxffa.....
	defb 006h,006h,086h,03ch,042h,046h,05ah,062h,042h,03ch,000h,03ch,042h,002h,00ch,010h	; 52cc  ...<BFZbB<.<B...
	defb 000h,010h,000h,07fh,060h,060h,060h,060h,07fh,07fh,000h,0f8h,006h,006h,006h,006h	; 52dc  ....````........
	defb 0f8h,0f8h,000h,060h,060h,060h,060h,060h,01fh,01fh,000h,006h,006h,006h,006h,006h	; 52ec  ...`````........
	defb 0f8h,0f8h,000h,061h,060h,060h,060h,060h,060h,060h,000h,086h,006h,006h,006h,006h	; 52fc  ...a``````......
	defb 006h,006h,000h,07fh,060h,060h,060h,060h,07fh,07fh,000h,0f8h,000h,000h,000h,000h	; 530c  ....````........
	defb 0feh,0feh,000h,07fh,060h,060h,060h,060h,060h,060h,000h,0f8h,060h,060h,018h,018h	; 531c  ....``````..``..
	defb 006h,006h,000h,07fh,060h,060h,060h,060h,060h,060h,000h,0feh,006h,006h,006h,006h	; 532c  ....``````......
	defb 006h,006h,000h,061h,060h,060h,060h,060h,060h,060h,000h,086h,066h,066h,01eh,01eh	; 533c  ...a``````..ff..
	defb 006h,006h,000h,000h,000h,000h,07ch,000h,000h,000h,000h,018h,024h,042h,07eh,042h	; 534c  ......|.....$B~B
	defb 042h,042h,000h,07ch,042h,042h,07ch,042h,042h,07ch,000h,01ch,022h,040h,040h,040h	; 535c  BB.|BB|BB|.."@@@
	defb 022h,01ch,000h,078h,044h,042h,042h,042h,044h,078h,000h,07eh,040h,040h,078h,040h	; 536c  "..xDBBBDx.~@@x@
	defb 040h,07eh,000h,07eh,040h,040h,078h,040h,040h,040h,000h,01ch,022h,040h,04eh,042h	; 537c  @~.~@@x@@@.."@NB
	defb 022h,01ch,000h,042h,042h,042h,07eh,042h,042h,042h,000h,01ch,008h,008h,008h,008h	; 538c  "..BBB~BBB......
	defb 008h,01ch,000h,00eh,004h,004h,004h,004h,044h,038h,000h,042h,044h,048h,070h,048h	; 539c  ........D8.BDHpH
	defb 044h,042h,000h,040h,040h,040h,040h,040h,040h,07eh,000h,042h,066h,05ah,05ah,042h	; 53ac  DB.@@@@@@~.BfZZB
	defb 042h,042h,000h,042h,062h,052h,04ah,046h,042h,042h,000h,03ch,042h,042h,042h,042h	; 53bc  BB.BbRJFBB.<BBBB
	defb 042h,03ch,000h,07ch,042h,042h,07ch,040h,040h,040h,000h,000h,000h,000h,000h,000h	; 53cc  B<.|BB|@@@......
	defb 000h,000h,000h,07ch,042h,042h,07ch,048h,044h,042h,000h,03ch,042h,040h,03ch,002h	; 53dc  ...|BB|HDB.<B@<.
	defb 042h,03ch,000h,03eh,008h,008h,008h,008h,008h,008h,000h,042h,042h,042h,042h,042h	; 53ec  B<.>.......BBBBB
	defb 042h,03ch,000h,000h,000h,000h,000h,000h,000h,000h,000h,042h,042h,042h,05ah,05ah	; 53fc  B<.........BBBZZ
	defb 066h,042h,000h,042h,042h,024h,018h,024h,042h,042h,000h,022h,022h,022h,01ch,008h	; 540c  fB.BB$.$BB."""..
	defb 008h,008h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 541c  ................
	defb 000h,000h,000h,004h,008h,010h,010h,010h,008h,004h,000h,020h,010h,008h,008h,008h	; 542c  ........... ....
	defb 010h,020h,000h,000h,000h,000h,000h,030h,030h,000h,000h,03ch,042h,002h,00ch,010h	; 543c  . .....00..<B...
	defb 000h,010h,000h,000h,000h,001h,001h,007h,01fh,03fh,07fh,050h,0e0h,050h,000h,0c0h	; 544c  .........?.P.P..
	defb 0f0h,0f8h,0fch,000h,000h,001h,001h,007h,01fh,03fh,07fh,020h,0e0h,020h,000h,0c0h	; 545c  .........?. . ..
	defb 0f0h,0f8h,0fch,001h,000h,001h,001h,007h,01fh,03fh,07fh,040h,080h,040h,000h,0c0h	; 546c  .........?.@.@..
	defb 0f0h,0f8h,0fch,000h,001h,000h,001h,007h,01fh,03fh,07fh,080h,040h,080h,000h,0c0h	; 547c  .........?..@...
	defb 0f0h,0f8h,0fch,000h,000h,001h,003h,007h,01fh,03fh,07fh,000h,000h,000h,080h,0c0h	; 548c  .........?......
	defb 0f0h,0f8h,0fch,000h,000h,000h,001h,002h,007h,01fh,03fh,000h,000h,000h,000h,080h	; 549c  ..........?.....
	defb 0c0h,0f0h,0f8h,000h,000h,001h,003h,007h,01fh,03fh,07fh,000h,000h,000h,080h,0c0h	; 54ac  .........?......
	defb 0f0h,0f8h,0fch,000h,000h,000h,000h,001h,003h,007h,01fh,000h,000h,000h,000h,000h	; 54bc  ................
	defb 080h,0c0h,0f0h,0ffh,0ffh,0ffh,0ffh,07fh,03fh,01fh,007h,0feh,0feh,0feh,0feh,0fch	; 54cc  ........?.......
	defb 0f8h,0f0h,0c0h,0ffh,0ffh,0ffh,0ffh,07fh,03fh,01fh,007h,0feh,0feh,0feh,0feh,0fch	; 54dc  ........?.......
	defb 0f8h,0f0h,0c0h,0ffh,0ffh,0ffh,0ffh,07fh,03fh,01fh,007h,0feh,0feh,0feh,0feh,0fch	; 54ec  ........?.......
	defb 0f8h,0f0h,0c0h,0ffh,0ffh,0ffh,0ffh,07fh,03fh,01fh,007h,0feh,0feh,0feh,0feh,0fch	; 54fc  ........?.......
	defb 0f8h,0f0h,0c0h,0ffh,0ffh,0ffh,0ffh,07fh,03fh,01fh,007h,0feh,0feh,0feh,0feh,0fch	; 550c  ........?.......
	defb 0f8h,0f0h,0c0h,07fh,07fh,07fh,07fh,03fh,01fh,007h,000h,0fch,0fch,0fch,0fch,0f8h	; 551c  .......?........
	defb 0f0h,0c0h,000h,0ffh,0ffh,0ffh,0ffh,07fh,03fh,01fh,007h,0feh,0feh,0feh,0feh,0fch	; 552c  ........?.......
	defb 0f8h,0f0h,0c0h,03fh,03fh,03fh,03fh,01fh,007h,000h,000h,0f8h,0f8h,0f8h,0f8h,0f0h	; 553c  ...????.........
	defb 0c0h,000h,000h,0fdh,005h,0fdh,000h,0dfh,050h,0dfh,000h,0ddh,005h,0fdh,000h,0dfh	; 554c  ........P.......
	defb 050h,0dbh,000h,0dch,005h,0fdh,000h,0dfh,050h,05bh,000h,0dch,005h,07dh,000h,0deh	; 555c  P.......P[...}..
	defb 050h,05bh,000h,0d8h,005h,05dh,000h,09eh,050h,04bh,000h,050h,005h,050h,000h,08ah	; 556c  P[...]..PK.P.P..
	defb 050h,008h,000h,010h,005h,050h,000h,002h,050h,008h,000h,000h,001h,040h,000h,002h	; 557c  P....P..P....@..
	defb 040h,008h,000h,0fdh,0fdh,0fdh,000h,0dfh,0dfh,0dfh,000h,0fdh,0fdh,0fdh,000h,0dfh	; 558c  @...............
	defb 0dfh,0dfh,000h,00fh,03fh,00fh,01eh,01fh,00eh,007h,01eh,080h,0e0h,080h,0c0h,0c0h	; 559c  ....?...........
	defb 080h,00eh,010h,007h,01fh,007h,00dh,00fh,004h,003h,00bh,0c0h,0f0h,0c0h,060h,0e0h	; 55ac  ..............`.
	defb 040h,080h,0a0h,007h,01fh,007h,00dh,00fh,004h,003h,00bh,0c0h,0f0h,0c0h,060h,0e0h	; 55bc  @.............`.
	defb 040h,080h,0a0h,018h,03ch,018h,03ch,05ah,03ch,066h,000h,038h,054h,07ch,06ch,038h	; 55cc  @...<.<Z<f.8T|l8
	defb 010h,00ch,000h,042h,042h,042h,07eh,042h,042h,042h,000h,078h,044h,042h,042h,042h	; 55dc  ...BBB~BBB.xDBBB
	defb 044h,078h,000h,07eh,040h,040h,078h,040h,040h,040h,000h,018h,024h,042h,07eh,042h	; 55ec  Dx.~@@x@@@..$B~B
	defb 042h,042h,000h,042h,066h,05ah,05ah,042h,042h,042h,000h,01ch,008h,008h,008h,008h	; 55fc  BB.BfZZBBB......
	defb 008h,01ch,000h,070h,040h,070h,01eh,07ah,00ah,00eh,000h,040h,040h,078h,028h,03eh	; 560c  ...p@p.z...@@x(>
	defb 00ah,00eh,000h,03eh,07fh,079h,078h,070h,070h,038h,03ch,038h,07ch,0feh,0feh,0feh	; 561c  ...>.yxpp8<8|...
	defb 07ch,038h,000h,01bh,03bh,06bh,04bh,00fh,00eh,00ch,01ch,0b0h,0b8h,0ach,0a4h,0e0h	; 562c  |8..;kK.........
	defb 0e0h,060h,070h,01bh,03bh,033h,01bh,00fh,00eh,00ch,01ch,0b0h,0b8h,098h,0b0h,0e0h	; 563c  .`p.;3..........
	defb 0e0h,060h,070h,003h,00fh,003h,006h,007h,002h,001h,00dh,0e0h,0f8h,0e0h,0b0h,0f0h	; 564c  .`p.............
	defb 020h,0c0h,0d0h,007h,01fh,007h,00dh,00fh,004h,003h,00bh,0c0h,0f0h,0c0h,060h,0e0h	; 565c   .............`.
	defb 040h,080h,0b0h,003h,00fh,003h,006h,007h,002h,001h,003h,0e0h,0f8h,0e0h,0f0h,0f0h	; 566c  @...............
	defb 0e0h,0c0h,0c0h,003h,00fh,003h,006h,007h,002h,001h,003h,0e0h,0f8h,0e0h,0f0h,0f0h	; 567c  ................
	defb 0e0h,0c0h,0e0h,007h,01fh,007h,00fh,00fh,007h,003h,003h,0c0h,0f0h,0c0h,060h,0e0h	; 568c  ..............`.
	defb 040h,080h,0c0h,007h,01fh,007h,00fh,00fh,007h,003h,007h,0c0h,0f0h,0c0h,060h,0e0h	; 569c  @.............`.
	defb 040h,080h,0c0h,007h,01fh,00fh,00fh,00fh,007h,003h,00bh,0c0h,0f0h,0e0h,0e0h,0e0h	; 56ac  @...............
	defb 0c0h,080h,0a0h,003h,00fh,007h,007h,007h,003h,001h,005h,0e0h,0f8h,0f0h,0f0h,0f0h	; 56bc  ................
	defb 0e0h,0c0h,0d0h,01dh,035h,025h,007h,007h,006h,00eh,000h,0d8h,0c8h,0d0h,0f0h,0f0h	; 56cc  ....5%..........
	defb 070h,030h,038h,01bh,013h,00bh,00fh,00fh,00eh,00ch,01ch,0b8h,0ach,0a4h,0e0h,0e0h	; 56dc  p08.............
	defb 060h,070h,000h,007h,00dh,01bh,003h,003h,001h,002h,006h,0f0h,0e8h,0e8h,0e0h,0e0h	; 56ec  `p..............
	defb 0e0h,0e0h,0e0h,007h,00bh,00bh,003h,001h,001h,003h,007h,0b0h,0d8h,0ech,0e0h,0e0h	; 56fc  ................
	defb 0d0h,090h,0b0h,00fh,017h,017h,007h,007h,007h,007h,007h,0e0h,0b0h,0d8h,0c0h,0c0h	; 570c  ................
	defb 080h,040h,060h,00dh,01bh,037h,007h,007h,00bh,009h,00dh,0e0h,0d0h,0d0h,0c0h,080h	; 571c  .@`..7..........
	defb 080h,0c0h,0e0h,01dh,01eh,01fh,00fh,00fh,00eh,00ch,01ch,070h,0d8h,0d8h,0d8h,0e0h	; 572c  ...........p....
	defb 060h,070h,000h,00eh,01bh,01bh,01bh,007h,006h,00eh,000h,0b8h,078h,0f8h,0f0h,0f0h	; 573c  `p..........x...
	defb 070h,030h,038h,000h,000h,007h,01fh,02fh,02dh,073h,07eh,000h,000h,0c0h,0f0h,0e8h	; 574c  p08..../-s~.....
	defb 068h,09ch,0fch,000h,003h,00fh,017h,017h,035h,03bh,03eh,000h,080h,0e0h,0d0h,0d0h	; 575c  h.......5;>.....
	defb 058h,0b8h,0f8h,000h,000h,007h,019h,035h,02bh,067h,07eh,000h,000h,0c0h,030h,058h	; 576c  X......5+g~...0X
	defb 0a8h,0cch,0fch,000h,003h,00fh,019h,015h,035h,033h,03eh,000h,080h,0e0h,030h,050h	; 577c  ........53>...0P
	defb 058h,098h,0f8h,000h,000h,007h,01fh,03fh,03fh,077h,07fh,000h,000h,0c0h,0f0h,0f8h	; 578c  X......??w......
	defb 0f8h,0dch,0fch,000h,003h,00fh,01fh,01fh,03fh,03bh,03fh,000h,080h,0e0h,0f0h,0f0h	; 579c  ........?;?.....
	defb 0f8h,0b8h,0f8h,000h,000h,007h,01fh,03fh,03fh,063h,07fh,000h,000h,0c0h,0f0h,0f8h	; 57ac  .......??c......
	defb 0f8h,08ch,0fch,000h,003h,00fh,01fh,01bh,03bh,03bh,03fh,000h,080h,0e0h,0f0h,0b0h	; 57bc  ........;;?.....
	defb 0b8h,0b8h,0f8h,07dh,07eh,03fh,03bh,01ch,007h,001h,000h,07ch,0fch,0f8h,0b8h,070h	; 57cc  ...}~?;....|...p
	defb 0c0h,010h,0e0h,03dh,03dh,03eh,01bh,01bh,00ch,003h,001h,078h,078h,0f8h,0b0h,0b0h	; 57dc  ...==>.....xx...
	defb 060h,0b0h,0c0h,07dh,07eh,03fh,038h,01fh,007h,001h,000h,07ch,0fch,0f8h,038h,0f0h	; 57ec  `..}~?8....|..8.
	defb 0c0h,010h,0e0h,03dh,03dh,03eh,01fh,01ch,00fh,003h,001h,078h,078h,0f8h,0f0h,070h	; 57fc  ...==>.....xx..p
	defb 0e0h,0b0h,0c0h,07dh,07eh,03fh,03eh,01dh,007h,001h,000h,07ch,0fch,0f8h,0f8h,070h	; 580c  ...}~?>....|...p
	defb 0c0h,010h,0e0h,03fh,03bh,03ch,01fh,01ch,00bh,003h,001h,0f8h,0b8h,078h,0f0h,070h	; 581c  ...?;<.......x.p
	defb 0a0h,0b0h,0c0h,05fh,05ch,02fh,033h,01ch,007h,001h,000h,0f4h,074h,0e8h,098h,070h	; 582c  ..._\/3.....t..p
	defb 0c0h,010h,0e0h,03eh,036h,036h,01bh,01ch,00fh,003h,001h,0f8h,0d8h,0d8h,0b0h,070h	; 583c  ...>66.........p
	defb 0e0h,0b0h,0c0h,0efh,07fh,0ffh,0fbh,0feh,0edh,0fah,0f5h,0fdh,0ffh,0ffh,0deh,07fh	; 584c  ................
	defb 0b7h,05fh,0afh,07dh,0efh,0bbh,0ffh,0ddh,077h,0feh,0dbh,0efh,07dh,0d7h,07dh,0efh	; 585c  ._.}....w...}.}.
	defb 0bbh,0feh,0efh,055h,0efh,0bah,06dh,0d5h,077h,0aah,0dbh,0abh,03dh,0d7h,05dh,0e6h	; 586c  ...U..m.w...=.].
	defb 0b9h,0d6h,06bh,055h,0a5h,090h,04dh,051h,055h,0a8h,08ah,0abh,028h,045h,009h,0a2h	; 587c  ..kU..MQU...(E..
	defb 028h,056h,069h,044h,0a4h,080h,045h,041h,014h,0a8h,082h,0aah,020h,045h,001h,000h	; 588c  (ViD..EA.... E..
	defb 028h,042h,041h,044h,0a0h,000h,045h,041h,010h,0a8h,082h,0a2h,020h,045h,001h,000h	; 589c  (BAD..EA.... E..
	defb 028h,042h,000h,040h,0a0h,000h,041h,000h,000h,088h,082h,020h,000h,000h,001h,000h	; 58ac  (B.@..A.... ....
	defb 020h,040h,000h,000h,080h,000h,041h,000h,000h,008h,002h,020h,000h,000h,001h,000h	; 58bc   @....A.... ....
	defb 020h,000h,000h,0f5h,0fah,0edh,0feh,07bh,0ffh,0ffh,0bfh,0afh,05fh,0b7h,07fh,0dfh	; 58cc   ......{...._...
	defb 0ffh,0feh,0f7h,07eh,0d7h,0fdh,0b7h,0fdh,0efh,0bbh,0eeh,0bfh,0fah,0dfh,0f5h,0bfh	; 58dc  ...~............
	defb 0edh,0bfh,0fbh,02ah,0d7h,06dh,092h,0bdh,04ah,0b9h,06eh,0b5h,06ah,05bh,0b5h,09ah	; 58ec  ...*.m..J.n.j[..
	defb 0edh,0b7h,0eah,008h,0d5h,045h,012h,099h,00ah,0b9h,066h,095h,048h,053h,035h,08ah	; 58fc  .....E....f.HS5.
	defb 0a9h,0b3h,062h,008h,0c5h,044h,010h,019h,002h,0a9h,046h,000h,008h,011h,014h,002h	; 590c  ..b..D....F.....
	defb 029h,001h,022h,008h,080h,044h,010h,009h,002h,029h,004h,000h,008h,010h,004h,000h	; 591c  )."..D...)......
	defb 009h,001h,022h,008h,080h,004h,000h,009h,002h,020h,004h,000h,008h,010h,004h,000h	; 592c  .."...... ......
	defb 009h,000h,022h,000h,080h,004h,000h,001h,000h,020h,004h,000h,008h,000h,000h,000h	; 593c  .."...... ......
	defb 009h,000h,020h,0f0h,050h,0a0h,006h,0f0h,002h,0a0h,006h,0f0h,012h,080h,013h,0f0h	; 594c  .. .P...........
	defb 04eh,0a0h,007h,0f0h,001h,0a0h,007h,0f0h,010h,080h,003h,0f0h,005h,080h,003h,0f0h	; 595c  N...............
	defb 016h,0d0h,06fh,0f0h,010h,0d0h,073h,0f0h,000h,0f0h,001h,040h,004h,0a0h,001h,0f0h	; 596c  ..o...s....@....
	defb 001h,0a0h,002h,040h,006h,0f0h,002h,040h,004h,080h,001h,0f0h,001h,080h,002h,040h	; 597c  ...@...@.......@
	defb 004h,0a0h,003h,0f0h,001h,040h,004h,0a0h,001h,080h,001h,0a0h,002h,040h,005h,080h	; 598c  .....@.......@..
	defb 002h,0f0h,001h,040h,004h,080h,004h,040h,006h,080h,002h,040h,007h,080h,001h,040h	; 599c  ...@...@...@...@
	defb 007h,0a0h,002h,040h,007h,0a0h,001h,040h,005h,080h,002h,040h,007h,080h,001h,040h	; 59ac  ...@...@...@...@
	defb 008h,0a0h,002h,040h,007h,0a0h,001h,040h,082h,080h,040h,0d0h,008h,080h,008h,0f0h	; 59bc  ...@...@..@.....
	defb 002h,0a0h,005h,020h,001h,0f0h,002h,0a0h,006h,0f0h,002h,0a0h,005h,020h,001h,0f0h	; 59cc  ... ......... ..
	defb 002h,0a0h,005h,020h,001h,0f0h,002h,0a0h,005h,020h,001h,0f0h,002h,0a0h,005h,020h	; 59dc  ... ..... ..... 
	defb 001h,0f0h,002h,0a0h,001h,020h,002h,080h,001h,0f0h,002h,080h,005h,0f0h,033h,020h	; 59ec  ..... ........3 
	defb 014h,0d0h,003h,0f0h,001h,040h,008h,020h,004h,0d0h,003h,0f0h,001h,020h,004h,0d0h	; 59fc  .....@. ..... ..
	defb 003h,0f0h,001h,020h,004h,0d0h,003h,0f0h,001h,020h,004h,0d0h,003h,0f0h,003h,0a0h	; 5a0c  ... ..... ......
	defb 005h,020h,001h,0f0h,002h,0a0h,005h,020h,001h,0f0h,002h,0a0h,005h,020h,001h,0f0h	; 5a1c  . ..... ..... ..
	defb 002h,0a0h,005h,020h,001h,0f0h,002h,0a0h,005h,020h,001h,0f0h,002h,0a0h,005h,020h	; 5a2c  ... ..... ..... 
	defb 001h,0f0h,002h,0a0h,005h,020h,001h,0f0h,002h,0a0h,005h,020h,001h,0f0h,002h,0a0h	; 5a3c  ..... ..... ....
	defb 005h,020h,001h,0f0h,002h,0a0h,005h,020h,001h,0f0h,002h,0a0h,005h,020h,001h,0f0h	; 5a4c  . ..... ..... ..
	defb 002h,0a0h,005h,020h,001h,0f0h,002h,040h,004h,0a0h,001h,020h,001h,0f0h,002h,040h	; 5a5c  ... ...@... ...@
	defb 004h,0a0h,001h,020h,001h,0f0h,002h,040h,004h,0a0h,001h,020h,001h,0f0h,002h,040h	; 5a6c  ... ...@... ...@
	defb 004h,0a0h,001h,020h,004h,0d0h,003h,0f0h,002h,020h,003h,0d0h,004h,0f0h,001h,020h	; 5a7c  ... ..... ..... 
	defb 003h,0d0h,004h,0f0h,001h,020h,003h,0d0h,003h,0f0h,002h,020h,003h,0d0h,004h,0f0h	; 5a8c  ..... ..... ....
	defb 001h,020h,003h,0d0h,004h,0f0h,001h,020h,003h,0d0h,004h,0f0h,001h,020h,003h,0d0h	; 5a9c  . ..... ..... ..
	defb 004h,0f0h,001h,020h,003h,0d0h,004h,0f0h,001h,020h,003h,0d0h,004h,0f0h,001h,020h	; 5aac  ... ..... ..... 
	defb 003h,0d0h,004h,0f0h,001h,020h,003h,0d0h,004h,0f0h,001h,020h,004h,0d0h,003h,0f0h	; 5abc  ..... ..... ....
	defb 001h,020h,004h,0d0h,002h,0f0h,002h,020h,004h,0d0h,002h,0f0h,002h,020h,004h,0d0h	; 5acc  . ..... ..... ..
	defb 003h,0f0h,003h,080h,020h,0d0h,05eh,080h,006h,0f0h,002h,080h,006h,0f0h,002h,080h	; 5adc  .... .^.........
	defb 007h,0f0h,001h,080h,006h,0f0h,002h,0d0h,006h,0f0h,002h,0d0h,006h,0f0h,002h,0d0h	; 5aec  ................
	defb 007h,0f0h,001h,0d0h,006h,0f0h,002h,0d0h,006h,0f0h,002h,0d0h,006h,0f0h,002h,0d0h	; 5afc  ................
	defb 007h,0f0h,001h,0d0h,006h,0f0h,002h,0d0h,006h,0f0h,002h,0d0h,006h,0f0h,002h,0d0h	; 5b0c  ................
	defb 007h,0f0h,001h,0d0h,006h,0f0h,000h,0f0h,002h,0ffh	; 5b1c  ..........

; ----------------------------------------------------------------------
; DATOS graficos_de_las_letras_del_marcador: Destino 0x0080, o sea la casilla
;   0x10, con 10 casillas y un solo tramo de color. Son las diez letras de
;   SCORE y BONUS, en ese orden. Lo carga 0x4074 al empezar la partida
;   0x5b26..0x5b7c  (86 bytes)
DATA_graficos_de_las_letras_del_marcador:
	defb 080h,000h,00ah,03ch,042h,040h,03ch,002h,042h,03ch,000h,03ch,042h,040h,040h,040h	; 5b26  ...<B@<.B<.<B@@@
	defb 042h,03ch,000h,03ch,042h,042h,042h,042h,042h,03ch,000h,07ch,042h,042h,07ch,048h	; 5b36  B<.<BBBBB<.|BB|H
	defb 044h,042h,000h,07eh,040h,040h,078h,040h,040h,07eh,000h,07ch,042h,042h,07ch,042h	; 5b46  DB.~@@x@@~.|BB|B
	defb 042h,07ch,000h,03ch,042h,042h,042h,042h,042h,03ch,000h,042h,062h,052h,04ah,046h	; 5b56  B|.<BBBBB<.BbRJF
	defb 042h,042h,000h,042h,042h,042h,042h,042h,042h,03ch,000h,03ch,042h,040h,03ch,002h	; 5b66  BB.BBBBBB<.<B@<.
	defb 042h,03ch,000h,0f0h,050h,0ffh	; 5b76

; ----------------------------------------------------------------------
; DATOS graficos_de_la_partida: Destino 0x0100, o sea la casilla 0x20, con 64
;   casillas y 92 tramos de color. Son la casilla vacia, los dos puntos, la T
;   y la G de STG, los siete cuadros del enemigo reventando y los ocho de la
;   agonia del bombero, que acaban en un OUT verde. Lo carga 0x407A, y es lo
;   que tapa el rotulo grande de la portada
;   0x5b7c..0x5e38  (700 bytes)
DATA_graficos_de_la_partida:
	defb 000h,001h,040h,000h,000h,000h,000h,000h,000h,000h,000h,018h,018h,018h,000h,018h	; 5b7c  ..@.............
	defb 018h,018h,000h,080h,000h,007h,01fh,035h,03bh,075h,07fh,000h,000h,0c0h,0f0h,058h	; 5b8c  .......5;u.....X
	defb 0b8h,05ch,0fch,000h,000h,007h,01fh,035h,03bh,075h,040h,000h,000h,0c0h,0f0h,058h	; 5b9c  .\.....5;u@....X
	defb 0b8h,05ch,03ch,000h,000h,007h,01fh,035h,03bh,040h,040h,000h,000h,0c0h,0f0h,058h	; 5bac  .\<....5;@@....X
	defb 0b8h,01ch,01ch,000h,000h,007h,01fh,035h,000h,000h,000h,000h,000h,080h,080h,008h	; 5bbc  .......5........
	defb 008h,00ch,00ch,000h,000h,000h,007h,017h,03dh,000h,000h,000h,000h,000h,0c0h,000h	; 5bcc  ........=.......
	defb 008h,008h,00ch,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 5bdc  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 5bec  ................
	defb 000h,000h,000h,03eh,008h,008h,008h,008h,008h,008h,000h,01ch,022h,040h,04eh,042h	; 5bfc  ...>........"@NB
	defb 022h,01ch,000h,07fh,078h,03ch,03ch,01dh,007h,001h,000h,07ch,07ch,078h,038h,0f0h	; 5c0c  "...x<<....||x8.
	defb 0c0h,010h,0e0h,040h,078h,038h,038h,019h,001h,001h,000h,03ch,03ch,000h,000h,0f0h	; 5c1c  ...@x88....<<...
	defb 0c0h,010h,0e0h,040h,070h,030h,030h,010h,003h,001h,000h,01ch,01ch,000h,000h,000h	; 5c2c  ...@p00.........
	defb 0c0h,010h,0e0h,060h,060h,020h,020h,000h,000h,001h,000h,00ch,00ch,008h,000h,000h	; 5c3c  ...``  .........
	defb 000h,010h,0e0h,000h,000h,060h,020h,020h,003h,001h,000h,00ch,00ch,00ch,000h,000h	; 5c4c  .....`  ........
	defb 0c0h,010h,0e0h,007h,01fh,035h,000h,000h,060h,079h,000h,080h,080h,008h,008h,00ch	; 5c5c  .....5..`y......
	defb 00ch,000h,0f0h,000h,000h,000h,003h,00fh,015h,06ch,057h,000h,000h,000h,080h,080h	; 5c6c  .........lW.....
	defb 01ch,01eh,0e0h,000h,000h,07bh,06bh,06bh,06bh,07bh,000h,000h,000h,05eh,04ch,04ch	; 5c7c  .....{kkk{...^LL
	defb 04ch,0cch,000h,000h,000h,000h,000h,000h,000h,001h,003h,000h,000h,000h,000h,000h	; 5c8c  L...............
	defb 000h,0c0h,018h,000h,000h,000h,000h,000h,008h,018h,018h,000h,000h,000h,000h,000h	; 5c9c  ................
	defb 07ch,0b4h,0dch,000h,000h,000h,000h,000h,000h,040h,060h,000h,000h,000h,000h,07ch	; 5cac  |........@`....|
	defb 0b4h,0dch,0b4h,000h,000h,000h,001h,002h,007h,004h,006h,000h,000h,000h,080h,0c0h	; 5cbc  ................
	defb 0e0h,0a0h,0c0h,000h,000h,001h,002h,007h,004h,004h,003h,000h,000h,080h,0c0h,0e0h	; 5ccc  ................
	defb 0a0h,0c0h,080h,000h,012h,00ah,007h,00dh,00fh,006h,004h,000h,090h,0a0h,0c0h,060h	; 5cdc  ...............`
	defb 0e0h,0c0h,040h,012h,00ah,007h,00dh,00fh,006h,004h,00bh,090h,0a0h,0c0h,060h,0e0h	; 5cec  ..@...........`.
	defb 0c0h,040h,0a0h,000h,000h,0f0h,0e0h,060h,03fh,03fh,01eh,000h,000h,01ch,03eh,022h	; 5cfc  .@.....`??....>"
	defb 07fh,06bh,03eh,006h,00fh,00bh,00bh,00bh,00bh,01eh,078h,02ch,05eh,07ah,06ch,038h	; 5d0c  .k>.......x,^zl8
	defb 080h,0f0h,03ch,018h,01bh,00bh,00bh,00bh,00bh,01eh,078h,0b4h,07ch,0beh,0bch,0a0h	; 5d1c  ..<.......x.|...
	defb 0a0h,0f0h,03ch,030h,01bh,00bh,00bh,00bh,00eh,01ch,038h,07ch,0beh,0bch,0a0h,0a0h	; 5d2c  ..<0......8|....
	defb 0e0h,070h,038h,003h,0fbh,07bh,00bh,00bh,00eh,01ch,038h,080h,0beh,0bch,0a0h,0a0h	; 5d3c  .p8..{....8.....
	defb 0e0h,070h,038h,01bh,03bh,06bh,04bh,00fh,00eh,00ch,01ch,0b0h,0b8h,0ach,0a4h,0e0h	; 5d4c  .p8.;kK.........
	defb 0e0h,060h,070h,0fbh,0fbh,00bh,00bh,00fh,00eh,00ch,01ch,0beh,0beh,0a0h,0a0h,0e0h	; 5d5c  .`p.............
	defb 0e0h,060h,070h,01bh,03bh,06bh,04bh,00fh,00eh,00ch,01ch,0b0h,0b8h,0ach,0a4h,0e0h	; 5d6c  .`p.;kK.........
	defb 0e0h,060h,070h,0f0h,012h,080h,06eh,0f0h,010h,080h,006h,0f0h,002h,080h,006h,0f0h	; 5d7c  .`p...n.........
	defb 002h,080h,006h,0f0h,002h,080h,006h,0f0h,002h,080h,006h,0f0h,002h,080h,006h,0f0h	; 5d8c  ................
	defb 002h,080h,006h,0f0h,002h,080h,006h,0f0h,004h,080h,004h,0f0h,002h,080h,006h,0f0h	; 5d9c  ................
	defb 002h,080h,006h,0f0h,002h,080h,007h,0f0h,004h,080h,00ch,0f0h,003h,020h,014h,070h	; 5dac  ............. .p
	defb 017h,0a0h,009h,070h,006h,0a0h,025h,040h,002h,0a0h,006h,040h,002h,0a0h,005h,040h	; 5dbc  ...p..%@...@...@
	defb 002h,0a0h,005h,070h,001h,040h,002h,0a0h,005h,070h,003h,0f0h,001h,0d0h,002h,070h	; 5dcc  ...p.@...p.....p
	defb 011h,0d0h,001h,0f0h,001h,070h,006h,0d0h,001h,0f0h,001h,070h,006h,0d0h,001h,0f0h	; 5ddc  .....p.....p....
	defb 001h,0a0h,002h,070h,004h,0d0h,001h,0f0h,001h,070h,005h,0d0h,002h,0f0h,001h,0a0h	; 5dec  ...p.....p......
	defb 001h,070h,004h,0d0h,002h,0f0h,001h,0a0h,001h,070h,004h,0d0h,002h,0f0h,001h,0a0h	; 5dfc  .p.......p......
	defb 001h,070h,004h,0d0h,002h,0f0h,001h,070h,004h,0d0h,003h,0f0h,001h,070h,004h,0d0h	; 5e0c  .p.....p.....p..
	defb 003h,0f0h,001h,070h,004h,0d0h,003h,0f0h,001h,070h,004h,0d0h,003h,0f0h,001h,070h	; 5e1c  ...p.....p.....p
	defb 004h,0d0h,003h,0f0h,001h,070h,004h,0d0h,003h,0f0h,001h,0ffh	; 5e2c  .....p......

; ----------------------------------------------------------------------
; DATOS dibujos_que_apunta_0x419B: Los 456 bytes del final del cartucho: los
;   dieciseis bloques a los que apunta la tabla de 0x419B, cada uno con su
;   destino, dos casillas de patrones y sus tramos de color. La primera
;   palabra de la tabla es 0x5E38 exacto, o sea el principio de este bloque
;   0x5e38..0x6000  (456 bytes)
DATA_dibujos_que_apunta_0x419B:
	defb 0d0h,000h,002h,075h,075h,0f8h,0fdh,0f5h,0f8h,07dh,03fh,05ch,07ch,03eh,05eh,05eh	; 5e38  ...uu....}?\|>^^
	defb 03eh,07ch,0f8h,0a0h,010h,0ffh,050h,000h,002h,00fh,07eh,01eh,00fh,00fh,01fh,03dh	; 5e48  >|....P...~....=
	defb 078h,01eh,021h,0d1h,00eh,080h,0e0h,078h,03ch,0a0h,003h,0d0h,001h,0a0h,004h,0d0h	; 5e58  x.!....x<.......
	defb 004h,0a0h,004h,0ffh,050h,000h,002h,01ch,024h,05ch,05ch,024h,01ch,00fh,00eh,004h	; 5e68  ....P...$\\$....
	defb 00ah,014h,028h,050h,0a0h,040h,0c0h,0a0h,006h,0f0h,00ah,0ffh,0d0h,000h,002h,00dh	; 5e78  ..(P.@..........
	defb 00bh,00fh,00fh,00fh,007h,003h,007h,0c0h,0c0h,0c0h,0c0h,0d2h,092h,012h,08ch,0f0h	; 5e88  ................
	defb 010h,0ffh,050h,000h,002h,080h,020h,011h,012h,023h,000h,07fh,047h,000h,080h,010h	; 5e98  ..P... ..#..G...
	defb 010h,090h,000h,0f8h,08fh,0f0h,010h,0ffh,0d0h,000h,002h,06fh,06bh,079h,07ah,07bh	; 5ea8  ...........okyz{
	defb 07fh,030h,01fh,0d9h,059h,079h,07eh,078h,0f8h,030h,0e0h,0f0h,010h,0ffh,050h,000h	; 5eb8  .0..Yy~x.0....P.
	defb 002h,000h,000h,000h,00fh,0e5h,0ffh,0ffh,0e1h,000h,000h,000h,080h,002h,0feh,0fch	; 5ec8  ................
	defb 080h,0f0h,00fh,080h,001h,0ffh,0d0h,000h,002h,003h,007h,008h,008h,010h,010h,020h	; 5ed8  ............... 
	defb 020h,0c0h,0e0h,090h,090h,088h,048h,044h,044h,080h,010h,0ffh,050h,000h,002h,000h	; 5ee8   .....HDD...P...
	defb 000h,000h,001h,003h,006h,00ch,01fh,018h,030h,0e0h,0c0h,060h,030h,098h,0cch,0f0h	; 5ef8  ........0..`0...
	defb 010h,0ffh,0d0h,000h,002h,03eh,03ch,029h,027h,013h,009h,005h,003h,00ch,074h,0e4h	; 5f08  .....><)'.....t.
	defb 0c8h,090h,020h,040h,080h,0f0h,010h,0ffh,050h,000h,002h,000h,000h,001h,007h,01fh	; 5f18  .. @....P.......
	defb 010h,010h,014h,000h,000h,0fch,0feh,0feh,004h,014h,014h,0f0h,002h,020h,00eh,0ffh	; 5f28  ............. ..
	defb 0d0h,000h,002h,016h,014h,078h,08fh,060h,090h,090h,060h,024h,0e4h,0e7h,0f8h,006h	; 5f38  .....x.`..`$....
	defb 009h,009h,006h,020h,004h,0a0h,004h,020h,004h,0a0h,004h,0ffh,050h,000h,002h,00eh	; 5f48  ... ... ....P...
	defb 008h,008h,004h,007h,004h,01fh,024h,000h,000h,000h,078h,0f0h,030h,008h,088h,0f0h	; 5f58  ......$...x.0...
	defb 00bh,020h,001h,0f0h,004h,0ffh,0d0h,000h,002h,044h,084h,084h,080h,080h,040h,020h	; 5f68  . .......D....@ 
	defb 01fh,048h,024h,024h,024h,026h,049h,089h,006h,0f0h,010h,0ffh,050h,000h,002h,01eh	; 5f78  .H$$$&I.....P...
	defb 01dh,01eh,01fh,01ch,01fh,010h,01fh,0d0h,050h,030h,0f0h,0d0h,030h,010h,0f0h,060h	; 5f88  ........P0..0..`
	defb 010h,0ffh,0d0h,000h,002h,01fh,01eh,01fh,01fh,01bh,017h,017h,018h,030h,0d0h,030h	; 5f98  .............0.0
	defb 0f0h,0b0h,0d0h,0d0h,030h,060h,010h,0ffh,000h,044h,083h,010h,010h,080h,080h,002h	; 5fa8  ....0`...D......
	defb 060h,001h,021h,000h,000h,064h,084h,080h,081h,000h,084h,000h,000h,042h,000h,008h	; 5fb8  `.!..d.......B..
	defb 004h,005h,000h,0c0h,050h,012h,081h,080h,041h,000h,002h,000h,008h,0c0h,070h,004h	; 5fc8  ....P...A.....p.
	defb 004h,008h,00bh,040h,052h,05ah,040h,0c0h,001h,050h,017h,02ah,000h,002h,010h,090h	; 5fd8  ...@RZ@..P.*....
	defb 000h,042h,00ah,000h,00ah,087h,000h,080h,009h,036h,0b1h,090h,029h,000h,041h,020h	; 5fe8  .B.......6..).A 
	defb 001h,000h,080h,021h,081h,005h,090h,090h	; 5ff8  ...!....

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
; la pila, y luego tres llamadas: la RAM a cero, el VDP y el PSG.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
INIT:
	ld sp,0f000h		;4004   ; la pila, arriba del todo de la RAM
	call pon_los_valores_de_partida		;4007   ; borra la RAM del juego
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


L_4019:
	ld hl,00000h		;4019   ; el marcador y el record, a cero
	ld (0e302h),hl		;401c   ; (0xE302), el marcador
	ld (0e300h),hl		;401f   ; (0xE300), el record
	jp L_4279		;4022   ; y a la pantalla de titulo

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Los efectos que duran mas de un cuadro: en vez de llevar la tabla
; incrustada, se guarda por donde va en (0xE305) y (0xE307), una
; pareja de punteros por voz. El 0xFF cierra la tabla igual.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
sigue_los_dos_guiones_de_sonido:
	ld iy,0e305h		;4025   ; el primero, en (0xE305)
	call sigue_un_guion_de_sonido		;4029
	ld iy,0e307h		;402c   ; y el segundo, en (0xE307)
sigue_un_guion_de_sonido:
	ld l,(iy+000h)		;4030   ; por donde iba
	ld h,(iy+001h)		;4033
	ld a,(hl)			;4036   ; con 0xFF no queda nada
	inc a			;4037
	jr z,L_4047		;4038
L_403A:
	ld d,(hl)			;403a   ; el registro
	ld a,(hl)			;403b
	inc hl			;403c
	inc a			;403d
	jr z,L_4047		;403e
	ld e,(hl)			;4040   ; y el valor
	call escribe_en_el_psg		;4041   ; al PSG
	inc hl			;4044
	jr L_403A		;4045
L_4047:
	ld (iy+000h),l		;4047   ; se apunta por donde se ha quedado
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
	jr L_4057		;404f
L_4051:
	dec d			;4051   ; deshace el `inc d` de la comprobacion
	ld e,(hl)			;4052   ; el valor
	call escribe_en_el_psg		;4053   ; al PSG
	inc hl			;4056
L_4057:
	ld d,(hl)			;4057   ; el registro
	inc hl			;4058
	inc d			;4059   ; con 0xFF se acabo
	jr nz,L_4051		;405a
	push hl			;405c   ; y se sigue DETRAS de la tabla
	ret			;405d
L_405E:
	ld hl,00000h		;405e
	ld (0e300h),hl		;4061
	ld a,001h		;4064
	ld (0e310h),a		;4066
	ld a,003h		;4069
	ld (0e30fh),a		;406b
	call L_511A		;406e
	call L_510E		;4071
	ld hl,05b26h		;4074
	call carga_los_graficos_en_los_tres_tercios		;4077
	ld hl,05b7ch		;407a
	call carga_los_graficos_en_los_tres_tercios		;407d
L_4080:
	ld hl,003e8h		;4080
	ld (0e30dh),hl		;4083
	xor a			;4086
	ld (0e319h),a		;4087
	ld (0e318h),a		;408a
	ld (0e380h),a		;408d
	ld (0e383h),a		;4090
	ld (0e312h),a		;4093
	ld (0e311h),a		;4096
	ld (0e314h),a		;4099
	ld (0e315h),a		;409c
	ld (0e316h),a		;409f
	ld (0e37bh),a		;40a2
	ld a,001h		;40a5
	ld (0e30bh),a		;40a7
	call L_41FB		;40aa
	call L_4589		;40ad
	call L_459D		;40b0
	call L_4982		;40b3
	call L_511A		;40b6
	call L_510E		;40b9
	call L_4F55		;40bc
	call L_4DB7		;40bf
	call L_4E35		;40c2
	xor a			;40c5
	ld (0e380h),a		;40c6
	ld (0e383h),a		;40c9
L_40CC:
	call L_46C8		;40cc
	call L_4F63		;40cf
	call L_4DB7		;40d2
	call L_4996		;40d5
	call L_4A08		;40d8
	call L_491C		;40db
	call L_4C09		;40de
	call L_46EC		;40e1
	call L_45F6		;40e4
	call L_4681		;40e7
	call L_4835		;40ea
	call L_45CE		;40ed
	call L_465A		;40f0
	call L_4B99		;40f3
	call L_453B		;40f6
	call L_44C3		;40f9
	call L_448A		;40fc
	call L_4E00		;40ff
	call L_4CE5		;4102
	call L_4D37		;4105
	ld a,(0e37bh)		;4108
	or a			;410b
	jp nz,L_41EB		;410c
	ld a,(0e316h)		;410f
	or a			;4112
	jp nz,L_41BB		;4113
	ld a,(0e318h)		;4116
	or a			;4119
	jr z,L_40CC		;411a
	ld bc,00014h		;411c
L_411F:
	push bc			;411f
	call L_4231		;4120
	pop bc			;4123
	dec bc			;4124
	ld a,b			;4125
	or c			;4126
	jp nz,L_411F		;4127
	ld hl,(0e30dh)		;412a
	ld a,h			;412d
	or l			;412e
	jr z,$+56		;412f
L_4131:
	push hl			;4131
	call L_4253		;4132
	call vuelca_la_tabla_del_psg		;4135

; ----------------------------------------------------------------------
; DATOS tabla_del_psg_1: Ocho parejas y el 0xFF: el tono de la voz A (0x020A),
;   los volumenes, y el periodo y la forma de la envolvente (0x0002 y 9)
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


L_4149:
	pop hl			;4149
	ld bc,0000ah		;414a
	or a			;414d
	sbc hl,bc		;414e
	ld (0e30dh),hl		;4150
	ld de,(0e300h)		;4153
	inc de			;4157
	ld (0e300h),de		;4158
	ld a,h			;415c
	or l			;415d
	jp nz,L_4131		;415e
	call L_4253		;4161
	call L_4253		;4164
L_4167:
	ld a,(0e310h)		;4167
	inc a			;416a
	ld (0e310h),a		;416b
	push af			;416e
	and 003h		;416f
	ld hl,0419bh		;4171
	call z,L_4197		;4174
	pop af			;4177
	and 0fch		;4178
	jp z,L_4080		;417a
	and 00ch		;417d
	ld c,a			;417f
	ld b,000h		;4180
	add hl,bc			;4182
	ld e,(hl)			;4183
	inc hl			;4184
	ld d,(hl)			;4185
	inc hl			;4186
	push hl			;4187
	ex de,hl			;4188
	call carga_los_graficos_en_los_tres_tercios		;4189
	pop hl			;418c
	ld e,(hl)			;418d
	inc hl			;418e
	ld d,(hl)			;418f
	ex de,hl			;4190
	call carga_los_graficos_en_los_tres_tercios		;4191
	jp L_4080		;4194
L_4197:
	ld hl,041abh		;4197
	ret			;419a

; ----------------------------------------------------------------------
; DATOS punteros_de_los_dibujos: Dieciseis palabras, todas dentro de
;   0x5E38..0x5F9A. 0x4171 las indexa con el contador de cuadros de (0xE310)
;   0x419b..0x41bb  (32 bytes)
DATA_punteros_de_los_dibujos:
	defw 05ec6h,05edeh,05e4eh,05e38h,05f54h,05f6eh,05f20h,05f38h	; 419b
	defw 05e9ah,05eb0h,05e6ch,05e84h,05f84h,05f9ah,05ef4h,05f0ah	; 41ab

; ======================================================================
; CODIGO 0x41bb..0x41d0  (21 bytes)
; ======================================================================


L_41BB:
	ld b,00ah		;41bb
	ld hl,041d0h		;41bd
	ld (0e307h),hl		;41c0
L_41C3:
	push bc			;41c3
	ld hl,00fa0h		;41c4
	call L_4231		;41c7
	pop bc			;41ca
	djnz L_41C3		;41cb
	jp L_4080		;41cd

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_41D0: Ocho cuadros de parejas (registro, valor)
;   separados por 0xFF y cerrados por un 0xFF doble; lo instala 0x41BD en
;   (0xE307). Sube el tono de la voz B de 0xEE a 0x7E y apaga la voz C
;   0x41d0..0x41eb  (27 bytes)
DATA_guion_de_sonido_41D0:
	defb 004h,0eeh,00ah,00ch,0ffh,004h,0d4h,0ffh,004h,0bdh,0ffh,004h,0b2h,0ffh,004h,09fh	; 41d0  ................
	defb 0ffh,004h,08eh,0ffh,004h,07eh,0ffh,00ah,000h,0ffh,0ffh	; 41e0  .....~.....

; ======================================================================
; CODIGO 0x41eb..0x4217  (44 bytes)
; ======================================================================


L_41EB:
	call L_4F7B		;41eb
	ld a,(0e30fh)		;41ee
	dec a			;41f1
	or a			;41f2
	ld (0e30fh),a		;41f3
	jr z,$+43		;41f6
	jp L_4080		;41f8
L_41FB:
	ld a,(0e310h)		;41fb
	cp 006h		;41fe
	jr c,L_4204		;4200
	ld a,005h		;4202
L_4204:
	dec a			;4204
	add a,a			;4205
	ld hl,04217h		;4206
	ld c,a			;4209
	ld b,000h		;420a
	add hl,bc			;420c
	ld a,(hl)			;420d
	ld (0e313h),a		;420e
	inc hl			;4211
	ld a,(hl)			;4212
	ld (0e317h),a		;4213
	ret			;4216

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4217..0x4221  (10 bytes)
DATA_4217:
	defb 001h,010h,002h,015h,003h,01ah,002h,01fh,004h,024h	; 4217  .........$

; ======================================================================
; CODIGO 0x4221..0x4323  (258 bytes)
; ======================================================================


L_4221:
	ld bc,00005h		;4221
L_4224:
	push bc			;4224
	call L_4231		;4225
	pop bc			;4228
	dec bc			;4229
	ld a,b			;422a
	or c			;422b
	jr nz,L_4224		;422c
	jp L_4279		;422e
L_4231:
	call L_46C8		;4231
	call L_4F63		;4234
	call L_4DB7		;4237
	call L_4A08		;423a
	call L_45F6		;423d
	call L_4681		;4240
	call L_4835		;4243
	call L_4B99		;4246
	call L_4996		;4249
	call L_4E00		;424c
	call L_4CE5		;424f
	ret			;4252
L_4253:
	call L_46C8		;4253
	call L_4F63		;4256
	call L_4DB7		;4259
	call L_45F6		;425c
	call L_4681		;425f
	call L_4B99		;4262
	call L_4E00		;4265
	call L_4CE5		;4268
	ret			;426b
L_426C:
	ld (hl),a			;426c
	or a			;426d
	ret z			;426e
	call L_50FC		;426f
	or a			;4272
	jr nz,L_426C		;4273
	pop hl			;4275
	jp L_405E		;4276
L_4279:
	call L_511A		;4279
	call L_510E		;427c
	ld hl,0514ch		;427f
	call carga_los_graficos_en_los_tres_tercios		;4282
	call L_4456		;4285
	call L_4442		;4288
	ld a,0ffh		;428b
	ld (0e304h),a		;428d
L_4290:
	call L_50FC		;4290
	ld hl,0e304h		;4293
	cp (hl)			;4296
	call nz,L_426C		;4297
	call L_46C8		;429a
	ld bc,0e000h		;429d
	ld d,0c0h		;42a0
	ld e,089h		;42a2
L_42A4:
	ld a,e			;42a4
	ld (bc),a			;42a5
	inc bc			;42a6
	dec d			;42a7
	jr nz,L_42A4		;42a8
	ld hl,0446eh		;42aa
L_42AD:
	ld a,(hl)			;42ad
	inc a			;42ae
	jr z,L_42C5		;42af
	dec a			;42b1
	ld e,a			;42b2
	inc hl			;42b3
	ld b,(hl)			;42b4
	inc hl			;42b5
	ld c,(hl)			;42b6
	inc hl			;42b7
	call L_5128		;42b8
	ld a,e			;42bb
	push hl			;42bc
	push de			;42bd
	call L_4B7B		;42be
	pop de			;42c1
	pop hl			;42c2
	jr L_42AD		;42c3
L_42C5:
	ld hl,04323h		;42c5
	call pinta_una_tira_de_rotulos		;42c8
	ld bc,0e216h		;42cb
	ld hl,(0e302h)		;42ce
	call L_4F29		;42d1
	ld bc,0e256h		;42d4
	ld hl,(0e300h)		;42d7
	call L_4F29		;42da
	ld bc,0e0e1h		;42dd
	ld a,08ch		;42e0
	call L_4B7B		;42e2
	call L_4A08		;42e5
	call L_4835		;42e8
	ld a,(0e36fh)		;42eb
	or a			;42ee
	jr nz,L_4301		;42ef
	ld a,(0e36eh)		;42f1
	xor 002h		;42f4
	ld (0e36eh),a		;42f6
	ld a,(0e358h)		;42f9
	xor 002h		;42fc
	ld (0e358h),a		;42fe
L_4301:
	ld bc,0e0f1h		;4301
	ld a,00ah		;4304
	call L_4B7B		;4306
	ld bc,0e0f9h		;4309
	ld a,00eh		;430c
	call L_4B7B		;430e
	jp L_4290		;4311

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
	call L_5128		;431b   ; pone el cursor
	call L_513C		;431e   ; y suelta el texto hasta el 0x00
	jr pinta_una_tira_de_rotulos		;4321

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


L_4442:
	call L_4982		;4442
	ld ix,0e359h		;4445
	ld (ix+000h),001h		;4449
	ld (ix+001h),00eh		;444d
	ld (ix+002h),00ah		;4451
	ret			;4455
L_4456:
	call L_4589		;4456
	ld ix,0e31ch		;4459
	ld (ix+000h),001h		;445d
	ld (ix+001h),00ah		;4461
	ld (ix+002h),007h		;4465
	ld (ix+003h),001h		;4469
	ret			;446d

; ----------------------------------------------------------------------
; DATOS sin identificar  0x446e..0x448a  (28 bytes)
DATA_446E:
	defb 022h,002h,002h,024h,002h,005h,026h,002h,008h,022h,002h,00bh,028h,002h,00eh,02ah	; 446e  "..$..&.."..(..*
	defb 002h,011h,026h,002h,016h,02ch,002h,019h,02eh,002h,01ch,0ffh	; 447e  ..&..,......

; ======================================================================
; CODIGO 0x448a..0x450f  (133 bytes)
; ======================================================================


L_448A:
	ld a,(0e379h)		;448a
	or a			;448d
	ret nz			;448e
	ld hl,(0e30dh)		;448f
	ld a,h			;4492
	or l			;4493
	jr z,L_449F		;4494
	ld bc,0000ah		;4496
	sbc hl,bc		;4499
	ld (0e30dh),hl		;449b
	ret			;449e
L_449F:
	ld a,(0e319h)		;449f
	or a			;44a2
	ret nz			;44a3
	call L_4F55		;44a4
	ld a,001h		;44a7
	ld (0e319h),a		;44a9
	xor a			;44ac
	ld (0e383h),a		;44ad
	ld (0e380h),a		;44b0
	ld a,001h		;44b3
	ld (0e314h),a		;44b5
	ld (0e315h),a		;44b8
	xor a			;44bb
	ld (0e37fh),a		;44bc
	ld (0e381h),a		;44bf
	ret			;44c2
L_44C3:
	ld bc,(0e309h)		;44c3
	ld a,(0e383h)		;44c7
	or a			;44ca
	jr z,L_44E3		;44cb
	ld a,(0e382h)		;44cd
	cp b			;44d0
	jr nz,L_44E3		;44d1
	ld a,(0e381h)		;44d3
	cp c			;44d6
	jr nz,L_44E3		;44d7
	xor a			;44d9
	ld (0e383h),a		;44da
	ld a,001h		;44dd
	ld (0e316h),a		;44df
	ret			;44e2
L_44E3:
	ld a,(0e380h)		;44e3
	or a			;44e6
	ret z			;44e7
	ld a,(0e37fh)		;44e8
	cp b			;44eb
	ret nz			;44ec
	ld a,(0e37eh)		;44ed
	cp c			;44f0
	ret nz			;44f1
	xor a			;44f2
	ld (0e380h),a		;44f3
	call L_4EF9		;44f6
	and 03fh		;44f9
	add a,a			;44fb
	set 4,a		;44fc
	ld c,a			;44fe
	ld b,000h		;44ff
	ld hl,(0e300h)		;4501
	add hl,bc			;4504
	ld (0e300h),hl		;4505
	ld hl,0450fh		;4508
	ld (0e305h),hl		;450b
	ret			;450e

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_450F: Lo instala 0x4508 en (0xE305)
;   0x450f..0x453b  (44 bytes)
DATA_guion_de_sonido_450F:
	defb 000h,0d4h,008h,00dh,0ffh,000h,0d4h,008h,009h,0ffh,001h,000h,000h,0b2h,001h,000h	; 450f  ................
	defb 008h,00ch,0ffh,000h,0b2h,001h,000h,008h,007h,0ffh,000h,08eh,001h,000h,008h,00ch	; 451f  ................
	defb 0ffh,000h,08eh,001h,000h,008h,006h,0ffh,008h,000h,0ffh,0ffh	; 452f  ............

; ======================================================================
; CODIGO 0x453b..0x45c6  (139 bytes)
; ======================================================================


L_453B:
	ld a,(0e311h)		;453b
	or a			;453e
	ret z			;453f
	ld a,(0e312h)		;4540
	or a			;4543
	ret nz			;4544
	ld bc,(0e31ah)		;4545
	call L_4F6F		;4549
	call L_46A8		;454c
	cp 020h		;454f
	ret nz			;4551
	ld a,(0e313h)		;4552
	add a,004h		;4555
	ld (0e313h),a		;4557
	ld ix,0e31ch		;455a
	ld d,004h		;455e
L_4560:
	ld a,(ix+000h)		;4560
	inc a			;4563
	jr z,L_4583		;4564
	dec a			;4566
	jr nz,L_457C		;4567
	ld (ix+000h),001h		;4569
	ld a,(0e31ah)		;456d
	ld (ix+001h),a		;4570
	ld a,(0e31bh)		;4573
	ld (ix+002h),a		;4576
	dec d			;4579
	jr z,L_4583		;457a
L_457C:
	ld bc,00007h		;457c
	add ix,bc		;457f
	jr L_4560		;4581
L_4583:
	ld a,001h		;4583
	ld (0e312h),a		;4585
	ret			;4588
L_4589:
	ld ix,0e31ch		;4589
L_458D:
	ld a,(ix+000h)		;458d
	inc a			;4590
	ret z			;4591
	ld (ix+000h),000h		;4592
	ld bc,00007h		;4596
	add ix,bc		;4599
	jr L_458D		;459b
L_459D:
	ld a,(0e313h)		;459d
	ld b,a			;45a0
	ld ix,0e31ch		;45a1
L_45A5:
	ld hl,045c6h		;45a5
	call L_4EF9		;45a8
	and 003h		;45ab
	add a,a			;45ad
	add a,l			;45ae
	ld l,a			;45af
	ld a,(hl)			;45b0
	ld (ix+001h),a		;45b1
	inc hl			;45b4
	ld a,(hl)			;45b5
	ld (ix+002h),a		;45b6
	ld (ix+000h),001h		;45b9
	ld de,00007h		;45bd
	add ix,de		;45c0
	dec b			;45c2
	jr nz,L_45A5		;45c3
	ret			;45c5

; ----------------------------------------------------------------------
; DATOS sin identificar  0x45c6..0x45ce  (8 bytes)
DATA_45C6:
	defb 001h,001h,01dh,001h,001h,013h,01dh,013h	; 45c6  ........

; ======================================================================
; CODIGO 0x45ce..0x481d  (591 bytes)
; ======================================================================


L_45CE:
	ld a,(0e314h)		;45ce
	or a			;45d1
	ret nz			;45d2
	ld bc,(0e37eh)		;45d3
	ld d,b			;45d7
	ld e,c			;45d8
	call L_4F6F		;45d9
	call L_46A8		;45dc
	cp 020h		;45df
	ret nz			;45e1
	ld b,d			;45e2
	ld c,e			;45e3
	call L_5128		;45e4
	call L_46A8		;45e7
	cp 020h		;45ea
	ret nz			;45ec
	ld a,001h		;45ed
	ld (0e380h),a		;45ef
	ld (0e314h),a		;45f2
	ret			;45f5
L_45F6:
	ld a,(0e380h)		;45f6
	or a			;45f9
	ret z			;45fa
	ld de,(0e37eh)		;45fb
	ld b,d			;45ff
	ld c,e			;4600
	call L_5128		;4601
	ld a,00ah		;4604
	call L_461E		;4606
	inc bc			;4609
	inc a			;460a
	call L_461E		;460b
	ld hl,0001fh		;460e
	add hl,bc			;4611
	ld b,h			;4612
	ld c,l			;4613
	add a,00fh		;4614
	call L_461E		;4616
	inc bc			;4619
	inc a			;461a
	jp L_461E		;461b
L_461E:
	push af			;461e
	ld a,(bc)			;461f
	cp 0e0h		;4620
	jr c,L_4639		;4622
	xor a			;4624
	ld (0e380h),a		;4625
	ld a,(0e37eh)		;4628
	ld (0e31ah),a		;462b
	ld a,(0e37fh)		;462e
	ld (0e31bh),a		;4631
	ld a,001h		;4634
	ld (0e311h),a		;4636
L_4639:
	pop af			;4639
	ld (bc),a			;463a
	ret			;463b
L_463C:
	push af			;463c
	ld a,(bc)			;463d
	cp 0e0h		;463e
	jr c,L_4657		;4640
	xor a			;4642
	ld (0e383h),a		;4643
	ld a,(0e381h)		;4646
	ld (0e31ah),a		;4649
	ld a,(0e382h)		;464c
	ld (0e31bh),a		;464f
	ld a,001h		;4652
	ld (0e311h),a		;4654
L_4657:
	pop af			;4657
	ld (bc),a			;4658
	ret			;4659
L_465A:
	ld a,(0e315h)		;465a
	or a			;465d
	ret nz			;465e
	ld bc,(0e381h)		;465f
	ld d,b			;4663
	ld e,c			;4664
	call L_4F6F		;4665
	call L_46A8		;4668
	cp 020h		;466b
	ret nz			;466d
	ld b,d			;466e
	ld c,e			;466f
	call L_5128		;4670
	call L_46A8		;4673
	cp 020h		;4676
	ret nz			;4678
	ld a,001h		;4679
	ld (0e383h),a		;467b
	ld (0e315h),a		;467e
L_4681:
	ld a,(0e383h)		;4681
	or a			;4684
	ret z			;4685
	ld bc,(0e381h)		;4686
	call L_5128		;468a
	ld a,00eh		;468d
	call L_463C		;468f
	inc bc			;4692
	inc a			;4693
	call L_463C		;4694
	ld hl,0001fh		;4697
	add hl,bc			;469a
	ld b,h			;469b
	ld c,l			;469c
	add a,00fh		;469d
	call L_463C		;469f
	inc bc			;46a2
	inc a			;46a3
	call L_463C		;46a4
	ret			;46a7
L_46A8:
	ld a,(bc)			;46a8
	cp 020h		;46a9
	ret nz			;46ab
	inc bc			;46ac
	ld a,(bc)			;46ad
	cp 020h		;46ae
	ret nz			;46b0
	ld hl,0001fh		;46b1
	add hl,bc			;46b4
	ld b,h			;46b5
	ld c,l			;46b6
	ld a,(bc)			;46b7
	cp 020h		;46b8
	ret nz			;46ba
	inc bc			;46bb
	ld a,(bc)			;46bc
	ret			;46bd
L_46BE:
	ld a,(hl)			;46be
	inc a			;46bf
	inc hl			;46c0
	cp (hl)			;46c1
	jr c,L_46C5		;46c2
	xor a			;46c4
L_46C5:
	dec hl			;46c5
	ld (hl),a			;46c6
	ret			;46c7
L_46C8:
	ld hl,0e36fh		;46c8
	call L_46BE		;46cb
	ld hl,0e375h		;46ce
	call L_46BE		;46d1
	ld hl,0e379h		;46d4
	call L_46BE		;46d7
	ld hl,0e377h		;46da
	call L_46BE		;46dd
	call L_510E		;46e0
	call sigue_los_dos_guiones_de_sonido		;46e3
	ld hl,00500h		;46e6
	jp L_4F7E		;46e9
L_46EC:
	ld a,(0e375h)		;46ec
	or a			;46ef
	ret nz			;46f0
	ld a,(0e358h)		;46f1
	xor 002h		;46f4
	ld (0e358h),a		;46f6
	ld ix,0e31ch		;46f9
L_46FD:
	ld a,(ix+000h)		;46fd
	inc a			;4700
	ret z			;4701
	dec a			;4702
	cp 001h		;4703
	jp nz,L_47B9		;4705
	ld a,(ix+004h)		;4708
	dec a			;470b
	ld d,a			;470c
	cp 0ffh		;470d
	jr nz,L_4722		;470f
	ld a,(ix+003h)		;4711
	dec a			;4714
	cp 0ffh		;4715
	jr nz,L_471B		;4717
	ld a,003h		;4719
L_471B:
	ld (ix+003h),a		;471b
	ld a,(0e317h)		;471e
	ld d,a			;4721
L_4722:
	ld a,d			;4722
	ld (ix+004h),a		;4723
	ld a,(ix+003h)		;4726
	or a			;4729
	jr z,L_4734		;472a
	ld a,(0e375h)		;472c
	and 003h		;472f
	jp nz,L_47B9		;4731
L_4734:
	ld a,(ix+003h)		;4734
	or a			;4737
	jr z,L_477B		;4738
	ld a,(ix+004h)		;473a
	and 00fh		;473d
	or a			;473f
	jr z,L_477B		;4740
	and 003h		;4742
	or a			;4744
	jr z,L_4767		;4745
	call L_47DC		;4747
	cp 080h		;474a
	jr nc,L_4753		;474c
	call L_47C1		;474e
	jr L_47B9		;4751
L_4753:
	call L_4EF9		;4753
	and 003h		;4756
	ld (ix+005h),a		;4758
	call L_47DC		;475b
	cp 080h		;475e
	jr nc,L_47B9		;4760
	call L_47C1		;4762
	jr L_47B9		;4765
L_4767:
	call L_4EF9		;4767
	and 003h		;476a
	ld (ix+005h),a		;476c
	call L_47DC		;476f
	cp 080h		;4772
	jr nc,L_47B9		;4774
	call L_47C1		;4776
	jr L_47B9		;4779
L_477B:
	ld a,(0e309h)		;477b
	ld b,a			;477e
	ld a,(ix+001h)		;477f
	cp b			;4782
	jr z,L_4798		;4783
	jr nc,L_478D		;4785
	ld (ix+005h),001h		;4787
	jr L_4791		;478b
L_478D:
	ld (ix+005h),000h		;478d
L_4791:
	call L_47DC		;4791
	cp 080h		;4794
	jr c,L_47B6		;4796
L_4798:
	ld a,(0e30ah)		;4798
	ld b,a			;479b
	ld a,(ix+002h)		;479c
	cp b			;479f
	jr z,L_47B9		;47a0
	jr nc,L_47AA		;47a2
	ld (ix+005h),003h		;47a4
	jr L_47AE		;47a8
L_47AA:
	ld (ix+005h),002h		;47aa
L_47AE:
	call L_47DC		;47ae
	cp 080h		;47b1
	jp nc,L_47B9		;47b3
L_47B6:
	call L_47C1		;47b6
L_47B9:
	ld bc,00007h		;47b9
	add ix,bc		;47bc
	jp L_46FD		;47be
L_47C1:
	ld a,(ix+005h)		;47c1
	add a,a			;47c4
	ld hl,0482dh		;47c5
	ld b,000h		;47c8
	ld c,a			;47ca
	add hl,bc			;47cb
	ld a,(ix+002h)		;47cc
	add a,(hl)			;47cf
	ld (ix+002h),a		;47d0
	inc hl			;47d3
	ld a,(ix+001h)		;47d4
	add a,(hl)			;47d7
	ld (ix+001h),a		;47d8
	ret			;47db
L_47DC:
	ld hl,0481dh		;47dc
	ld a,(ix+005h)		;47df
	add a,a			;47e2
	add a,a			;47e3
	ld c,a			;47e4
	ld b,000h		;47e5
	add hl,bc			;47e7
	ld a,(ix+002h)		;47e8
	add a,(hl)			;47eb
	ld b,a			;47ec
	inc hl			;47ed
	ld a,(ix+001h)		;47ee
	add a,(hl)			;47f1
	ld c,a			;47f2
	push bc			;47f3
	call L_5128		;47f4
	ld a,(bc)			;47f7
	pop bc			;47f8
	cp 080h		;47f9
	ret nc			;47fb
	call L_4F6F		;47fc
	ld a,(bc)			;47ff
	cp 080h		;4800
	ret nc			;4802
	inc hl			;4803
	ld a,(ix+002h)		;4804
	add a,(hl)			;4807
	ld b,a			;4808
	inc hl			;4809
	ld a,(ix+001h)		;480a
	add a,(hl)			;480d
	ld c,a			;480e
	push bc			;480f
	call L_5128		;4810
	ld a,(bc)			;4813
	pop bc			;4814
	cp 080h		;4815
	ret nc			;4817
	call L_4F6F		;4818
	ld a,(bc)			;481b
	ret			;481c

; ----------------------------------------------------------------------
; DATOS sin identificar  0x481d..0x4835  (24 bytes)
DATA_481D:
	defb 000h,0ffh,001h,0ffh,000h,002h,001h,002h,0ffh,000h,0ffh,001h,002h,000h,002h,001h	; 481d  ................
	defb 000h,0ffh,000h,001h,0ffh,000h,001h,000h	; 482d  ........

; ======================================================================
; CODIGO 0x4835..0x4892  (93 bytes)
; ======================================================================


L_4835:
	ld ix,0e31ch		;4835
L_4839:
	ld a,(ix+000h)		;4839
	inc a			;483c
	ret z			;483d
	dec a			;483e
	jp z,L_4907		;483f
	cp 001h		;4842
	jp z,L_48DB		;4844
	ld c,(ix+001h)		;4847
	ld b,(ix+002h)		;484a
	call L_5128		;484d
	ld a,(ix+000h)		;4850
	add a,a			;4853
	add a,01eh		;4854
	cp 030h		;4856
	jr c,L_4861		;4858
	ld a,020h		;485a
	call L_4B8C		;485c
	jr L_486A		;485f
L_4861:
	call L_4B7B		;4861
	ld c,a			;4864
	ld b,d			;4865
	ld b,c			;4866
	ld b,h			;4867
	ld b,h			;4868
	nop			;4869
L_486A:
	push hl			;486a
	ld hl,0e373h		;486b
	call L_46BE		;486e
	pop hl			;4871
	ld a,(0e373h)		;4872
	or a			;4875
	jp nz,L_4907		;4876
	ld a,(ix+000h)		;4879
	inc a			;487c
	cp 00ah		;487d
	jr z,$+38		;487f
	ld (ix+000h),a		;4881
	ld e,a			;4884
	ld d,001h		;4885
	call escribe_en_el_psg		;4887
	ld hl,04892h		;488a
	ld (0e305h),hl		;488d
	jr $+119		;4890

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_4892: Lo instala 0x488A en (0xE305)
;   0x4892..0x48a5  (19 bytes)
DATA_guion_de_sonido_4892:
	defb 000h,000h,008h,00dh,0ffh,000h,064h,008h,00ah,0ffh,000h,0fah,008h,007h,0ffh,008h	; 4892  ......d.........
	defb 000h,0ffh,0ffh	; 48a2

; ======================================================================
; CODIGO 0x48a5..0x49f3  (334 bytes)
; ======================================================================


L_48A5:
	xor a			;48a5
	ld (ix+000h),a		;48a6
	ld a,(ix+003h)		;48a9
	add a,a			;48ac
	add a,a			;48ad
	inc a			;48ae
	inc a			;48af
	ld b,a			;48b0
	call L_4EF9		;48b1
	and 003h		;48b4
	inc a			;48b6
	add a,b			;48b7
	ld c,a			;48b8
	ld b,000h		;48b9
	ld hl,(0e300h)		;48bb
	add hl,bc			;48be
	ld (0e300h),hl		;48bf
	ld a,(0e30bh)		;48c2
	cp 006h		;48c5
	jr nc,L_4907		;48c7
	ld a,(0e313h)		;48c9
	dec a			;48cc
	ld (0e313h),a		;48cd
	jr nz,L_4907		;48d0
	ld a,(0e318h)		;48d2
	inc a			;48d5
	ld (0e318h),a		;48d6
	jr L_4907		;48d9
L_48DB:
	ld c,(ix+001h)		;48db
	ld b,(ix+002h)		;48de
	call L_5128		;48e1
	ld a,(ix+003h)		;48e4
	add a,a			;48e7
	add a,a			;48e8
	add a,0c0h		;48e9
	ld hl,0e358h		;48eb
	add a,(hl)			;48ee
	call L_490F		;48ef
	inc a			;48f2
	inc bc			;48f3
	call L_490F		;48f4
	ld hl,0001fh		;48f7
	add hl,bc			;48fa
	ld b,h			;48fb
	ld c,l			;48fc
	add a,00fh		;48fd
	call L_490F		;48ff
	inc bc			;4902
	inc a			;4903
	call L_490F		;4904
L_4907:
	ld bc,00007h		;4907
	add ix,bc		;490a
	jp L_4839		;490c
L_490F:
	push af			;490f
	ld a,(bc)			;4910
	cp 0e0h		;4911
	jr c,L_4919		;4913
	ld (ix+000h),002h		;4915
L_4919:
	pop af			;4919
	ld (bc),a			;491a
	ret			;491b
L_491C:
	ld a,(0e30bh)		;491c
	cp 006h		;491f
	ret nc			;4921
	ld a,(0e310h)		;4922
	and 003h		;4925
	jr z,L_492E		;4927
	call L_50FC		;4929
	inc a			;492c
	ret nz			;492d
L_492E:
	ld ix,0e359h		;492e
L_4932:
	ld a,(ix+000h)		;4932
	inc a			;4935
	ret z			;4936
	dec a			;4937
	or a			;4938
	jr nz,L_4976		;4939
	ld bc,(0e309h)		;493b
	ld (ix+001h),c		;493f
	ld (ix+002h),b		;4942
	call L_4F6F		;4945
	ld d,b			;4948
	ld e,c			;4949
	call L_497E		;494a
	ret nz			;494d
	inc bc			;494e
	call L_497E		;494f
	ret nz			;4952
	ld hl,0001fh		;4953
	add hl,bc			;4956
	ld b,h			;4957
	ld c,l			;4958
	call L_497E		;4959
	ret nz			;495c
	inc bc			;495d
	call L_497E		;495e
	ret nz			;4961
	ld b,d			;4962
	ld c,e			;4963
	ld a,060h		;4964
	call L_4B7B		;4966
	ld a,001h		;4969
	ld (ix+000h),a		;496b
	xor a			;496e
	ld (ix+003h),a		;496f
	ld (0e30bh),a		;4972
	ret			;4975
L_4976:
	ld bc,00004h		;4976
	add ix,bc		;4979
	jp L_4932		;497b
L_497E:
	ld a,(bc)			;497e
	cp 020h		;497f
	ret			;4981
L_4982:
	ld ix,0e359h		;4982
L_4986:
	ld a,(ix+000h)		;4986
	inc a			;4989
	ret z			;498a
	ld (ix+000h),000h		;498b
	ld bc,00004h		;498f
	add ix,bc		;4992
	jr L_4986		;4994
L_4996:
	ld a,(0e36eh)		;4996
	xor 002h		;4999
	ld (0e36eh),a		;499b
	ld ix,0e359h		;499e
L_49A2:
	ld a,(ix+000h)		;49a2
	inc a			;49a5
	ret z			;49a6
	dec a			;49a7
	jr z,L_49E9		;49a8
	cp 005h		;49aa
	jr nc,L_49B9		;49ac
	ld a,(ix+003h)		;49ae
	inc a			;49b1
	ld (ix+003h),a		;49b2
	cp 007h		;49b5
	jr nz,L_49E9		;49b7
L_49B9:
	xor a			;49b9
	ld (ix+003h),a		;49ba
	ld a,(0e377h)		;49bd
	or a			;49c0
	jr nz,L_49E9		;49c1
	ld a,(ix+000h)		;49c3
	inc a			;49c6
	cp 00eh		;49c7
	jr z,L_49DF		;49c9
	ld (ix+000h),a		;49cb
	cp 005h		;49ce
	jr c,L_49E9		;49d0
	cp 006h		;49d2
	jr z,L_49F0		;49d4
	ld a,(0e30bh)		;49d6
	cp 006h		;49d9
	jr nc,L_49E9		;49db
	jr L_49E9		;49dd
L_49DF:
	xor a			;49df
	ld (ix+000h),a		;49e0
	ld de,00900h		;49e3
	call escribe_en_el_psg		;49e6
L_49E9:
	ld bc,00004h		;49e9
	add ix,bc		;49ec
	jr L_49A2		;49ee
L_49F0:
	call vuelca_la_tabla_del_psg		;49f0

; ----------------------------------------------------------------------
; DATOS tabla_del_psg_2: Nueve parejas y el 0xFF: el tono de la voz B, el
;   ruido a 0x1F y la envolvente otra vez
;   0x49f3..0x4a06  (19 bytes)
DATA_tabla_del_psg_2:
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
; CODIGO 0x4a06..0x4ac9  (195 bytes)
; ======================================================================


L_4A06:
	jr $-29		;4a06
L_4A08:
	ld ix,0e359h		;4a08
L_4A0C:
	ld a,(ix+000h)		;4a0c
	inc a			;4a0f
	ret z			;4a10
	dec a			;4a11
	jr z,L_4A66		;4a12
	cp 00dh		;4a14
	jr z,L_4A7A		;4a16
	cp 005h		;4a18
	jr c,L_4A24		;4a1a
	add a,a			;4a1c
	add a,0d6h		;4a1d
	exx			;4a1f
	ld d,a			;4a20
	exx			;4a21
	jr L_4A8C		;4a22
L_4A24:
	dec a			;4a24
	add a,a			;4a25
	add a,a			;4a26
	ld d,a			;4a27
	ld a,(0e36eh)		;4a28
	add a,d			;4a2b
	add a,060h		;4a2c
	ld d,a			;4a2e
	exx			;4a2f
	ld d,a			;4a30
	exx			;4a31
	ld a,(ix+001h)		;4a32
	ld c,a			;4a35
	exx			;4a36
	ld c,a			;4a37
	exx			;4a38
	ld a,(ix+002h)		;4a39
	ld b,a			;4a3c
	exx			;4a3d
	ld b,a			;4a3e
	exx			;4a3f
	call L_4F6F		;4a40
	call L_4A6D		;4a43
	inc bc			;4a46
	inc d			;4a47
	call L_4A6D		;4a48
	ld hl,0001fh		;4a4b
	add hl,bc			;4a4e
	ld b,h			;4a4f
	ld c,l			;4a50
	ld a,00fh		;4a51
	add a,d			;4a53
	ld d,a			;4a54
	call L_4A6D		;4a55
	inc bc			;4a58
	inc d			;4a59
	call L_4A6D		;4a5a
	exx			;4a5d
	call L_5128		;4a5e
	ld a,d			;4a61
	call L_4B7B		;4a62
	exx			;4a65
L_4A66:
	ld bc,00004h		;4a66
	add ix,bc		;4a69
	jr L_4A0C		;4a6b
L_4A6D:
	ld a,(bc)			;4a6d
	cp 0e0h		;4a6e
	ret c			;4a70
	ld (ix+000h),004h		;4a71
	ld (ix+003h),006h		;4a75
	ret			;4a79
L_4A7A:
	ld a,(ix+001h)		;4a7a
	ld c,a			;4a7d
	ld a,(ix+002h)		;4a7e
	ld b,a			;4a81
	call L_4F6F		;4a82
	ld a,020h		;4a85
	call L_4B8C		;4a87
	jr L_4A66		;4a8a
L_4A8C:
	ld c,(ix+001h)		;4a8c
	ld b,(ix+002h)		;4a8f
	call L_4F6F		;4a92
	exx			;4a95
	ld a,d			;4a96
	exx			;4a97
	call L_4B7B		;4a98
	exx			;4a9b
	ld a,d			;4a9c
	exx			;4a9d
	inc a			;4a9e
	inc a			;4a9f
	cp 0f0h		;4aa0
	jr c,L_4AA6		;4aa2
	ld a,020h		;4aa4
L_4AA6:
	exx			;4aa6
	ld e,a			;4aa7
	exx			;4aa8
	ld hl,04f8dh		;4aa9
L_4AAC:
	ld a,(hl)			;4aac
	or a			;4aad
	jr z,L_4AB4		;4aae
	add a,a			;4ab0
	or a			;4ab1
	jr z,L_4A66		;4ab2
L_4AB4:
	ld a,(hl)			;4ab4
	inc hl			;4ab5
	add a,(ix+002h)		;4ab6
	ld b,a			;4ab9
	ld a,(hl)			;4aba
	inc hl			;4abb
	add a,(ix+001h)		;4abc
	ld c,a			;4abf
	call L_4B21		;4ac0
	cp 088h		;4ac3
	jr nz,$+16		;4ac5
	jr $+6		;4ac7

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4ac9..0x4acd  (4 bytes)
DATA_4AC9:
	defb 0feh,089h,020h,008h	; 4ac9

; ======================================================================
; CODIGO 0x4acd..0x4c01  (308 bytes)
; ======================================================================


L_4ACD:
	inc hl			;4acd
	inc hl			;4ace
	inc hl			;4acf
	inc hl			;4ad0
	inc hl			;4ad1
	inc hl			;4ad2
	jr $-39		;4ad3
L_4AD5:
	ld a,(hl)			;4ad5
	inc hl			;4ad6
	add a,(ix+002h)		;4ad7
	ld b,a			;4ada
	ld a,(hl)			;4adb
	inc hl			;4adc
	add a,(ix+001h)		;4add
	ld c,a			;4ae0
	call L_4B21		;4ae1
	cp 080h		;4ae4
	jr c,L_4AF2		;4ae6
	cp 08ah		;4ae8
	jr nc,L_4AF2		;4aea
	inc hl			;4aec
	inc hl			;4aed
	inc hl			;4aee
	inc hl			;4aef
	jr $-68		;4af0
L_4AF2:
	ld a,(hl)			;4af2
	inc hl			;4af3
	add a,(ix+002h)		;4af4
	ld b,a			;4af7
	ld a,(hl)			;4af8
	inc hl			;4af9
	add a,(ix+001h)		;4afa
	ld c,a			;4afd
	call L_4B5A		;4afe
	ex af,af'			;4b01
	cp 080h		;4b02
	jr c,L_4B0F		;4b04
	cp 08ah		;4b06
	jr nc,L_4B0F		;4b08
	ex af,af'			;4b0a
	inc hl			;4b0b
	inc hl			;4b0c
	jr $-97		;4b0d
L_4B0F:
	ex af,af'			;4b0f
	ld a,(hl)			;4b10
	inc hl			;4b11
	add a,(ix+002h)		;4b12
	ld b,a			;4b15
	ld a,(hl)			;4b16
	inc hl			;4b17
	add a,(ix+001h)		;4b18
	ld c,a			;4b1b
	call L_4B5A		;4b1c
	jr $-115		;4b1f
L_4B21:
	push bc			;4b21
	call L_5128		;4b22
	ld a,(bc)			;4b25
	pop bc			;4b26
	cp 088h		;4b27
	ret z			;4b29
	cp 089h		;4b2a
	ret z			;4b2c
	call L_4F6F		;4b2d
	ld a,(bc)			;4b30
	cp 088h		;4b31
	ret z			;4b33
	cp 080h		;4b34
	jr c,L_4B3E		;4b36
	cp 08ah		;4b38
	jr nc,L_4B3E		;4b3a
	jr L_4B43		;4b3c
L_4B3E:
	exx			;4b3e
	ld a,e			;4b3f
	exx			;4b40
	jr L_4B4C		;4b41
L_4B43:
	call L_4B4E		;4b43
	cp 088h		;4b46
	jr nz,L_4B4C		;4b48
	ld a,020h		;4b4a
L_4B4C:
	ld (bc),a			;4b4c
	ret			;4b4d
L_4B4E:
	push af			;4b4e
	ex (sp),hl			;4b4f
	ld a,(0e377h)		;4b50
	or a			;4b53
	jr nz,L_4B57		;4b54
	inc h			;4b56
L_4B57:
	ex (sp),hl			;4b57
	pop af			;4b58
	ret			;4b59
L_4B5A:
	push bc			;4b5a
	call L_5128		;4b5b
	ld a,(bc)			;4b5e
	ex af,af'			;4b5f
	ld a,(bc)			;4b60
	ex af,af'			;4b61
	pop bc			;4b62
	cp 088h		;4b63
	ret z			;4b65
	cp 089h		;4b66
	ret z			;4b68
	call L_4F6F		;4b69
	ld a,(bc)			;4b6c
	cp 08ah		;4b6d
	jr nc,L_4B76		;4b6f
	cp 080h		;4b71
	jr c,L_4B76		;4b73
	ret			;4b75
L_4B76:
	exx			;4b76
	ld a,e			;4b77
	exx			;4b78
	ld (bc),a			;4b79
	ret			;4b7a
L_4B7B:
	ld (bc),a			;4b7b
	inc bc			;4b7c
	inc a			;4b7d
	ld (bc),a			;4b7e
	ld hl,0001fh		;4b7f
	add hl,bc			;4b82
	ld b,h			;4b83
	ld c,l			;4b84
	add a,00fh		;4b85
	ld (bc),a			;4b87
	inc bc			;4b88
	inc a			;4b89
	ld (bc),a			;4b8a
	ret			;4b8b
L_4B8C:
	ld (bc),a			;4b8c
	inc bc			;4b8d
	ld (bc),a			;4b8e
	ld hl,0001fh		;4b8f
	add hl,bc			;4b92
	ld b,h			;4b93
	ld c,l			;4b94
	ld (bc),a			;4b95
	inc bc			;4b96
	ld (bc),a			;4b97
	ret			;4b98
L_4B99:
	ld a,(0e30bh)		;4b99
	cp 006h		;4b9c
	jr nc,L_4BC1		;4b9e
	cp 002h		;4ba0
	jr nc,L_4BB3		;4ba2
	or a			;4ba4
	jr nz,L_4BAF		;4ba5
	inc a			;4ba7
	ld (0e30bh),a		;4ba8
	ld e,08ah		;4bab
	jr L_4BC9		;4bad
L_4BAF:
	ld e,08ch		;4baf
	jr L_4BC9		;4bb1
L_4BB3:
	dec a			;4bb3
	dec a			;4bb4
	add a,a			;4bb5
	add a,a			;4bb6
	add a,0a0h		;4bb7
	ld e,a			;4bb9
	ld a,(0e30ch)		;4bba
	add a,e			;4bbd
	ld e,a			;4bbe
	jr L_4BC9		;4bbf
L_4BC1:
	sub 006h		;4bc1
	add a,a			;4bc3
	ld e,a			;4bc4
	ld a,04eh		;4bc5
	sub e			;4bc7
	ld e,a			;4bc8
L_4BC9:
	ld a,(0e30ah)		;4bc9
	ld b,a			;4bcc
	ld a,(0e309h)		;4bcd
	ld c,a			;4bd0
	call L_5128		;4bd1
	call L_4BEB		;4bd4
	call L_4BEB		;4bd7
	ld hl,0001eh		;4bda
	add hl,bc			;4bdd
	ld b,h			;4bde
	ld c,l			;4bdf
	ld a,e			;4be0
	add a,00eh		;4be1
	ld e,a			;4be3
	call L_4BEB		;4be4
	call L_4BEB		;4be7
	ret			;4bea
L_4BEB:
	ld a,(bc)			;4beb
	ld d,a			;4bec
	ld a,e			;4bed
	ld (bc),a			;4bee
	inc bc			;4bef
	inc e			;4bf0
	ld a,d			;4bf1
	cp 0c0h		;4bf2
	ret c			;4bf4
	ld a,(0e30bh)		;4bf5
	cp 006h		;4bf8
	ret nc			;4bfa
	ld a,006h		;4bfb
	ld (0e30bh),a		;4bfd
	ret			;4c00

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4c01..0x4c09  (8 bytes)
DATA_4C01:
	defb 000h,001h,0ffh,000h,001h,000h,000h,0ffh	; 4c01  ........

; ======================================================================
; CODIGO 0x4c09..0x4c3b  (50 bytes)
; ======================================================================


L_4C09:
	ld a,(0e36fh)		;4c09
	or a			;4c0c
	ret nz			;4c0d
	ld a,(0e30bh)		;4c0e
	cp 006h		;4c11
	jr c,$+58		;4c13
	cp 00dh		;4c15
	jr z,$+48		;4c17
	ld hl,0e371h		;4c19
	call L_46BE		;4c1c
	ld a,(0e371h)		;4c1f
	or a			;4c22
	ret nz			;4c23
	ld a,(0e30bh)		;4c24
	inc a			;4c27
	ld (0e30bh),a		;4c28
	add a,a			;4c2b
	add a,a			;4c2c
	add a,a			;4c2d
	ld e,a			;4c2e
	ld d,004h		;4c2f
	call escribe_en_el_psg		;4c31
	ld hl,04c3bh		;4c34
	ld (0e307h),hl		;4c37
	ret			;4c3a

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_4C3B: Lo instala 0x4C34 en (0xE307)
;   0x4c3b..0x4c47  (12 bytes)
DATA_guion_de_sonido_4C3B:
	defb 005h,001h,00ah,00dh,0ffh,00ah,009h,0ffh,00ah,000h,0ffh,0ffh	; 4c3b  ............

; ======================================================================
; CODIGO 0x4c47..0x4cc7  (128 bytes)
; ======================================================================


L_4C47:
	ld a,001h		;4c47
	ld (0e37bh),a		;4c49
	ret			;4c4c
L_4C4D:
	ld b,002h		;4c4d
	call L_50E1		;4c4f
	cp 005h		;4c52
	jr z,L_4C64		;4c54
	inc b			;4c56
	cp 007h		;4c57
	jr z,L_4C64		;4c59
	inc b			;4c5b
	cp 003h		;4c5c
	jr z,L_4C64		;4c5e
	inc b			;4c60
	cp 001h		;4c61
	ret nz			;4c63
L_4C64:
	ld a,(0e30ch)		;4c64
	xor 002h		;4c67
	ld (0e30ch),a		;4c69
	ld hl,04c01h		;4c6c
	ld a,b			;4c6f
	ld e,a			;4c70
	dec a			;4c71
	dec a			;4c72
	add a,a			;4c73
	ld b,000h		;4c74
	ld c,a			;4c76
	add hl,bc			;4c77
	ld a,(0e309h)		;4c78
	add a,(hl)			;4c7b
	ld c,a			;4c7c
	ld a,(0e30ah)		;4c7d
	inc hl			;4c80
	add a,(hl)			;4c81
	ld b,a			;4c82
	push bc			;4c83
	call L_5128		;4c84
	ld d,000h		;4c87
	call L_4CD4		;4c89
	call L_4CD4		;4c8c
	ld hl,0001eh		;4c8f
	add hl,bc			;4c92
	ld b,h			;4c93
	ld c,l			;4c94
	call L_4CD4		;4c95
	call L_4CD4		;4c98
	ld a,d			;4c9b
	or a			;4c9c
	pop bc			;4c9d
	ret nz			;4c9e
	ld a,b			;4c9f
	ld (0e30ah),a		;4ca0
	ld a,c			;4ca3
	ld (0e309h),a		;4ca4
	ld a,e			;4ca7
	ld (0e30bh),a		;4ca8
	ld b,008h		;4cab
	ld a,(0e30ch)		;4cad
	sla a		;4cb0
	sla a		;4cb2
	sla a		;4cb4
	sla a		;4cb6
	or 080h		;4cb8
	ld e,a			;4cba
	ld d,004h		;4cbb
	call escribe_en_el_psg		;4cbd
	ld hl,04cc7h		;4cc0
	ld (0e307h),hl		;4cc3
	ret			;4cc6

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_4CC7: Lo instala 0x4CC0 en (0xE307)
;   0x4cc7..0x4cd4  (13 bytes)
DATA_guion_de_sonido_4CC7:
	defb 005h,000h,00ah,00dh,0ffh,00ah,009h,0ffh,00ah,000h,0ffh,0ffh,0c9h	; 4cc7  .............

; ======================================================================
; CODIGO 0x4cd4..0x4d6c  (152 bytes)
; ======================================================================


L_4CD4:
	ld a,(bc)			;4cd4
	inc bc			;4cd5
	cp 088h		;4cd6
	jr nz,L_4CDB		;4cd8
	inc d			;4cda
L_4CDB:
	cp 089h		;4cdb
	jr nz,L_4CE0		;4cdd
	inc d			;4cdf
L_4CE0:
	cp 080h		;4ce0
	ret nz			;4ce2
	inc d			;4ce3
	ret			;4ce4
L_4CE5:
	ld bc,0e001h		;4ce5
	ld hl,04d87h		;4ce8
	call L_513C		;4ceb
	ld bc,0e00dh		;4cee
	ld hl,04d8eh		;4cf1
	call L_513C		;4cf4
	ld bc,0e019h		;4cf7
	ld hl,04d96h		;4cfa
	call L_513C		;4cfd
	ld bc,0e01eh		;4d00
	ld a,(0e310h)		;4d03
	call L_4F19		;4d06
	ld bc,(0e300h)		;4d09
	ld hl,(0e302h)		;4d0d
	sbc hl,bc		;4d10
	jr nc,L_4D18		;4d12
	ld (0e302h),bc		;4d14
L_4D18:
	ld bc,0e007h		;4d18
	ld hl,(0e300h)		;4d1b
	call L_4F29		;4d1e
	ld bc,0e014h		;4d21
	ld hl,(0e30dh)		;4d24
	call L_4F29		;4d27
	dec bc			;4d2a
	ld a,020h		;4d2b
	ld (bc),a			;4d2d
	ld bc,0e2e1h		;4d2e
	ld hl,04d9ch		;4d31
	jp L_513C		;4d34
L_4D37:
	ld a,(0e310h)		;4d37
	and 003h		;4d3a
	ret nz			;4d3c
	ld bc,0e2e1h		;4d3d
	ld a,(0e386h)		;4d40
	or a			;4d43
	jr z,L_4D52		;4d44
	ld hl,0e386h		;4d46
	call L_46BE		;4d49
	ld hl,04d6ch		;4d4c
	jp L_513C		;4d4f
L_4D52:
	ld h,b			;4d52
	ld l,c			;4d53
	ld b,01ah		;4d54
L_4D56:
	ld (hl),020h		;4d56
	inc hl			;4d58
	djnz L_4D56		;4d59
	ld hl,0e388h		;4d5b
	call L_46BE		;4d5e
	ld a,(0e388h)		;4d61
	or a			;4d64
	ret nz			;4d65
	ld hl,0e386h		;4d66
	jp L_46BE		;4d69

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4d6c..0x4db7  (75 bytes)
DATA_4D6C:
	defb 020h,020h,015h,016h,096h,015h,020h,095h,018h,030h,016h,020h,010h,014h,030h,030h	; 4d6c    .... ..0. ..00
	defb 097h,017h,031h,020h,010h,030h,095h,031h,014h,020h,000h,010h,011h,012h,013h,014h	; 4d7c  ..1 .0.1. ......
	defb 021h,000h,020h,015h,016h,017h,018h,019h,021h,000h,020h,010h,030h,031h,021h,000h	; 4d8c  !. .....!. .01!.
	defb 020h,015h,016h,096h,015h,014h,013h,096h,095h,017h,020h,092h,018h,093h,010h,012h	; 4d9c   ......... .....
	defb 017h,010h,012h,094h,030h,020h,001h,009h,008h,003h,000h	; 4dac  ....0 .....

; ======================================================================
; CODIGO 0x4db7..0x4e0c  (85 bytes)
; ======================================================================


L_4DB7:
	ld a,088h		;4db7
	ld b,020h		;4db9
	ld hl,0e000h		;4dbb
L_4DBE:
	ld (hl),a			;4dbe
	inc hl			;4dbf
	djnz L_4DBE		;4dc0
	ld b,020h		;4dc2
	ld hl,0e2e0h		;4dc4
L_4DC7:
	ld (hl),a			;4dc7
	inc hl			;4dc8
	djnz L_4DC7		;4dc9
	ld b,017h		;4dcb
	ld hl,0e01fh		;4dcd
	ld de,0001fh		;4dd0
L_4DD3:
	ld (hl),a			;4dd3
	inc hl			;4dd4
	ld (hl),a			;4dd5
	add hl,de			;4dd6
	djnz L_4DD3		;4dd7
	ld hl,0e063h		;4dd9
	ld c,005h		;4ddc
	ld a,089h		;4dde
L_4DE0:
	ld b,007h		;4de0
L_4DE2:
	call L_4DF5		;4de2
	or a			;4de5
	ld de,0001dh		;4de6
	sbc hl,de		;4de9
	djnz L_4DE2		;4deb
	ld de,00064h		;4ded
	add hl,de			;4df0
	dec c			;4df1
	jr nz,L_4DE0		;4df2
	ret			;4df4
L_4DF5:
	ld (hl),a			;4df5
	inc hl			;4df6
	ld (hl),a			;4df7
	ld de,0001fh		;4df8
	add hl,de			;4dfb
	ld (hl),a			;4dfc
	inc hl			;4dfd
	ld (hl),a			;4dfe
	ret			;4dff
L_4E00:
	ld hl,04e0ch		;4e00
	call pinta_una_tira_de_rotulos		;4e03
	dec bc			;4e06
	ld a,(0e30fh)		;4e07
	ld (bc),a			;4e0a
	ret			;4e0b

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4e0c..0x4e15  (9 bytes)
DATA_4E0C:
	defb 017h,01ah,020h,020h,090h,021h,020h,000h,0ffh	; 4e0c  ..  .! ..

; ======================================================================
; CODIGO 0x4e15..0x4edf  (202 bytes)
; ======================================================================


L_4E15:
	call L_4EF9		;4e15
	and 01fh		;4e18
	cp 00fh		;4e1a
	jr nc,L_4E15		;4e1c
	ld c,a			;4e1e
L_4E1F:
	call L_4EF9		;4e1f
	and 01fh		;4e22
	cp 00bh		;4e24
	jr nc,L_4E1F		;4e26
	ld b,a			;4e28
	ret			;4e29
L_4E2A:
	ld a,b			;4e2a
	add a,a			;4e2b
	add a,001h		;4e2c
	ld b,a			;4e2e
	ld a,c			;4e2f
	add a,a			;4e30
	add a,001h		;4e31
	ld c,a			;4e33
	ret			;4e34
L_4E35:
	call L_4E15		;4e35
	ld a,c			;4e38
	ld (0e37ch),a		;4e39
	cp 002h		;4e3c
	jr c,L_4E35		;4e3e
	cp 00dh		;4e40
	jr nc,L_4E35		;4e42
	ld a,b			;4e44
	ld (0e37dh),a		;4e45
	cp 002h		;4e48
	jr c,L_4E35		;4e4a
	cp 009h		;4e4c
	jr nc,L_4E35		;4e4e
	call L_4E2A		;4e50
	push bc			;4e53
	call L_5128		;4e54
	ld a,(bc)			;4e57
	cp 020h		;4e58
	pop bc			;4e5a
	jr nz,L_4E35		;4e5b
	ld a,c			;4e5d
	ld (0e309h),a		;4e5e
	ld a,b			;4e61
	ld (0e30ah),a		;4e62
	ld a,023h		;4e65
L_4E67:
	ex af,af'			;4e67
L_4E68:
	call L_4E15		;4e68
	ld d,b			;4e6b
	ld e,c			;4e6c
	ld a,(0e37ch)		;4e6d
	sub e			;4e70
	jr nc,L_4E75		;4e71
	neg		;4e73
L_4E75:
	cp 002h		;4e75
	jr nc,L_4E87		;4e77
	ld a,(0e37dh)		;4e79
	sub d			;4e7c
	jr nc,L_4E81		;4e7d
	neg		;4e7f
L_4E81:
	cp 002h		;4e81
	jr nc,L_4E87		;4e83
	jr L_4E68		;4e85
L_4E87:
	ld a,c			;4e87
	bit 0,a		;4e88
	jr z,L_4E93		;4e8a
	ld a,b			;4e8c
	bit 0,a		;4e8d
	jr nz,L_4E68		;4e8f
	jr L_4E98		;4e91
L_4E93:
	ld a,b			;4e93
	bit 0,a		;4e94
	jr z,L_4E68		;4e96
L_4E98:
	call L_4E2A		;4e98
	ld hl,04edfh		;4e9b
L_4E9E:
	ld a,(hl)			;4e9e
	inc a			;4e9f
	jr z,L_4EB1		;4ea0
	dec a			;4ea2
	cp b			;4ea3
	jr nz,L_4EAD		;4ea4
	inc hl			;4ea6
	ld a,(hl)			;4ea7
	cp c			;4ea8
	jr z,L_4E68		;4ea9
	jr L_4EAE		;4eab
L_4EAD:
	inc hl			;4ead
L_4EAE:
	inc hl			;4eae
	jr L_4E9E		;4eaf
L_4EB1:
	ld a,(0e380h)		;4eb1
	or a			;4eb4
	jr nz,L_4EC4		;4eb5
	ld a,b			;4eb7
	ld (0e37fh),a		;4eb8
	ld a,c			;4ebb
	ld (0e37eh),a		;4ebc
	ld a,001h		;4ebf
	ld (0e380h),a		;4ec1
L_4EC4:
	ld a,b			;4ec4
	ld (0e382h),a		;4ec5
	ld a,c			;4ec8
	ld (0e381h),a		;4ec9
	ld a,001h		;4ecc
	ld (0e383h),a		;4ece
	call L_4F6F		;4ed1
	ld a,080h		;4ed4
	call L_4B8C		;4ed6
	ex af,af'			;4ed9
	dec a			;4eda
	jp nz,L_4E67		;4edb
	ret			;4ede

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4edf..0x4ef9  (26 bytes)
DATA_4EDF:
	defb 001h,003h,003h,001h,013h,001h,015h,003h,001h,01bh,003h,01dh,015h,01bh,013h,01dh	; 4edf  ................
	defb 0ffh,0cdh,06fh,04fh,03eh,020h,0cdh,08ch,04bh,0c9h	; 4eef  ..oO> ..K.

; ======================================================================
; CODIGO 0x4ef9..0x4f84  (139 bytes)
; ======================================================================


L_4EF9:
	push hl			;4ef9
	push de			;4efa
	push bc			;4efb
	ld hl,(0e384h)		;4efc
	ld a,h			;4eff
	rla			;4f00
	rla			;4f01
	xor l			;4f02
	rra			;4f03
	push af			;4f04
	ld a,h			;4f05
	xor l			;4f06
	ld h,a			;4f07
	ld a,r		;4f08
	xor l			;4f0a
	ld l,a			;4f0b
	pop af			;4f0c
	rl l		;4f0d
	rl h		;4f0f
	ld (0e384h),hl		;4f11
	ld a,l			;4f14
	pop bc			;4f15
	pop de			;4f16
	pop hl			;4f17
	ret			;4f18
L_4F19:
	cp 00ah		;4f19
	jr c,L_4F27		;4f1b
	ld h,000h		;4f1d
	ld l,a			;4f1f
	ld de,0000ah		;4f20
	call L_4F48		;4f23
	ld a,l			;4f26
L_4F27:
	ld (bc),a			;4f27
	ret			;4f28
L_4F29:
	ld de,02710h		;4f29
	call L_4F48		;4f2c
	ld de,003e8h		;4f2f
	call L_4F48		;4f32
	ld de,00064h		;4f35
	call L_4F48		;4f38
	ld de,0000ah		;4f3b
	call L_4F48		;4f3e
	ld a,l			;4f41
	ld (bc),a			;4f42
	inc bc			;4f43
	xor a			;4f44
	ld (bc),a			;4f45
	inc bc			;4f46
	ret			;4f47
L_4F48:
	xor a			;4f48
L_4F49:
	or a			;4f49
	sbc hl,de		;4f4a
	jr c,L_4F51		;4f4c
	inc a			;4f4e
	jr L_4F49		;4f4f
L_4F51:
	add hl,de			;4f51
	ld (bc),a			;4f52
	inc bc			;4f53
	ret			;4f54
L_4F55:
	ld hl,0e38ah		;4f55
	ld de,0e38bh		;4f58
	ld bc,002ffh		;4f5b
	ld (hl),020h		;4f5e
	ldir		;4f60
	ret			;4f62
L_4F63:
	ld de,0e000h		;4f63
	ld hl,0e38ah		;4f66
	ld bc,00300h		;4f69
	ldir		;4f6c
	ret			;4f6e
L_4F6F:
	push hl			;4f6f
	call L_5128		;4f70
	ld hl,0038ah		;4f73
	add hl,bc			;4f76
	ld b,h			;4f77
	ld c,l			;4f78
	pop hl			;4f79
	ret			;4f7a
L_4F7B:
	ld hl,05000h		;4f7b
L_4F7E:
	dec hl			;4f7e
	ld a,h			;4f7f
	or l			;4f80
	jr nz,L_4F7E		;4f81
	ret			;4f83

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4f84..0x4fd1  (77 bytes)
DATA_4F84:
	defb 021h,000h,004h,02bh,07ch,0b5h,020h,0fbh,0c9h,000h,0ffh,000h,0feh,000h,0fdh,000h	; 4f84  !..+|. .........
	defb 0fch,001h,0ffh,001h,0feh,001h,0fdh,001h,0fch,000h,002h,000h,003h,000h,004h,000h	; 4f94  ................
	defb 005h,001h,002h,001h,003h,001h,004h,001h,005h,0ffh,000h,0feh,000h,0fdh,000h,0fch	; 4fa4  ................
	defb 000h,0ffh,001h,0feh,001h,0fdh,001h,0fch,001h,002h,000h,003h,000h,004h,000h,005h	; 4fb4  ................
	defb 000h,002h,001h,003h,001h,004h,001h,005h,001h,080h,080h,080h,080h	; 4fc4  .............

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
;   son los punteros de sonido de arranque. El `ldir` se pasa once bytes y
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
; CODIGO 0x5062..0x50d6  (116 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Deja la maquina lista: quita el gancho de la BIOS, vuelca los ocho
; registros del VDP desde 0x5144 y apaga la lista de sprites.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
monta_el_vdp:
	di			;5062
	im 1		;5063
	ld a,0c9h		;5065   ; un `ret` en H.TIMI: la BIOS deja de meter mano cada interrupcion
	ld (0fd9fh),a		;5067
	ld d,008h		;506a   ; los ocho registros
	ld c,000h		;506c   ; empezando por el 0
	ld hl,05144h		;506e   ; la tabla de 0x5144
L_5071:
	ld b,(hl)			;5071
	call 00047h		;5072   ; BIOS WRTVDP - Writes data in the VDP-register | BIOS WRTVDP
	push hl			;5075
	pop hl			;5076
	inc hl			;5077
	inc c			;5078
	dec d			;5079
	jr nz,L_5071		;507a
	ld hl,01c00h		;507c   ; los atributos de sprite, en 0x1C00
	ld a,0d0h		;507f   ; un 0xD0 en el primero: no hay ni un sprite
	call 0004dh		;5081   ; BIOS WRTVRM - Writes data in VRAM
	im 1		;5084
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
	ld a,010h		;5091   ; y el tercero
carga_un_tercio:
	push hl			;5093
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
	ld a,(de)			;50b6
	inc de			;50b7
	cp 0ffh		;50b8   ; con 0xFF se acabo
	jr z,L_50CD		;50ba
	push af			;50bc
	ld a,(de)			;50bd   ; cuantas casillas del mismo color
	inc de			;50be
	ld c,a			;50bf
	ld b,000h		;50c0
	dec c			;50c2
	inc bc			;50c3
	pop af			;50c4
	push bc			;50c5
	call 00056h		;50c6   ; BIOS FILVRM - Fills VRAM with value | BIOS FILVRM
	pop bc			;50c9
	add hl,bc			;50ca   ; y a por el tramo siguiente
	jr rellena_el_color		;50cb
L_50CD:
	pop hl			;50cd
	ret			;50ce
escribe_en_el_psg:
	push af			;50cf   ; D es el registro y E el valor
	ld a,d			;50d0
	call 00093h		;50d1   ; BIOS WRTPSG - Writes data to PSG-register
	pop af			;50d4
	ret			;50d5

; ----------------------------------------------------------------------
; DATOS sin identificar  0x50d6..0x50e1  (11 bytes)
DATA_50D6:
	defb 0c5h,047h,00eh,007h,0f3h,0cdh,047h,000h,0fbh,0c1h,0c9h	; 50d6  .G....G....

; ======================================================================
; CODIGO 0x50e1..0x5144  (99 bytes)
; ======================================================================


L_50E1:
	push bc			;50e1
	push de			;50e2
	push hl			;50e3
	xor a			;50e4
	call 000d5h		;50e5   ; BIOS GTSTCK - Returns the joystick status
	or a			;50e8
	jr nz,L_50F8		;50e9
	ld a,001h		;50eb
	call 000d5h		;50ed   ; BIOS GTSTCK - Returns the joystick status
	or a			;50f0
	jr nz,L_50F8		;50f1
	ld a,002h		;50f3
	call 000d5h		;50f5   ; BIOS GTSTCK - Returns the joystick status
L_50F8:
	pop hl			;50f8
	pop de			;50f9
	pop bc			;50fa
	ret			;50fb
L_50FC:
	xor a			;50fc
	call 000d8h		;50fd   ; BIOS GTTRIG - Returns current trigger status
	or a			;5100
	ret nz			;5101
	ld a,001h		;5102
	call 000d8h		;5104   ; BIOS GTTRIG - Returns current trigger status
	or a			;5107
	ret nz			;5108
	ld a,002h		;5109
	jp 000d8h		;510b   ; BIOS GTTRIG - Returns current trigger status
L_510E:
	ld hl,0e000h		;510e
	ld de,01800h		;5111
	ld bc,00300h		;5114
	call 0005ch		;5117   ; BIOS LDIRVM - Block transfers to VRAM from memory
L_511A:
	ld hl,0e000h		;511a
	ld de,0e001h		;511d
	ld bc,002ffh		;5120
	ld (hl),020h		;5123
	ldir		;5125
	ret			;5127
L_5128:
	push hl			;5128
	ld l,b			;5129
	ld h,000h		;512a
	add hl,hl			;512c
	add hl,hl			;512d
	add hl,hl			;512e
	add hl,hl			;512f
	add hl,hl			;5130
	ld b,000h		;5131
	add hl,bc			;5133
	ld bc,0e000h		;5134
	add hl,bc			;5137
	ld c,l			;5138
	ld b,h			;5139
	pop hl			;513a
	ret			;513b
L_513C:
	ld a,(hl)			;513c
	inc hl			;513d
	or a			;513e
	ret z			;513f
	ld (bc),a			;5140
	inc bc			;5141
	jr L_513C		;5142

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho registros que 0x5062 vuelca del 0 al 7:
;   SCREEN 2, sprites de 16x16, nombres en 0x1800, atributos en 0x1C00 y
;   patrones de sprite en 0x3800
;   0x5144..0x514c  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0c2h,006h,07fh,007h,038h,007h,0f0h	; 5144  .....8..

; ----------------------------------------------------------------------
; DATOS graficos_de_la_pantalla_de_titulo: El bloque que carga 0x427F: destino
;   0x0000, 256 casillas de patrones y 235 tramos de color. Lo vuelca 0x5088
;   en los tres tercios
;   0x514c..0x5b26  (2522 bytes)
DATA_graficos_de_la_pantalla_de_titulo:
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
; DATOS graficos_1: Destino 0x0080, 10 casillas y un solo tramo de color. Lo
;   carga 0x4074
;   0x5b26..0x5b7c  (86 bytes)
DATA_graficos_1:
	defb 080h,000h,00ah,03ch,042h,040h,03ch,002h,042h,03ch,000h,03ch,042h,040h,040h,040h	; 5b26  ...<B@<.B<.<B@@@
	defb 042h,03ch,000h,03ch,042h,042h,042h,042h,042h,03ch,000h,07ch,042h,042h,07ch,048h	; 5b36  B<.<BBBBB<.|BB|H
	defb 044h,042h,000h,07eh,040h,040h,078h,040h,040h,07eh,000h,07ch,042h,042h,07ch,042h	; 5b46  DB.~@@x@@~.|BB|B
	defb 042h,07ch,000h,03ch,042h,042h,042h,042h,042h,03ch,000h,042h,062h,052h,04ah,046h	; 5b56  B|.<BBBBB<.BbRJF
	defb 042h,042h,000h,042h,042h,042h,042h,042h,042h,03ch,000h,03ch,042h,040h,03ch,002h	; 5b66  BB.BBBBBB<.<B@<.
	defb 042h,03ch,000h,0f0h,050h,0ffh	; 5b76

; ----------------------------------------------------------------------
; DATOS graficos_2: Destino 0x0100, 64 casillas y 92 tramos de color. Lo carga
;   0x407A
;   0x5b7c..0x5e38  (700 bytes)
DATA_graficos_2:
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
; DATOS dibujos_que_apunta_0x419B: Los 456 bytes del final del cartucho, que
;   son a lo que apuntan las dieciseis palabras de 0x419B. La primera de ellas
;   es 0x5E38 exacto, o sea el principio de este bloque
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

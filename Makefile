# Bomber Man (Hudson Soft, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# El cartucho no se distribuye: hace falta en la raiz como bomberman.rom, y
# `make comprueba` verifica su sha256.

ROM      = bomberman.rom
SHA      = eab39bab547089facf9df3021e729b65fba2b263c505325d034ed1b6e3df8eea
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = BOMBER MAN - Hudson Soft - MSX1 - cartucho de 8 KB en la pagina 1

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Bomber Man (Hudson Soft, 1983) para MSX, 8192 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo ""
	@echo " Sin el se puede leer el listado ya generado en $(SRC)/, y los"
	@echo " tests que no dependen del binario siguen pasando."
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/bomberman.trace.json: $(ROM) $(SRC)/bomberman.entries $(SRC)/bomberman.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/bomberman.entries \
	        $(WORK)/bomberman $(SRC)/bomberman.nocode

trace: $(WORK)/bomberman.trace.json

listado: $(WORK)/bomberman.trace.json $(SRC)/bomberman.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/bomberman.trace.json \
	        $(SRC)/bomberman.notes work/msx.sym $(SRC)/bomberman.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/bomberman.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/bomberman.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/bomberman.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/bomberman.trace.json $(SRC)/bomberman.nocode
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/bomberman.entries $(SRC)/bomberman.notes \
	        $(SRC)/bomberman.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/bomberman.asm

# Las laminas de docs/imagenes, todas dibujadas ejecutando en Python los pasos del
# cartucho. Aqui no entra ni una captura de pantalla.
imagenes: $(ROM)
	python3 tools/pantallas.py $(ROM) $(ORG) docs/imagenes

# Y la prueba de que esas laminas son las de la maquina: se vuelca la VRAM de
# openMSX y se resta. Hace falta el emulador; `make cotejo` lo arranca solo.
$(WORK)/omsx/vram_08.bin: $(ROM) tools/omsx_vram.tcl
	@mkdir -p $(WORK)/omsx
	"$(OPENMSX)" -machine Philips_VG_8020 -cart $(ROM) -script tools/omsx_vram.tcl

cotejo: $(WORK)/omsx/vram_08.bin
	python3 tools/coteja_vram.py $(ROM) $(ORG) $(WORK)/omsx

# La comprobacion del modo de bomba automatica: fuerza la fase a 4 y mira el
# rotulo de abajo en las dos mitades de su parpadeo.
fase4: $(ROM)
	@mkdir -p $(WORK)/omsx
	"$(OPENMSX)" -machine Philips_VG_8020 -cart $(ROM) -script tools/omsx_fase4.tcl
	@python3 -c "import sys;f={0x20:' ',0x21:':',0x88:'#',0x90:'@',0x10:'S',0x11:'C',0x12:'O',0x13:'R',0x14:'E',0x15:'B',0x16:'O',0x17:'N',0x18:'U',0x19:'S',0x30:'T',0x31:'G',0x92:'H',0x93:'D',0x94:'F',0x95:'A',0x96:'M',0x97:'I'};f.update({k:str(k) for k in range(10)});[print(' %s fila 23: %r'%(n,''.join(f.get(b,'?') for b in open('$(WORK)/omsx/nombres_%s.bin'%n,'rb').read()[736:768]))) for n in 'abcd']"

# La web, en los dos idiomas. Las imagenes se rehacen antes: si una lamina
# cambia, la portada la lleva embebida y tiene que ir con ella.
web: imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	python3 tools/check_enlaces.py docs

# La medida del alcance de la explosion, en la maquina y no sobre el papel.
alcance: $(ROM)
	@mkdir -p $(WORK)/omsx
	"$(OPENMSX)" -machine Philips_VG_8020 -cart $(ROM) -script tools/omsx_alcance.tcl
	python3 tools/mide_el_alcance.py $(WORK)/omsx

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

clean:
	rm -rf $(WORK)/bomberman.trace.json $(WORK)/bomberman.blocks

OPENMSX = C:/Program Files/openMSX/openmsx.exe

.PHONY: all comprueba trace listado verify sanity test densidad imagenes cotejo alcance fase4 web clean

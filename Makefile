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

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

clean:
	rm -rf $(WORK)/bomberman.trace.json $(WORK)/bomberman.blocks

.PHONY: all comprueba trace listado verify sanity test densidad clean

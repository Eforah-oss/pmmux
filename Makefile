.POSIX:
.SILENT:
.PHONY: install uninstall

install: pmmux.sh
	cp pmmux.sh "${DESTDIR}${PREFIX}/bin/pmmux"
	chmod 755 "${DESTDIR}${PREFIX}/bin/pmmux"

uninstall:
	rm -f "${DESTDIR}${PREFIX}/bin/pmmux"

# Makefile for gay-cli

.PHONY: test check install uninstall

PREFIX ?= $(HOME)/.local/bin

test:
	sh ./tests/test.sh

check:
	sh -n ./bin/gay ./install.sh ./tests/test.sh
	node --check ./bin/gay.mjs

install:
	sh ./install.sh --prefix "$(PREFIX)"

uninstall:
	rm -f "$(PREFIX)/gay"
	@printf 'Removed %s/gay\n' "$(PREFIX)"

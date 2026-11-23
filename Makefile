# Makefile for gay-cli

.PHONY: build typecheck test check install uninstall

PREFIX ?= $(HOME)/.local/bin

build:
	npm run build
	chmod +x ./bin/gay.mjs

typecheck:
	npm run typecheck

test:
	sh ./tests/test.sh

check:
	sh -n ./bin/gay ./install.sh ./tests/test.sh
	node --check ./bin/gay.mjs
	npm run typecheck

install:
	sh ./install.sh --prefix "$(PREFIX)"

uninstall:
	rm -f "$(PREFIX)/gay"
	@printf 'Removed %s/gay\n' "$(PREFIX)"

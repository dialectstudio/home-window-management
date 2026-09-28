# Makefile

.PHONY: check install status reload test uninstall

check:
	@./scripts/check.zsh

install:
	@./scripts/install.zsh

status:
	@./scripts/status.zsh --report

reload:
	@./scripts/reload.zsh

test:
	@./tests/lifecycle.zsh

uninstall:
	@./scripts/uninstall.zsh

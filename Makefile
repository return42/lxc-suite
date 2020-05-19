# -*- coding: utf-8; mode: makefile-gmake -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
.DEFAULT_GOAL=help

include utils/makefile.include

help:
	@echo  'targets:'
	@echo  '  test - run tests'
	@echo  'options:'
	@$(MAKE) -e -s make-help

PHONY += test test.sh
test: test.sh

test.sh:
	@echo "TEST      shellcheck"
	$(Q)shellcheck -x -f gcc -s bash .config.sh
	$(Q)shellcheck -x -f gcc *-env/*.sh
	$(Q)shellcheck -x -f gcc base-env
	$(Q)shellcheck -x -f gcc suite
	$(Q)shellcheck -x -f gcc lxc
	$(Q)shellcheck -x -f gcc utils/lxc.sh
	$(Q)shellcheck -x -f gcc utils/lib.sh

.PHONY: $(PHONY)

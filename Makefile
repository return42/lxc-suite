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
	$(Q)shellcheck -x -s bash .config.sh
	$(Q)shellcheck -x utils/lxc.sh
	$(Q)shellcheck -x utils/lxc-dev.env

.PHONY: $(PHONY)

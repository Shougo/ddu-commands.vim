PATH := ./vim-themis/bin:$(PATH)
export THEMIS_VIM  := nvim
export THEMIS_ARGS := -e -s --headless
export THEMIS_HOME := ./vim-themis

test:
	themis --version
	themis test/autoload/*

install:
	git clone https://github.com/thinca/vim-themis vim-themis

lint:
	vint --version
	vint plugin
	vint autoload

.PHONY: install lint test

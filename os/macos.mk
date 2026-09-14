# os/macos.mk - Homebrew backend, ported from install.sh:26-32.
# ponytail: no sudo handling here - install.sh:9-12 skips the keepalive on Darwin entirely.
# Included by the root Makefile; do not add `include`, a default goal, or a target
# named all/deps/zsh/tmux/nvim/opencode here - the root Makefile owns those.

PKGS_CORE := stow tmux neovim fzf zoxide ripgrep fd jq
PKGS_EXTRA := starship lazygit awscli terraform

.PHONY: deps-install

deps-install:
	brew list --versions stow >/dev/null 2>&1 || brew install stow
	brew list --versions tmux >/dev/null 2>&1 || brew install tmux
	brew list --versions neovim >/dev/null 2>&1 || brew install neovim
	brew list --versions fzf >/dev/null 2>&1 || brew install fzf
	brew list --versions zoxide >/dev/null 2>&1 || brew install zoxide
	brew list --versions ripgrep >/dev/null 2>&1 || brew install ripgrep
	brew list --versions fd >/dev/null 2>&1 || brew install fd
	brew list --versions jq >/dev/null 2>&1 || brew install jq
	if [ -z "$(MINIMAL)" ]; then brew list --versions starship >/dev/null 2>&1 || brew install starship || echo "WARN: starship install failed."; fi
	if [ -z "$(MINIMAL)" ]; then brew list --versions lazygit >/dev/null 2>&1 || brew install lazygit || echo "WARN: lazygit install failed."; fi
	if [ -z "$(MINIMAL)" ]; then brew list --versions awscli >/dev/null 2>&1 || brew install awscli || echo "WARN: AWS CLI install failed."; fi
	if [ -z "$(MINIMAL)" ]; then brew list --versions terraform >/dev/null 2>&1 || brew install terraform || echo "WARN: terraform install failed."; fi

# os/ubuntu.mk - apt backend, ported from install.sh:33-58.
# Included by the root Makefile; do not add `include`, a default goal, or a target
# named all/deps/zsh/tmux/nvim/opencode here - the root Makefile owns those.

# curl, wget and gnupg are NOT optional here even though nothing in PKGS_EXTRA is an
# apt package: stock ubuntu:24.04 ships none of the three, and the extras below fetch
# and verify through them (starship+awscli via curl, the hashicorp gpg key via wget,
# dearmored by gpg). Without them every `|| echo WARN` guard fires on `command not
# found` and `make all` still exits 0 - a silent install missing three of four extras.
# gnupg's absence was doubly invisible: the recipe's own `2>/dev/null` swallowed
# `sudo: gpg: command not found`, leaving a bare "WARN: terraform install failed."
# with no cause. Same omission exists in install.sh:33; this is the fix, not a
# refactor regression.
# Ubuntu's apt repo (noble/universe) ships neovim 0.9.5, which is too old for
# LazyVim (requires >=0.11.2 - see https://github.com/LazyVim/LazyVim/issues/6421).
# neovim is therefore NOT in PKGS_CORE; it's installed below from the official
# GitHub release tarball into /opt and symlinked onto PATH instead.
PKGS_CORE := stow zsh tmux git fzf zoxide ripgrep fd-find jq unzip curl wget gnupg
PKGS_EXTRA := starship lazygit awscli terraform

NVIM_MIN_MAJOR := 0
NVIM_MIN_MINOR := 11

.PHONY: deps-install

deps-install:
	sudo -v
	sudo apt install -y $(PKGS_CORE)
	ver="$$(command -v nvim >/dev/null 2>&1 && nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo 0.0.0)"; maj="$$(echo "$$ver" | cut -d. -f1)"; min="$$(echo "$$ver" | cut -d. -f2)"; if [ "$$maj" -gt "$(NVIM_MIN_MAJOR)" ] || { [ "$$maj" -eq "$(NVIM_MIN_MAJOR)" ] && [ "$$min" -ge "$(NVIM_MIN_MINOR)" ]; }; then echo "nvim $$ver already satisfies >=$(NVIM_MIN_MAJOR).$(NVIM_MIN_MINOR) - skipping."; else curl -fsSLo /tmp/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz && sudo rm -rf /opt/nvim-linux-x86_64 && sudo tar xf /tmp/nvim-linux-x86_64.tar.gz -C /opt && sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim && rm -f /tmp/nvim-linux-x86_64.tar.gz || echo "WARN: nvim release install failed - LazyVim needs >=0.11.2."; fi
	# No nerd-font apt package ships the glyphs LazyVim/nvim-web-devicons need, and
	# neither Alacritty nor Neovim can render icons without one - installed to the
	# user's own font dir (no sudo), independent of the apt packages above.
	fc-list | grep -qi "JetBrainsMono Nerd Font" || (mkdir -p "$$HOME/.local/share/fonts" && curl -fsSLo /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip && rm -rf "$$HOME/.local/share/fonts/JetBrainsMonoNerdFont" && unzip -oq /tmp/JetBrainsMono.zip -d "$$HOME/.local/share/fonts/JetBrainsMonoNerdFont" && fc-cache -f "$$HOME/.local/share/fonts" && rm -f /tmp/JetBrainsMono.zip) || echo "WARN: JetBrainsMono Nerd Font install failed - icons in nvim/alacritty will render as boxes."
	command -v kitty >/dev/null 2>&1 || (curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n) || echo "WARN: kitty install failed."
	if [ -z "$(MINIMAL)" ]; then command -v starship >/dev/null 2>&1 || (curl -sS https://starship.rs/install.sh | sh -s -- -y) || echo "WARN: starship install failed."; fi
	if [ -z "$(MINIMAL)" ]; then if command -v lazygit >/dev/null 2>&1; then : > /tmp/lazygit-version.txt; else bash lib/lazygit-version.sh > /tmp/lazygit-version.txt 2>/dev/null || : > /tmp/lazygit-version.txt; fi; fi
	if [ -z "$(MINIMAL)" ] && [ -s /tmp/lazygit-version.txt ]; then curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_$$(cat /tmp/lazygit-version.txt)_Linux_x86_64.tar.gz" && tar xf /tmp/lazygit.tar.gz -C /tmp lazygit && sudo install /tmp/lazygit /usr/local/bin || echo "WARN: lazygit install failed."; fi
	if [ -z "$(MINIMAL)" ] && [ ! -s /tmp/lazygit-version.txt ] && ! command -v lazygit >/dev/null 2>&1; then echo "WARN: lazygit install failed."; fi
	if [ -z "$(MINIMAL)" ]; then command -v aws >/dev/null 2>&1 || (curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && unzip -qo /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install && rm -rf /tmp/awscliv2.zip /tmp/aws) || echo "WARN: AWS CLI install failed."; fi
	# `lsb_release` is NOT on a stock ubuntu:24.04 either, and this line used to
	# interpolate it UNGUARDED: `$$(lsb_release -cs)` expanded to the empty string and
	# wrote `deb [...] https://apt.releases.hashicorp.com  main` - a 2-field entry that
	# poisons apt PERMANENTLY ("E: Malformed entry 1 in list file .../hashicorp.list
	# (Component)"), so the NEXT `make all` died at `sudo apt install` with Error 100.
	# The gate caught exactly that as EXIT-RUN2=2. Two changes, both load-bearing:
	# read the codename from /etc/os-release (always present, no package needed, and
	# what lsb_release itself reads) and refuse to WRITE the list at all unless the
	# codename is non-empty - a failed fetch must not leave apt broken behind it.
	if [ -z "$(MINIMAL)" ]; then command -v terraform >/dev/null 2>&1 || (wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null && cn="$$(. /etc/os-release 2>/dev/null; echo "$$VERSION_CODENAME")" && [ -n "$$cn" ] && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$cn main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null && sudo apt update -qq && sudo apt install -y terraform) || echo "WARN: terraform install failed."; fi
# ponytail: plain `sudo -v` above, no keepalive loop - install.sh:9-12's
# backgrounded "re-authenticate sudo every 50s while this process is alive"
# loop cannot survive here: each make recipe line is its own shell, so a
# backgrounded watcher tied to that shell's own PID dies the instant the line
# it started on exits - before the next line even runs. Ceiling: a very long
# apt run may re-prompt for the password. Upgrade path: wrap this whole recipe
# in one `sudo -s` script invoked as a single recipe line if that becomes
# annoying in practice.

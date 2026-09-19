# Makefile - dotfiles installer entry point. Replaces install.sh.
#
# Prerequisite: GNU Make. macOS ships 3.81 (2006), where `.ONESHELL:` is SILENTLY
# IGNORED and `.RECIPEPREFIX` is a hard error. Every recipe line therefore runs in
# its OWN shell: `cd` and shell variables do NOT persist from one line to the next.
# Keep every recipe line self-contained. No backslash line continuations.

SHELL := /bin/bash

# Must precede every `include`: an include placed before the first target steals
# the default goal, so bare `make` would run a target from os/*.mk instead of all.
.DEFAULT_GOAL := all

REPO := $(CURDIR)

UNAME_S := $(shell uname -s)

# Override for testing:  make nvim OS=ubuntu
OS ?= $(if $(filter Darwin,$(UNAME_S)),macos,$(if $(wildcard /etc/fedora-release),fedora,ubuntu))

# A missing include is a fatal exit 2 with make's unhelpful "No rule to make target"
# message. Name the error instead. Matching against $(wildcard os/*.mk) rather than
# probing os/$(OS).mk directly also confines the include to os/, so OS=../something
# can never reach a file outside that directory.
$(if $(filter os/$(OS).mk,$(wildcard os/*.mk)),,$(error Unsupported OS '$(OS)'. Expected os/$(OS).mk. Add that file - see AGENTS.md))
include os/$(OS).mk

# zsh/ tmux/ nvim/ opencode/ all exist as real directories at this repo's root.
# Without .PHONY, `make nvim` prints "`nvim' is up to date." and exits 0 having
# installed NOTHING. The `check` target below is the regression gate for that.
.PHONY: all deps zsh tmux nvim opencode alacritty check

# Prerequisite order within `all` is unspecified and the components share mkdir
# steps that would race. Do not use `make -j`.
.NOTPARALLEL:

# Skip the optional extras (starship, lazygit, awscli, terraform):
#   make deps MINIMAL=1
MINIMAL ?=

all: zsh tmux nvim opencode alacritty

# deps-install is supplied by the included os/$(OS).mk.
deps: deps-install

# Every optional step below ends in `|| echo "WARN: ..."`. install.sh could let a
# fallible step print a warning and carry on; under make a non-zero recipe line
# FAILS the whole target, so the `||` is load-bearing, not decorative.
# Ports install.sh:146-151 and :172-177.
#
# MINIMAL and starship: README.md:40 promises `--minimal` means "no starship", but
# install.sh:147 curl-installed it regardless. The README is the contract; MINIMAL
# now skips starship here too, not just in os/*.mk.
#
# Bug D (install.sh:175): `getent` does not exist on macOS, so login_shell came back
# empty, `[ "" != "/bin/zsh" ]` was always true, and chsh ran on EVERY invocation.
# `dscl . -read /Users/<u> UserShell` prints `UserShell: /bin/zsh` WITH the label, so
# the awk is required - comparing the raw line leaves D unfixed while looking fixed.
# chsh also FAILS on a shell missing from /etc/shells (e.g. /opt/homebrew/bin/zsh),
# and a failing recipe line fails the target, so /etc/shells is checked before trying.
#
# That guard is load-bearing but was firing on a FALSE negative on Fedora: usrmerge
# puts /usr/sbin ahead of /usr/bin on PATH, so `command -v zsh` answers /usr/sbin/zsh
# while /etc/shells lists /bin/zsh and /usr/bin/zsh - the same binary under the names
# the distro blessed. Resolving to a LISTED equivalent (any /etc/shells line ending in
# /zsh that is executable) fixes the resolution instead of weakening the guard: when
# no listed zsh exists at all, zp is unchanged and the original WARN still runs.
zsh: deps
	lib/stow.sh zsh
	if [ -n "$(MINIMAL)" ]; then echo "MINIMAL set - skipping starship, per README.md:40."; elif ! command -v starship >/dev/null 2>&1; then curl -sS https://starship.rs/install.sh | sh -s -- -y || echo "WARN: starship install failed."; fi
	if [ ! -d "$(REPO)/zsh/znap" ]; then git clone --depth 1 https://github.com/marlonrichert/zsh-snap "$(REPO)/zsh/znap" || echo "WARN: znap clone failed."; else echo "znap already cloned - skipping."; fi
	zp="$$(command -v zsh 2>/dev/null || true)"; alt=; if [ -n "$$zp" ] && ! grep -qxF "$$zp" /etc/shells 2>/dev/null; then for s in $$(grep -E '/zsh$$' /etc/shells 2>/dev/null); do if [ -x "$$s" ]; then alt="$$s"; break; fi; done; fi; if [ -n "$$alt" ]; then echo "note: $$zp is not listed in /etc/shells; using the listed equivalent $$alt"; zp="$$alt"; fi; cur="$$(if [ "$$(uname -s)" = Darwin ]; then dscl . -read "/Users/$$USER" UserShell 2>/dev/null | awk '{print $$2}'; else getent passwd "$$USER" | cut -d: -f7; fi)"; echo "login shell: $${cur:-<unreadable>} | zsh: $${zp:-<absent>}"; if [ -z "$$zp" ]; then echo "WARN: zsh not on PATH - skipping chsh."; elif [ "$$cur" = "$$zp" ]; then echo "login shell is already $$zp - chsh not needed."; elif ! grep -qxF "$$zp" /etc/shells; then echo "WARN: $$zp is absent from /etc/shells, so chsh would fail. Add this exact line to /etc/shells, then re-run: $$zp"; else chsh -s "$$zp" || echo "WARN: chsh -s $$zp failed."; fi

# install.sh:158 runs install_plugins UNCONDITIONALLY, outside the clone guard, so
# tpm keeps updating plugins on every run. Deliberate - do not wrap it in a guard.
tmux: deps
	lib/stow.sh tmux
	if [ ! -d "$$HOME/.tmux/plugins/tpm" ]; then git clone --depth 1 https://github.com/tmux-plugins/tpm "$$HOME/.tmux/plugins/tpm" || echo "WARN: tpm clone failed."; else echo "tpm already cloned - skipping."; fi
	tmux source "$$HOME/.tmux.conf" 2>/dev/null || true
	"$$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || echo "WARN: tpm plugins skipped. Run prefix+I inside tmux."

# Stow only. LazyVim bootstraps itself on first nvim launch; install.sh had no
# nvim bootstrap step either.
nvim: deps
	lib/stow.sh nvim

# Ports install.sh:162-169. The npm guard is repeated on the second line rather than
# shared, because make 3.81 gives each recipe line its own shell - an `if` opened on
# one line cannot close on the next. The npm-absent WARN stays on line one so it
# prints exactly once.
#
# Bug E (install.sh:165): the guard used to be `[ -d ~/.config/opencode/node_modules ]`.
# That directory existed on this host while containing NEITHER plugin, so the check
# passed and npm install never ran. Assert the actual plugin directories, then re-assert
# AFTER installing - npm's exit code is not proof that anything landed. The manifest
# opencode/.config/opencode/package.json is tracked and stowed (verified: npm neither
# rewrites nor replaces the symlink); package-lock.json is deliberately NOT tracked,
# because npm rewrites it THROUGH the symlink into tracked repo content.
opencode: deps
	lib/stow.sh opencode
	if command -v npm >/dev/null 2>&1; then command -v opencode >/dev/null 2>&1 || npm install -g opencode-ai || echo "WARN: opencode install failed."; else echo "WARN: npm not found - skip opencode install. Install Node.js and re-run."; fi
	if command -v npm >/dev/null 2>&1; then if [ -d "$$HOME/.config/opencode/node_modules/oh-my-openagent" ] && [ -d "$$HOME/.config/opencode/node_modules/@dietrichgebert/ponytail" ]; then echo "opencode plugins present - skipping npm install."; else (cd "$$HOME/.config/opencode" && npm install --prefer-offline) || echo "WARN: npm install failed in ~/.config/opencode."; [ -d "$$HOME/.config/opencode/node_modules/oh-my-openagent" ] && [ -d "$$HOME/.config/opencode/node_modules/@dietrichgebert/ponytail" ] || echo "WARN: opencode plugins STILL absent after npm install - check that ~/.config/opencode/package.json resolves into this repo."; fi; fi

# Stow only. Font install (Nerd Font, needed for LazyVim/devicons glyphs) is
# handled in deps-install per-OS, same pattern as the nvim version bump above.
alacritty: deps
	lib/stow.sh alacritty

# Anti-phony regression gate. Two probes, because one is not enough:
#   1. SYMPTOM - the user-visible "`nvim' is up to date." that silently installs nothing.
#   2. CAUSE   - make's own database marking the target .PHONY.
# Probe 1 alone cannot fail here: every component has the phony `deps` prerequisite,
# which forces a rebuild and masks the symptom even when .PHONY is lost. Verified.
# Probe 2 fires on the lost .PHONY regardless of prerequisites.
# Single-line recipes; $$ escapes make's $.
check:
	@for t in all deps zsh tmux nvim opencode alacritty; do $(MAKE) -n $$t 2>&1 | grep -q "is up to date" && { echo "FAIL: target '$$t' reports 'is up to date' - it is shadowed by a same-named file or directory. Add it to .PHONY."; exit 1; }; done; echo "ok: no target reports 'is up to date'"
	@db=$$($(MAKE) -p -n 2>/dev/null); for t in all deps zsh tmux nvim opencode alacritty; do echo "$$db" | grep -A1 "^$$t:" | grep -q "Phony target" || { echo "FAIL: target '$$t' is NOT marked .PHONY - a same-named file or directory would shadow it. Add it to .PHONY."; exit 1; }; done; echo "PASS: all seven targets are .PHONY and none reports 'is up to date'"

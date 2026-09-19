# AGENTS.md

## Repo structure

```
Makefile             # Entry point. Targets: all, deps, zsh, tmux, nvim, opencode, alacritty, check
os/                   # Per-OS package backends: macos.mk, ubuntu.mk, fedora.mk
lib/                  # lib/stow.sh (per-package symlink cleanup + stow), lib/verify-linux.sh (Docker gate)
install.ps1           # Windows installer (winget + delegates to setup-config.ps1)
setup-config.ps1      # Windows config-only (no admin: junctions/copies fallback)
zsh/.zshrc            # → ~/.zshrc (via stow)
zsh/.config/          # → ~/.config/starship.toml (via stow)
tmux/.tmux.conf       # → ~/.tmux.conf (via stow)
nvim/.config/nvim/    # → ~/.config/nvim/ (via stow) or %LOCALAPPDATA%\nvim (via symlink/junction)
opencode/.config/opencode/  # → ~/.config/opencode/ (via stow)
opencode/.agents/skills/    # → ~/.agents/skills/ (via stow)
alacritty/.config/alacritty/  # → ~/.config/alacritty/ (via stow); os/ubuntu.mk also installs
                               # JetBrainsMono Nerd Font since apt ships none and LazyVim/nvim-web-devicons need glyph coverage
```

## Conventions

- GNU Stow manages all symlinks. Each top-level dir is a stow package targeting `$HOME`.
- **Never add `--adopt` to the stow loop.** It moves files from `$HOME` into the repo and
  overwrites tracked content. It has already silently gutted `opencode.jsonc` once.
- Because targets are symlinks into the repo, editing repo content is live immediately.
  Re-stow only when files are added or removed. Dry-run with `stow -n -v` first.
- Shell scripts use `#!/usr/bin/env bash`, `set -e`, and resolve `SCRIPT_DIR` for portability.
- System packages are installed by the per-OS backends in `os/*.mk`; stow handles config placement.
- Plugin managers bootstrap post-stow (znap, tpm, lazy.nvim).
- `.gitignore` excludes cloned plugin dirs (`znap/`, `zsh-users/`).
- On Windows, `setup-config.ps1` falls back to junctions (dirs) and copies (files) when
  symlinks require admin. Copies are not live — re-run after repo edits. Enable Developer
  Mode for real symlinks without elevation.
- `oh-my-openagent.json` is a git symlink (mode `120000`). When `core.symlinks=false`
  (Windows default), git checks it out as a plain text stub containing the target filename.
  On Windows, `install.ps1`/`setup-config.ps1` detect and resolve the stub. On Linux/macOS,
  `lib/stow.sh` does the same after stowing the `opencode` package.
- zsh gets no `/etc/profile` (no `/etc/zprofile` exists), so `PATH` must be set explicitly
  in `zsh/.zshrc`. Do not rely on `~/.bashrc` — zsh never reads it.
- `$SHELL` is unreliable: `/etc/bashrc` hardcodes `SHELL=/bin/bash`. Read the login shell
  from `getent passwd "$USER" | cut -d: -f7` instead.

## OpenCode model profiles

`opencode/.config/opencode/oh-my-openagent.json` is a **symlink to a preset**
(`.bedrock.json`, `.github-copilot.json`, `.opencode-go.json`, `.mixed.json`), because
the plugin only ever reads that one fixed filename. Switch with
`ln -sfn oh-my-openagent.<preset>.json oh-my-openagent.json` inside the repo. Git tracks
the symlink as mode `120000`. See README.md for the full workflow.

`opencode.jsonc` must keep its `plugin` array — without it `oh-my-openagent` never loads
and every `oh-my-openagent.*.json` file is inert.

Plugin versions are **pinned on purpose**. `@latest` makes opencode resolve the version
over the network on every startup, and that lookup hangs here (see IPv6 note below),
turning a 7s start into minutes.

The ponytail plugin is `@dietrichgebert/ponytail`. The bare npm name `ponytail` is an
**unrelated 2019 package** ("Rethinking maintenance of multiple sites") — do not use it.
The `gkwa/ponytail` URL in older notes is a dead link.

OpenCode itself is the npm package `opencode-ai`. `@nicepkg/opencode` does not exist
on npm (404) — `setup-config.ps1` used to install it and silently failed.

`opencode.jsonc` sets the **primary session model**; `oh-my-openagent.json` sets
**per-agent and per-category routing**. They are independent. A third thing, the
picker state in `~/.local/state/opencode/model.json`, wins over config for new
sessions. A retired model ID in any of the three surfaces as a startup warning.

OpenCode reads its config **once at process start**. Opening a new session inside a
running process does not reload it, so config fixes appear not to work until every
instance is quit.

## Known machine issue: broken IPv6

This host gets a global IPv6 address and default route from router advertisement, but has
no IPv6 transit:

```bash
curl -4 https://registry.npmjs.org/ponytail   # 200 in ~0.07s
curl -6 https://registry.npmjs.org/ponytail   # hangs
ping6 2606:4700::6810:22                      # 100% packet loss
```

There is no `/etc/gai.conf`, so glibc prefers IPv6 and every AAAA-first lookup stalls
`tcp_syn_retries=6` ≈ **127s per attempt**. `curl` and npm survive via Happy Eyeballs
(Node 20+ enables `autoSelectFamily`); bun does not, which is why opencode plugin
*version resolution* hung while `npm install` worked.

Permanent fix (needs root):

```bash
echo 'precedence ::ffff:0:0/96  100' | sudo tee /etc/gai.conf
```

## Commands

```bash
make                       # Full setup (deps + all components: zsh tmux nvim opencode)
make zsh nvim              # Selective: only zsh + nvim
make deps MINIMAL=1        # System packages only, skip starship, lazygit, AWS, terraform
make deps                  # System packages only, with extras
make check                 # Regression gate: asserts every component target is .PHONY
```

`make` itself is a prerequisite. Stock `ubuntu:24.04` has neither `make` nor `stow`:

```bash
xcode-select --install       # macOS
sudo apt install make        # Ubuntu/Debian
sudo dnf install make        # Fedora
```

```powershell
.\install.ps1             # Full setup (winget + config, requires admin)
.\setup-config.ps1        # Config only (no admin needed)
```

## Adding a new tool

1. Create `tool/.config/tool/` mirroring target path relative to `$HOME`.
2. Add the system package to each `os/*.mk` (`macos.mk`, `ubuntu.mk`, `fedora.mk`).
3. Add a `tool: deps` target to the `Makefile`, including `tool` in the `.PHONY` list.
4. Add `tool`'s package→target-paths entry to the `case` in `lib/stow.sh`.
5. If it needs shell init, add `eval "$(tool init zsh)"` to `zsh/.zshrc`.

## Adding an OS backend

Adding OS support is one file plus one line, by design:

1. Create `os/<name>.mk` defining a `deps-install` target (and `.PHONY: deps-install`)
   that installs packages via that OS's package manager, honoring `MINIMAL` the same
   way `os/macos.mk` does. Every recipe line must be self-contained — GNU Make 3.81
   gives each line its own shell, so `cd` and shell variables don't persist across lines.
2. Add one branch to the OS-detection line near the top of the `Makefile`:
   `OS ?= $(if $(filter Darwin,$(UNAME_S)),macos,$(if $(wildcard /etc/fedora-release),fedora,ubuntu))`.
   The `Makefile` matches against `$(wildcard os/*.mk)` rather than probing the file
   directly, so `OS=../something` can never `include` a file outside `os/`.

Override for testing without touching the detection logic: `make nvim OS=ubuntu`.

## Neovim

LazyVim-based config in `nvim/.config/nvim/`. Plugins auto-install on first launch. Lua formatting uses stylua.

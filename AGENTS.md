# AGENTS.md

## Repo structure

```
install.sh          # Top-level installer (runs sub-installers)
zsh/install.sh      # Symlinks .zshrc + starship.toml, installs znap
tmux/install.sh     # Symlinks tmux.conf, installs tpm + plugins
nvim/install.sh     # Symlinks nvim/ → ~/.config/nvim (LazyVim)
```

Each tool gets its own directory with an `install.sh` that is idempotent and OS-aware (brew/apt/dnf).

## Conventions

- Shell scripts use `#!/usr/bin/env bash`, `set -e`, and resolve `SCRIPT_DIR` for portability.
- System packages are installed in the root `install.sh`; sub-installers handle tool-specific setup only.
- Config files are symlinked into place (`ln -sf`), never copied.
- Plugin managers bootstrap themselves if missing (znap, tpm, lazy.nvim).
- `.gitignore` excludes cloned plugin dirs (`znap/`, `zsh-users/`).

## Commands

```bash
./install.sh              # Full setup (deps + all sub-installers)
./zsh/install.sh          # Just zsh config
./tmux/install.sh         # Just tmux config
./nvim/install.sh         # Just nvim config
```

## Adding a new tool

1. Add system package to `install.sh` (all three package managers).
2. If it needs shell init, add `eval "$(tool init zsh)"` to `zsh/.zshrc`.
3. If it needs its own config dir, create `tool/install.sh` following existing pattern and call it from root `install.sh`.

## Neovim

LazyVim-based config. `nvim/` is symlinked wholesale to `~/.config/nvim`. Plugins auto-install on first launch. Lua formatting uses stylua (`nvim/stylua.toml`).

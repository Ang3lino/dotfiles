# AGENTS.md

## Repo structure

```
install.sh          # Top-level installer (deps + stow + bootstrap)
zsh/.zshrc          # → ~/.zshrc (via stow)
zsh/.config/        # → ~/.config/starship.toml (via stow)
tmux/.tmux.conf     # → ~/.tmux.conf (via stow)
nvim/.config/nvim/  # → ~/.config/nvim/ (via stow, LazyVim)
opencode/.config/opencode/  # → ~/.config/opencode/ (via stow)
opencode/.agents/skills/    # → ~/.agents/skills/ (via stow)
```

## Conventions

- GNU Stow manages all symlinks. Each top-level dir is a stow package targeting `$HOME`.
- Shell scripts use `#!/usr/bin/env bash`, `set -e`, and resolve `SCRIPT_DIR` for portability.
- System packages are installed in the root `install.sh`; stow handles config placement.
- Plugin managers bootstrap post-stow (znap, tpm, lazy.nvim).
- `.gitignore` excludes cloned plugin dirs (`znap/`, `zsh-users/`).

## Commands

```bash
./install.sh              # Full setup (deps + all components)
./install.sh zsh nvim     # Selective: only zsh + nvim
./install.sh --minimal    # Skip starship, lazygit, AWS, terraform
./install.sh deps         # System packages only
```

## Adding a new tool

1. Create `tool/.config/tool/` mirroring target path relative to `$HOME`.
2. Add system package to `install.sh` (all three package managers).
3. Add `tool` to the stow loop in `install.sh`.
4. If it needs shell init, add `eval "$(tool init zsh)"` to `zsh/.zshrc`.

## Neovim

LazyVim-based config in `nvim/.config/nvim/`. Plugins auto-install on first launch. Lua formatting uses stylua.

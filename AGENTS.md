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
- **Never add `--adopt` to the stow loop.** It moves files from `$HOME` into the repo and
  overwrites tracked content. It has already silently gutted `opencode.jsonc` once.
- Because targets are symlinks into the repo, editing repo content is live immediately.
  Re-stow only when files are added or removed. Dry-run with `stow -n -v` first.
- Shell scripts use `#!/usr/bin/env bash`, `set -e`, and resolve `SCRIPT_DIR` for portability.
- System packages are installed in the root `install.sh`; stow handles config placement.
- Plugin managers bootstrap post-stow (znap, tpm, lazy.nvim).
- `.gitignore` excludes cloned plugin dirs (`znap/`, `zsh-users/`).
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

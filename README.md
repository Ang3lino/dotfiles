# dotfiles

Personal dotfiles for zsh, tmux, neovim, vim, and opencode.

## Install

```bash
git clone https://github.com/Ang3lino/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`--minimal` skips starship and lazygit.

## What's included

| Tool | Config | Installer |
|------|--------|-----------|
| zsh | `.zshrc`, `starship.toml` | `zsh/install.sh` |
| tmux | `tmux.conf` | `tmux/install.sh` |
| neovim | LazyVim config | `nvim/install.sh` |
| vim | amix/vimrc basic | `vim/install.sh` |
| opencode | agent config, skills, commands | `opencode/install.sh` |

## OpenCode addons

| Addon | What it does | Source |
|-------|-------------|--------|
| [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) | Agent orchestration, model routing, fallback chains | Plugin |
| [ponytail](https://github.com/gkwa/ponytail) | Lazy senior dev mode — YAGNI enforcement | Plugin + commands |
| brainstorming | Intent/requirements exploration before implementation | Skill |
| find-skills | Discover and install agent skills | Skill |

### Related projects

- [OpenCode](https://github.com/nicepkg/opencode) — AI coding agent
- [Everything Claude Code (ECC)](https://github.com/affaan-m/everything-claude-code) — Skill/rule collection (some skills sourced from here)
- [Starship](https://starship.rs/) — Cross-shell prompt
- [LazyVim](https://www.lazyvim.org/) — Neovim config framework

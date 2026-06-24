# dotfiles

Personal dotfiles for zsh, tmux, neovim, vim, opencode, and PowerShell.

## Install

### Linux / macOS / WSL

```bash
git clone https://github.com/Ang3lino/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Windows (PowerShell as Admin)

```powershell
git clone https://github.com/Ang3lino/dotfiles.git $env:USERPROFILE\dotfiles
cd $env:USERPROFILE\dotfiles
.\install.ps1
```

`--minimal` skips starship, lazygit, AWS CLI, and terraform on both platforms.

## What's included

| Tool | Config | Linux/macOS | Windows |
|------|--------|-------------|---------|
| zsh | `.zshrc`, `starship.toml` | `zsh/install.sh` | N/A (use WSL) |
| PowerShell | `profile.ps1`, `starship.toml` | N/A | `pwsh/install.ps1` |
| tmux | `tmux.conf` | `tmux/install.sh` | N/A (use WSL) |
| neovim | LazyVim config | `nvim/install.sh` | `nvim/install.ps1` |
| vim | amix/vimrc basic | `vim/install.sh` | N/A |
| opencode | agent config, skills, commands | `opencode/install.sh` | `opencode/install.ps1` |

## Secrets

Create a secrets file (never committed) for API keys:

```bash
# Linux/macOS: ~/.secrets
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
export OPENCODE_API_KEY=xxx
```

```powershell
# Windows: ~\.secrets.ps1
$env:AWS_ACCESS_KEY_ID = "xxx"
$env:AWS_SECRET_ACCESS_KEY = "xxx"
$env:OPENCODE_API_KEY = "xxx"
```

Both shells source these automatically on startup.

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

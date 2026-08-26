# dotfiles

Personal dotfiles for zsh, tmux, neovim, vim, opencode, and PowerShell.

## Install

### Linux / macOS / WSL

```bash
git clone https://github.com/Ang3lino/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Windows

```powershell
git clone https://github.com/Ang3lino/dotfiles.git $env:USERPROFILE\dotfiles
cd $env:USERPROFILE\dotfiles

# Full install (admin — installs tools via winget + config)
.\install.ps1

# Config only (no admin — symlinks/junctions + plugins)
.\setup-config.ps1
```

`install.ps1` requires admin (winget installs). `setup-config.ps1` works without admin
by falling back to junctions (directories) and copies (files) when symlinks aren't permitted.

> **Note:** File copies won't auto-update when you edit the repo. Re-run `.\setup-config.ps1`
> after changes, or enable Developer Mode (Settings → Privacy & Security → For Developers)
> for real symlinks without admin.

### Options

```bash
./install.sh                   # everything
./install.sh zsh nvim          # just zsh + neovim
./install.sh --minimal zsh     # zsh without extras (no starship, lazygit, aws, terraform)
./install.sh deps              # system packages only, no configs
```

Components: `deps`, `zsh`, `tmux`, `nvim`, `opencode`. No args = everything.

Uses GNU Stow for symlinks — each top-level dir mirrors `$HOME`.

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
| [@dietrichgebert/ponytail](https://github.com/DietrichGebert/ponytail) | Lazy senior dev mode — YAGNI enforcement | Plugin + commands |
| brainstorming | Intent/requirements exploration before implementation | Skill |
| find-skills | Discover and install agent skills | Skill |

### Switching agent model profiles

`oh-my-openagent` reads exactly one filename: `~/.config/opencode/oh-my-openagent.json`.
In this repo that name is a **symlink to a profile preset**, so switching providers
is a one-line change.

| Preset | Providers used |
|--------|----------------|
| `oh-my-openagent.bedrock.json` | `amazon-bedrock` only |
| `oh-my-openagent.github-copilot.json` | `github-copilot` only — **currently active** |
| `oh-my-openagent.opencode-go.json` | `opencode-go` only |
| `oh-my-openagent.mixed.json` | All three, with `fallback_models` chains |

To switch, re-point the symlink **inside the repo** (not in `~/.config`):

```bash
cd opencode/.config/opencode
ln -sfn oh-my-openagent.github-copilot.json oh-my-openagent.json
```

Confirm which preset is live, and that it parses through both symlink hops:

```bash
readlink -f ~/.config/opencode/oh-my-openagent.json
jq -e . ~/.config/opencode/oh-my-openagent.json >/dev/null && echo OK
```

List every provider the active profile references — useful for catching a stray
`github-copilot` entry when you meant Bedrock only:

```bash
jq -r '[.agents[].model, .categories[].model] | map(split("/")[0]) | unique | .[]' \
  ~/.config/opencode/oh-my-openagent.json
```

Restart opencode to pick up the change.

**You do not need to re-run `stow` for this.** `~/.config/opencode/oh-my-openagent.json`
already points into the repo, so editing repo content — including re-pointing the
profile symlink — is live immediately. Re-stow only when you **add or remove a
file**, since only then does the set of required links change:

```bash
stow -n -v --target="$HOME" --restow opencode   # dry run first
stow    -v --target="$HOME" --restow opencode
```

Never pass `--adopt`. It moves files from `$HOME` *into* the repo, overwriting
tracked content, and will flatten the profile symlink into a plain file.

### Related projects

- [OpenCode](https://github.com/nicepkg/opencode) — AI coding agent
- [Everything Claude Code (ECC)](https://github.com/affaan-m/everything-claude-code) — Skill/rule collection (some skills sourced from here)
- [Starship](https://starship.rs/) — Cross-shell prompt
- [LazyVim](https://www.lazyvim.org/) — Neovim config framework

## Troubleshooting

### IPv6 hangs (opencode black screen / npm stalls)

If your machine has a global IPv6 address but no transit, Node.js tries AAAA records first
and hangs ~127s per attempt. Symptoms: opencode shows black screen on startup, `npm install`
stalls.

**Linux fix:**

```bash
echo 'precedence ::ffff:0:0/96  100' | sudo tee /etc/gai.conf
```

**Windows fix:**

```powershell
# Persistent env var (user-level)
[Environment]::SetEnvironmentVariable("NODE_OPTIONS", "--dns-result-order=ipv4first", "User")
# Also fix OS-level preference
netsh interface ipv6 set prefixpolicy ::ffff:0:0/96 46 4
```

### `oh-my-openagent.json` git symlink on Windows

Git on Windows defaults to `core.symlinks=false`, checking out symlinks as plain text stub
files. Both `install.ps1` and `setup-config.ps1` handle this automatically by reading the
stub content and resolving to the actual preset file.

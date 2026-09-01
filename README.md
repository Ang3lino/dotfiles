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

There is one installer per OS. Individual tools have no separate installer;
`install.sh` / `setup-config.ps1` handle every component.

| Tool | Config | Linux/macOS | Windows |
|------|--------|-------------|---------|
| zsh | `.zshrc`, `starship.toml` | `./install.sh zsh` | N/A (use WSL) |
| PowerShell | `profile.ps1`, `starship.toml` | N/A | `pwsh/install.ps1` (called by `install.ps1`) |
| tmux | `tmux.conf` | `./install.sh tmux` | N/A (use WSL) |
| neovim | LazyVim config | `./install.sh nvim` | `.\setup-config.ps1` |
| opencode | agent config, skills, commands | `./install.sh opencode` | `.\setup-config.ps1` |

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

## OpenCode

### Install

OpenCode itself is the npm package **`opencode-ai`** (not `@nicepkg/opencode`, which
does not exist on npm). Node.js is a hard prerequisite on both platforms.

```bash
./install.sh opencode          # Linux/macOS/WSL — stow + opencode-ai + plugins
```

```powershell
.\setup-config.ps1             # Windows — links + opencode-ai + plugins, no admin
```

Both do the same three things:

1. Link this repo's config into the live config directory.
2. `npm install -g opencode-ai` if `opencode` is not already on `PATH`.
3. `npm install` inside the live config dir, which materialises `node_modules/`
   for the plugins declared in `opencode.jsonc`.

Step 3 is not optional. `opencode.jsonc` names plugins by package; without that
local `node_modules` the `plugin` array is inert and no agent routing happens.

### Where each file lives

| Repo path | Linux/macOS | Windows |
|-----------|-------------|---------|
| `opencode/.config/opencode/opencode.jsonc` | `~/.config/opencode/opencode.jsonc` | `%USERPROFILE%\.config\opencode\opencode.jsonc` |
| `opencode/.config/opencode/oh-my-openagent.json` | `~/.config/opencode/oh-my-openagent.json` | `%USERPROFILE%\.config\opencode\oh-my-openagent.json` |
| `opencode/.config/opencode/commands/*.md` | `~/.config/opencode/commands/` | `%USERPROFILE%\.config\opencode\commands\` |
| `opencode/.agents/skills/<name>/` | `~/.agents/skills/<name>/` | `%USERPROFILE%\.agents\skills\<name>\` |

Not in this repo — runtime state OpenCode owns, useful when debugging:

| Path | Contents |
|------|----------|
| `~/.local/state/opencode/model.json` | model picker `recent` / `favorite` / `variant` |
| `~/.local/share/opencode/log/opencode.log` | the only place startup warnings are recorded |
| `~/.local/share/opencode/opencode.db` | session transcripts |
| `~/.config/opencode/node_modules/` | resolved plugins (generated, not tracked) |

Windows uses the same `~`-relative layout, i.e. `%USERPROFILE%\.local\state\opencode\`.

### Modifying config after install

Every live path is a **symlink into this repo**, so editing repo content is live
immediately on both platforms — no re-stow, no re-run, just restart opencode.

The one exception is *adding or removing a file*, since only then does the set of
required links change:

```bash
stow -n -v --target="$HOME" --restow opencode   # dry run first
stow    -v --target="$HOME" --restow opencode
```

```powershell
.\setup-config.ps1
```

Never pass `--adopt` to stow. It moves files from `$HOME` *into* the repo,
overwriting tracked content, and will flatten the profile symlink into a plain file.

**Windows caveat.** `setup-config.ps1` links to the *resolved preset target*, not to
the `oh-my-openagent.json` stub. Editing preset contents is therefore live, but
*switching* presets requires re-running `setup-config.ps1` — unlike Linux, where
re-pointing the symlink is enough. Confirm you got real symlinks and not the
copy fallback:

```powershell
(Get-Item ~\.config\opencode\oh-my-openagent.json).LinkType   # want: SymbolicLink
```

If it prints nothing, you got a **copy** — edits will not propagate. Enable
Developer Mode (Settings → Privacy & Security → For Developers) and re-run.

### Manual installation

If you would rather not run the installers:

```bash
npm install -g opencode-ai
mkdir -p ~/.config/opencode ~/.agents/skills
ln -sfn ~/dotfiles/opencode/.config/opencode/opencode.jsonc        ~/.config/opencode/opencode.jsonc
ln -sfn ~/dotfiles/opencode/.config/opencode/oh-my-openagent.github-copilot.json \
                                                                   ~/.config/opencode/oh-my-openagent.json
ln -sfn ~/dotfiles/opencode/.config/opencode/commands              ~/.config/opencode/commands
ln -sfn ~/dotfiles/opencode/.agents/skills/brainstorming           ~/.agents/skills/brainstorming
ln -sfn ~/dotfiles/opencode/.agents/skills/find-skills             ~/.agents/skills/find-skills
(cd ~/.config/opencode && npm install)
```

```powershell
npm install -g opencode-ai
$repo = "$env:USERPROFILE\dotfiles\opencode"
New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\opencode","$env:USERPROFILE\.agents\skills" | Out-Null
New-Item -ItemType SymbolicLink -Force -Path "$env:USERPROFILE\.config\opencode\opencode.jsonc" `
    -Target "$repo\.config\opencode\opencode.jsonc"
New-Item -ItemType SymbolicLink -Force -Path "$env:USERPROFILE\.config\opencode\oh-my-openagent.json" `
    -Target "$repo\.config\opencode\oh-my-openagent.github-copilot.json"
New-Item -ItemType SymbolicLink -Force -Path "$env:USERPROFILE\.config\opencode\commands" `
    -Target "$repo\.config\opencode\commands"
New-Item -ItemType SymbolicLink -Force -Path "$env:USERPROFILE\.agents\skills\brainstorming" `
    -Target "$repo\.agents\skills\brainstorming"
New-Item -ItemType SymbolicLink -Force -Path "$env:USERPROFILE\.agents\skills\find-skills" `
    -Target "$repo\.agents\skills\find-skills"
Push-Location "$env:USERPROFILE\.config\opencode"; npm install; Pop-Location
```

### Addons

| Addon | What it does | Source |
|-------|-------------|--------|
| [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) | Agent orchestration, model routing, fallback chains | Plugin |
| [@dietrichgebert/ponytail](https://github.com/DietrichGebert/ponytail) | Lazy senior dev mode — YAGNI enforcement | Plugin + commands |
| brainstorming | Intent/requirements exploration before implementation | Skill |
| find-skills | Discover and install agent skills | Skill |

Plugin versions in `opencode.jsonc` are **pinned deliberately**. `@latest` forces an
npm registry round-trip on every startup, which turns a 7s start into minutes on a
host with broken IPv6 (see Troubleshooting).

The ponytail plugin is `@dietrichgebert/ponytail`. The bare npm name `ponytail` is an
unrelated 2019 package — do not use it.

### Two independent model settings

These are separate and are a common source of confusion:

| Setting | File | Controls |
|---------|------|----------|
| Primary session model | `opencode.jsonc` → `"model"` | what a new session opens with |
| Agent / category routing | `oh-my-openagent.json` | which model each agent and category uses |

Setting one does not affect the other. The model picker also persists its own
choice in `~/.local/state/opencode/model.json`, which takes precedence for new
sessions — if a session opens on an unexpected model, look there first, not at
the routing profile.

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

On Windows, re-run `.\setup-config.ps1` afterwards (see the caveat above).

`oh-my-openagent.json` is tracked as a git symlink (mode `120000`). With
`core.symlinks=false` — the Windows default — git checks it out as a plain text
stub containing the target filename. Both installers detect and resolve that stub.

### Useful commands

```bash
opencode                                    # start the TUI
opencode models                             # every model available to you
opencode models github-copilot              # one provider
opencode run "prompt"                       # headless, one-shot
opencode --version
```

Confirm which preset is live, and that it parses through both symlink hops:

```bash
readlink -f ~/.config/opencode/oh-my-openagent.json
jq -e . ~/.config/opencode/oh-my-openagent.json >/dev/null && echo OK
```

List every provider the active profile references — catches a stray
`github-copilot` entry when you meant Bedrock only:

```bash
jq -r '[.agents[].model, .categories[].model] | map(split("/")[0]) | unique | .[]' \
  ~/.config/opencode/oh-my-openagent.json
```

Catch retired model IDs before they become a startup warning — every configured
model checked against what your account actually offers:

```bash
comm -23 <(jq -r '[.agents[].model, .categories[].model] | unique | .[]' \
             ~/.config/opencode/oh-my-openagent.json | sort) \
         <(opencode models | sort)
```

Windows equivalents:

```powershell
(Get-Item ~\.config\opencode\oh-my-openagent.json).LinkType
Get-Content ~\.config\opencode\oh-my-openagent.json -Raw | ConvertFrom-Json | Out-Null; "OK"

$live = (opencode models) -replace '\x1b\[[0-9;]*m',''
$cfg  = Get-Content ~\.config\opencode\oh-my-openagent.json -Raw | ConvertFrom-Json
@($cfg.agents.PSObject.Properties.Value.model + $cfg.categories.PSObject.Properties.Value.model) |
  Sort-Object -Unique |
  ForEach-Object { "{0} -> {1}" -f $_, $(if ($_ -in $live) { "LIVE" } else { "MISSING" }) }
```

### Troubleshooting

**`Agent <X>'s configured model <id> is not valid`** — a retired model ID. Run the
model-vs-account check above. If it reports everything `LIVE`, the warning is
stale: opencode reads config once at process start, and opening a *new session*
inside an already-running process does not reload it. Quit every instance and
relaunch.

```powershell
Get-Process opencode | Stop-Process -Force
```

**New sessions open on an unexpected model** — the picker's saved state wins over
config. Drop the retired entries:

```powershell
$p = "$env:USERPROFILE\.local\state\opencode\model.json"
$j = Get-Content $p -Raw | ConvertFrom-Json
$live = (opencode models) -replace '\x1b\[[0-9;]*m',''
$j.recent = @($j.recent | Where-Object { "$($_.providerID)/$($_.modelID)" -in $live })
$v = [ordered]@{}
$j.variant.PSObject.Properties | Where-Object { $_.Name -in $live } | ForEach-Object { $v[$_.Name] = $_.Value }
$j.variant = $v
$j | ConvertTo-Json -Depth 5 -Compress | Set-Content $p -NoNewline
```

**Config edits appear to do nothing on Windows** — you have copies, not symlinks.
Check `LinkType` as shown above.

**Agents ignore the routing profile entirely** — `opencode.jsonc` lost its `plugin`
array, or `~/.config/opencode/node_modules` was never created. Re-run the
installer.

**Startup hangs / black screen** — broken IPv6. See Troubleshooting at the end of
this file.

### Related projects

- [OpenCode](https://github.com/anomalyco/opencode) — AI coding agent (npm: `opencode-ai`)
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

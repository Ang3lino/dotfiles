#Requires -RunAsAdministrator
# Windows dotfiles installer — winget-based, idempotent
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Minimal = $args -contains "--minimal"

function Install-WinGet($id) {
    $installed = winget list --id $id 2>$null | Select-String $id
    if (-not $installed) {
        Write-Host "Installing $id..."
        winget install --id $id --accept-source-agreements --accept-package-agreements -e
    }
}

# PowerShell 7 (MSIX — Install-WinGet doesn't work for this package)
winget install --id Microsoft.PowerShell --source winget --accept-source-agreements --accept-package-agreements

# Windows Terminal
Install-WinGet "Microsoft.WindowsTerminal"

# Core tools (always)
Install-WinGet "Neovim.Neovim"
Install-WinGet "junegunn.fzf"
Install-WinGet "BurntSushi.ripgrep.MSVC"
Install-WinGet "sharkdp.fd"
Install-WinGet "jqlang.jq"
Install-WinGet "ajeetdsouza.zoxide"
Install-WinGet "astral-sh.uv"
Install-WinGet "9P5PK6TVQXF7" # Charmy — hot corners for Windows

if (-not $Minimal) {
    Install-WinGet "JanDeDobbeleer.OhMyPosh"
    Install-WinGet "JesseDuffield.lazygit"
    Install-WinGet "Amazon.AWSCLI"
    Install-WinGet "Hashicorp.Terraform"
}

# --- Sub-installers ---
& "$ScriptDir\pwsh\install.ps1"

# --- Symlink configs (replaces stow on Windows) ---
function Link-Item($target, $link) {
    if (Test-Path $link) { Remove-Item $link -Force -Recurse }
    $parent = Split-Path -Parent $link
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    New-Item -ItemType SymbolicLink -Force -Path $link -Target $target | Out-Null
    Write-Host "  $link -> $target"
}

# Neovim
Link-Item "$ScriptDir\nvim\.config\nvim" "$env:LOCALAPPDATA\nvim"

# OpenCode config
Link-Item "$ScriptDir\opencode\.config\opencode\opencode.jsonc" "$env:USERPROFILE\.config\opencode\opencode.jsonc"
Link-Item "$ScriptDir\opencode\.config\opencode\oh-my-openagent.json" "$env:USERPROFILE\.config\opencode\oh-my-openagent.json"

# OpenCode commands
$cmdSrc = "$ScriptDir\opencode\.config\opencode\commands"
$cmdDst = "$env:USERPROFILE\.config\opencode\commands"
if (-not (Test-Path $cmdDst)) { New-Item -ItemType Directory -Force -Path $cmdDst | Out-Null }
Get-ChildItem "$cmdSrc\*.md" | ForEach-Object {
    Link-Item $_.FullName "$cmdDst\$($_.Name)"
}

# OpenCode skills
Link-Item "$ScriptDir\opencode\.agents\skills\brainstorming" "$env:USERPROFILE\.agents\skills\brainstorming"
Link-Item "$ScriptDir\opencode\.agents\skills\find-skills" "$env:USERPROFILE\.agents\skills\find-skills"

# Bash (Git Bash)
Link-Item "$ScriptDir\bash\.bashrc" "$env:USERPROFILE\.bashrc"

Write-Host "Done. Restart your terminal."

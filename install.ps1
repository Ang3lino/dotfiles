#Requires -RunAsAdministrator
# Windows dotfiles installer — winget-based, idempotent
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Minimal = $args -contains "--minimal"
$Force = $args -contains "--force"

function Install-WinGet($id) {
    if (-not $Force) {
        $installed = winget list --id $id 2>$null | Select-String $id
        if ($installed) { return }
    }
    Write-Host "Installing $id..."
    winget install --id $id --accept-source-agreements --accept-package-agreements -e 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "  WARN: $id install returned exit code $LASTEXITCODE" }
}

# PowerShell 7
Install-WinGet "Microsoft.PowerShell"

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
Install-WinGet "GitHub.cli"
Install-WinGet "9P5PK6TVQXF7" # Charmy — hot corners for Windows

if (-not $Minimal) {
    Install-WinGet "JanDeDobbeleer.OhMyPosh"
    Install-WinGet "JesseDuffield.lazygit"
    Install-WinGet "Amazon.AWSCLI"
    Install-WinGet "Hashicorp.Terraform"
}

# --- Sub-installers ---
# Run under PowerShell 7 so $PROFILE resolves to the correct PS7 path
$pwshExe = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshExe) {
    & pwsh -NoProfile -File "$ScriptDir\pwsh\install.ps1"
} else {
    Write-Host "  pwsh not yet on PATH — skipping profile setup (re-run after restarting terminal)"
}

# --- Config symlinks + plugins (delegates to setup-config.ps1) ---
& "$ScriptDir\setup-config.ps1"

Write-Host "Done. Restart your terminal."

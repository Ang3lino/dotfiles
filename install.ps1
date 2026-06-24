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

# Core tools (always)
Install-WinGet "Neovim.Neovim"
Install-WinGet "junegunn.fzf"
Install-WinGet "BurntSushi.ripgrep.MSVC"
Install-WinGet "sharkdp.fd"
Install-WinGet "jqlang.jq"
Install-WinGet "ajeetdsouza.zoxide"

if (-not $Minimal) {
    Install-WinGet "Starship.Starship"
    Install-WinGet "JesseDuffield.lazygit"
    Install-WinGet "Amazon.AWSCLI"
    Install-WinGet "Hashicorp.Terraform"
}

# Run sub-installers
& "$ScriptDir\pwsh\install.ps1"
& "$ScriptDir\nvim\install.ps1"
& "$ScriptDir\opencode\install.ps1"

Write-Host "Done. Restart your terminal."

# Symlink PowerShell profile into place
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProfileDir = Split-Path -Parent $PROFILE

New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
New-Item -ItemType SymbolicLink -Force -Path $PROFILE -Target "$ScriptDir\profile.ps1" | Out-Null

# Oh My Posh — install Nerd Font for icon support
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh font install Meslo
}

# PowerShell modules — icons
Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck -ErrorAction SilentlyContinue

# Set PowerShell 7 as default profile in Windows Terminal + apply Nerd Font
$WTSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $WTSettingsPath) {
    $settings = Get-Content $WTSettingsPath -Raw | ConvertFrom-Json
    # Find PowerShell 7 profile GUID
    $pwshProfile = $settings.profiles.list | Where-Object { $_.name -match "PowerShell" -and $_.source -eq "Windows.Terminal.PowershellCore" } | Select-Object -First 1
    if ($pwshProfile) {
        $settings.defaultProfile = $pwshProfile.guid
    }
    # Set Nerd Font in defaults
    if (-not $settings.profiles.defaults) {
        $settings.profiles | Add-Member -NotePropertyName "defaults" -NotePropertyValue @{} -Force
    }
    $settings.profiles.defaults | Add-Member -NotePropertyName "font" -NotePropertyValue @{ face = "MesloLGS Nerd Font" } -Force
    $settings | ConvertTo-Json -Depth 10 | Set-Content $WTSettingsPath -Encoding UTF8
    Write-Host "Windows Terminal: PowerShell 7 set as default, Nerd Font applied."
}

Write-Host "pwsh ready. Restart your terminal."

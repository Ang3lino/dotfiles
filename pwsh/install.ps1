# Symlink PowerShell profile into place
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProfileDir = Split-Path -Parent $PROFILE

New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
New-Item -ItemType SymbolicLink -Force -Path $PROFILE -Target "$ScriptDir\profile.ps1" | Out-Null

# Starship config
$StarshipDir = "$env:USERPROFILE\.config"
New-Item -ItemType Directory -Force -Path $StarshipDir | Out-Null
New-Item -ItemType SymbolicLink -Force -Path "$StarshipDir\starship.toml" -Target "$ScriptDir\..\zsh\starship.toml" | Out-Null

Write-Host "pwsh ready. Restart your terminal."

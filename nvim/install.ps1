# Symlink nvim config to Windows nvim path
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$NvimDir = "$env:LOCALAPPDATA\nvim"

if (Test-Path $NvimDir) { Remove-Item -Recurse -Force $NvimDir }
New-Item -ItemType SymbolicLink -Force -Path $NvimDir -Target $ScriptDir | Out-Null

Write-Host "nvim ready."

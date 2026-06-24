# Symlink opencode config files to Windows paths
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OpenCodeDir = "$env:USERPROFILE\.config\opencode"
$AgentsDir = "$env:USERPROFILE\.agents\skills"

New-Item -ItemType Directory -Force -Path "$OpenCodeDir\commands" | Out-Null
New-Item -ItemType Directory -Force -Path $AgentsDir | Out-Null

New-Item -ItemType SymbolicLink -Force -Path "$OpenCodeDir\opencode.jsonc" -Target "$ScriptDir\opencode.jsonc" | Out-Null
New-Item -ItemType SymbolicLink -Force -Path "$OpenCodeDir\oh-my-openagent.json" -Target "$ScriptDir\oh-my-openagent.json" | Out-Null

foreach ($cmd in Get-ChildItem "$ScriptDir\commands\*.md") {
    New-Item -ItemType SymbolicLink -Force -Path "$OpenCodeDir\commands\$($cmd.Name)" -Target $cmd.FullName | Out-Null
}

foreach ($skill in Get-ChildItem "$ScriptDir\skills" -Directory) {
    $target = "$AgentsDir\$($skill.Name)"
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    New-Item -ItemType SymbolicLink -Force -Path $target -Target $skill.FullName | Out-Null
}

Write-Host "opencode ready."

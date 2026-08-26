# User-level config setup — no admin required
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Force = $args -contains "--force"

function Link-Item($target, $link) {
    if (Test-Path $link) {
        $item = Get-Item $link -Force
        if ($item.LinkType -eq "SymbolicLink" -or $item.LinkType -eq "Junction") {
            $item.Delete()
        } else {
            Remove-Item $link -Force -Recurse -Confirm:$false
        }
    }
    $parent = Split-Path -Parent $link
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    # Try symlink first; fall back to junction (dirs) or copy (files) if no admin
    try {
        New-Item -ItemType SymbolicLink -Force -Path $link -Target $target -ErrorAction Stop | Out-Null
    } catch [System.UnauthorizedAccessException] {
        if (Test-Path $target -PathType Container) {
            cmd /c mklink /J "$link" "$target" | Out-Null
        } else {
            Copy-Item $target $link -Force
        }
    }
    Write-Host "  $link -> $target"
}

# Neovim
Link-Item "$ScriptDir\nvim\.config\nvim" "$env:LOCALAPPDATA\nvim"

# OpenCode config
Link-Item "$ScriptDir\opencode\.config\opencode\opencode.jsonc" "$env:USERPROFILE\.config\opencode\opencode.jsonc"

# oh-my-openagent.json — resolve git stub if core.symlinks=false
$agentLink = "$ScriptDir\opencode\.config\opencode\oh-my-openagent.json"
$agentItem = Get-Item $agentLink -Force
if ($agentItem.LinkType -eq "SymbolicLink") {
    $agentTarget = $agentItem.Target
} else {
    $agentTargetName = (Get-Content $agentLink -Raw).Trim()
    $agentTarget = "$ScriptDir\opencode\.config\opencode\$agentTargetName"
}
Link-Item $agentTarget "$env:USERPROFILE\.config\opencode\oh-my-openagent.json"

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

# OpenCode plugins (npm)
$ocDir = "$env:USERPROFILE\.config\opencode"
if ($Force -or -not (Test-Path "$ocDir\node_modules")) {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Host "Installing opencode plugins..."
        Push-Location $ocDir
        npm install --prefer-offline 2>$null
        Pop-Location
    } else {
        Write-Host "WARN: npm not found - skip plugin install. Install Node.js and re-run."
    }
}

# Bash (Git Bash)
Link-Item "$ScriptDir\bash\.bashrc" "$env:USERPROFILE\.bashrc"

Write-Host "Done."

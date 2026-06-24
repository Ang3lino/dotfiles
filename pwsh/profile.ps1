# PowerShell profile — starship, aliases, zoxide, secrets
# Symlinked to $PROFILE by pwsh/install.ps1

# Secrets (never committed)
$SecretsFile = "$env:USERPROFILE\.secrets.ps1"
if (Test-Path $SecretsFile) { . $SecretsFile }

# Aliases
Set-Alias -Name g -Value git
Set-Alias -Name v -Value nvim
Set-Alias -Name k -Value kubectl
function ll { Get-ChildItem -Force @args }

# Zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# Starship prompt
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
} else {
    function prompt { "PS $($executionContext.SessionState.Path.CurrentLocation)> " }
}

# PowerShell profile — oh-my-posh, aliases, zoxide, secrets
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

# PSReadLine — predictive IntelliSense & history search
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -MaximumHistoryCount 10000
}

# Terminal-Icons — file/folder icons in ls output
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# Oh My Posh prompt (bubblesextra theme)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config bubblesextra | Invoke-Expression
} else {
    function prompt { "PS $($executionContext.SessionState.Path.CurrentLocation)> " }
}

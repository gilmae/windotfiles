# Profile for the Microsoft.Powershell Shell, only. (Not Visual Studio or other PoSh instances)
# ===========

Push-Location (Split-Path -parent $profile)
"functions","aliases" | Where-Object {Test-Path "$_.ps1"} | ForEach-Object -process {Invoke-Expression ". .\$_.ps1"}
Pop-Location

function dotfile {git --git-dir=$HOME\.dotfiles\ --work-tree=$HOME $args}

function vs13 {  & 'C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\devenv.exe' $args }
function vs17 {  & 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\devenv.exe' $args }
function e {  & 'notepad++.exe' $args }

#Set-Alias ~ $HOME

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}


# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

#Import-Module 'C:\tools\poshgit\dahlbyk-posh-git-9bda399\src\posh-git.psd1'

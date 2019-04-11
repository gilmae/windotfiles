
# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

function prompt {
  $ESC = [char]27

  "$(Get-Location) $esc[0;32m$(Get-Current-Branch)$esc[0m`r`n$('$ ' * ($nestedPromptLevel + 1))"
}

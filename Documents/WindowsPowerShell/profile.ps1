# Profile for the Microsoft.Powershell Shell, only. (Not Visual Studio or other PoSh instances)
# ===========

Push-Location (Split-Path -parent $profile)
"functions","aliases" | Where-Object {Test-Path "$_.ps1"} | ForEach-Object -process {Invoke-Expression ". .\$_.ps1"}
Pop-Location

function dotfile {git --git-dir=$HOME\.dotfiles\ --work-tree=$HOME $args}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

Set-PSReadlineOption -BellStyle None

function prompt {

  $ESC = [char]27
  $Admin=''
  $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent() 
  $principal = new-object System.Security.principal.windowsprincipal($CurrentUser)
  if ($principal.IsInRole("Administrators")) { $Admin="ADMIN " }

  "$ESC[31m$Admin$ESC[0m$(Get-Location)\`r`n$('$ ' * ($nestedPromptLevel + 1))$ESC[0m"
}
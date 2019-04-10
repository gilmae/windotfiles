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
  # $Admin=''
  # $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent() 
  # $principal = new-object System.Security.principal.windowsprincipal($CurrentUser)
  # if ($principal.IsInRole("Administrators")) { $Admin="$ESC[31mAdmin$ESC[0m " }
  "$(Get-Location) $esc[0;32m$(Get-Current-Branch)$esc[0m`r`n$('$ ' * ($nestedPromptLevel + 1))"
}

function Find-Git-Dir {
  $p = $pwd
  while ($p -ne $Null) {
    if (Join-Path -Path $p -ChildPath ".git" | Test-Path ) {
        return $p
    }
    $p = (get-item $p).parent.FullName
  }
}

function Get-Current-Branch {
  Find-Git-Dir | Join-Path -ChildPath ".git\logs\HEAD" | gci | Get-Content | Select-String -Pattern "checkout: moving from .+ to (.+)" | % {$_.matches.groups[1].Value} | select-object -Last 1
}

function Get-Last-Branch {
  Find-Git-Dir | Join-Path -ChildPath ".git\logs\HEAD" | gci | Get-Content | Select-String -Pattern "checkout: moving from .+ to (.+)" | % {$_.matches.groups[1].Value}  | Get-Unique | select-object -last 2 | select-object -first 1
}

function Git-Back {
  iex "git checkout $(Get-Last-Branch)"
}
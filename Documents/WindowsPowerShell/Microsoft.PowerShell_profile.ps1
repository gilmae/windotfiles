
# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

$folder

function prompt {
  Prompt-Command
  
  $ESC = [char]27

  "$(hostname) $(Get-Location) $esc[0;32m$(Get-Current-Branch)$esc[0m`r`n$('$ ' * ($nestedPromptLevel + 1))"
}

function Prompt-Command {
    
}

$pshost = get-host
$pswindow = $pshost.ui.rawui
$newsize = $pswindow.buffersize
$newsize.height = 3000
$newsize.width = 150
$pswindow.buffersize = $newsize
$newsize = $pswindow.windowsize
$newsize.height = 50
$newsize.width = 150
$pswindow.windowsize = $newsize

if ($env:TERM_PROGRAM -eq "") {
  Good-Morning
}

$script:base_environment = Get-Environment

# Set a breakpoint on the pwd variable in order to check for the .fenv.ps1 files
$null = Set-PSBreakpoint -Variable pwd -Action {
  Restore-Environment $script:base_environment
  $locations = @()
  $loc = $pwd
  do {
	  $locations += $loc
	  $loc = (Get-Item $loc).Parent.FullName
  } while ($loc -ne $Null)

  # make sure that children override parents by reversing the execution paths
  [array]::Reverse($locations)
  foreach ($location in $locations) {
  	Set-Folder-Environment $location
  }
}
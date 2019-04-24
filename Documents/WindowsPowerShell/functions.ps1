# Basic commands
function which($name) { Get-Command $name -ErrorAction SilentlyContinue | Select-Object Definition }

function path($name) { Get-Command $name -ErrorAction SilentlyContinue | Split-Path  }

function touch($file) { "" | Out-File $file -Encoding ASCII }

# Common Editing needs
function Edit-Hosts { Invoke-Expression "sudo $(if($env:EDITOR -ne $null)  {$env:EDITOR } else { 'notepad' }) $env:windir\system32\drivers\etc\hosts" }
function Edit-Profile { Invoke-Expression "$(if($env:EDITOR -ne $null)  {$env:EDITOR } else { 'notepad' }) $profile" }

function minutes-from-now-cron($minutes) {
    [DateTime]::UtcNow.AddMInutes($minutes).ToString("mm HH dd MM ? yyyy");
}

function open($str) {
    Start-Process $str
}

function execute($str) {
    Invoke-Expression($str)
}

# Sudo
function sudo() {
    
    if ($args.Length -eq 1) {
        if ($args[0] = "!!") {
            $cmd =  $(Get-History -Count 1).CommandLine
            
        } else {
            $cmd = $args[0]
        }
        Write-Host $cmd
        Start-Process $cmd -verb "runAs"
    }
    if ($args.Length -gt 1) {
        Start-Process $args[0] -ArgumentList $args[1..$args.Length] -verb "runAs"
    }
}

# System Update - Update RubyGems, NPM, and their installed packages
function System-Update() {
    Install-WindowsUpdate -IgnoreUserInput -IgnoreReboot -AcceptAll
    Update-Module
    Update-Help -Force
    #gem update --system
    #gem update
    #npm install npm -g
    #npm update -g
}

# Reload the Shell
function Reload-Powershell {
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
    $newProcess.Arguments = "-nologo";
    [System.Diagnostics.Process]::Start($newProcess);
    exit
}

# Download a file into a temporary folder
function curlex($url) {
    $uri = New-Object system.uri $url
    $filename = $name = $uri.segments | Select-Object -Last 1
    $path = Join-Path $env:Temp $filename
    if ( Test-Path $path ) { Remove-Item -force $path }

    (New-Object net.webclient).DownloadFile($url, $path)

    return New-Object io.fileinfo $path
}

# Empty the Recycle Bin on all drives
function Empty-RecycleBin {
    $RecBin = (New-Object -ComObject Shell.Application).Namespace(0xA)
    $RecBin.Items() | ForEach-Object { Remove-Item $_.Path -Recurse -Confirm:$false }
}

# Sound Volume
function Get-SoundVolume { [math]::Round([Audio]::Volume * 100) }
function Set-SoundVolume([Parameter(mandatory = $true)][Int32] $Volume) { [Audio]::Volume = ($Volume / 100) }
function Set-SoundMute { [Audio]::Mute = $true }
function Set-SoundUnmute { [Audio]::Mute = $false }


### File System functions
### ----------------------------
# Create a new directory and enter it
function CreateAndSet-Directory([String] $path) { New-Item $path -ItemType Directory -ErrorAction SilentlyContinue; Set-Location $path }

# Determine size of a file or total size of a directory
function Get-DiskUsage([string] $path = (Get-Location).Path) {
    Convert-ToDiskSize `
    ( `
            Get-ChildItem .\ -recurse -ErrorAction SilentlyContinue `
        | Measure-Object -property length -sum -ErrorAction SilentlyContinue
    ).Sum `
        1
}

# Cleanup all disks (Based on Registry Settings in `windows.ps1`)
function Clean-Disks {
    Start-Process "$(Join-Path $env:WinDir 'system32\cleanmgr.exe')" -ArgumentList "/sagerun:6174" -Verb "runAs"
}

### Environment functions
### ----------------------------

# Reload the $env object from the registry
function Refresh-Environment {
    $locations = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'HKCU:\Environment'

    $locations | ForEach-Object {
        $k = Get-Item $_
        $k.GetValueNames() | ForEach-Object {
            $name = $_
            $value = $k.GetValue($_)
            Set-Item -Path Env:\$name -Value $value
        }
    }

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Set a permanent Environment variable, and reload it into $env
function Set-Environment([String] $variable, [String] $value) {
    Set-ItemProperty "HKCU:\Environment" $variable $value
    # Manually setting Registry entry. SetEnvironmentVariable is too slow because of blocking HWND_BROADCAST
    #[System.Environment]::SetEnvironmentVariable("$variable", "$value","User")
    Invoke-Expression "`$env:${variable} = `"$value`""
}

# Add a folder to $env:Path
function Prepend-EnvPath([String]$path) { $env:PATH = $env:PATH + ";$path" }
function Prepend-EnvPathIfExists([String]$path) { if (Test-Path $path) { Prepend-EnvPath $path } }
function Append-EnvPath([String]$path) { $env:PATH = $env:PATH + ";$path" }
function Append-EnvPathIfExists([String]$path) { if (Test-Path $path) { Append-EnvPath $path } }


### Utilities
### ----------------------------

# Convert a number to a disk size (12.4K or 5M)
function Convert-ToDiskSize {
    param ( $bytes, $precision = '0' )
    foreach ($size in ("B", "K", "M", "G", "T")) {
        if (($bytes -lt 1000) -or ($size -eq "T")) {
            $bytes = ($bytes).tostring("F0" + "$precision")
            return "${bytes}${size}"
        }
        else { $bytes /= 1KB }
    }
}

# Start IIS Express Server with an optional path and port
function Start-IISExpress {
    [CmdletBinding()]
    param (
        [String] $path = (Get-Location).Path,
        [Int32]  $port = 3000
    )

    if ((Test-Path "${env:ProgramFiles}\IIS Express\iisexpress.exe") -or (Test-Path "${env:ProgramFiles(x86)}\IIS Express\iisexpress.exe")) {
        $iisExpress = Resolve-Path "${env:ProgramFiles}\IIS Express\iisexpress.exe" -ErrorAction SilentlyContinue
        if ($iisExpress -eq $null) { $iisExpress = Get-Item "${env:ProgramFiles(x86)}\IIS Express\iisexpress.exe" }

        & $iisExpress @("/path:${path}") /port:$port
    }
    else { Write-Warning "Unable to find iisexpress.exe" }
}

# Extract a .zip file
function Unzip-File {
    <#
    .SYNOPSIS
       Extracts the contents of a zip file.

    .DESCRIPTION
       Extracts the contents of a zip file specified via the -File parameter to the
    location specified via the -Destination parameter.

    .PARAMETER File
        The zip file to extract. This can be an absolute or relative path.

    .PARAMETER Destination
        The destination folder to extract the contents of the zip file to.

    .PARAMETER ForceCOM
        Switch parameter to force the use of COM for the extraction even if the .NET Framework 4.5 is present.

    .EXAMPLE
       Unzip-File -File archive.zip -Destination .\d

    .EXAMPLE
       'archive.zip' | Unzip-File

    .EXAMPLE
        Get-ChildItem -Path C:\zipfiles | ForEach-Object {$_.fullname | Unzip-File -Destination C:\databases}

    .INPUTS
       String

    .OUTPUTS
       None

    .NOTES
       Inspired by:  Mike F Robbins, @mikefrobbins

       This function first checks to see if the .NET Framework 4.5 is installed and uses it for the unzipping process, otherwise COM is used.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$File,

        [ValidateNotNullOrEmpty()]
        [string]$Destination = (Get-Location).Path
    )

    $filePath = Resolve-Path $File
    $destinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)

    if (($PSVersionTable.PSVersion.Major -ge 3) -and
        ((Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Version -like "4.5*" -or
            (Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Client" -ErrorAction SilentlyContinue).Version -like "4.5*")) {

        try {
            [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$filePath", "$destinationPath")
        }
        catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }
    }
    else {
        try {
            $shell = New-Object -ComObject Shell.Application
            $shell.Namespace($destinationPath).copyhere(($shell.NameSpace($filePath)).items())
        }
        catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }
    }
}

function Install-Dependencies {
    <#
    .SYNOPSIS
       Installs Module dependencies.

    .DESCRIPTION
       Inspects a file for module dependencies declarations (#requires -Modules), parses the declarations and installs the modules

    .PARAMETER Path
        The file to scan for dependency declarations

    .EXAMPLE
       Install-Dependencies 'script.ps1'

    .OUTPUTS
       None

    .NOTES
       Inspired by:  bundle install, npm install, but using the built-in syntax for dependency declaration
    #>
    [CmdletBinding()]
    param (
        [String] $path = (Get-Location).Path

    )

    $modules = Get-Content $path | Select-String -Pattern "#requires -Modules?\s(.*)" | ForEach-Object { $_.matches.groups[1] } | ForEach-Object { $_.ToString().split(',') }

    foreach ($module in $modules) {
        $cmd = "Install-Module"
        if ($module.IndexOf("@") -eq 0) {
            $h = Invoke-Expression($module)
            $cmd = "$cmd $($h.ModuleName)"
            if ($h.ContainsKey("ModuleVersion")) {
                $cmd = "$cmd -MinimumVersion $($h.ModuleVersion)"
            }
            elseif ($h.ContainsKey("RequiredVersion")) {
                $cmd = "$cmd -RequiredVersion $($h.RequiredVersion)"
            }
        }
        else {
            $cmd = "$cmd $module"
        }

        Invoke-Expression $cmd
    }
}

function Open-Pr {
    [CmdletBinding()]
    Param( 
        [string]$remote = "origin"
    )  

    $origin = Invoke-Expression("git url $remote") 
    $branch = Invoke-Expression("git rev-parse --abbrev-ref HEAD") 

    if ($origin.IndexOf("visualstudio.com") -gt -1) {
        Start-Process "$origin/pullrequestcreate?sourceRef=$branch"
    }
    elseif ($origin.IndexOf("github.com" -gt -1)) {
        Start-Process "$origin/compare/$branch)"
    }
    elseif ($origin.IndexOf("bitbucket") -gt -1) {
        Start-Process "$origin/pull-requests/new?source=$branch"
    }
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
  
  function Weather {
    (Invoke-WebRequest "http://wttr.in/Sydney" -UserAgent curl -UseBasicParsing).content
  }
  
  function Moon {
    (Invoke-WebRequest "http://wttr.in/Moon" -UserAgent curl -UseBasicParsing).content
  }

  function Timesheets {
      open("https://fiori.interpublic.com/flp#Shell-home")
  }


  $projectsDirectory = 'c:\projects'
  function Open-Project {
    [CmdletBinding()]
    Param(
        $Project
    )

    

    Set-Location $projectsDirectory

    if ($project -ne $Null -and $project -ne "") {
        Set-Location $project
    }
  }

  Register-ArgumentCompleter -CommandName 'Open-Project' -ParameterName 'project' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    (Get-ChildItem -Path $projectsDirectory).Name | 
        Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

function Good-Morning {
    $statusfile = '~/.status'
    if (!(Test-Path $statusfile) -or (Get-Item $statusfile).LastWriteTime -lt (Get-Date).Date) { 
        touch $statusfile
        Write-Host "Good morning."
        Weather
    }
}
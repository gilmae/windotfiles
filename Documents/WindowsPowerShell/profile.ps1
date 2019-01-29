# Profile for the Microsoft.Powershell Shell, only. (Not Visual Studio or other PoSh instances)
# ===========

Push-Location (Split-Path -parent $profile)
"components","functions","aliases","exports","extra" | Where-Object {Test-Path "$_.ps1"} | ForEach-Object -process {Invoke-Expression ". .\$_.ps1"}
Pop-Location

function dotfile {git --git-dir=$HOME\.dotfiles\ --work-tree=$HOME $args}

function vs13 {  & 'C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\devenv.exe' $args }
function vs17 {  & 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\devenv.exe' $args }
function e {  & 'notepad++.exe' $args }

Import-Module posh-git

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

function get-session-token{
	$AWS_CLI = iex "which aws"
	if ($AWS_CLI -eq '')
	{
		Write-Host "AWS CLI cannot be found; exiting"
		exit
	}

	$name = Read-Host -Prompt 'Name'
	$token = Read-Host -Prompt 'MFA Token'
	$command = "aws --profile m4uinflogin sts get-session-token --duration 129600 --serial-number arn:aws:iam::183839469016:mfa/$name --token-code $token"
write-host $command
	$result = iex $command | ConvertFrom-Json | select -Expand Credentials

	$sessionToken =  $result.SessionToken
	$accessKeyId =  $result.AccessKeyId
	$secretAccessKey =  $result.SecretAccessKey

	iex "aws configure --profile default set aws_access_key_id $accessKeyId"
	iex "aws configure --profile default set aws_secret_access_key $secretAccessKey"
	iex "aws configure --profile default set aws_session_token $sessionToken"
	
	Write-Host $result
}

function ecr-docker-login{
	$result = iex "aws --profile m4uinf ecr get-login --no-include-email --region ap-southeast-2"
	iex $result
}

function create-migration($env, $name) {
	$migrationName = (Get-Date).ToString("yyyyMMddhhmm") + '_' + $name
	
	if (-not (test-path "SQL/migrations/$env/deploy/") ) {
		mkdir -p "SQL/migrations/$env/deploy/"
	}
	
	if (-not (test-path "SQL/migrations/$env/rollback/") ) {
		mkdir -p "SQL/migrations/$env/rollback/"
	}
	
	iex "echo ""USE $ENV;"" > SQL/migrations/$env/deploy/$migrationName.sql"
	iex "echo ""USE $ENV;"" > SQL/migrations/$env/rollback/$migrationName.sql"
}

function minutes-from-now-cron($minutes) {
	 [DateTime]::UtcNow.AddMInutes($minutes).ToString("mm HH dd MM ? yyyy");
}
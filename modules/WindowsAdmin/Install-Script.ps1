#Script to help install/setup AuditTools
$ModulePaths = @($env:PSModulePath -split ';')
$ExpectedUserModulePath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath WindowsPowerShell\Modules
$Destination = $ModulePaths | Where-Object { $_ -eq $ExpectedUserModulePath }
if (-not $Destination) {
  $Destination = $ModulePaths | Select-Object -Index 0
}
if (-not (Test-Path ($Destination + "\WindowsAdmin\"))) {
  New-Item -Path ($Destination + "\WindowsAdmin\") -ItemType Directory -Force | Out-Null
  Write-Host 'Downloading AuditTools from https://github.com/PhoenixB1rd/Windows/tree/master/modules/WndowsAdmin'
  $client = (New-Object Net.WebClient)
  $client.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
  $client.DownloadFile("https://raw.githubusercontent.com/PhoenixB1rd/Windows/master/modules/WndowsAdmin/Get-Disktimeout.ps1", $Destination + "\WindowsAdmin\Get-DiskTimeout.ps1")
  $client.DownloadFile("https://raw.githubusercontent.com/PhoenixB1rd/Windows/master/modules/WndowsAdmin/WindowsAdmin.ps1", $Destination + "\WindowsAdmin\WindowsAdmin.psm1")
  
  $executionPolicy = (Get-ExecutionPolicy)
  $executionRestricted = ($executionPolicy -eq "Restricted")
  if ($executionRestricted) {
    Write-Warning @"
Your execution policy is $executionPolicy, this means you will not be able import or use any scripts -- including modules.
To fix this, change your execution policy to something like RemoteSigned.
    PS> Set-ExecutionPolicy RemoteSigned
For more information, execute:
    PS> Get-Help about_execution_policies
"@
  }

  if (!$executionRestricted) {
    # Ensure AuditTools is imported from the location it was just installed to
    Import-Module -Name $Destination\WindowsAdmin
    Get-Command -Module WindowsAdmin
  }
}

Write-Host "WindowsAdmin is installed and ready to use" -Foreground Green
Write-Host @"
For more details, visit: 
https://github.com/PhoenixB1rd/Windows


Also, Thanks to ScriptAutomate for allowing me to use his installation script.
"@
Function Stop-Web (
[String]$application,
[String]$servers){
$srvrs = gc $servers
Import-Module Webadministration
$s = New-PSSession -ComputerName $srvrs
Foreach ($srv in $srvrs){
Import-Module Webadministration -Force  
Stop-Website -Name $application -ErrorAction Stop 
{ Write-host "Stopped $application on $srv" -ForegroundColor Yellow }
Else {Write-Warning "$application cannot be stopped on $srv, please double check the name and rerun the script" }
 }
 }
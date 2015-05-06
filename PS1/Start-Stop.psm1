Function Stop-Web (
[String]$application,
[String]$servers = (Get-Content .\servers.txt)
 ){
Foreach ($server in $servers){
Import-Module Webadministration
Try {If ( Stop-Website $application -ErrorAction Stop ) 
{ Write-host "Stopped $application on $server" -ForegroundColor Yellow }
 }
Catch {Write-Warning "$application cannot be stopped on $server, please double check the name and rerun the script" }
 }
}

Function Start-Web (
[String]$application,
[String]$servers = (Get-Content .\servers.txt)
 ){
Foreach ($server in $servers){
Import-Module Webadministration
Try {If (Start-Website $application  -ErrorAction Stop ) 
{ Write-host "Restarted $application on $server" -ForegroundColor Green }
  }
Catch {Write-Warning "$application cannot be started on $server, please double check the name and rerun the script"}
 }
}
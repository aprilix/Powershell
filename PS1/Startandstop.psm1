Function Stop-Web (
[String]$application,
[String]$servers = (Get-Content .\servers.txt)
 ){
Foreach ($server in $servers){
if (Stop-Website $application -ErrorAction Stop )
{Write-Host "Stopped $application on $server"}
Else { Write-Warning "$application cannot be stopped, please double check the name and rerun the script"}
 }
} 
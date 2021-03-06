﻿function Unmanage-Solarwinds([int] $Minutes,[string] $servers){ 
Write-Host " Please ensure input file contains DNS name of the servers you wish to SUPRESS OR UNSUPRESS THE ALERTS FOR " -ForegroundColor Red
cmd /C Pause
cd "C:\Program Files (x86)\SolarWinds\Orion SDK\SWQL Studio"
Import-Module .\SwisPowerShell.dll
$Swis = Connect-Swis -Trusted -Hostname server1.com
$uris = Get-Content $servers | foreach {Get-SwisData $swis "SELECT URI FROM Orion.Nodes WHERE DNS like '$_'"}
$srvrs = gc $servers
if ($uris.Count –ne $srvrs.Count) { Write-Host “Servers in the input file doesn't exist in Solarwinds or it requires FULLY QUALIFIED DOMAIN NAME to be identified” -ForegroundColor Red } 
else {Write-Host “Unmanaging servers in Solarwinds” -ForegroundColor Green}
$uris | ForEach-Object { Set-SwisObject $swis $_ @{Status=9;Unmanaged=$true;UnmanageFrom=[DateTime]::UtcNow;UnmanageUntil=[DateTime]::UtcNow.AddMinutes($minutes)} }
$unmanagedservers = Get-Content $servers | foreach {Get-SwisData $swis "SELECT SysName FROM Orion.Nodes WHERE DNS like '$_'"}
$unmanageduntil = Get-Content $servers | foreach {Get-SwisData $swis "SELECT UnmanageUntil FROM Orion.Nodes WHERE DNS like '$_'"}
"$unmanagedServers".Split(" ") 
"$unmanageduntil".Split(" ") 
Write-Host Above Servers have been Unmanaged  for $Minutes Minutes -ForegroundColor Green
}
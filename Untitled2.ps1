function Unmanage-Solarwinds([int] $Minutes,[string] $servers){ 
Write-Host " Please ensure input file contains DNS name of the servers you wish to Unmanage / Manage " -ForegroundColor Red
cmd /C Pause
cd "C:\Program Files (x86)\SolarWinds\Orion SDK\SWQL Studio"
Import-Module .\SwisPowerShell.dll
$Swis = Connect-Swis -Trusted -Hostname Server1
$NodeID = Get-Content ".\servers1.txt" | foreach {Get-SwisData $swis "SELECT NodeID FROM Orion.Nodes WHERE DNS like '$_'"}
$NodeID > ".\Nodes.txt"

Param
(
[String] $Servers
) 
$srvrs = Get-Content $servers
foreach ($srv in $srvrs) {
Write-host "Testing RDP on $srv" 
Try {If (New-Object System.Net.Sockets.TCPClient -ArgumentList $srv,3389 -ErrorAction Stop) { Write-Host "It Works!" -ForegroundColor Green } 
}
Catch {Write-Warning "RDP Failed, Either the server is offline or the name is incorrect"}
} 



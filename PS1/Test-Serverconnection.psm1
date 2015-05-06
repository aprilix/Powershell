Function Test-Serverconnection (
[string]$servers = (get-content "C:\servers.txt")){
$srvrs = gc $servers
Foreach ($srv in $srvrs)
{
	Write-Host "Testing connection for $srv"
	if (Test-Connection -ComputerName $srv -Count 3 -Quiet)
	{ Write-Host "Connection established with $srv" -ForegroundColor Green }
	Else
	{
		Write-Host "$srv is offline, Please double check the connection and server name and rerun the job"
		Break
		Stop-Transcript
	}
  }
}
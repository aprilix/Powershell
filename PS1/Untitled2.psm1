Function Test-Serverconnection (
[parameter(Mandatory = $TRUE)]
[string] $servers){
$srvrs = gc $servers
Foreach ($_ in $srvrs)
{
	Write-Host "Testing connection for $_"
	if (Test-Connection -ComputerName $_ -Count 3 -Quiet)
	{ Write-Host "Connection established with $_" -ForegroundColor Green }
	Else
	{
		Write-Host "$_ is offline, Please double check the connection and server name and rerun the job"
		Break
		Stop-Transcript
	}
  }
}
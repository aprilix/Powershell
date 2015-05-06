Function Website-Stop (
[parameter(Mandatory = $TRUE)]
[string] $servers){
$srvrs = gc $servers
Foreach ($_ in $srvrs)
{
	IISRESET /Stop $_
	Write-host "IIS Stopped on $_" -ForegroundColor Red
 }
}

Function Website-Start(
[parameter(Mandatory = $TRUE)]
[string] $servers){
$srvrs = gc $servers
Foreach ($_ in $srvrs)
{
	IISRESET /Start $_
	Write-host "IIS Restarted on $_" -ForegroundColor Yellow
 }
}
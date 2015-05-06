Function Test-Serverconnection (
[string]$servers = (get-content "C:\servers.txt")){
Foreach ($server in $servers)
{
	Write-Host "Testing connection for $server"
	if (Test-Connection -ComputerName $server -Count 3 -Quiet)
	{ Write-Host "Connection established with $server" -ForegroundColor Green }
	Else
	{
		Write-Host "$server is offline, Please double check the connection and server name and rerun the job"
		Break
		Stop-Transcript
	}
  }
}

Function Test-Serverdiskspace (
[string] $servers = (get-content "C:\servers.txt")){
Foreach ($server in $servers)
{
	$Object = Get-WmiObject -ComputerName $server -Class Win32_logicalDisk | Where-Object { $_.DeviceID -eq "C:" } | Select DeviceID, FreeSpace
	If ($Object.FreeSpace -lt "20033212400")
	{
		Write-Warning "LOW DISK SPACE on $server , Clear some disk space and rerun the job"
		Break
		Stop-Transcript
	}
	Else
	{ Write-Host "Disk Space check completed on server $server" -ForegroundColor Green }
 }
}

Function Website-Stop (
[string] $servers = (get-content "C:\servers.txt")){
Foreach ($server in $servers)
{
	IISRESET /Stop $server
	Write-host "IIS Stopped on $server" -ForegroundColor Red
 }
}

Function Website-Start(
[string] $servers = (get-content "C:\servers.txt")){
Foreach ($server in $servers)
{
	IISRESET /Start $server
	Write-host "IIS Restarted on $server" -ForegroundColor Yellow
 }
}

Function Test-ApplicationURL(){
$requesturlarray = gc "C:\URL.txt"
foreach ($i in $requesturlarray)
{
	Try { $response = Invoke-WebRequest -Uri $i }
	Catch
	{ Write-Warning "Application indicates error on $i" }
}
Write-Host "If you dint see any WARNING above, it means all the endpoints are validated with a 200 - OK response. Else the output will include the specific endpoints which are down"
}
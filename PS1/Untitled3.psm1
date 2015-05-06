Function Test-Serverdiskspace (
[parameter(Mandatory = $TRUE)]
[string] $servers){
$srvrs = gc $servers
$srvrs | foreach {
	$Object = Get-WmiObject -ComputerName $_ -Class Win32_logicalDisk | Where-Object { $_.DeviceID -eq "C:" } | Select DeviceID, FreeSpace
	If ($Object.FreeSpace -lt "20033212400")
	{
		Write-Warning "LOW DISK SPACE on $_ , Clear some disk space and rerun the job"
		Break
		Stop-Transcript
	}
	Else
	{ Write-Host "Disk Space check completed on server $_" -ForegroundColor Green }
 }
}
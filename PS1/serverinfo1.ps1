Param
(
	[parameter(Mandatory = $TRUE)]
	[String]$servers
)

$srvrs = gc $servers
foreach ($srv in $srvrs)
{
	if (Test-Connection -ComputerName $srv -Count 3 -Quiet)
	{
		Write-Host "Working on $srv to get server configuration info"
		systeminfo.exe /s $srv | findstr /c:"OS Version" /c:"Host Name" /c:"OS Name" /c:"System Type" /C:"Processor(s)" /c:"Total Physical Memory" /c:"Available Physical Memory" /c:"Virtual Memory: Max Size:"
	}
	
	Else { Write-Host "Cannot connect to $srv, Either the server is offline or the name is incorrect" -ForegroundColor Yellow }
}
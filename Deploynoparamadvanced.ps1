Param
(
	[parameter(Mandatory = $TRUE)]
	[string]$Servers,
	[String]$Publishedpath,
	[String]$application,
	[String]$buildnumber,
	[String]$artifactorypath
)

#Start log transcript
Start-Transcript -Path C:\Logs\$buildnumber.txt

#Test server connection
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

#Disk Space check
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

#check build package
if (!(Test-Path $artifactorypath))
{
	Write-Warning "NO, $buildnumber package doesn't exist in server artifactory"
	Break
	Stop-Transcript
}
Else
{ Write-Host "$buildnumber package exists in server artifactory" -ForegroundColor Green }

#IIS and service stop
Foreach ($_ in $srvrs)
{
	IISRESET /Stop $_
	Write-host "IIS Stopped on $_" -ForegroundColor Yellow
}

#Backup old code and clean up folders
$s = New-PSSession -ComputerName $srvrs
$foldername = Get-Date -Format 'yyyyMMddhhmm'
$backuppath = join-Path -Path \\ -ChildPath (Join-Path -Path $Srvrs.Get(0) -ChildPath \c$\HostedSites\$application)
if (!(test-path $backuppath))
{
	Write-Host  "BACKUP failed since the $application folder is missing on "$Srvrs.Get(0)" " -ForegroundColor Yellow
}
else
{
	Rename-Item $backuppath -NewName "BACKUP$application$foldername" -Force
	Move-Item -path (join-path \\ -childpath (Join-Path -path $Srvrs.Get(0) -ChildPath \C$\hostedsites\BACKUP$application$foldername)) -Destination (join-path \\ -childpath (Join-Path -path $Srvrs.Get(0) -ChildPath \C$\BACKUP)) -Force
	Write-host "BACKUP for $application is completed and renamed as BACKUP$application$foldername and moved to C:\BACKUP archive on "$Srvrs.Get(0)" " -ForegroundColor Green
}

#Recreate folders and copy code
Foreach ($_ in $srvrs)
{
	Write-Host "Cleanup & Recreate $application directories and deploying code on $_"
	$removepath = (join-path \\ -childpath (Join-Path -path $_ -ChildPath \C$\hostedsites\$application))
	if (!(test-path -path $removepath)) { Write-Host "." -ForegroundColor Green }
	else { Remove-Item -Path $removepath -Force -Recurse }
	New-Item -Path (join-path \\ -childpath (Join-Path -path $_ -ChildPath \C$\hostedsites)) -ItemType Directory -Name $application
	Copy-Item -Path $Publishedpath -Destination (join-path \\ -childpath (Join-Path -path $_ -ChildPath \C$\hostedsites\$application\))
	
}

#compare the code sync between build server and deployed server
$a = gci "$publishedpath"
$b = gci (join-path \\ -childpath (Join-Path -path $Srvrs.Get(0) -ChildPath \C$\hostedsites\$application\))  -Include *
$c = gci (join-path \\ -childpath (Join-Path -path $Srvrs.Get(1) -ChildPath \C$\hostedsites\$application\))  -Include *
if (!($a.count -eq $b.count))
{
	Write-Host "Code Sync unsuccessfull on $Srvrs.Get(0)" -ForegroundColor 'Yellow'
	Break
	Stop-Transcript
}
elseif (!($a.count -eq $c.count))
{
	Write-Host "Code sync unsuccessfull on $srvrs.Get(1)" -ForegroundColor 'Yellow'
	Break
	Stop-Transcript
}
Else
{ Write-Host "Code Deployment completed successfully on $srvrs" -ForegroundColor Green }

#IIS START
Foreach ($_ in $srvrs)
{
	IISRESET /Start $_
	Write-host "IIS Started on $_" -ForegroundColor Green
}

#Validate endpoint URL response code and confirm success or failure
Write-Host Validating endpoint URL response.. .. ..
$requesturlarray = @("http://rkstrtndevapp1/2Return/Login.aspx", "http://rkstrtnuatapp1/2Return/Login.aspx", "http://rkstrtnqaapp1/2Return/Login.aspx")
foreach ($i in $requesturlarray)
{
	Try { $response = Invoke-WebRequest -Uri $i }
	Catch
	{ Write-Warning "Application indicates error on $i" }
}
Write-Host "If you dint see any WARNING above, it means all the endpoints are validated with a 200 - OK response. Else the output will include the specific endpoints which are down"

#Create Build number file
$date = Get-Date
$output = "$application is running under $buildnumber version deployed on $date"
$output > "C:\temp\buildnumber.htm"
Foreach ($_ in $srvrs)
{
	Copy-Item -Path "C:\temp\buildnumber.htm" -Destination (join-path \\ -childpath (Join-Path -path $_ -ChildPath \C$\hostedsites\$application\))
}
Write-Host "$buildnumber for $application application is deployed to $srvrs and buildnumber.html file inside site root directory includes details about time and version of deployment" -ForegroundColor Green

#Stop log transcript
Stop-Transcript 
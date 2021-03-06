#Clean Disk Space
Write-Host "Checking disk space on the server" 
$size = ([wmi]"\\localhost\root\cimv2:Win32_logicalDisk.DeviceID='c:'").Size
$free = ([wmi]"\\remotecomputer\root\cimv2:Win32_logicalDisk.DeviceID='c:'").FreeSpace
$mindiskspace = 20000
if ( $free -lt $mindiskspace ) {
Write-Host "LOW DISK SPACE, PLEASE CLEAN SOME SPACE AND RERUN THE SCRIPT" 
Exit
}

#STOP IIS/APPPOOLS
Write-Host "Stopping IIS on the target WEB SERVERS"
IISRESET /Stop Server1
IISRESET /Stop server2
IISRESET /Stop server23
IISRESET /Stop server24

#Backup folder and copy to staged location
$folder = Get-WmiObject -Query "SELECT * FROM CIM_Directory WHERE Name='C:\\HostedSites'"
$folder.Compress() 
Rename-Item C:\HostedSites -NewName C:\BACKUP_$buildnumber
Move-Item C:\BACKUP_$buildnumber -Recurse -Destination C:\BACKUP 
 
#Deploy code from build server to all PROD servers using LABEL number
$Publishedpath =  gci C:\CVVPart\OFOS\* | sort LastWriteTime | select -last 1
cd $Publishedpath
Copy-Item -Include * -Destination \\vlmonapp.scif.com\c$\HostedSites
Copy-Item -Include * -Destination \\vlmonapp1.scif.com\c$\HostedSites
Copy-Item -Include * -Destination \\vlmonapp2.scif.com\c$\HostedSites
Copy-Item -Include * -Destination \\vlmonapp3.scif.com\c$\HostedSites

#Deploy environment specific configuration file from a shared location


#Compare the WEB directory on all the PROD servers to ensure servers are in sync with the latest code
$srv1 = "Server1M\C$\HostedSites"
$srv2 = "Server1\C$\HostedSites"
$srv3 = "Server1\C$\HostedSites"
$srv4 = "Server1\C$\HostedSites"
Compare-Object $srv1 $srv4
Compare-Object $srv3 $srv2

#Compare the web.config on all the PROD servers to ensure they are i sync across the farm
$config1 = "Server1\C$\HostedSites\web.config"
$config2 = "Server1\C$\HostedSites\web.config"
$config3 = "Server1\C$\HostedSites\web.config"
$config4 = "Server1\C$\HostedSites\web.config"
Compare-Object $config1 $config4
Compare-Object $config2 $config3

#Restart IIS on all servers
Write-Host "Starting IIS on the target WEB SERVERS"
IISRESET /Start Server1
IISRESET /Start Server1
IISRESET /Start Server1
IISRESET /Start Server1

#Browse the page locally on all the PROD servers
$request = Invoke-WebRequest http:\\server1.com
if ($request.StatusCode -ne "302") 
{ Write-Host "Unable to load the page, Please look at eventviewer or logs to find out more about the error" -ForegroundColor RED }
else
{ Write-host "URL indicates a 200 OK response and deployment seem to be successfull. Please validate your changes"}

#Report Success or Failure
Write-Host "SUCCESS"
Exit
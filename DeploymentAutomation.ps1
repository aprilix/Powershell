Function Deployment-Automation {
Param
(
[parameter(Mandatory=$TRUE)]
[String]$Server

) }

# Clean Disk Space 
$free1 = ([wmi]"\\localhost\root\cimv2:Win32_logicalDisk.DeviceID='c:'").FreeSpace
$free2 = ([wmi]"\\localhost\root\cimv2:Win32_logicalDisk.DeviceID='D:'").FreeSpace
$array = @( $free1, $free2 )
foreach ( $i in $array ) 
{ 
if ( $i -lt 3159396355 ) 
 {
Write-Host "Less than $i MB available on disk. Please clear some space and restart the job"
Invoke-Expression -Command "C:\Disk-Spacedata.ps1"
 }
 else 
  { Continue } 
}

# STOP IIS/APPPOOLS 
Write-Host "Stopping IIS on the target WEB SERVERS"
$servers | foreach { IISRESET /Stop $_ }

# Backup folder and copy to a staged location
$folder = Get-WmiObject -Query "SELECT * FROM CIM_Directory WHERE Name='C:\\HostedSites'"
$folder.Compress()
$foldername = Get-Date -Format 'yyyymmddhhmm'
Rename-Item C:\HostedSites -NewName C:\BACKUP_$foldername
Move-Item C:\BACKUP_$foldername -Recurse -Destination C:\BACKUP
New-Item -Name HostedSites -Path C:\ -ItemType Directory
 
# Deploy code from build server to all PROD servers using LABEL number
$Publishedpath =  gci C:\Buildserver\CVVPart\OFOS\* | sort LastWriteTime | select -last 1
cd $Publishedpath
foreach ($i in $servers) { Copy-Item -Include * -Destination \\$i\c$\HostedSites -Force }


# Deploy environment specific configuration file from a shared location
#Still working on it as I will need specific path and also discuss with DEV team on how we want to name these files per environment

# Compare the WEB directory on all the PROD servers to ensure servers are in sync with the latest code
$srv1 = "SERVER1\C$\HostedSites"
$srv2 = "SERVER2\C$\HostedSites"
$srv3 = "SERVER3\C$\HostedSites"
$srv4 = "SERVER4\C$\HostedSites"
Compare-Object $srv1 $srv4
Compare-Object $srv3 $srv2

# Compare the web.config on all the PROD servers to ensure they are in sync across the farm
$config1 = "SERVER1\C$\HostedSites\web.config"
$config2 = "SERVER2\C$\HostedSites\web.config"
$config3 = "SERVER3\C$\HostedSites\web.config"
$config4 = “SERVER4\C$\HostedSites\web.config"
Compare-Object $config1 $config4
Compare-Object $config2 $config3

# Restart IIS on all servers
Write-Host "Starting IIS on the target WEB SERVERS"
IISRESET /Start SERVER1
IISRESET /Start SERVER2
IISRESET /Start SERVER3
IISRESET /Start SERVER4


# Browse the page locally on all the PROD servers
$request = Invoke-WebRequest http:\\strwebapps.wsgc.com
if ($request.StatusCode -ne "200") 
{ Write-Host "Unable to load the page, Please look at eventviewer or logs to find out more about the error" -ForegroundColor RED }
else
{ Write-host "URL indicates a 200 OK response and deployment is successful. Please validate your changes"}

# Report Success or Failure
Write-Host "SUCCESS"
Exit 
}
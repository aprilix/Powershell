Function Website-Backup (
[String]$application,
[String]$Labelnumber
)
{
$foldername = Get-Date -Format 'yyyyMMddhhmm'
$backuppath = "C:\HostedSites\$application" 
$archivepath = "C:\BACKUP"
Rename-Item $backuppath -NewName "BACKUP_$Labelnumber_$application_$foldername" -Force
Move-Item -path "C:\HostedSites\BACKUP$application$foldername" -Destination $archivepath
}
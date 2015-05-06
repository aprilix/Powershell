$diskspace = Get-WmiObject -query "Select * from Win32_logicaldisk" | Select-Object FreeSpace
$diskspace.GetValue(0)
$MinDiskSpace= "100000"
if($diskspace.GetValue(0) -lt $MinDiskSpace)
{
Write-Host "LOW DISK SPACE"
}
$servers = gc C:\Servers.txt
Foreach ($server in $servers){
$schtask = schtasks.exe /query /s $server /V /FO CSV | ConvertFrom-Csv | Where { $_.TaskName -ne "TaskName" }
$schtask | where { $_."Run As User" -clike "SYSTEM" } | Select-Object "HostName", "TaskName","Run As User" }
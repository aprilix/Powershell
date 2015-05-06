$servers = gc "C:\Users\Desktop\servers.txt"
foreach($server in $servers)
{
$psversiontable | Select MachineName
} 
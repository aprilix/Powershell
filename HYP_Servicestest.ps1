$servers = gc "C:\Users\admins4v89kr\Desktop\servers.txt"
foreach($server in $servers)
{
$psversiontable | Select MachineName
} 
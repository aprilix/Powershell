$servers = gc "C:\Users\admins4v89kr\Desktop\servers.txt"
foreach($server in $servers)
{
Get-WmiObject -ComputerName $servers -Class Win32_Group -Namespace "root\cimv2" -Filter "LocalAccount='$True'"
} 
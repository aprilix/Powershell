$servers = gc "C:\Users\admins4v89kr\Desktop\servers.txt"
foreach($server in $servers)
{
Get-Service -DisplayName Oracle* | ft -a
}
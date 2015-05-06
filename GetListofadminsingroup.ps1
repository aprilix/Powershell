$servers = gc "C:\Users\admins4v89kr\Desktop\servers.txt"
foreach($server in $servers)
{
.\Psexec.exe NET.exe localgroup administrators
}
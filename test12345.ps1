$Servers = Get-Content "C:\Users\admins4v89kr\Desktop\servers.txt"
foreach ($Server in $Servers){
cd C:\Windows\System32\inetsrv
.\appcmd.exe list sites
}
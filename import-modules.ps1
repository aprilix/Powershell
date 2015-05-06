$computers = gc "C:\Users\admins4v89kr\Desktop\servers.txt"
foreach ( $server in $servers ) 
{ Import-Module Webadministration }
$Servers = Get-Content "C:\Users\admins4v89kr\Desktop\computers.txt"
$service = "OPNET*"
foreach($server in $servers) {
get-service -Name AudioSrv -computer Localhost | Set-service -StartupType disabled -PassThru
get-service -Name AudioSrv -computer $Server | stop-service
}

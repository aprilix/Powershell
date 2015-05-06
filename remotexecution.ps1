$computers = gc "C:\Users\admins4v89kr\Desktop\computers (2).txt"
foreach ($computer in $computers) {
Get-Service AudioSrv | Stop-Service -PassThru | Set-Service -StartupType Disabled
}
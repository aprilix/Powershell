$Servers = Get-Content "C:\Users\admins4v89kr\Desktop\computers.txt"
$service = "AudioSrv"
foreach($server in $servers) {         
 Write-Host "Working on $Server"            
 if(!(Test-Connection -ComputerName $Server -Count 1 -quiet)) {            
  Write-Warning "$Server : Offline"  }
  else {
  gwmi win32_service -computername $server -Filter "name='$service'" | select __server,name,startmode,state,status 
}
}
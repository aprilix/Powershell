$servers= Get-Content "C:\Users\admins4v89kr\Desktop\computers (2).txt"
foreach($server in $servers) { 
gwmi win32_service -computername $server -Filter "name='AudioSrv'" | select __server,name,startmode,state,status 
}


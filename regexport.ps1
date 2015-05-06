$Servers = Get-Content  "C:\Users\admins4v89kr\Desktop\servers.txt"

 foreach ($Server in $Servers){

    if (Test-Path "\\$Server\c$\windows"){
        Write-Host "Processing $Server..."
        # Copy update package to local folder on server
       
       Reg export "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-tcp" MinEncryptionLevel.reg 

    } else { 
        Write-Host "Hey   Some Execution Failed all"
    }
}
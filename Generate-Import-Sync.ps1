<#
Generate-Import-Sync Script will:
1) Generate keys on the local server.
2) Export Keys to the XML file.
3) Copy the keys to rest of the servers in the farm.
4) Sync the keys with the rest of the servers in the farm.
#>
$help = Get-Content "C:\Users\admins4v89kr\Desktop\Generate-Import-Sync.ps1" | Select-Object -First 7
cd "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
.\aspnet_regiis.exe -pc "NetFrameworkConfigurationKey"
 
.\aspnet_regiis.exe -px "NetFrameworkConfigurationKey" "c:\temp\keys.xml" -pri

Get-Content "C:\Users\admins4v89kr\Desktop\computers.txt" | foreach {Copy-Item "C:\Temp\import.ps1", "C:\Temp\keys.xml" -Destination \\$_\c$\temp}
$Servers = Get-Content "C:\Users\admins4v89kr\Desktop\computers.txt"
foreach ($Server in $Servers)
{invoke-command -computername $server -filepath C:\Temp\import.ps1 }




<#
Generate keys on the local server.
Export Keys to the XML file.
Copy the keys to rest of the servers in the farm.
Import keys 
#>
$path = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
cd $path\.\aspnet_regiis.exe -pc "NetFrameworkConfigurationKey"
cd $path\ .\aspnet_regiis.exe -px "NetFrameworkConfigurationKey" "c:\keys.xml" -pri
Get-Content "C:\Users\admins4v89kr\Desktop\computers.txt" | foreach {Copy-Item "C:\Keys.xml", "C:\import.bat" -Destination \\$_\c$\}
Get-Content "C:\Users\admins4v89kr\Desktop\computers.txt" | foreach { Invoke-Command -ScriptBlock  .\Query_Value.ps1 }

Invoke-Command -ScriptBlock { .\Query_Value.ps1 }



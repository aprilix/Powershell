Enter-PSSession vlpmwebqa2	
cd 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
Set-ItemProperty -Path . -Name "MinEncryptionLevel" -Value "1"
Exit-PSSession


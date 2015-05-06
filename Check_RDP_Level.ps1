$path = ‘HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp’
Get-ItemProperty -Path $path -Name “MinEncryptionLevel”
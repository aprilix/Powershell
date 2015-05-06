$servers = (Get-Content .\serverlistDB.txt)
Invoke-Command -ComputerName $servers -ScriptBlock {$path = ‘HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp’;Set-ItemProperty -Path $path -Name “MinEncryptionLevel” -Value “3”}

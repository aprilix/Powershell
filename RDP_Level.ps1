$servers = (Get-Content "s.txt") 
Invoke-Command -ComputerName $servers -ScriptBlock {$path = ‘HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp’;Get-ItemProperty -Path $path -Name “MinEncryptionLevel” } | ft -property MinEncryptionLevel -GroupBy PSComputername


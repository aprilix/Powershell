$computers = gc "C:\Users\admins4v89kr\Desktop\computers.txt"
foreach ($computer in $computers) { 
enter-pssession -ComputerName $computer 
powershell.exe
$path = ‘HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp’
Get-ItemProperty -Path $path -Name “MinEncryptionLevel”
}
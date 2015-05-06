$servers = (Get-Content "C:\Users\admins4v89kr\Desktop\servers.txt")
Invoke-Command -ComputerName $servers -ScriptBlock {
$oldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
$newPath=$oldPath+’;C:\Windows\System32\inetsrv’
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $newPath
}
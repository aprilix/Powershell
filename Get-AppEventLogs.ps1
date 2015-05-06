Param
(
[String] $Computers
) 
$srvrs = Get-Content "C:\Users\SVARMA\Desktop\Servers.txt"
Foreach ($srv in $srvrs) {
Write-Host "Pulling application Logs from $srv"
Try {Get-EventLog -Message *Exception* -Newest 5 -LogName Application -Source *ASP.NET* -ComputerName $srv | Select-Object Message | ft -Wrap }
Catch
{ Write-Warning "Cannot connect to $srv, Please double check and rerun the script" }
}
schtasks /Run /TN RE_CacheRefresher
timeout 600  (timeout for 10 mins so the job completes on server 1)
$job = C:\Get-Scheduledtask.ps1 | Where-Object { $_.TaskName -cmatch "RE_" } 
if ( $job.LastResult –ne $null ) {
schtasks /RUN /S server1 /TN "RE_CacheRefresher"
timeout 600 
schtasks /RUN /S server2 /TN "RE_CacheRefresher"
timeout 600
schtasks /RUN /S server3 /TN "RE_CacheRefresher"
timeout 600
$session = New-PSSession -ComputerName "server1", "server2","server3"
Invoke-Command -Session $session -ScriptBlock { appcmd.exe recycle apppool IOS}
}
else 
{
Send-MailMessage -From svarma@scif.com -To svarma@scif.com -SmtpServer 10.65.15.124 -Subject "RE_CacheRefresher job has failed, Please look at the logs or event viewer on Server1 for more info" 
}  
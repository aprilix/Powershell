schtasks /Run /TN RE_CacheRefresher
timeout 600  (timeout for 10 mins so the job completes on server 1)
$job = C:\Get-Scheduledtask.ps1 | Where-Object { $_.TaskName -cmatch "RE_" } 
if ( $job.LastResult –ne $null ) {
schtasks /RUN /S vlios2.scif.com /TN "RE_CacheRefresher"
timeout 600 
schtasks /RUN /S vlios3.scif.com /TN "RE_CacheRefresher"
timeout 600
schtasks /RUN /S vlios4.scif.com /TN "RE_CacheRefresher"
timeout 600
$session = New-PSSession -ComputerName "vliosweb", "vliosweb","vliosweb3", "vliosweb4"
Invoke-Command -Session $session -ScriptBlock { appcmd.exe recycle apppool IOS}
}
else 
{
Send-MailMessage -From svarma@scif.com -To svarma@scif.com -SmtpServer 10.65.15.124 -Subject "RE_CacheRefresher job has failed, Please look at the logs or event viewer on VLIOS.SCIF.COM for more info" 
}  
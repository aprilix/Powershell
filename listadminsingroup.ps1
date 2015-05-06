invoke-command {
$members = net localgroup administrators | 
 where {$_ -AND $_ -notmatch "command completed successfully"} | 
 select -skip 4
New-Object PSObject -Property @{
 Computername = $env:COMPUTERNAME
 Group = "Administrators"
 Members=$members
 }
} -computer Server,server1,server2 | 
Select * -ExcludeProperty RunspaceID
invoke-command {
$members = net localgroup administrators | 
 where {$_ -AND $_ -notmatch "command completed successfully"} | 
 select -skip 4
New-Object PSObject -Property @{
 Computername = $env:COMPUTERNAME
 Group = "Administrators"
 Members=$members
 }
} -computer vliosdev,vliosdev2,vliosqa.vliosqa2.vlioswebqa.vlioswebqa2 | 
Select * -ExcludeProperty RunspaceID
Param
(
[String] $Servers
) 
$srvrs = gc $servers
$collection = $()
foreach ($srv in $srvrs)
{    
     $status = @{ "ServerName" = $srv; "TimeStamp" = (Get-Date -f s) }  
     if (Test-Connection $srv -Count 1 -ea 0 -Quiet)    
     {         
              $status["Results"] = "Up"    
     }     
     else     
     {         
     $status["Results"] = "Down"     
     }    
     New-Object -TypeName PSObject -Property $status -OutVariable serverStatus    
     $collection += $serverStatus 
}
$collection | Export-Csv .\ServerStatus.csv -NoTypeInformation
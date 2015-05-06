   <#  
   .SYNOPSIS  
   PowerShell function to monitor what process is using resources   
   .DESCRIPTION  
   Includes parameters to monitor server and latecy, and capture data in file.  
   .EXAMPLE  
   Monitor-ProcessMemoryUsage -IntervalinSeconds 600 -MonitorPeriodHours 1 -File c:\temp\CapturedData.csv  
   #>   
  #####################################   
  ## http://kunaludapi.blogspot.com   
  ## Version: 1   
  ## Tested this script on successfully  
  ## 1) Powershell v4   
  ## 2) Windows 7   
  ##   
  #####################################  
   [CmdletBinding()]  
     param(  
       [Parameter(Mandatory=$False, HelpMessage="Enter Interval in seconds[After how many second you want to capture data]")]  
       [alias("Interval","I")]  
       [string]$IntervalinSeconds = 300,  
       [Parameter(Mandatory=$False, HelpMessage="For how long you want to capture data [in hours]")]  
       [alias("Monitor","M")]  
       [string]$MonitorPeriodHours = 1,  
       [Parameter(Mandatory=$False, HelpMessage="Where you want to store CSV file")]  
       [alias("File","F")]  
       [string]$FileName = "$env:USERPROFILE\Desktop\$("MemUsage{0}{1}{2}.csv" -f $(Get-Date).day, $(Get-Date).Month, $(Get-Date).Year)"  
     )  
   begin {  
     $FutureTime = [DateTime]::Now.AddHours($MonitorPeriodHours)  
     $i=0  
   }  
   process {  
     do {  
       $i++  
       $TimeNow = [DateTime]::Now  
       $AllProcesses = Get-Process -IncludeUserName   
       $Processors = Get-WmiObject -Namespace root\CIMv2 -Class win32_processor | Select-Object -ExpandProperty NumberOfLogicalProcessors  
       $SortedMemory = $AllProcesses | Sort-Object PM -Descending   
       $TopMemory = $SortedMemory | Select-Object -First 10 -Property @{l="Number"; e={$i}}, @{l="Time"; e={$TimeNow}}, Name, Description, Path, Id, StartTime, @{l="Private Memory (MB)"; e={[Math]::Round($($_.PM / 1mb),2)}}, UserName  
       $TopMemory | Export-Csv -NoTypeInformation -Path $FileName -Append  
       Start-Sleep -Seconds $IntervalinSeconds  
     }   
     While ([DateTime]::Now -lt $FutureTime)  
   }  
   end {} 
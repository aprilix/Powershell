﻿#+-------------------------------------------------------------------+  
#| = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = |  
#|{>/-------------------------------------------------------------\<}|           
#|: | Author:  Aman Dhally                                                   
#| :| Email:   amandhally@gmail.com                          
#|: | Purpose: 													   
#| :|       Ping Multiple Server and get an Average Ping time . 
#|: |  Blog: http://newdelhipowershellusergroup.blogspot.com/          						                         
#|: |                                Date: 16-03-2012           
#| :| 					/^(o.o)^\    Version: 1        
#|{>\-------------------------------------------------------------/<}|
#| = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = |
#+-------------------------------------------------------------------+

### Inculde other Script files


$CompName = "dc-Local","google.com","rediff.com","yahoo.com"

foreach ($comp in $CompName) {
	
	$test = (Test-Connection -ComputerName $comp -Count 4  | measure-Object -Property ResponseTime -Average).average
	$response = ($test -as [int] )
		
	write-Host "The Average response time for" -ForegroundColor Green -NoNewline;write-Host " `"$comp`" is " -ForegroundColor Red -NoNewline;;Write-Host "$response ms" -ForegroundColor Black -BackgroundColor white
	  
}

##### End of the script #### 
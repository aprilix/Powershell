<#
			"SatNaam WaheGuru" 

Date:	 05-July-2012 ; 19:46
Author: Aman Dhally
Email:  amandhally@gmail.com
web:	www.amandhally.net/blog
blog:	http://newdelhipowershellusergroup.blogspot.com/
More Info : 

Version : 1

	/^(o.o)^\  [Spider Man ] 


#>

$servers = "google.com","hotmail.com","msn.com"

foreach ( $server in $servers ) {
		
		if ((test-Connection -ComputerName $server -Count 2 -Quiet) -eq $true ) { 
				
			write-Host "$server is alive and Pinging `n " -ForegroundColor Green
			
		
					} else { 
					
					Write-Host "========================= Testing Done for all Servers ========== `n" -ForegroundColor Green
					"`n"
					"`n"
					
					write-Host " `"Computer $server not Pinging, i am going to do traceroute now.`" `n`n" -ForegroundColor RED 
		
					Write-Host "========================= Starting Traceroute for $server ========== `n" -ForegroundColor Yellow
					tracert -d  $server 
					Write-Host "========================= Traceroute for $server Done ========== `n" -ForegroundColor Yellow
			
					}
}

	### ### End of Script

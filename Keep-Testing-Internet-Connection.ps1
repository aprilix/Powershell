#==================| Satnaam Waheguru Ji |===============================
#           
#            Author  :  Aman Dhally 
#            E-Mail  :  amandhally@gmail.com 
#            website :  www.amandhally.net 
#            twitter :   @AmanDhally 
#            blog    : http://newdelhipowershellusergroup.blogspot.in/
#            facebook: http://www.facebook.com/groups/254997707860848/ 
#            Linkedin: http://www.linkedin.com/profile/view?id=23651495 
# 
#            Creation Date    : 29-07-2013 
#            File    : 
#            Purpose : 
#            Version : 1 
#
#            My Pet Spider :          /^(o.o)^\  
#========================================================================


# Setting bit as False First
$bit = $false

# running while.

while ( $bit -eq $false ) 
		
		{
		# just a notification
		Write-Host 'Checking Internet Connection.' -ForegroundColor 'Yellow'
		
		# Testing Network Connection and storing it in to a vraible
		# when we use -QUIET Parameter with Test-Connection, it stored the value in 
		# true or false
		$testInternetConnectivity = Test-Connection -Count 3 "www.google.com" -Quiet	
		
		# Test-Connection CMDLET return output in TRUE and False
		# we are assigning the output of $testInternetConnectivity to the $bit Variable
		$bit = 	$testInternetConnectivity
		
		#if the $bit is false then 
		if ( $testInternetConnectivity -ne $true) 
			{
			# show notifications
			Write-Host 'Please check your connection, I am not able to Ping www.google.com.'
			# just adding a new blank line
			"`n"		
			} #end of IF
	
	
		} # end of while

# if the $bit is $true , then we are good to go.
if ( $bit -eq $true ) 
		{
		# notifications	
		"`n"
		Write-Host 'Internet is Pingable, we are good to go.'	-ForegroundColor 'Green'
	
		} #end of IF



# end of the script
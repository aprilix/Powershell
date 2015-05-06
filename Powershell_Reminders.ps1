<#
 				"SatNaam WaheGuru"
					
				Author  :  Aman Dhally
				E-Mail  :  amandhally@gmail.com
				website :  www.amandhally.net
				twitter : https://twitter.com/#!/AmanDhally
				facebook: http://www.facebook.com/groups/254997707860848/
				Linkedin: http://www.linkedin.com/profile/view?id=23651495
				
				Purpose	: Want to ceate a console base Birthday reminder.
				Date	: 28-Aug-2012	19:09
				File Nam: Powershell Reminder
				More Info: www.amandhally.net
#>


# Global Variables
$dateDay = (Get-Date).Day

# Tex Reminders Colour Coding
	# Red = Urgent DONE ASAP
	# Yellow = Medium
	# Green = Can be Done any Time

#Reminders

# Bill Payments
	# Mobile Payment is on 14 of everyMont
	$mobilePayment =  "==> Please pay Your Airtel Mobile Bill today." 
	# Credit Card Payemnt of 28 of Everymonth
	$creditcardPayment = "Please pay your credit Card payment today."	


## Payment Script

# this is for payments becasue they are relies to day only

	switch ( $dateDay ) {
	14 { Write-Host $mobilePayment -ForegroundColor 'Red'}
	28 {  Write-Host $creditcardPayment -ForegroundColor 'Red'}
	default { Write-Host "Posh Reminder : No Payment reminders for today." -ForegroundColor 'Cyan'}
	}


# Birthdays LIST

# Janurary
	#Januarary 27 Jan
	$mannaBirthday = "Today is `"Manpreet`" birthday, wish him." 
#Feburay
	#feburary 18 feb
	$brotherBirthday = "Today is brothers birtday, wish him." 
# March
# April
#May
	#1
	$viruBirthday = "Todays is Varinder Birthday"
#June 
	#6
	$rahulBirthday = "Today is Rahul's Birthday."
#July
	#8
	$bossBirthday = "Boss's Birthday"
#August
	#12 Aug
	$sarbBirthday = "Today is `"Sarabpreet`" birthday, wish him." 
	# 24 August
	$JasbirBirthday = "Today is `"Jasbir`" birthday, wish him" 
#Spetember
	# My Birthday 9 sep
	$myBirthday = "Today is my birthday, i should give my self treat."
#October
	#Wife Birthday 30 Oct
	$wifeBirthday =  "Today is Wify Birthday, Dont forget otherwise you ARE screwed"
#November
	#
#December
	#27
	$jassBirthday = "Today is Jasmeet birthday"

# Script


switch ((Get-Date).Month) { 
	#main
	
	#Jan
	1  {
		 switch ((Get-Date).Day) {
			27 {Write-Host $mannaBirthday -ForegroundColor 'Yellow'} 
			default {Out-Null}
			}
		}
	
	#Feb
	2  {
			switch ((Get-Date).Day) {
			16 {Write-Host $brotherBirthday -ForegroundColor 'Yellow'} 
			default {Out-Null}
			}
		
		}
#	#Mar
#	No Birthdays in March	
#	3  { 
#			switch ((Get-Date).Day) {
#			27 	{ Write-Host $mannaBirthday -ForegroundColor 'Yellow' } 
#			default {Out-Null}
#			}
#		
#		}
#	#Apr
# 	# No Birthdays in April	
#	4  {
#			switch ((Get-Date).Day) {
#			27 {Write-Host $mannaBirthday -ForegroundColor 'Yellow'} 
#			default {Out-Null}
#			}
#		}
	#May
	5  { 
			switch ((Get-Date).Day) {
			1 {Write-Host $viruBirthday -ForegroundColor 'Yellow'} 
			default {Out-Null}
			}
		
		}
	#June
	6  { 
			switch ((Get-Date).Day) {
			6 {Write-Host $rahulBirthday -ForegroundColor 'Yellow'} 
			default {Out-Null}
			}
		
		}
	#July
	7  { 
			switch ((Get-Date).Day) {
			8 {Write-Host $bossBirthday -ForegroundColor 'Red'} 
			default {Out-Null}
			}
		
		}
	#Aug
	8  { 
			switch ((Get-Date).Day) {
			12 { Write-Host $sarbBirthday -ForegroundColor 'Yellow'} 
			24 { Write-Host $JasbirBirthday -ForegroundColor 'Yellow'}
			default {Out-Null}
			}
		
		}
	#Sep
	9  { 
			 switch ((Get-Date).Day) {
			9 {Write-Host $myBirthday -ForegroundColor 'Yellow'} 
			default {Out-Null}
			}
		
		}
	#Oct
	10 { 
			switch ((Get-Date).Day) {
			30 {Write-Host $wifeBirthday -ForegroundColor 'Red'} 
			default {Out-Null}
			}
		
		
		}
	#Nov
	# No Birthdays in November
#	11 { 
#			switch ((Get-Date).Day) {
#			27 {Write-Host $mannaBirthday -ForegroundColor 'Yellow'} 
#			default {Out-Null}
#			}
#		}
	#Dec
	12 { 
			 switch ((Get-Date).Day) {
			27 {Write-Host $jassBirthday -ForegroundColor 'Yellow'} 
			default {Out-Null}
			}
		}
	
	default { Out-Null } 
	
}

# You cans aslo use $Shell.WindowTitle in to the script for show reminders
# on your conslose tile bar
# example
#	12 { 
#			 switch ((Get-Date).Day) {
#			27 { $Shell.WindowTitle=$jassBirthday } 
#			default {Out-Null}
#			}
#		}
#

#### END of the SCRIPT ###### a m a n D ##


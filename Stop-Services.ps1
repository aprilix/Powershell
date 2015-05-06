$computers= Get-Content "C:\Users\admins4v89kr\Desktop\computers (2).txt"
get-service -Name OPNET* -computer $computers | Stop-Service 
Set-service -StartupType disabled -PassThru|


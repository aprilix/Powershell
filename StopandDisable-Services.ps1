$computers= Get-Content "C:\Users\admins4v89kr\Desktop\computers (2).txt"
get-service -Name AudioSrv -computer $computers |
     set-service -StartupType disabled -PassThru|
     stop-service -PassThru -Force



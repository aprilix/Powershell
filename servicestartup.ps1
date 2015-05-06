$servers = "C:\Users\admins4v89kr\Desktop\computers (2).txt"
foreach($server in $servers) {
$os = Get-WmiObject Win32_OperatingSystem -ComputerName $server
Get-WmiObject Win32_Service -ComputerName $server -Property StartMode -Filter "Name='AudioSrv'" | Foreach-Object{

    New-Object -TypeName PSObject -Property @{
        SystemName=$_.SystemName
        Name=$_.Name
        Status=$_.Status
        State=$_.State
        StartMode=$_.Startmode
        DisplayName=$_.DisplayName
        IPAddress = [System.Net.Dns]::GetHostAddresses($_.SystemName)[0].IPAddressToString
        OSName = $os.Caption            
    } | Select-Object StartMode,IPAddress,OSName

 } 

}
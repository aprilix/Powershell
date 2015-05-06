###Puts all Non-Server computers in a variable using their dnshostname
$computers = Get-ADComputer -Filter {OperatingSystem -NotLike "*server*"} -Properties operatingsystem | 
foreach { $_.DNSHostName }
###Tests Connection to $computers and restarts any up $computers

foreach ($computer in $computers) 
{
    if (test-connection $computer -count 1 -Quiet) 
    {
        Write-Verbose "$computer would be rebooted"
        #Restart-Computer -ComputerName $computer -Force -WhatIf
    }
    else
    { 
        write-host "$computer is not online"
    }
}
<#
    .SYNOPSIS
    Gets the size, maxsize, overwrite policy, and status of all of the event logs for all of the computers specified.
    .DESCRIPTION
    Gets the size, maxsize, overwrite policy, and status of all of the event logs for all of the computers specified. This scripts uses the root\cimv2 WMI namespace. Requires administrator rights on the target server(s). The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-EventLogSizes.ps1 -Computers Web01;Web02;Web03
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you are current logged in with.
    .EXAMPLE
    .\Get-EventLogSizes.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Notes
    Name: Get-EventLogSizes.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    LastEdit: December 23rd, 2011
    Keywords: PowerShell, WMI, IIS7
#>
param([string]$Computers="$env:computername",[string]$User='',[string]$Password='')

#// Argument processing
$global:Computers = $Computers
$global:User = $User
$global:Password = $Password

Function ProcessArguments
{    
    $global:aComputers = $global:Computers.Split(';')
    If ($global:aComputers -isnot [System.String[]])
    {
        $global:aComputers = @($global:Computers)
    }
    
    #// If credentials are passed into this script, then make them secure.
    If ($global:User -ne '')
    {        
        If ($global:Password -ne '')
        {
            $global:Password = ConvertTo-SecureString -AsPlainText -Force -String $global:Password
            $global:oCredential = New-Object System.Management.Automation.PsCredential($global:User,$global:Password)            
        }
        Else
        {
            $global:oCredential = Get-Credential -Credential $global:User
        }  
    }
}

Function Get-WmiQuery
{
    param($Namespace='root\cimv2',$Query,$Computer)
    
    If ($global:User -ne '')
    {
        Get-WmiObject -Namespace $Namespace -Query $Query -ComputerName $Computer -Authentication 6 -Credential $global:oCredential -ErrorAction SilentlyContinue
    }
    Else
    {
        Get-WmiObject -Namespace $Namespace -Query $Query -ComputerName $Computer -Authentication 6 -ErrorAction SilentlyContinue
    }
}

Function Start-Timer
{
    $global:dBeginTime = Get-Date
}

Function Stop-Timer
{
    param($BeginTime=$global:dBeginTime)
    $dEndTime = Get-Date
    New-TimeSpan -Start $BeginTime -End $dEndTime
}

ProcessArguments
$aObjects = @()
ForEach ($sComputer in $global:aComputers)
{
	Write-Host "Getting data from $sComputer..." -NoNewline; Start-Timer
	$EventLogs = Get-WmiQuery -Query "SELECT LogFileName, FileSize, MaxFileSize, Status, OverWritePolicy FROM Win32_NTEventlogFile" -computer $sComputer
	
	ForEach ($EventLog in $EventLogs)
	{
		$culture = Get-Culture
		$a = New-Object System.Globalization.CultureInfo($(Get-Culture).Name)
		
		$FileSize = $($EventLog.FileSize / 1MB)
		$MaxFileSize = $($EventLog.MaxFileSize / 1MB)
		$SizePercentage = ([int] $EventLog.FileSize * [int] 100) / [int] $EventLog.MaxFileSize
		$SizePercentage = [math]::round($SizePercentage, 0)
		
		$oObject = New-Object pscustomobject
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $sComputer
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'LogFileName' -Value $($EventLog.LogFileName)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Size (MB)' -Value $($FileSize.ToString("n2", $a))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'MaxSize (MB)' -Value $($MaxFileSize.ToString("n2", $a))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name '%' -Value $($SizePercentage)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'OverWritePolicy' -Value $($EventLog.OverWritePolicy)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Status' -Value $($EventLog.Status)
		$aObjects += @($oObject)
	}
	Write-Host "Done! [$(Stop-Timer)]"
}
$aObjects | Format-Table -AutoSize
$aObjects | Export-Csv -Path '.\Get-EventLogSizes.csv' -NoTypeInformation
Write-Host 'Done!'


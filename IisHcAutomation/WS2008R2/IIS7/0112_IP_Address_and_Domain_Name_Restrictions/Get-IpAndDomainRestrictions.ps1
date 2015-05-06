<#
    .SYNOPSIS
    Gets the application pool configuration.
    .DESCRIPTION
    Gets the application pool configuration and writes them to a comma separated file (CSV) for post-analysis such as auto-filter in Microsoft Excel. This script requires remote WMI connectivity to all of the servers specified. WMI uses Remote Procedure Calls (RPC) which uses random network ports. The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-IpAndDomainRestrictions.ps1 -Computers Web01;Web02;Web03
    This will gather the permissions from Web01, Web02, and Web03 using the credentials you are current logged in with. The output is written to .\Iis7NtfsPermissions.csv.
    .EXAMPLE
    .\Get-IpAndDomainRestrictions.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the permissions from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt. The output is written to .\Iis7NtfsPermissions.csv.    
    .EXAMPLE
    .\Get-IpAndDomainRestrictions.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator' -Password 'LetMeIn123' -OutputCsvFilePath 'C:\Iis7NtfsPermissions.csv'
    This will gather the permissions from Web01, Web02, and Web03 using the credentials passed in (optional) and write the output to C:\Iis7NtfsPermissions.csv. The default output location is the local directory. Avoid providing the password via command line. Consider omitting the password for a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Notes
    Name: Get-IpAndDomainRestrictions.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    Created: January 10th, 2012
    Keywords: PowerShell, WMI, IIS7, security, NTFS
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

Function Convert-WmiTimeSpan
{ 
	param([String] $WmiDateTime)
    $WmiDateTime = $WmiDateTime.Trim()
    $iYear   = [Int32]::Parse($WmiDateTime.SubString( 0, 4)) 
    $iMonth  = [Int32]::Parse($WmiDateTime.SubString( 4, 2)) 
    $iDay    = [Int32]::Parse($WmiDateTime.SubString( 6, 2)) 
    $iHour   = [Int32]::Parse($WmiDateTime.SubString( 8, 2)) 
    $iMinute = [Int32]::Parse($WmiDateTime.SubString(10, 2)) 
    $iSecond = [Int32]::Parse($WmiDateTime.SubString(12, 2))
	New-TimeSpan -Days $iDay -Hours $iHour -Minutes $iMinute -Seconds $iSecond
} 

# Main
ProcessArguments
$aObjects = @()
ForEach ($sComputer in $global:aComputers)
{
	Write-Host "Getting data from $sComputer..." -NoNewline; Start-Timer
	$oCollection = Get-WmiQuery -Namespace 'root\WebAdministration' -Query 'SELECT * FROM IPAddressFilterElement' -Computer $sComputer
    Write-Host "Done! [$(Stop-Timer)]"
	
	If ($oCollection -ne $null)
	{
		ForEach ($oInstance in $oCollection)
		{			
			$oObject = New-Object pscustomobject
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $([string] $sComputer)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'DomainName' -Value $([string] $oInstance.DomainName)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'IpAddress' -Value $([string] $oInstance.IpAddress)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'SubnetMask' -Value $([string] $oInstance.SubnetMask)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Allowed' -Value $([bool] $oInstance.Allowed)
			$aObjects += @($oObject)
		}
	}
	Else
	{
		Write-Host "`t[No data]"
	}
}
$aObjects | Format-Table -AutoSize
$aObjects | Export-Csv -Path '.\Get-IpAndDomainRestrictions.csv' -NoTypeInformation
Write-Host 'Done!'
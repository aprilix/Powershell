<#
    .SYNOPSIS
    Gets the BIOS data for all web sites and virtual directories for all IIS7 servers.
    .DESCRIPTION
    Gets the BIOS data for all web sites and virtual directories for all IIS7 servers. This scripts uses the root\WebAdministration WMI namespace. Requires administrator rights on the target server(s). The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-Bios.ps1 -Computers Web01;Web02;Web03
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you are current logged in with.
    .EXAMPLE
    .\Get-Bios.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Notes
    Name: Get-Bios.ps1
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

$global:LastComputerEnvCollected = ''
Function Expand-EnvironmentVariables
{
    param([string] $Computer,[string] $String)
    $String = $String.ToLower()
    $sWql = 'SELECT Name, VariableValue FROM Win32_Environment'
    If ($global:LastComputerEnvCollected -ne $Computer)
    {
        $global:oCollectionOfEnvironmentVariables = Get-WmiQuery -Query $sWql -Computer $Computer
    }
    ForEach ($oEnv in $global:oCollectionOfEnvironmentVariables)
    {
        $sEnv = '%' + "$($oEnv.Name)" + '%'
        $sValue = "$($oEnv.VariableValue)"
        $String = $String.Replace($sEnv,$sValue)
    }
    If ($($String.IndexOf('%')) -ge 0)
    {
        #// Some environment variables like %SystemRoot% must be manually looked up.
        If ($global:LastComputerEnvCollected -ne $Computer)
        {
            $sWql = 'SELECT SystemDrive, SystemDirectory, WindowsDirectory FROM Win32_OperatingSystem'
            $global:oCollectionOfOperatingSystems = Get-WmiQuery -Query $sWql -Computer $Computer
            $global:LastComputerEnvCollected = $Computer
        }

        ForEach ($oEnv in $global:oCollectionOfOperatingSystems)
        {
            $sValue = "$($oEnv.WindowsDirectory)"
            $String = $String.Replace('%systemroot%',$sValue)
            $String = $String.Replace('%windir%',$sValue)
            
            $sValue = "$($oEnv.SystemDrive)"
            $String = $String.Replace('%systemdrive%',$sValue)
            
            $sValue = "$($oEnv.SystemDirectory)"
            $String = $String.Replace('%systemdirectory%',$sValue)            
        }
        
        If ($($String.IndexOf('%')) -ge 0)
        {
            Write-Warning 'Unable to resolve one or more of the environment variables in the following string:'
            Write-Host "$String"
        }
    }
    $String
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
$null = [Reflection.Assembly]::LoadWithPartialName("System.Management")
$aObjects = @()
ForEach ($sComputer in $global:aComputers)
{
	Write-Host "Getting data from $sComputer..." -NoNewline; Start-Timer
	
	$oCollection = Get-WmiQuery -Namespace 'root\cimv2' -Query 'SELECT * FROM Win32_BIOS' -Computer $sComputer
	If ($oCollection -ne $null)
	{
	    ForEach ($oInstance in $oCollection)
		{
			$dReleaseDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($($oInstance.ReleaseDate))
			$oObject = New-Object pscustomobject
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $sComputer
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'BIOSVersion' -Value $($oInstance.BIOSVersion)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Manufacturer' -Value $($oInstance.Manufacturer)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'ReleaseDate' -Value $dReleaseDate
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Version' -Value $($oInstance.Version)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'SMBIOSBIOSVersion' -Value $($oInstance.SMBIOSBIOSVersion)
			$aObjects += @($oObject)
		}
	}
	Write-Host "Done! [$(Stop-Timer)]"
}
$aObjects | Format-Table -AutoSize
$aObjects | Export-Csv -Path '.\Get-Bios.csv' -NoTypeInformation
Write-Host 'Done!'
<#
    .SYNOPSIS
    Gets the file information from a directory path and writes them to a comma separated file (CSV) for post-analysis such as auto-filter in Microsoft Excel.
    .DESCRIPTION
    Gets the file information from a directory path and writes them to a comma separated file (CSV) for post-analysis such as auto-filter in Microsoft Excel. This script requires remote WMI connectivity to all of the servers specified. WMI uses Remote Procedure Calls (RPC) which uses random network ports. The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-FileInformation.ps1 -Computers Web01;Web02;Web03
    Gets the file information from a directory path from Web01, Web02, and Web03 using the credentials you are current logged in with.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Parameter OutputCsvFilePath
    The file path to a comma separated value (CSV) file to write the output to. If omitted, then .\Iis7NtfsPermissions.csv is used.
    .Notes
    Name: Get-FileInformation.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    Created: 2012 01 27
    Keywords: PowerShell, WMI, IIS7, security, NTFS
#>
param([string]$Computers="$env:computername",[string]$User='',[string]$Password='',[string] $Directory)

#// Argument processing
$global:Computers = $Computers
$global:User = $User
$global:Password = $Password
$global:Directory = $Directory

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


ProcessArguments
$aObjects = @()
If (($global:Directory -ne '') -and ($global:Directory -is [string]))
{
	$sDoubleBackSlashDirectory = $global:Directory.Replace('\','\\')
	ForEach ($sComputer in $global:aComputers)
	{
		Write-Host "Getting data from $sComputer..." -NoNewline; Start-Timer
		$sWmiQuery = 'ASSOCIATORS OF {Win32_Directory.Name="' + $sDoubleBackSlashDirectory + '"} WHERE ResultClass = CIM_DataFile'
		$oCollection = Get-WmiQuery -Namespace 'root\cimv2' -Query $sWmiQuery -Computer $sComputer
	    Write-Host "Done! [$(Stop-Timer)]"
		
		If ($oCollection -ne $null)
		{
			ForEach ($oFile in $oCollection)
			{
				$sFileName = [string] $oFile.FileName + '.' + [string] $oFile.Extension
				$dLastModified = [System.Management.ManagementDateTimeConverter]::ToDateTime($($oFile.LastModified))
				
				$oObject = New-Object pscustomobject
				Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $([string] $sComputer)
				Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Directory' -Value $([string] $global:Directory)
				Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Extension' -Value $([string] $oFile.Extension)
				Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'FileName' -Value $([string] $sFileName)
				Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Version' -Value $([string] $oFile.Version)
				Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'LastModified' -Value $([datetime] $dLastModified)
				Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Manufacturer' -Value $([string] $oFile.Manufacturer)
				
				$aObjects += @($oObject)		
			}
		}
	}
}
$aObjects | Format-Table -AutoSize
$aObjects | Export-Csv -Path '.\Get-FileInformation.csv' -NoTypeInformation
Write-Host 'Done!'
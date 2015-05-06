<#
    .SYNOPSIS
    Diagnoses and logs network connectivity with another computer.
    .DESCRIPTION
    This script is designed to be ran periodically from a Scheduled Task to check the connectivity to another computer. It uses ping, nslookup, and WMI (DCOM) connectivity.
    .EXAMPLE
    .\NCon.ps1 -TargetIpOrName 'Test.example.com'
    .EXAMPLE
    .\NCon.ps1 -TargetIpOrName 'Web01' -ExpectedIpAddress '192.168.1.1' -ExpectedMacAddress '02:BF:4C:4F:4F:51'
    This will checck the connectivity from this computer to Web01 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt.
    .Parameter TargetIpOrName
    This parameters requires a string of a computer name to target for network connectivity.
	.Parameter ExpectedIpAddress
	(Optional) This paraameter is used to compare to the return IP address from the ping.
	.Parameter ExpectedMacAddress
	(Optional) This paraameter is used to compare to the MAC address of the target server returned from a WMI query.	
    .Notes
    Name: NCon.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    LastEdit: March 14th, 2012
	Version: 1.0
    Keywords: PowerShell, WMI, network
#>
param([string]$TargetIpOrName="$env:computername",[string] $ExpectedIpAddress='*',[string] $ExpectedMacAddress='*')

#// Argument processing
$global:Computer = $TargetIpOrName
$global:IpAddress = $ExpectedIpAddress
$global:MacAddress = $ExpectedMacAddress
$global:Logfile = 'C:\logfiles\NCon.log'

Function Get-VLan
{
	param($Computer)

	$sCmd = "ping -a $Computer -n 1"
	$oOutput = Invoke-Expression -Command $sCmd

	ForEach ($sLine in $oOutput)
	{
		If ($($sLine.IndexOf('Pinging')) -ge 0)
		{
			$aLine = $sLine.Split()
			Return $aLine
		}		
	}	
}

Function Get-MacAddress
{
	param($Computer,$IpAddress)
	$oWmiCollection = Get-WmiObject -Query 'SELECT IPAddress, MACAddress FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = True' -ComputerName $Computer
	ForEach ($oWmiInstance in $oWmiCollection)
	{
		ForEach ($sWmiIpAddress in $oWmiInstance.IPAddress)
		{
			If ($sWmiIpAddress -eq $IpAddress)
			{
				Return $oWmiInstance.MACAddress
			}
		}
	}
	Return 'NoIpToMacAddrMatch'
}

#// MAIN

[bool] $bDriveExists = Test-Path -Path 'I:\'
If ($bDriveExists -eq $true)
{
	[bool] $bDirExists = Test-Path -Path 'I:\logfiles'
	If ($bDirExists -eq $false)
	{
		New-Item -Path 'I:\' -Name 'logfiles' -type directory -ErrorAction SilentlyContinue
	}
	$global:Logfile = 'I:\logfiles\NCon.log'
}
Else
{
	[bool] $bDirExists = Test-Path -Path 'C:\logfiles'
	If ($bDirExists -eq $false)
	{
		New-Item -Path 'C:\' -Name 'logfiles' -type directory -ErrorAction SilentlyContinue
	}
	$global:Logfile = 'C:\logfiles\NCon.log'
}

$oPingResult = Test-Connection -ComputerName $global:Computer -Count 1

If ($oPingResult.StatusCode -ne 0)
{
	$aVLanLookup = Get-VLan -Computer $global:Computer
	$sVLanLookupName = $aVLanLookup[1]
	$sVLanIpAddress = $aVLanLookup[2]
	$sRemark = 'No ping response from host.'
	$sResult = "[$(Get-Date)] " + "$env:computername" + ' => ' + "$global:Computer" + ', IP:' + "$sVLanIpAddress" + ', VLan: ' + "$sVLanLookupName" + ', Remark: '+ "$sRemark"
	Write-Host $sResult
	$sResult >> $global:Logfile
	break;
}
Else
{	
	[string] $sRemark = ''
	[string] $sMacAddress = $global:MacAddress
	[bool] $IsIpAddressMatch = $true
	[bool] $IsMacAddressMatch = $true
	
	If ($($oPingResult.IPv4Address.IPAddressToString) -eq $global:IpAddress)
	{
		$IsIpAddressMatch = $true
		If ($global:MacAddress -ne '*')
		{
			$sMacAddress = Get-MacAddress -Computer $global:Computer -IpAddress $($oPingResult.IPv4Address.IPAddressToString)
			If ($sMacAddress -eq $global:MacAddress)
			{
				$IsMacAddressMatch = $true
				$sRemark = 'verified'
			}
			Else
			{
				$IsMacAddressMatch = $false
				If ($sRemark -eq '')
				{
					[string] $sRemark = "MAC address mismatch expecting $global:MacAddress"
				}
				Else
				{
					[string] $sRemark = $sRemark + '|' + "MAC address mismatch expecting $global:MacAddress"
				}		
			}
		}
		Else
		{
			$sRemark = 'verified'
		}
	}
	Else
	{
		If ($global:IpAddress -ne '*')
		{
			$IsIpAddressMatch = $false
			If ($sRemark -eq '')
			{
				[string] $sRemark = "IP Address mismatch expecting $global:IpAddress"
			}
			Else
			{
				[string] $sRemark = $sRemark + '|' + "IP Address mismatch expecting $global:IpAddress"
			}
		}
	}
	
	$aVLanLookup = Get-VLan -Computer $global:Computer
	$sVLanLookupName = $aVLanLookup[1]
	$sVLanIpAddress = $aVLanLookup[2]
	
	$sResult = "[$(Get-Date)] " + "$env:computername" + ' => ' + "$global:Computer" + ', IP:' + "$($oPingResult.IPv4Address.IPAddressToString)" + ', MAC:' + "$sMacAddress" + ', VLan: ' + "$sVLanLookupName" + ', Remark: '+ "$sRemark"
	Write-Host $sResult
	$sResult >> $global:Logfile
	If (($IsIpAddressMatch -eq $false) -or ($IsMacAddressMatch -eq $false))
	{
		Write-EventLog -LogName Application -Source WSH -EventId '4242' -Message $sResult -EntryType 1 -Category 0
	}
}




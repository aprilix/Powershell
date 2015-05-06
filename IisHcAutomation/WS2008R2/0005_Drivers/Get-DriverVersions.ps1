<#
    .SYNOPSIS
    Gets the driver information for all of the servers.
    .DESCRIPTION
    Gets the driver information for all of the servers. This scripts uses the root\cimv2 WMI namespace. Requires administrator rights on the target server(s). The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-DriverVersions.ps1 -Computers Web01;Web02;Web03
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you are current logged in with.
    .EXAMPLE
    .\Get-DriverVersions.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt.
    .EXAMPLE
    .\Get-DriverVersions.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator' -Password 'LetMeIn123'
    Enables all of the W3C logging fields on all web sites from Web01, Web02, and Web03 using the credentials passed in (optional). The default output location is the local directory. Avoid providing the password via command line. Consider omitting the password for a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Notes
    Name: Get-DriverVersions.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    LastEdit: December 12th, 2011
	Version: 1.0
    Keywords: PowerShell, WMI, IIS7
#>
param([string]$Computers="$env:computername",[string]$User='',[string]$Password='')
cls

#$Computers = 'cop-white;iis701'
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

[Void] [reflection.assembly]::LoadWithPartialName("'Microsoft.VisualBasic")
ProcessArguments
#// COMPUTER
$aWmiObjects = @()
ForEach ($sComputer in $global:aComputers)
{
    Write-Host ''
    Write-Host "Computer: $sComputer"
		
	[string] $sNamespace = 'root\cimv2'
	[string] $sWmiClass = 'Win32_SystemDriver'


	Start-Timer
    Write-Host "Getting driver data from $sComputer..." -NoNewline
    If ($global:User -ne '')
    {
        $oWmiCollectionOfInstances = Get-WmiObject -Namespace $sNamespace -Query "SELECT * FROM $sWmiClass" -ComputerName $sComputer -Authentication 6 -ErrorAction SilentlyContinue -Credential $global:oCredential
		$oWmiClass = Get-WmiObject -Namespace $sNamespace -Class $sWmiClass -ComputerName $sComputer -Authentication 6 -ErrorAction SilentlyContinue -Credential $global:oCredential
    }
    Else
    {
        $oWmiCollectionOfInstances = Get-WmiObject -Namespace $sNamespace -Query "SELECT * FROM $sWmiClass" -ComputerName $sComputer -Authentication 6 -ErrorAction SilentlyContinue
    }
    $dDuration = Stop-Timer
    Write-Host "Done! [$dDuration]"	
			
	#// INSTANCE
	If ($oWmiCollectionOfInstances -ne $null)
	{
		Start-Timer
	    Write-Host "Getting file data from $sComputer..." -NoNewline		
		ForEach ($oWmiInstance in $oWmiCollectionOfInstances)
		{
			If ($oWmiInstance -ne $null)
			{
				$oNewObject1 = New-Object System.Object
				Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name 'Computer' -Value $([System.String]$sComputer)
				#// PROPERTIES
				Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name 'Caption' -Value $([System.String]$oWmiInstance.Caption)
				Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name 'PathName' -Value $([System.String]$oWmiInstance.PathName)
				Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name 'ServiceType' -Value $([System.String]$oWmiInstance.ServiceType)
				Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name 'State' -Value $([System.String]$oWmiInstance.State)
				
				
				[string] $sDoubleBackSlashFilePath = $($oWmiInstance.PathName).Replace('\','\\')
				$sWmiQuery = 'SELECT * FROM CIM_DataFile WHERE Name = "' + "$sDoubleBackSlashFilePath" + '"'
				
			    If ($global:User -ne '')
			    {
			        $oWmiCollectionOfFiles = Get-WmiObject -Namespace $sNamespace -Query $sWmiQuery -ComputerName $sComputer -Authentication 6 -ErrorAction SilentlyContinue -Credential $global:oCredential
			    }
			    Else
			    {
			        $oWmiCollectionOfFiles = Get-WmiObject -Namespace $sNamespace -Query $sWmiQuery -ComputerName $sComputer -Authentication 6 -ErrorAction SilentlyContinue
			    }
				
				If ($oWmiCollectionOfFiles -ne $null)
				{
					ForEach ($oWmiFile in $oWmiCollectionOfFiles)
					{
						[System.DateTime] $oLastModifiedDateTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($($oWmiFile.LastModified))
						Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name 'Version' -Value $([System.String]$oWmiFile.Version)
						Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name 'Manufacturer' -Value $([System.String]$oWmiFile.Manufacturer)
						Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name 'LastModified' -Value $([System.DateTime]$oLastModifiedDateTime)
						Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name 'FileSize' -Value $([System.Int64]$oWmiFile.FileSize)						
					}
				}
				$aWmiObjects += $oNewObject1
			}
		}
    $dDuration = Stop-Timer
    Write-Host "Done! [$dDuration]"	
	}
}
$aWmiObjects | Format-Table -AutoSize
$aWmiObjects | Export-Csv -Path '.\Get-DriverVersions.csv' -NoTypeInformation
<#
    .SYNOPSIS
    Gets the instances of Win32_Operating system for all of the servers.
    .DESCRIPTION
    Gets the instances of Win32_Operating system for all of the servers. This scripts uses the root\cimv2 WMI namespace. Requires administrator rights on the target server(s). The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-OperatingSystem.ps1 -Computers Web01;Web02;Web03
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you are current logged in with.
    .EXAMPLE
    .\Get-OperatingSystem.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt.
    .EXAMPLE
    .\Get-OperatingSystem.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator' -Password 'LetMeIn123'
    Enables all of the W3C logging fields on all web sites from Web01, Web02, and Web03 using the credentials passed in (optional). The default output location is the local directory. Avoid providing the password via command line. Consider omitting the password for a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Notes
    Name: Get-OperatingSystem.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    LastEdit: December 12th, 2011
	Version: 1.0
    Keywords: PowerShell, WMI, IIS7
#>
param([string]$Computers="$env:computername",[string]$User='',[string]$Password='')
cls
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

[Void] [reflection.assembly]::LoadWithPartialName("'Microsoft.VisualBasic")

ProcessArguments
$aWmiObjects = @()
#// COMPUTER
ForEach ($sComputer in $global:aComputers)
{
    #Write-Host ''
    #Write-Host "Computer: $sComputer"
		
	[string] $sNamespace = 'root\cimv2'
	[string] $sWmiClass = 'Win32_OperatingSystem'
	
    If ($global:User -ne '')
    {
        $oWmiCollectionOfInstances = Get-WmiObject -Namespace $sNamespace -Query "SELECT * FROM $sWmiClass" -ComputerName $sComputer -Authentication 6 -ErrorAction SilentlyContinue -Credential $global:oCredential
		$oWmiClass = Get-WmiObject -Namespace $sNamespace -Class $sWmiClass -ComputerName $sComputer -Authentication 6 -ErrorAction SilentlyContinue -Credential $global:oCredential
    }
    Else
    {
        $oWmiCollectionOfInstances = Get-WmiObject -Namespace $sNamespace -Query "SELECT * FROM $sWmiClass" -ComputerName $sComputer -Authentication 6 -ErrorAction SilentlyContinue
		$oWmiClass = Get-WmiObject -Namespace $sNamespace -Class $sWmiClass -ComputerName $sComputer -Authentication 6 -ErrorAction SilentlyContinue
    }
			
	#// INSTANCE
	If ($oWmiCollectionOfInstances -ne $null)
	{
		ForEach ($oWmiInstance in $oWmiCollectionOfInstances)
		{
			If ($oWmiInstance -ne $null)
			{
				$oNewObject1 = New-Object System.Object
				Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name 'Computer' -Value $([System.String]$sComputer)
				#// PROPERTIES
				ForEach ($oWmiProperty in $($oWmiClass.Properties))
				{
					$sInstancePropertyName = $oWmiProperty.Name
					$sInstancePropertyType = $oWmiProperty.Type					
					
					If ($sInstancePropertyType -eq $null)
					{
						$sInstancePropertyType = 'Object'
					}
					
					$bIsNumeric = [Microsoft.VisualBasic.Information]::isnumeric($($oWmiInstance.$($oWmiProperty.Name)))
					If ($bIsNumeric -eq $true)
					{
						$sInstancePropertyType = 'SInt32'
					}
					
					
					switch ($sInstancePropertyType)
					{
						'Boolean'
						{
							Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name $sInstancePropertyName -Value $([Bool] $oWmiInstance.$($oWmiProperty.Name))
						}
						'DateTime'
						{
							[System.DateTime] $oDateTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($($oWmiInstance.$($oWmiProperty.Name)))
							Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name $sInstancePropertyName -Value $([System.DateTime] $oDateTime)
						}
						'Object'
						{
							$XmlNewOBJECT = $XmlDump.CreateElement("$($oWmiProperty.Name)")
							#$oNewObject2 = New-Object System.Object
							$oWmiPropertyObjectValue = $oWmiInstance.$($oWmiProperty.Name)
							Switch ($oWmiPropertyObjectValue.GetType().FullName)
							{
								'System.Management.ManagementBaseObject'
								{
									Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name $sInstancePropertyName -Value $($oWmiInstance.$($oWmiProperty.Name))
								}
								'System.Management.ManagementBaseObject[]'
								{
									Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name $sInstancePropertyName -Value $($oWmiInstance.$($oWmiProperty.Name))
								}
								default
								{
									Write-Host "Unknown type: $($oWmiPropertyObjectValue.Value.GetType().FullName)"
								}
							}
						}
						'SInt32' 
						{
							Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name $sInstancePropertyName -Value $([System.Int32] $oWmiInstance.$($oWmiProperty.Name))
						}								
						'String' 
						{
							Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name $sInstancePropertyName -Value $([System.String] $oWmiInstance.$($oWmiProperty.Name))
						}
						'UInt32' 
						{
							Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name $sInstancePropertyName -Value $([System.UInt32] $oWmiInstance.$($oWmiProperty.Name))
						}
						default
						{
							Add-Member -InputObject $oNewObject1 -MemberType NoteProperty -Name $sInstancePropertyName -Value $($oWmiInstance.$($oWmiProperty.Name))
						}
					}
				}
				$aWmiObjects += $oNewObject1
			}
		}
	}
}
$aWmiObjects | Format-Table -AutoSize
$aWmiObjects | Export-Csv -Path '.\Get-OperatingSystem.csv'
#Write-Host 'Done!'
<#
    .SYNOPSIS
    Gets all of the WMI data of one or more IIS7 servers and writes it to a single XML document.
    .DESCRIPTION
    Gets all of the WMI data of one or more IIS7 servers and writes it to a single XML document. This data comes from the root\WebAdministration WMI namespace. Requires administrator rights on the target server(s). The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-WebAdministrationToXml.ps1 -Computers Web01;Web02;Web03
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you are current logged in with. The output is written to .\IIS7WmiDump.xml.
    .EXAMPLE
    .\Get-WebAdministrationToXml.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt. The output is written to .\IIS7WmiDump.xml.    
    .EXAMPLE
    .\Get-WebAdministrationToXml.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator' -Password 'LetMeIn123' -OutputXmlFilePath 'C:\IIS7WmiDump.xml'
    This will WMI data from Web01, Web02, and Web03 using the credentials passed in (optional) and write the output to C:\IIS7WmiDump.xml. The default output location is the local directory. Avoid providing the password via command line. Consider omitting the password for a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Parameter OutputXmlFilePath
    The file path to an XML file to overwrite the output to. If omitted, then .\IIS7WmiDump.xml is used.
    .Notes
    Name: Get-WebAdministrationToXml.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    LastEdit: November 25th, 2011
    Keywords: PowerShell, WMI, IIS7
#>
param([string]$Computers="$env:computername",[string]$User='',[string]$Password='',[string]$OutputXmlFilePath="$(Split-Path -parent $MyInvocation.MyCommand.Definition)\IIS7WmiDump.xml")

#// Argument processing
$global:Computers = $Computers
$global:User = $User
$global:Password = $Password
$global:OutputXmlFilePath = $OutputXmlFilePath

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
            #If ($global:Password -isnot [System.Security.SecureString])
            #{
            #    Write-Error 'Unable to convert password into a secure string password.'
            #    Break;
            #}              
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
		#Write-Host "$Namespace,$Query,$Computer"
        Get-WmiObject -Namespace $Namespace -Query $Query -ComputerName $Computer -Authentication 6 -ErrorAction SilentlyContinue
    }
}

Function Get-WmiIis7Query
{
    param($Namespace='root\WebAdministration',$Query,$Computer)
    Get-WmiQuery -Namespace 'root\WebAdministration' -Query $Query -Computer $Computer
}

Function Start-Timer
{
    $global:dBeginTime = Get-Date
}

Function Stop-Timer
{
    param($BeginTime=$global:dBeginTime)
    $dEndTime = Get-Date
	#$dDurationTime = New-TimeSpan -Start $BeginTime -End $dEndTime
    New-TimeSpan -Start $BeginTime -End $dEndTime
	#Write-Host "`t[$dDurationTime] $Title"	
}

Function Start-GlobalTimer
{
    $global:dGlobalBeginTime = Get-Date   
}

Function Stop-GlobalTimer
{
    $dGlobalEndTime = Get-Date
	$dDurationTime = New-TimeSpan -Start $global:dGlobalBeginTime -End $dGlobalEndTime
	"`nScript Execution Duration: " + $dDurationTime + "`n"
}

#trap
#{
#	Write-Host 'Failed...' -NoNewline -BackgroundColor Yellow
#	#Continue;
#}

Start-GlobalTimer
ProcessArguments
$global:alWmiPropertyTypes = New-Object System.Collections.ArrayList

$XmlDump = New-Object System.Xml.XmlDocument
$XmlIIS7HC = $XmlDump.CreateElement('IIS7HC')
[void] $XmlDump.AppendChild($XmlIIS7HC)

#// COMPUTER
ForEach ($sComputer in $global:aComputers)
{
    Write-Host ''
    Write-Host "Computer: $sComputer"
	
	$XmlNewCOMPUTER = $XmlDump.CreateElement('COMPUTER')
	$XmlNewCOMPUTER.SetAttribute('NAME',"$sComputer")
	[void] $XmlIIS7HC.AppendChild($XmlNewCOMPUTER)
	
    Start-Timer
    Write-Host "Getting WMI classes from $sComputer..." -NoNewline
	
    If ($global:User -ne '')
    {
        $oWmiCollectionOfClasses = Get-WmiObject -Namespace 'root\WebAdministration' -List -ComputerName $sComputer -Authentication 6 -ErrorAction SilentlyContinue -Credential $global:oCredential
    }
    Else
    {
		#Write-Host "$Namespace,$Query,$Computer"
        $oWmiCollectionOfClasses = Get-WmiObject -Namespace 'root\WebAdministration' -List -ComputerName $sComputer -Authentication 6 -ErrorAction SilentlyContinue
    }	
    $dDuration = Stop-Timer
    Write-Host "Done! [$dDuration]"
	
	#// CLASS
	ForEach ($oWmiClass in $oWmiCollectionOfClasses)
	{
		$sWmiClassName = $oWmiClass.Name
		#Write-Host $sWmiClassName
				
		If ($($sWmiClassName.SubString(0,2)) -ne '__') #// Avoid WMI schema classes
		{
			$XmlNewCLASS = $XmlDump.CreateElement('CLASS')
			$XmlNewCLASS.SetAttribute('NAME',"$sWmiClassName")
			[void] $XmlNewCOMPUTER.AppendChild($XmlNewCLASS)
			
		    Start-Timer
		    Write-Host "`tGetting WMI instances from $sWmiClassName..." -NoNewline		
			$oWmiCollectionOfInstances = Get-WmiIis7Query -Query "SELECT * FROM $sWmiClassName" -Computer $sComputer
		    $dDuration = Stop-Timer
		    Write-Host "Done! [$dDuration]"			
			
			#// INSTANCE
			If ($oWmiCollectionOfInstances -ne $null)
			{
				ForEach ($oWmiInstance in $oWmiCollectionOfInstances)
				{
					If ($oWmiInstance -ne $null)
					{
						$XmlNewINSTANCE = $XmlDump.CreateElement('INSTANCE')
						
						#// PROPERTIES
						ForEach ($oWmiProperty in $($oWmiClass.Properties))
						{
							$sInstancePropertyName = $oWmiProperty.Name
							$sInstancePropertyType = $oWmiProperty.Type
							
							If ($sInstancePropertyType -eq $null)
							{
								$sInstancePropertyType = 'Object'
							}
							
							switch ($sInstancePropertyType)
							{
								'Boolean'
								{
									$XmlNewINSTANCE.SetAttribute($sInstancePropertyName,"$($oWmiInstance.$($oWmiProperty.Name))")	
								}
								'DateTime'
								{
									$XmlNewINSTANCE.SetAttribute($sInstancePropertyName,"$($oWmiInstance.$($oWmiProperty.Name))")
								}
								'Object'
								{
									$XmlNewOBJECT = $XmlDump.CreateElement("$($oWmiProperty.Name)")
									$oWmiPropertyObjectValue = $oWmiInstance.$($oWmiProperty.Name)
									Switch ($oWmiPropertyObjectValue.GetType().FullName)
									{
										'System.Management.ManagementBaseObject'
										{
											ForEach ($oObjectProperty in $($oWmiPropertyObjectValue.Properties))
											{
												$XmlNewOBJECT.SetAttribute("$($oObjectProperty.Name)","$($oObjectProperty.Value)")
											}
											[void] $XmlNewINSTANCE.AppendChild($XmlNewOBJECT)
										}
										'System.Management.ManagementBaseObject[]'
										{
											ForEach ($oObjectInstance1 in $oWmiPropertyObjectValue)
											{
												$XmlNewOBJECT2 = $XmlDump.CreateElement("$($oWmiProperty.Name)")
												ForEach ($oObjectProperty2 in $($oObjectInstance1.Properties))
												{
													$XmlNewOBJECT2.SetAttribute("$($oObjectProperty2.Name)","$($oObjectProperty2.Value)")
													[void] $XmlNewOBJECT.AppendChild($XmlNewOBJECT2)
												}
												[void] $XmlNewINSTANCE.AppendChild($XmlNewOBJECT)
											}
										}
										default
										{
											Write-Host "Unknown type: $($oWmiPropertyObjectValue.Value.GetType().FullName)"
										}
									}
								}
								'SInt32' 
								{
									$XmlNewINSTANCE.SetAttribute($sInstancePropertyName,"$($oWmiInstance.$($oWmiProperty.Name))")
								}								
								'String' 
								{
									$XmlNewINSTANCE.SetAttribute($sInstancePropertyName,"$($oWmiInstance.$($oWmiProperty.Name))")
								}
								'UInt32' 
								{
									$XmlNewINSTANCE.SetAttribute($sInstancePropertyName,"$($oWmiInstance.$($oWmiProperty.Name))")
								}
								default
								{
									$XmlNewINSTANCE.SetAttribute($sInstancePropertyName,"$($oWmiInstance.$($oWmiProperty.Name))")
								}
							}
						}
						[void] $XmlNewCLASS.AppendChild($XmlNewINSTANCE)
					}
				}
			}
		}
	}
}
$XmlDump.Save($global:OutputXmlFilePath)
Stop-GlobalTimer
Write-Host 'Done!'
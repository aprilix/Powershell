<#
    .SYNOPSIS
    Gets the services for all of the IIS7 servers and determine if they should be enabled or disabled.
    .DESCRIPTION
    Gets the services for all of the IIS7 servers and determine if they should be enabled or disabled. This scripts uses the root\WebAdministration WMI namespace. Requires administrator rights on the target server(s). The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-ServiceLockdownSettings.ps1 -Computers Web01;Web02;Web03
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you are current logged in with.
    .EXAMPLE
    .\Get-ServiceLockdownSettings.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Notes
    Name: Get-ServiceLockdownSettings.ps1
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

# Main
ProcessArguments

$aRequiredServices = @('Windows Event Log','IIS Admin Service','Distributed Transaction Coordinator','Windows Time','Virtual Disk','Application Host Helper Service','Network Store Interface Service','RPC Endpoint Mapper','DCOM Server Process Launcher','Windows Process Activation Service','World Wide Web Publishing Service','Workstation','Security Accounts Manager','Server','Remote Procedure Call (RPC)','Protected Storage','Windows Management Instrumentation','Netlogon','Task Scheduler')
$aOptionalServices = @('Microsoft FTP Service','Certificate Authority','FTP Publishing Service','Windows Firewall','COM+ System Application ','COM+ Event System','ASP.NET State Service','Power','IPsec Policy Agent','Windows Defender','Volume Shadow Copy')
$aRecommendDisabledServices = @('Alerter','Computer Browser','DHCP Client','TCP/IP NetBIOS Helper','Telephony','Print Spooler','Network Monitor Agent')
$aBuiltInServices = @('Application Experience','Application Layer Gateway Service','Application Host Helper Service','Application Identity','Application Information','Application Management','ASP.NET State Service','Windows Audio Endpoint Builder','Windows Audio','Base Filtering Engine','Background Intelligent Transfer Service','Computer Browser','Certificate Propagation','Microsoft .NET Framework NGEN v2.0.50727_X86','Microsoft .NET Framework NGEN v2.0.50727_X64','COM+ System Application','Cryptographic Services','DCOM Server Process Launcher','Disk Defragmenter','DHCP Client','DNS Client','Wired AutoConfig','Diagnostic Policy Service','Extensible Authentication Protocol','Encrypting File System (EFS)','Windows Event Log','COM+ Event System','Microsoft Fibre Channel Platform Registration Service','Function Discovery Provider Host','Function Discovery Resource Publication','Windows Font Cache Service','Microsoft FTP Service','Group Policy Client','Human Interface Device Access','Health Key and Certificate Management','IIS Admin Service','IKE and AuthIP IPsec Keying Modules','PnP-X IP Bus Enumerator','IP Helper','CNG Key Isolation','KtmRm for Distributed Transaction Coordinator','Server','Workstation','Link-Layer Topology Discovery Mapper','TCP/IP NetBIOS Helper','Multimedia Class Scheduler','Windows Firewall','Distributed Transaction Coordinator','Microsoft iSCSI Initiator Service','Windows Installer','Network Access Protection Agent','Netlogon','Network Connections','Network List Service','Network Location Awareness','Network Store Interface Service','Performance Counter DLL Host','Performance Logs & Alerts','Plug and Play','IPsec Policy Agent','Power','User Profile Service','Protected Storage','Remote Access Auto Connection Manager','Remote Access Connection Manager','Routing and Remote Access','Remote Registry','RPC Endpoint Mapper','Remote Procedure Call (RPC) Locator','Remote Procedure Call (RPC)','Resultant Set of Policy Provider','Special Administration Console Helper','Security Accounts Manager','Smart Card','Task Scheduler','Smart Card Removal Policy','Secondary Logon','System Event Notification Service','Remote Desktop Configuration','Internet Connection Sharing (ICS)','Shell Hardware Detection','SNMP Trap','Print Spooler','Software Protection','SPP Notification Service','SSDP Discovery','Secure Socket Tunneling Protocol Service','Microsoft Software Shadow Copy Provider','Telephony','TPM Base Services','Remote Desktop Services','Thread Ordering Server','Distributed Link Tracking Client','Windows Modules Installer','Interactive Services Detection','Remote Desktop Services UserMode Port Redirector','UPnP Device Host','Desktop Window Manager Session Manager','Credential Manager','Virtual Disk','Hyper-V Heartbeat Service','Hyper-V Data Exchange Service','Hyper-V Guest Shutdown Service','Hyper-V Time Synchronization Service','Hyper-V Volume Shadow Copy Requestor','Volume Shadow Copy','Windows Time','World Wide Web Publishing Service','Windows Process Activation Service','Windows Color System','Diagnostic Service Host','Diagnostic System Host','Windows Event Collector','Problem Reports and Solutions Control Panel Support','Windows Error Reporting Service','WinHTTP Web Proxy Auto-Discovery Service','Windows Management Instrumentation','Windows Remote Management (WS-Management)','WMI Performance Adapter','Web Management Service','Portable Device Enumerator Service','Windows Update','Windows Driver Foundation - User-mode Driver Framework')

$aObjects = @()
ForEach ($sComputer in $global:aComputers)
{
	Write-Host "Getting Services data from $sComputer..." -NoNewline; Start-Timer
	$oCollection = Get-WmiQuery -Namespace 'root\cimv2' -Query 'SELECT * FROM Win32_Service' -Computer $sComputer | Sort-Object Caption
    Write-Host "Done! [$(Stop-Timer)]"
	
	ForEach ($oInstance in $oCollection)
	{
		$sCaption = $oInstance.Caption
			
		[string] $sRecommendation = ''
		#// Required
		$bIsRequired = $false
		:IsRequiredLoop ForEach ($sService in $aRequiredServices)
		{
			If ($sService -eq $sCaption)
			{
				$bIsRequired = $true
				$sRecommendation = 'Required'
				Break IsRequiredLoop;
			}
		}
		
		#// Optional
		$bIsOptional = $false
		If ($bIsRequired -eq $false)
		{
			:IsOptionalLoop ForEach ($sService in $aOptionalServices)
			{
				If ($sService -eq $sCaption)
				{
					$bIsOptional = $true
					$sRecommendation = 'Optional'
					Break IsOptionalLoop;				
				}
			}
		}
		
		#// Recommend to disable
		If (($bIsRequired -eq $false) -and ($bIsOptional -eq $false)) 
		{
			:RecommendDisableLoop ForEach ($sService in $aRecommendDisabledServices)
			{
				If ($sService -eq $sCaption)
				{
					$sRecommendation = 'Consider disabling'
					Break RecommendDisableLoop;				
				}
			}		
		}
		
		#// Built into the operating system
		$IsBuiltIn = $false
		:IsBuiltInLoop ForEach ($sService in $aBuiltInServices)
		{
			If ($sService -eq $sCaption)
			{
				$IsBuiltIn = $true
				Break IsBuiltInLoop;				
			}
		}
		
		$oObject = New-Object pscustomobject
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $sComputer
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Caption' -Value $($oInstance.Caption)			
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Recommendation' -Value $sRecommendation
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'StartMode' -Value $($oInstance.StartMode)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'BuiltIn' -Value $IsBuiltIn
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'State' -Value $($oInstance.State)
		$aObjects += @($oObject)
	}
}
$aObjects | Format-Table -AutoSize
$aObjects | Export-Csv -Path '.\Get-ServiceLockdownSettings.csv' -NoTypeInformation
Write-Host 'Done!'
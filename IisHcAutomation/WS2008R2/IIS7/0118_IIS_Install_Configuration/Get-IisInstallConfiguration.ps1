<#
    .SYNOPSIS
    Gets the W3C logging fields on all web sites of one or more IIS7 servers.
    .DESCRIPTION
    Gets the W3C logging fields on all web sites of one or more IIS7 servers. This scripts uses the root\WebAdministration WMI namespace. Requires administrator rights on the target server(s). The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-IisInstallConfiguration.ps1 -Computers Web01;Web02;Web03
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you are current logged in with.
    .EXAMPLE
    .\Get-IisInstallConfiguration.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt.
    .EXAMPLE
    .\Get-IisInstallConfiguration.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator' -Password 'LetMeIn123'
    Enables all of the W3C logging fields on all web sites from Web01, Web02, and Web03 using the credentials passed in (optional). The default output location is the local directory. Avoid providing the password via command line. Consider omitting the password for a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Notes
    Name: Get-IisInstallConfiguration.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    LastEdit: November 28th, 2011
    Keywords: PowerShell, WMI, IIS7
#>
param([string]$Computers="$env:computername",[string]$User='',[string]$Password='')
cls

HKEY_CLASSES_ROOT  = &H80000000
HKEY_CURRENT_USER  = &H80000001
HKEY_LOCAL_MACHINE = &H80000002
HKEY_USERS         = &H80000003
REG_SZ = 1
REG_EXPAND_SZ = 2
REG_BINARY = 3
REG_DWORD = 4
REG_MULTI_SZ = 7

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

Function Convert-IisLogConfigurationToString
{
    param([System.Int32] $Mask)
	
	If ($Mask -eq 0){Return 'None'}
	
    #// Constants used for IIS W3C field mask
	[System.Int32] $date = 1
	[System.Int32] $time = 2
	[System.Int32] $c_ip = 4
	[System.Int32] $cs_username = 8
	[System.Int32] $s_sitename = 16
	[System.Int32] $s_computername = 32
	[System.Int32] $s_ip = 64
	[System.Int32] $cs_method = 128
	[System.Int32] $cs_uri_stem = 256
	[System.Int32] $cs_uri_query = 512
	[System.Int32] $sc_status = 1024
	[System.Int32] $sc_win32_status = 2048
	[System.Int32] $sc_bytes = 4096
	[System.Int32] $cs_bytes = 8192
	[System.Int32] $time_taken = 16384
	[System.Int32] $s_port = 32768
	[System.Int32] $cs_user_agent = 65536
	[System.Int32] $cs_cookie = 131072
	[System.Int32] $cs_referer = 262144
	[System.Int32] $cs_version = 524288
	[System.Int32] $cs_host = 1048576
	[System.Int32] $sc_substatus = 2097152
	
	$aResult = @()
	If ($Mask -band $date){$aResult += @('date')}
	If ($Mask -band $time){$aResult += @('time')}
	If ($Mask -band $c_ip){$aResult += @('c-ip')}	
	If ($Mask -band $cs_username){$aResult += @('cs-username')}
	If ($Mask -band $s_sitename){$aResult += @('s-sitename')}
	If ($Mask -band $s_computername){$aResult += @('s-computername')}
	If ($Mask -band $s_ip){$aResult += @('s-ip')}
	If ($Mask -band $cs_method){$aResult += @('cs-method')}
	If ($Mask -band $cs_uri_stem){$aResult += @('cs-uri-stem')}
	If ($Mask -band $cs_uri_query){$aResult += @('$cs-uri-query')}
	If ($Mask -band $sc_status){$aResult += @('sc-status')}
	If ($Mask -band $sc_win32_status){$aResult += @('sc-win32-status')}
	If ($Mask -band $sc_bytes){$aResult += @('sc-bytes')}
	If ($Mask -band $cs_bytes){$aResult += @('cs-bytes')}
	If ($Mask -band $time_taken){$aResult += @('time-taken')}
	If ($Mask -band $s_port){$aResult += @('s-port')}
	If ($Mask -band $cs_user_agent){$aResult += @('cs-user-agent')}
	If ($Mask -band $cs_cookie){$aResult += @('cs-cookie')}
	If ($Mask -band $cs_referer){$aResult += @('cs-referer')}
	If ($Mask -band $cs_version){$aResult += @('cs-version')}
	If ($Mask -band $cs_host){$aResult += @('cs-host')}
	If ($Mask -band $sc_substatus){$aResult += @('sc-substatus')}
	[string]::Join(',',$aResult)
	#$aResult
}

ProcessArguments
$aObjects = @()
$aDisplayObjects = @()
ForEach ($sComputer in $global:aComputers)
{
	Write-Host "Getting data from $sComputer..." -NoNewline; Start-Timer
	$oCollection = Get-WmiQuery -Namespace 'root\WebAdministration' -Query 'SELECT * FROM Site' -Computer $sComputer
	ForEach ($oSite in $oCollection)
	{
		[string] $sExtFlags = Convert-IisLogConfigurationToString -Mask $($oSite.LogFile.LogExtFileFlags)
		
		$oObject = New-Object pscustomobject
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $([string] $sComputer)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'SiteName' -Value $([string] $oSite.Name)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'ID' -Value $([UInt32] $oSite.Id)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'date' -Value $([string] $sExtFlags.Contains('date'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'time' -Value $([string] $sExtFlags.Contains('time'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'c-ip' -Value $([string] $sExtFlags.Contains('c-ip'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'cs-username' -Value $([string] $sExtFlags.Contains('cs-username'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 's-sitename' -Value $([string] $sExtFlags.Contains('s-sitename'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 's-computername' -Value $([string] $sExtFlags.Contains('s-computername'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 's-ip' -Value $([string] $sExtFlags.Contains('s-ip'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'cs-method' -Value $([string] $sExtFlags.Contains('cs-method'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'cs-uri-stem' -Value $([string] $sExtFlags.Contains('cs-uri-stem'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'cs-uri-query' -Value $([string] $sExtFlags.Contains('cs-uri-query'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'sc-status' -Value $([string] $sExtFlags.Contains('sc-status'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'sc-win32-status' -Value $([string] $sExtFlags.Contains('sc-win32-status'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'sc-bytes' -Value $([string] $sExtFlags.Contains('sc-bytes'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'cs-bytes' -Value $([string] $sExtFlags.Contains('cs-bytes'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'time-taken' -Value $([string] $sExtFlags.Contains('time-taken'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 's-port' -Value $([string] $sExtFlags.Contains('s-port'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'cs-user-agent' -Value $([string] $sExtFlags.Contains('cs-user-agent'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'cs-cookie' -Value $([string] $sExtFlags.Contains('cs-cookie'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'cs-referer' -Value $([string] $sExtFlags.Contains('cs-referer'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'cs-version' -Value $([string] $sExtFlags.Contains('cs-version'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'cs-host' -Value $([string] $sExtFlags.Contains('cs-host'))
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'sc-substatus' -Value $([string] $sExtFlags.Contains('sc-substatus'))
		$aObjects += @($oObject)
					
		$oDisplayObject = New-Object pscustomobject
		Add-Member -InputObject $oDisplayObject -MemberType NoteProperty -Name 'Computer' -Value $([string] $sComputer)
		Add-Member -InputObject $oDisplayObject -MemberType NoteProperty -Name 'SiteName' -Value $([string] $oSite.Name)
		Add-Member -InputObject $oDisplayObject -MemberType NoteProperty -Name 'ID' -Value $([UInt32] $oSite.Id)
		Add-Member -InputObject $oDisplayObject -MemberType NoteProperty -Name 'W3cFields' -Value $([string] $sExtFlags)
		$aDisplayObjects += @($oDisplayObject)
	}
	Write-Host "Done! [$(Stop-Timer)]"
}
$aDisplayObjects | Format-Table -AutoSize
$aObjects | Export-Csv -Path '.\Get-IisInstallConfigurationcsv' -NoTypeInformation
Write-Host 'Done!'
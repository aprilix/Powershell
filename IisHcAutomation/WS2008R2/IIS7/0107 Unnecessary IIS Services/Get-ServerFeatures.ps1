<#
    .SYNOPSIS
    Gets the server features for all of the IIS7 servers.
    .DESCRIPTION
    Gets the server features for all of the IIS7 servers. This scripts uses the root\cimv2 WMI namespace. Requires administrator rights on the target server(s). The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-ServerFeature.ps1 -Computers Web01;Web02;Web03
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you are current logged in with.
    .EXAMPLE
    .\Get-ServerFeature.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Notes
    Name: Get-ServerFeature.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    LastEdit: Janurary 2nd, 2012
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

$aRequiredFeatures = @('Web Server','Web Server (IIS)','Common HTTP Features','Management Service','Security','HTTP Logging','HTTP Errors','Default Document','Static Content') | Sort-Object
$aOptionalFeatures = @('Remote Server Administration Tools','IIS Hostable Web Core','FTP Extensibility','FTP Service','Web Server (IIS) Tools','Role Administration Tools','FTP Server','IIS Management Scripts and Tools','IIS Management Console','Management Tools','Dynamic Content Compression','Static Content Compression','Performance','IP and Domain Restrictions','Request Filtering','URL Authorization','IIS Client Certificate Mapping Authentication','Client Certificate Mapping Authentication','Windows Authentication','ODBC Logging','Custom Logging','Tracing','Request Monitor','Logging Tools','Health and Diagnostics','ISAPI Filters','ISAPI Extensions','ASP','.NET Extensibility','ASP.NET','Application Development','HTTP Redirection') | Sort-Object
$aRecommendRemovalFeatures = @('WebDAV Publishing','IIS 6 Management Console','IIS 6 Scripting Tools','IIS 6 WMI Compatibility','IIS 6 Metabase Compatibility','IIS 6 Management Compatibility','Digest Authentication','Basic Authentication','Server Side Includes','CGI','Directory Browsing') | Sort-Object

$aObjects = @()
ForEach ($sComputer in $global:aComputers)
{
	Write-Host "Getting server features data from $sComputer..." -NoNewline; Start-Timer
	$oCollection = Get-WmiQuery -Namespace 'root\cimv2' -Query 'SELECT Name FROM Win32_ServerFeature' -Computer $sComputer | Sort-Object Name
    Write-Host "Done! [$(Stop-Timer)]"
	
	ForEach ($oInstance in $oCollection)
	{
		$sName = $oInstance.Name
			
		[string] $sRecommendation = '**Unknown**'
		#// Required
		$bIsRequired = $false
		:IsRequiredLoop ForEach ($sService in $aRequiredFeatures)
		{
			If ($sService -eq $sName)
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
			:IsOptionalLoop ForEach ($sService in $aOptionalFeatures)
			{
				If ($sService -eq $sName)
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
			:RecommendDisableLoop ForEach ($sService in $aRecommendRemovalFeatures)
			{
				If ($sService -eq $sName)
				{
					$sRecommendation = 'Remove'
					Break RecommendDisableLoop;				
				}
			}		
		}
				
		$oObject = New-Object pscustomobject
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $sComputer
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Name' -Value $($oInstance.Name)		
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Recommendation' -Value $sRecommendation
		$aObjects += @($oObject)
	}
}
$aObjects | Format-Table -AutoSize
$aObjects | Export-Csv -Path '.\Get-ServerFeature.csv' -NoTypeInformation
Write-Host 'Done!'
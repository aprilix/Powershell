<#
    .SYNOPSIS
    Gets all of the web sites and virtual directories and writes them to a comma separated file (CSV) for post-analysis such as auto-filter in Microsoft Excel.
    .DESCRIPTION
    Gets all of the web sites and virtual directories and writes them to a comma separated file (CSV) for post-analysis such as auto-filter in Microsoft Excel. This script requires remote WMI connectivity to all of the servers specified. WMI uses Remote Procedure Calls (RPC) which uses random network ports. The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-UnnecessaryVdirsAndSites.ps1 -Computers Web01;Web02;Web03
    This will gather the permissions from Web01, Web02, and Web03 using the credentials you are current logged in with. The output is written to .\Iis7NtfsPermissions.csv.
    .EXAMPLE
    .\Get-UnnecessaryVdirsAndSites.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the permissions from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt. The output is written to .\Iis7NtfsPermissions.csv.    
    .EXAMPLE
    .\Get-UnnecessaryVdirsAndSites.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator' -Password 'LetMeIn123' -OutputCsvFilePath 'C:\Iis7NtfsPermissions.csv'
    This will gather the permissions from Web01, Web02, and Web03 using the credentials passed in (optional) and write the output to C:\Iis7NtfsPermissions.csv. The default output location is the local directory. Avoid providing the password via command line. Consider omitting the password for a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Parameter OutputCsvFilePath
    The file path to a comma separated value (CSV) file to write the output to. If omitted, then .\Get-UnnecessaryVdirsAndSites.csv is used.
    .Notes
    Name: Get-UnnecessaryVdirsAndSites.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    LastEdit: November 23rd, 2011
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

# Main
ProcessArguments

$aRequired = @('#####Never#####') | Sort-Object
$aOptional = @('#####Never#####') | Sort-Object
$aRecommendRemoval = @('blah','test','temp','old') | Sort-Object

$aObjects = @()
ForEach ($sComputer in $global:aComputers)
{
	Write-Host "Getting server features data from $sComputer..." -NoNewline; Start-Timer
	$oCollection = Get-WmiQuery -Namespace 'root\WebAdministration' -Query 'SELECT * FROM VirtualDirectory' -Computer $sComputer
    Write-Host "Done! [$(Stop-Timer)]"
	
	ForEach ($oInstance in $oCollection)
	{
		[string] $sPath = $oInstance.Path
		$sPath = $sPath.ToLower()
		[string] $sPhysicalPath = $oInstance.PhysicalPath
		$sPhysicalPath = $sPhysicalPath.ToLower()
		[string] $sSiteName = $oInstance.SiteName
		[string] $sSiteName = $sSiteName.ToLower()
			
		[string] $sRecommendation = ''
		#// Required
		$bIsRequired = $false
		:IsRequiredLoop ForEach ($sString in $aRequired)
		{
			$sString = $sString.ToLower()
			If (($sPath.Contains($sString)) -or ($sPhysicalPath.Contains($sString)) -or ($sSiteName.Contains($sString)))
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
			:IsOptionalLoop ForEach ($sString in $aOptional)
			{
				$sString = $sString.ToLower()
				If (($sPath.Contains($sString)) -or ($sPhysicalPath.Contains($sString)) -or ($sSiteName.Contains($sString)))				
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
			
			:RecommendDisableLoop ForEach ($sString in $aRecommendRemoval)
			{
				$sString = $sString.ToLower()
				If (($sPath.Contains($sString)) -or ($sPhysicalPath.Contains($sString)) -or ($sSiteName.Contains($sString)))
				{
					$sRecommendation = 'Necessary?'
					Break RecommendDisableLoop;				
				}
			}
		}
				
		$oObject = New-Object pscustomobject
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $sComputer
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'SiteName' -Value $($oInstance.SiteName)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Path' -Value $($oInstance.Path)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'PhysicalPath' -Value $($oInstance.PhysicalPath)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Recommendation' -Value $sRecommendation
		$aObjects += @($oObject)
	}
}
$aObjects | Format-Table -AutoSize
$aObjects | Export-Csv -Path '.\Get-UnnecessaryVdirsAndSites.csv' -NoTypeInformation
Write-Host 'Done!'
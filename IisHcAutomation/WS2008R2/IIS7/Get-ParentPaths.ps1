<#
    .SYNOPSIS
    Gets the ASP Parent Path setting for all web sites for all IIS7 servers.
    .DESCRIPTION
    Gets the ASP Parent Path setting for all web sites for all IIS7 servers. This scripts uses the root\WebAdministration WMI namespace. Requires administrator rights on the target server(s). The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-ParentPaths.ps1 -Computers Web01;Web02;Web03
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you are current logged in with.
    .EXAMPLE
    .\Get-ParentPaths.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt.
    .EXAMPLE
    .\Get-ParentPaths.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator' -Password 'LetMeIn123'
    Enables all of the W3C logging fields on all web sites from Web01, Web02, and Web03 using the credentials passed in (optional). The default output location is the local directory. Avoid providing the password via command line. Consider omitting the password for a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Notes
    Name: Get-ParentPaths.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    LastEdit: November 28th, 2011
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

ProcessArguments
$aObjects = @()
ForEach ($sComputer in $global:aComputers)
{
	Write-Host $sComputer
	$oCollection = Get-WmiQuery -Namespace 'root\WebAdministration' -Query 'SELECT * FROM AspSection' -Computer $sComputer
	ForEach ($oInstance in $oCollection)
	{
		$oObject = New-Object pscustomobject
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name Computer -Value $sComputer
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name Location -Value $($oInstance.Location)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name Path -Value $($oInstance.Path)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name EnableParentPaths -Value $($oInstance.EnableParentPaths)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name IsLocal -Value $($oInstance.Properties['EnableParentPaths'].IsLocal)
		$aObjects += @($oObject)
	}
}
$aObjects | Format-Table -AutoSize
$aObjects | Export-Csv -Path '.\Get-ParentPaths.csv' -NoTypeInformation
Write-Host 'Done!'
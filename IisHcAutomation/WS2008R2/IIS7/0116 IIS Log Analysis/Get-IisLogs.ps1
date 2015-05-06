<#
    .SYNOPSIS
    Gets the IIS logs (commonly W3C logs) from all of the web sites of an IIS7 server.
    .DESCRIPTION
    Gets the IIS logs (commonly W3C logs) from all of the web sites of an IIS7 server. This scripts uses the root\WebAdministration and root\cimv2 WMI namespaces. Requires administrator rights on the target server(s). The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-IisLogs.ps1 -Computers Web01;Web02;Web03
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you are current logged in with.
    .EXAMPLE
    .\Get-IisLogs.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Parameter DaysOld
    This is the number of days previous to now of IIS logs to collect from each web site.
	.Notes
    Name: Get-IisLogs.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    Created: January 6th, 2012
    Keywords: PowerShell, WMI, IIS7
#>
param([string]$Computers="$env:computername",[string]$User='',[string]$Password='',[int] $DaysOld=2)

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

$global:LastComputerEnvCollected = ''
Function Expand-EnvironmentVariables
{
    param([string] $Computer,[string] $String)
    $String = $String.ToLower()
    $sWql = 'SELECT Name, VariableValue FROM Win32_Environment'
    If ($global:LastComputerEnvCollected -ne $Computer)
    {
        $global:oCollectionOfEnvironmentVariables = Get-WmiQuery -Query $sWql -Computer $Computer
    }
    ForEach ($oEnv in $global:oCollectionOfEnvironmentVariables)
    {
        $sEnv = '%' + "$($oEnv.Name)" + '%'
        $sValue = "$($oEnv.VariableValue)"
        $String = $String.Replace($sEnv,$sValue)
    }
    If ($($String.IndexOf('%')) -ge 0)
    {
        #// Some environment variables like %SystemRoot% must be manually looked up.
        If ($global:LastComputerEnvCollected -ne $Computer)
        {
            $sWql = 'SELECT SystemDrive, SystemDirectory, WindowsDirectory FROM Win32_OperatingSystem'
            $global:oCollectionOfOperatingSystems = Get-WmiQuery -Query $sWql -Computer $Computer
            $global:LastComputerEnvCollected = $Computer
        }

        ForEach ($oEnv in $global:oCollectionOfOperatingSystems)
        {
            $sValue = "$($oEnv.WindowsDirectory)"
            $String = $String.Replace('%systemroot%',$sValue)
            $String = $String.Replace('%windir%',$sValue)
            
            $sValue = "$($oEnv.SystemDrive)"
            $String = $String.Replace('%systemdrive%',$sValue)
            
            $sValue = "$($oEnv.SystemDirectory)"
            $String = $String.Replace('%systemdirectory%',$sValue)            
        }
        
        If ($($String.IndexOf('%')) -ge 0)
        {
            Write-Warning 'Unable to resolve one or more of the environment variables in the following string:'
            Write-Host "$String"
        }
    }
    $String
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

ProcessArguments
$aObjects = @()
ForEach ($sComputer in $global:aComputers)
{
	Write-Host "Getting data from $sComputer..." -NoNewline; Start-Timer
	
	$oCollection = Get-WmiQuery -Namespace 'root\WebAdministration' -Query 'SELECT Name, ID, LogFile FROM Site' -Computer $sComputer
	If ($oCollection -ne $null)
	{
	    ForEach ($oInstance in $oCollection)
		{
			$sLogDirPath = $($oInstance.LogFile.Directory) + '\W3SVC' + $($oInstance.ID)
			$sLogDirPath = Expand-EnvironmentVariables -Computer $sComputer -String $sLogDirPath
			$oObject = New-Object pscustomobject
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $sComputer
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Site' -Value $($oInstance.Name)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'ID' -Value $($oInstance.ID)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'LogDirPath' -Value $sLogDirPath
			$aObjects += @($oObject)
		}
	}
	Write-Host "Done! [$(Stop-Timer)]"
}
$aObjects | Format-Table -AutoSize
$aObjects | Export-Csv -Path '.\Get-IisLogs.csv' -NoTypeInformation

$null = [Reflection.Assembly]::LoadWithPartialName("System.Management")
[Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
ForEach ($oObject in $aObjects)
{
	$sComputer = $oObject.Computer
	$sLogDirPath = $oObject.LogDirPath
	Write-Host "Copying log files from $sComputer at $sLogDirPath..." -NoNewline; Start-Timer
	$sDoubleSlashLogDirPath = $sLogDirPath.Replace('\','\\')
	$sWql = 'ASSOCIATORS OF {Win32_Directory.Name="' + "$sDoubleSlashLogDirPath" + '"} WHERE ResultClass = CIM_DataFile'
	#$sWql = 'SELECT Name, FileName, LastModified FROM CIM_DataFile WHERE Name = "' + $sDoubleSlashLogDirPath + '"'
	$oCollection = Get-WmiQuery -Namespace 'root\cimv2' -Query $sWql -Computer $sComputer
	$iCountOfFilesCopied = 0
	ForEach ($oFile in $oCollection)
	{
		$dLastModified = [System.Management.ManagementDateTimeConverter]::ToDateTime($($oFile.LastModified))
		$dDateDiff = New-TimeSpan $dLastModified $(Get-Date)
		If ($dDateDiff.Days -lt $DaysOld)
		{
			$sTargetFilePath = [Environment]::CurrentDirectory + '\' + $oFile.FileName + '_' + $oObject.Computer + '_' + $oObject.ID + '.' + $oFile.Extension
			$oReturnValue = $oFile.Copy($sTargetFilePath)
            $sSourceFilePath = $oFile.Name -Replace ':','$'
            $sSourceFilePath = "\\$sComputer\$sSourceFilePath"
			Copy-Item -Path $sSourceFilePath -Destination $sTargetFilePath
		}
	}
	Write-Host "Done! [FilesCopies: $iCountOfFilesCopied] [$(Stop-Timer)]"
}
Write-Host 'Done!'
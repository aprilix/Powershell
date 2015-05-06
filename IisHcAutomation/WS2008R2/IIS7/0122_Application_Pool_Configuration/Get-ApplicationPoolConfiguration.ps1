<#
    .SYNOPSIS
    Gets the application pool configuration.
    .DESCRIPTION
    Gets the application pool configuration and writes them to a comma separated file (CSV) for post-analysis such as auto-filter in Microsoft Excel. This script requires remote WMI connectivity to all of the servers specified. WMI uses Remote Procedure Calls (RPC) which uses random network ports. The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-ApplicationPoolConfiguration.ps1 -Computers Web01;Web02;Web03
    This will gather the permissions from Web01, Web02, and Web03 using the credentials you are current logged in with. The output is written to .\Iis7NtfsPermissions.csv.
    .EXAMPLE
    .\Get-ApplicationPoolConfiguration.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the permissions from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt. The output is written to .\Iis7NtfsPermissions.csv.    
    .EXAMPLE
    .\Get-ApplicationPoolConfiguration.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator' -Password 'LetMeIn123' -OutputCsvFilePath 'C:\Iis7NtfsPermissions.csv'
    This will gather the permissions from Web01, Web02, and Web03 using the credentials passed in (optional) and write the output to C:\Iis7NtfsPermissions.csv. The default output location is the local directory. Avoid providing the password via command line. Consider omitting the password for a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Notes
    Name: Get-ApplicationPoolConfiguration.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    Created: January 10th, 2012
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

Function Convert-WmiTimeSpan
{ 
	param([String] $WmiDateTime)
    $WmiDateTime = $WmiDateTime.Trim()
    $iYear   = [Int32]::Parse($WmiDateTime.SubString( 0, 4)) 
    $iMonth  = [Int32]::Parse($WmiDateTime.SubString( 4, 2)) 
    $iDay    = [Int32]::Parse($WmiDateTime.SubString( 6, 2)) 
    $iHour   = [Int32]::Parse($WmiDateTime.SubString( 8, 2)) 
    $iMinute = [Int32]::Parse($WmiDateTime.SubString(10, 2)) 
    $iSecond = [Int32]::Parse($WmiDateTime.SubString(12, 2))
	New-TimeSpan -Days $iDay -Hours $iHour -Minutes $iMinute -Seconds $iSecond
} 

# Main
ProcessArguments
$aObjects = @()
ForEach ($sComputer in $global:aComputers)
{
	Write-Host "Getting data from $sComputer..." -NoNewline; Start-Timer
	$oCollection = Get-WmiQuery -Namespace 'root\WebAdministration' -Query 'SELECT * FROM ApplicationPool' -Computer $sComputer
    Write-Host "Done! [$(Stop-Timer)]"
	
	If ($oCollection -ne $null)
	{
		ForEach ($oAppPool in $oCollection)
		{
			$sManagedPipelineMode = ''
			switch ($($oAppPool.ManagedPipelineMode)) 
			{
				0 {$sManagedPipelineMode = 'Integrated'}
				1 {$sManagedPipelineMode = 'Classic'}
				default {$sManagedPipelineMode = 'Unknown'}
			}
			
			If ($($oAppPool.Failure.RapidFailProtectionInterval) -ne $null)
			{
				$dRapidFailProtectionInterval = Convert-WmiTimeSpan -WmiDateTime $($oAppPool.Failure.RapidFailProtectionInterval)
			}
			Else
			{
				$dRapidFailProtectionInterval = New-TimeSpan
			}
			
			$sIdentity = ''
			switch ($($oAppPool.ProcessModel.IdentityType)) 
			{
				0 {$sIdentity = 'LocalSystem'}
				1 {$sIdentity = 'LocalService'}
				2 {$sIdentity = 'NetworkService'}
				3 {$sIdentity = $oAppPool.ProcessModel.UserName}
				4 {$sIdentity = 'ApplicationPoolIdentity'}
				default {$sIdentity = 'Unknown'}
			}
						
			If ($($oAppPool.ProcessModel.IdleTimeout) -ne $null)
			{
				$dIdleTimeout = Convert-WmiTimeSpan -WmiDateTime $($oAppPool.ProcessModel.IdleTimeout)
			}
			Else
			{
				$dIdleTimeout = New-TimeSpan
			}
			
			If ($($oAppPool.Recycling.PeriodicRestart.Requests.Schedule) -ne $null)
			{
				$sSchedule = [string]::Join(',',$oAppPool.Recycling.PeriodicRestart.Requests.Schedule)
			}
			Else
			{
				$sSchedule = ''
			}
			
			If ($($oAppPool.Recycling.PeriodicRestart.Requests.Time) -ne $null)
			{
				$dRestartEvery = Convert-WmiTimeSpan -WmiDateTime $($oAppPool.Recycling.PeriodicRestart.Requests.Time)
			}
			Else
			{
				$dRestartEvery = New-TimeSpan
			}
			
			$oObject = New-Object pscustomobject
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $([string] $sComputer)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Name' -Value $([string] $oAppPool.Name)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'CpuLimit' -Value $([int] $oAppPool.Cpu.Limit)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Enable32Bit' -Value $([bool] $oAppPool.Enable32BitAppOnWin64)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'PipelineMode' -Value $([string] $sManagedPipelineMode)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'ManagedVer' -Value $([string] $oAppPool.ManagedRuntimeVersion)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'PassAnonToken' -Value $([bool] $oAppPool.PassAnonymousToken)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'StartMode' -Value $([int] $oAppPool.StartMode)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'RapidFailProtection' -Value $([bool] $oAppPool.Failure.RapidFailProtection)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'RapidFailProtectionInterval' -Value $([System.TimeSpan] $dRapidFailProtectionInterval)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Identity' -Value $([string] $sIdentity)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'MaxProcesses' -Value $([uint32] $oAppPool.ProcessModel.MaxProcesses)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'IdleTimeout' -Value $([System.TimeSpan] $dIdleTimeout)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'LogEventOnRecycle' -Value $([int32] $oAppPool.Recycling.LogEventOnRecycle)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'RestartAtMemory' -Value $([uint32] $oAppPool.Recycling.PeriodicRestart.Memory)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'RestartAtPrivateMemory' -Value $([uint32] $oAppPool.Recycling.PeriodicRestart.PrivateMemory)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'RestartAtRequests' -Value $([uint32] $oAppPool.Recycling.PeriodicRestart.Requests)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'RestartSchedule' -Value $([string] $sSchedule)
			Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'RestartEvery' -Value $([System.TimeSpan] $dRestartEvery)
			$aObjects += @($oObject)
		}
	}
}
$aObjects | Format-Table -AutoSize
$aObjects | Export-Csv -Path '.\Get-ApplicationPoolConfiguration.csv' -NoTypeInformation
Write-Host 'Done!'
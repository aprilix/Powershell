<#
    .SYNOPSIS
    Gets the discretionary access control lists (DACLs) from the physical paths of IIS7 web sites and virtual directories and writes them to a comma separated file (CSV) for post-analysis such as auto-filter in Microsoft Excel.
    .DESCRIPTION
    Gets the discretionary access control lists (DACLs) from the physical paths of IIS7 web sites and virtual directories and writes them to a comma separated file (CSV) for post-analysis such as auto-filter in Microsoft Excel. This script requires remote WMI connectivity to all of the servers specified. WMI uses Remote Procedure Calls (RPC) which uses random network ports. The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-NtfsPermissionsOfIisContentToCsv.ps1 -Computers Web01;Web02;Web03
    This will gather the permissions from Web01, Web02, and Web03 using the credentials you are current logged in with. The output is written to .\Iis7NtfsPermissions.csv.
    .EXAMPLE
    .\Get-NtfsPermissionsOfIisContentToCsv.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the permissions from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt. The output is written to .\Iis7NtfsPermissions.csv.    
    .EXAMPLE
    .\Get-NtfsPermissionsOfIisContentToCsv.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator' -Password 'LetMeIn123' -OutputCsvFilePath 'C:\Iis7NtfsPermissions.csv'
    This will gather the permissions from Web01, Web02, and Web03 using the credentials passed in (optional) and write the output to C:\Iis7NtfsPermissions.csv. The default output location is the local directory. Avoid providing the password via command line. Consider omitting the password for a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Parameter OutputCsvFilePath
    The file path to a comma separated value (CSV) file to write the output to. If omitted, then .\Iis7NtfsPermissions.csv is used.
    .Notes
    Name: Get-NtfsPermissionsOfIisContentToCsv.ps1
    Author: Clint Huffman (clinth@microsoft.com)
    LastEdit: November 23rd, 2011
    Keywords: PowerShell, WMI, IIS7, security, NTFS
#>
param([string]$Computers="$env:computername")

#// Argument processing
$global:Computers = $Computers
$global:User = $User
$global:Password = $Password
$global:Recursive = $Recursive

Function ProcessArguments
{    
    $global:aComputers = $global:Computers.Split(';')
    If ($global:aComputers -isnot [System.String[]])
    {
        $global:aComputers = @($global:Computers)
    }
}

Function Multi-Execute
{
	param
	(
		[string] $ScriptFileDirectory,
		[string] $ScriptFileName,
		[System.Int32] $JobNumber,
		[string] $OutputFile
	)		
		
	#// Remove all of the jobs that might be running previously to this session.
	If ($(Get-Job) -ne $null)
	{
	    Remove-Job -Name * -Force
	}
	
	$global:aObjects = @()

	#cd 'IIS7\0101 NTFS Permissions (Content)'
	cd $ScriptFileDirectory
	$JobTracker = @{}
	$iCurrentJobsRunning = 0
	ForEach ($sComputer in $global:aComputers)
	{
		$sJobName = "$JobNumber_$sComputer"
		$oReturn = Start-Job -FilePath $ScriptFileName -ArgumentList $sComputer -Name $sJobName
		$iCurrentJobsRunning++
		$JobTracker.Add($oReturn.Id,$sJobName)
		Write-Host "`t[Started] $sJobName"
	}

	$bIsAllJobsNotDone = $true
	while ($iCurrentJobsRunning -gt 0)
	{
		$CollectionOfJobs = Get-Job
		foreach ($Job in $CollectionOfJobs)
		{
			Switch ($Job.State)
			{
				"Completed"
				{
					$JobReturn = Receive-Job $Job.id -ErrorAction SilentlyContinue
	                If ($JobReturn -ne $null)
	                {
						$global:aObjects += $JobReturn
						Write-Host "`t[Done] $sJobName"
						Remove-Job $Job.id
						$iCurrentJobsRunning--
	                }
				}
				
				"Failed"
				{
					Write-Host "`t[Failed] $sJobName"
					Remove-Job $Job.id
					$iCurrentJobsRunning--
				}
				
				Else
				{
					Write-Host "`t[$Job.State] $sJobName"
				}
			}
		}
		Start-Sleep -m 500
	}
	cd ..
	cd ..
	$global:aObjects | Export-Csv -Path $OutputFile -NoTypeInformation	
}

ProcessArguments
Multi-Execute -ScriptFileDirectory 'IIS7\0101 NTFS Permissions (Content)' -ScriptFileName 'Get-NtfsPermissionsOfIisContentAsObject.ps1' -JobNumber '0101' -OutputFile 'Get-NtfsPermissionsOfIisContent.csv'

break;
cd 'IIS7'
cd '0101 NTFS Permissions (Content)'
.\Get-NtfsPermissionsOfIisContent.ps1 -Computers $Computers
cd ..
cd ..

cd 'IIS7'
cd '0102 NTFS Permissions (IIS Folders)'
.\Get-NtfsPermissionsOfIisFolders.ps1 -Computers $Computers
cd ..
cd ..

cd 'IIS7'
cd '0103 Handler Access and Lockdown'
.\Get-HandlerAccess.ps1 -Computers $Computers
cd ..
cd ..

cd 'IIS7'
cd '0104 Request Filtering'
.\Get-RequestFiltering.ps1 -Computers $Computers
cd ..
cd ..

cd 'IIS7'
cd '0105 Service Lockdown Settings'
.\Get-ServiceLockdownSettings.ps1 -Computers $Computers
cd ..
cd ..

Write-Host 'Done!'
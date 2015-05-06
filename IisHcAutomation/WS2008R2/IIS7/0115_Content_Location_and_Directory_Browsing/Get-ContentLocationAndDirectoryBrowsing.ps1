<#
    .SYNOPSIS
    Gets the handler access settings for all web sites and virtual directories for all IIS7 servers and counts the number of files that have that extension.
    .DESCRIPTION
    Gets the handler access settings for all web sites and virtual directories for all IIS7 servers and counts the number of files that have that extension. This scripts uses the root\WebAdministration WMI namespace. Requires administrator rights on the target server(s). The WMI connections are encrypted when possible.
    .EXAMPLE
    .\Get-ContentLocationAndDirectoryBrowsing.ps1 -Computers Web01;Web02;Web03
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you are current logged in with.
    .EXAMPLE
    .\Get-ContentLocationAndDirectoryBrowsing.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator'
    This will gather the WMI data from Web01, Web02, and Web03 using the credentials you specified. This is the recommended way to use different credentials because this will prompt you for a password using a secure prompt.
    .EXAMPLE
    .\Get-ContentLocationAndDirectoryBrowsing.ps1 -Computers Web01;Web02;Web03 -User 'contoso\administrator' -Password 'LetMeIn123'
    Enables all of the W3C logging fields on all web sites from Web01, Web02, and Web03 using the credentials passed in (optional). The default output location is the local directory. Avoid providing the password via command line. Consider omitting the password for a secure prompt.
    .Parameter Computers
    This parameters requires a string of computer names separated by semi-colons (;) or a single computer name. If omitted, then the local computer name is used.
    .Parameter User
    A user account that has administrator privileges to all of the target computers. If omitted, then your currently logged in credentials are used. You cannot change your credentials when targeting the local computer.
    .Parameter Password
    The password of the user account specified. If a user account is specified, then a password is required. You can specify the password as a string argument to this script or omit the password to get a secure prompt.
    .Notes
    Name: Get-ContentLocationAndDirectoryBrowsing.ps1
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

Function Convert-IisHandlerRequiredAccessToStringArray
{
    param([System.Int32] $Mask)
	[System.Int32] $ACCESS_READ = 1
	[System.Int32] $ACCESS_WRITE = 2
	[System.Int32] $ACCESS_SCRIPT = 3
	[System.Int32] $ACCESS_EXECUTE = 4
	If ($Mask -eq 0){Return 'None'}
	If ($Mask -eq $ACCESS_READ){Return 'Read'}
	If ($Mask -eq $ACCESS_WRITE){Return 'Write'}
	If ($Mask -eq $ACCESS_SCRIPT){Return 'Script'}
	If ($Mask -eq $ACCESS_EXECUTE){Return 'Execute'}
	If ($Mask -gt $ACCESS_EXECUTE){Return "$Mask"}
}

Function Convert-IISAccessPolicyMaskToStringArray
{
    param([System.Int32] $Mask)
	
	If ($Mask -eq 0){Return 'None'}
	
    #// Constants used for security bit mask
	[System.Int32] $ACCESS_READ = 1
	[System.Int32] $ACCESS_WRITE = 2
	[System.Int32] $ACCESS_EXECUTE = 4
	[System.Int32] $ACCESS_SOURCE = 16
	[System.Int32] $ACCESS_SCRIPT = 512
	[System.Int32] $ACCESS_NOREMOTEWRITE = 1024
	[System.Int32] $ACCESS_NOREMOTEREAD = 4096
	[System.Int32] $ACCESS_NOREMOTEEXECUTE = 8192
	[System.Int32] $ACCESS_NOREMOTESCRIPT = 16384
	$aResult = @()
	If ($Mask -band $ACCESS_READ){$aResult += @('Read')}
	If ($Mask -band $ACCESS_WRITE){$aResult += @('Write')}
	If ($Mask -band $ACCESS_SCRIPT){$aResult += @('Script')}	
	If ($Mask -band $ACCESS_EXECUTE){$aResult += @('Execute')}
	If ($Mask -band $ACCESS_SOURCE){$aResult += @('Source')}
	If ($Mask -band $ACCESS_NOREMOTEWRITE){$aResult += @('NoRemoteWrite')}
	If ($Mask -band $ACCESS_NOREMOTEREAD){$aResult += @('NoRemoteRead')}
	If ($Mask -band $ACCESS_NOREMOTEEXECUTE){$aResult += @('NoRemoteExecute')}
	If ($Mask -band $ACCESS_NOREMOTESCRIPT){$aResult += @('NoRemoteScript')}	
	$aResult
}

$global:LastComputerEnvCollected = ''
Function Expand-EnvironmentVariables
{
    param([string] $Computer,[string] $String)
    $String = $String.ToLower()
    $sWql = 'SELECT Name, VariableValue FROM Win32_Environment'
    If ($global:LastComputerEnvCollected -ne $Computer)
    {
        #$dBeginTime = Get-Date
        #Write-Host "Getting environment variables from $Computer..." -NoNewline
        $global:oCollectionOfEnvironmentVariables = Get-WmiQuery -Query $sWql -Computer $Computer
        #Write-Host "Done! [$dDuration]"
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

Function Get-PhysicalPathFromAppHost
{
	param([string] $Computer,[string] $AppHostPath)
	$aAppHostPath = $AppHostPath.Split('/')
	$u = $aAppHostPath.GetUpperBound(0)
	[string] $sWebSite = 'Default Web Site'
	If ($u -gt 2)
	{
		[string] $sWebSite = $aAppHostPath[3]
	}
	
	[string] $sVDirPath = '/'
	If ($u -gt 3)
	{
		$sVDirPath = $sVDirPath + $([string]::Join('/',$($aAppHostPath[4..$u])))
	}
	$sQuery = "SELECT * FROM VirtualDirectory WHERE SiteName = '$sWebSite' AND Path = '$sVDirPath'"
	$oCollection = Get-WmiQuery -Namespace 'root\WebAdministration' -Query $sQuery -Computer $Computer
	ForEach ($oInstance in $oCollection)
	{
		$oInstance.PhysicalPath
	}
}

Function Get-SubDirectories
{
    param($Computer,$Path,$Recursive=$False)
    #// This function gets all of the sub directories of a given path.
    If (($Path -ne $null) -and ($Path -ne ''))
    {        
        $Path = $Path.ToLower()
        $DoubleBackslashPath = $Path.Replace('\','\\') #// WMI uses backslashes for escape sequences.
        $sWql = 'ASSOCIATORS OF {Win32_Directory.Name="' + $DoubleBackslashPath + '"} WHERE ResultClass = Win32_Directory'
        $oCollectionOfDirectories = Get-WmiQuery -Query $sWql -Computer $Computer
        ForEach ($oDirectory in $oCollectionOfDirectories)
        {            
            $sDirectoryPath = $($oDirectory.Name).ToLower()            
            If (($($sDirectoryPath.IndexOf($Path)) -ge 0) -and ($sDirectoryPath -ne $Path))
            {
                $bFound = $False
                ForEach ($sSubDirectory in $global:alSubDirectoriesForGetSubDirectories)
                {
                    If ($sSubDirectory -eq $sDirectoryPath)
                    {
                        $bFound = $True
                    }
                }
                If ($bFound -eq $False)
                {
                    $sDirectoryPath
                    If ($Recursive -eq $True)
                    {
                        Get-SubDirectories -Computer $Computer -Path $sDirectoryPath -Recursive $True
                    }                    
                }
            }
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

Function Get-FilesFromAppHostPath
{
	param([string] $Computer,[string] $AppHostPath)
	$aFiles = @()
	$sPhysicalFilePath = Get-PhysicalPathFromAppHost -AppHostPath $AppHostPath -Computer $Computer
	$sPhysicalFilePath = Expand-EnvironmentVariables -Computer $Computer -String $sPhysicalFilePath
    $DoubleBackslashPath = $sPhysicalFilePath.Replace('\','\\') #// WMI uses backslashes for escape sequences.
	$sWql = 'ASSOCIATORS OF {Win32_Directory.Name="' + "$DoubleBackslashPath" + '"} WHERE ResultClass = CIM_DataFile'
	$oCollection = Get-WmiQuery -Namespace 'root\cimv2' -Query $sWql -Computer $Computer
	ForEach ($oInstance in $oCollection)
	{
		$aFiles += $oInstance
	}
	$aSubDirectories = Get-SubDirectories -Computer $sComputer -Path $sPhysicalFilePath -Recursive $True
	ForEach ($sDirectory in $aSubDirectories)
	{
		If ($sDirectory -ne $null)
		{
		    $DoubleBackslashPath = $sDirectory.Replace('\','\\') #// WMI uses backslashes for escape sequences.
			$sWql = 'ASSOCIATORS OF {Win32_Directory.Name="' + "$DoubleBackslashPath" + '"} WHERE ResultClass = CIM_DataFile'
			$oCollection = Get-WmiQuery -Namespace 'root\cimv2' -Query $sWql -Computer $Computer
			ForEach ($oInstance in $oCollection)
			{
				$aFiles += $oInstance
			}
		}
	}
	$aFiles
}

ProcessArguments
$aObjects = @()
ForEach ($sComputer in $global:aComputers)
{
	Write-Host "Getting data from $sComputer..." -NoNewline; Start-Timer
	$oCollection = Get-WmiQuery -Namespace 'root\WebAdministration' -Query 'SELECT * FROM DirectoryBrowseSection' -Computer $sComputer
    Write-Host "Done! [$(Stop-Timer)]"
	
	ForEach ($oInstance in $oCollection)
	{
		If ($($oInstance.Path) -ne $null)
		{
			$sPath = [string] $($oInstance.Path).Replace('MACHINE/WEBROOT/APPHOST/','')
			$sPath = [string] $sPath.Replace('MACHINE/WEBROOT/APPHOST','/')		
		}

		[string] $sPhysicalFilePath = Get-PhysicalPathFromAppHost -AppHostPath $($oInstance.Path) -Computer $sComputer
		[string] $sPhysicalFilePath = Expand-EnvironmentVariables -Computer $sComputer -String $sPhysicalFilePath
		[string] $sSystemDrive = Expand-EnvironmentVariables -Computer $sComputer -String '%systemdrive%'
		[bool] $IsOnSystemDrive = $($sPhysicalFilePath.ToLower()).Contains($($sSystemDrive.ToLower()))
		
		$oObject = New-Object pscustomobject
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $([string] $sComputer)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Path' -Value $([string] $sPath)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'DirBrowseEnabled' -Value $([bool] $oInstance.Enabled)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'SystemDrive' -Value $([string] $sSystemDrive)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'ContentOnSystemDrive' -Value $([bool] $IsOnSystemDrive)
		Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'PhysicalFilePath' -Value $([string] $sPhysicalFilePath)
		$aObjects += @($oObject)
	}
}
$aObjects | Format-Table -AutoSize
$aObjects | Export-Csv -Path '.\Get-ContentLocationAndDirectoryBrowsing.csv' -NoTypeInformation
Write-Host 'Done!'
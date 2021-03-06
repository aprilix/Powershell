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
param([string]$Computers="$env:computername",[string]$User='',[string]$Password='',[string]$OutputCsvFilePath="$(Split-Path -parent $MyInvocation.MyCommand.Definition)\Get-NtfsPermissionsOfIisContent.csv",[bool] $Recursive = $false)

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

Function WriteTo-Csv
{
    param($Line)
    $Line | Out-File -FilePath $global:oOutputFile -Encoding 'ASCII' -Append
}

Function Get-WmiQuery
{
    param($Namespace='root\cimv2',$Query,$Computer)
    
    If ($global:User -ne '')
    {
        Get-WmiObject -Namespace $Namespace -Query $Query -ComputerName $Computer -Authentication 6 -Credential $global:oCredential
    }
    Else
    {
        Get-WmiObject -Namespace $Namespace -Query $Query -ComputerName $Computer -Authentication 6
    }
}

Function Get-WmiIis7Query
{
    param($Namespace='root\WebAdministration',$Query,$Computer)
    Get-WmiQuery -Namespace 'root\WebAdministration' -Query $Query -Computer $Computer
}

$global:LastComputerEnvCollected = ''

Function Expand-EnvironmentVariables
{
    param($Computer,$String)
    $String = $String.ToLower()
    $sWql = 'SELECT Name, VariableValue FROM Win32_Environment'
    If ($global:LastComputerEnvCollected -ne $Computer)
    {
        $dBeginTime = Get-Date
        Write-Host "Getting environment variables from $Computer..." -NoNewline
        $global:oCollectionOfEnvironmentVariables = Get-WmiQuery -Query $sWql -Computer $Computer
        $dDuration = Stop-Timer -BeginTime $dBeginTime
        Write-Host "Done! [$dDuration]"
    }
    ForEach ($oEnv in $global:oCollectionOfEnvironmentVariables)
    {
		If ($oEnv -ne $null)
		{
	        $sEnv = '%' + "$($oEnv.Name)" + '%'
	        $sValue = "$($oEnv.VariableValue)"
	        $String = $String.Replace($sEnv,$sValue)
		}
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
			If ($($oDirectory.Name) -ne $null)
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
	                        Get-SubDirectories -Computer $Computer -Path $sDirectoryPath -Recursive $Recursive
	                    }                    
	                }
	            }
			}
        }
    }
}

Function Get-NtfsPermissions
{
    param($Computer,$Path)
    If (($Path -ne $null) -and ($Path -ne ''))
    {
        $DoubleBackslashPath = $Path.Replace('\','\\') #// WMI uses backslashes for escape sequences.
        $sFilter = 'Path="' + "$($DoubleBackslashPath)" + '"'
        If ($global:User -ne '')
        {
            $oSecurity = Get-WmiObject Win32_LogicalFileSecuritySetting -filter $sFilter -Computer $Computer -Credential $global:oCredential
        }
        Else
        {
            $oSecurity = Get-WmiObject Win32_LogicalFileSecuritySetting -filter $sFilter -Computer $Computer
        }
        $oSecurityDescriptor = $oSecurity.GetSecurityDescriptor()
        $oDacl = $oSecurityDescriptor.Descriptor["DACL"]
        $oDacl
    }
}

Function Convert-AccessMask
{
    param($Mask)
    #// Constants used for security bit mask
    $FILE_LIST_DIRECTORY = 1 #FILE_READ_DATA (file) or FILE_LIST_DIRECTORY (directory). Grants the right to read data from the file. For a directory, the right to list the contents of the directory
    $FILE_ADD_FILE = 2 #FILE_WRITE_DATA (file) or FILE_ADD_FILE (directory). Grants the right to write data to the file. For a directory, the right to create a file in the directory.
    $FILE_ADD_SUBDIRECTORY = 4 #FILE_APPEND_DATA (file) or FILE_ADD_SUBDIRECTORY (directory). Grants the right to append data to the file. For a directory, the right to create a subdirectory
    $FILE_READ_EA = 8 #Grants the right to read extended attributes.    
    $FILE_WRITE_EA = 16 #Grants the right to write extended attributes.
    $FILE_TRAVERSE = 32 #Grants the right to execute a file. For a directory, the directory can be traversed.
    $FILE_DELETE_CHILD = 64 #Right to delete a directory and all the files it contains (its children), even if the files are read-only.
    $FILE_READ_ATTRIBUTES = 128 #Grants the right to read file attributes.
    $FILE_WRITE_ATTRIBUTES = 256 #Grants the right to change file attributes.
    $FILE_DELETE = 65536 #Grants delete access.
    $READ_CONTROL = 131072 #Grants read access to the security descriptor and owner.
    $WRITE_DAC = 262144 #Grants write access to the discretionary ACL.
    $WRITE_OWNER = 524288 #Used to assign write owner. 
    $FILE_SYNCHRONIZE = 1048576 # Used to synchronize access and to allow a process to wait for an object to enter the signaled state.
    
	$aPermsArray = @()    
    For ($i=0;$i -le 13;$i++)
    {
        $aPermsArray = $aPermsArray + 0
    }
	
	If ($Mask -band $FILE_LIST_DIRECTORY)
    { 
		$aPermsArray[0] = "FILE_LIST_DIRECTORY"
	}
	
	If ($Mask -band $FILE_ADD_FILE)
    {
		$aPermsArray[1] = "FILE_ADD_FILE"
	}
	
	If ($Mask -band $FILE_ADD_SUBDIRECTORY)
    {
		$aPermsArray[2] = "FILE_ADD_SUBDIRECTORY"
	}
	
	If ($Mask -band $FILE_READ_EA)
    {
		$aPermsArray[3] = "FILE_READ_EA"
	}
	
	If ($Mask -band $FILE_WRITE_EA)
    {
		$aPermsArray[4] = "FILE_WRITE_EA"
	}
    
    If ($Mask -band $FILE_TRAVERSE)
    {
		$aPermsArray[5] = "FILE_TRAVERSE"
	}
	
	If ($Mask -band $FILE_DELETE_CHILD)
    {
        $aPermsArray[6] = "FILE_DELETE_CHILD"
    }   
    
    If ($Mask -band $FILE_READ_ATTRIBUTES)
    {
    	$aPermsArray[7] = "FILE_READ_ATTRIBUTES"
    }
    
    If ($Mask -band $FILE_WRITE_ATTRIBUTES)
    {
    	$aPermsArray[8] = "FILE_WRITE_ATTRIBUTES"
    }                                              
    
    If ($Mask -band $FILE_DELETE)
    {
    	$aPermsArray[9] = "FILE_DELETE"
    }                                              
    
    If ($Mask -band $READ_CONTROL)
    {
    	$aPermsArray[10] = "READ_CONTROL"
    }                                              
    
    If ($Mask -band $WRITE_DAC)
    {
    	$aPermsArray[11] = "WRITE_DAC"
    }                                              
    
    If ($Mask -band $WRITE_OWNER)
    {
    	$aPermsArray[12] = "WRITE_OWNER"
    }                                              
    
    If ($Mask -band $FILE_SYNCHRONIZE)
    {
    	$aPermsArray[13] = "FILE_SYNCHRONIZE"
    }
    $aPermsArray 
}

Function Main
{
	
    $global:oOutputFile = New-Item -Path $OutputCsvFilePath -ItemType 'file' -Force
    WriteTo-Csv 'Computer,SiteName,VDirPath,PhysicalPath,UserDomain,UserAccount,Permission'
        

    ForEach ($sComputer in $global:aComputers)
    {
        Write-Host ''
        Write-Host "Computer: $sComputer"

        #// Enumerate each web site and virtual directory for file paths
        Start-Timer
        Write-Host "Getting VirtualDirectory data from $sComputer..." -NoNewline
        $oWmiCollectionOfVirtualDirectory = Get-WmiIis7Query -Namespace 'root\WebAdministration' -Query 'SELECT * FROM VirtualDirectory' -Computer $sComputer | SELECT SiteName, Path, ApplicationPath, PhysicalPath
        $dDuration = Stop-Timer
        Write-Host "Done! [$dDuration]"
        ForEach ($oVDir in $oWmiCollectionOfVirtualDirectory)
        {
	    $global:aObjects = @()
            $alDirectories = New-Object System.Collections.ArrayList
            $Path = Expand-EnvironmentVariables -Computer $sComputer -String $($oVDir.PhysicalPath)
            $Path = $Path.ToLower()
            $sVDirPath = Expand-EnvironmentVariables -Computer $sComputer -String $($oVDir.Path)
            $sDisplayWebPath = "$($oVDir.SiteName)" + "$sVDirPath"
            Write-Host $sDisplayWebPath
            #Write-Host "`t$Path"
            
            [void] $alDirectories.Add($Path)

			If ($global:Recursive -eq $True)
			{
                Write-Host "`tGetting subdirectories of $Path..." -NoNewline
                Start-Timer				
				$global:alSubDirectoriesForGetSubDirectories = New-Object System.Collections.ArrayList
            	$alSubDirectories = Get-SubDirectories -Computer $sComputer -Path $Path -Recursive $global:Recursive
                $dDuration = Stop-Timer
                Write-Host "Done! [$dDuration]"
                ForEach ($sSubDirectory in $alSubDirectories)
                {
                    [void] $alDirectories.Add($sSubDirectory)
                }					
			}
            
            #// Enumerate permissions on each directory                        
            ForEach ($sDirectory in $alDirectories)
            {
                If (($sDirectory -ne $null) -and ($sDirectory -ne ''))
                {
                    Start-Timer                    
                    Write-Host "`t$sDirectory..." -NoNewline
					If ($($sDirectory.Substring(0,2)) -eq '\\' )
					{
						$sSiteName = $oVdir.SiteName
						[string] $sLine = "$sComputer,$sSiteName,$sVDirPath,$Path,'','',''"
						WriteTo-Csv $sLine
						$oObject = New-Object pscustomobject
						#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $([string] $sComputer)
						#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'SiteName' -Value $([string] $oVdir.SiteName)
						#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'VDirPath' -Value $([string] $sVDirPath)
						#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'PhysicalPath' -Value $([string] $Path)
						#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'UserDomain' -Value ''
						#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'UserAccount' -Value ''
						#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Permission' -Value ''
						#$global:aObjects += @($oObject)					
					}
					Else
					{
	                    $oDacl = Get-NtfsPermissions -Computer $sComputer -Path $sDirectory
	                    #$iNumOfTrustees = $oDacl.Count            
	                    For ($k = 0;$k -lt $oDacl.Count;$k++)
	                    {
	                        $oAce = $oDacl[$k]
	                        $oTrustee = $oAce.Trustee
	                        $oSid = $oTrustee.SID
	                        
	                        For ($i = 0;$i -lt $oSid.Count;$i++)
	                        {
	                            $sSid = "$sSid" + "$oSid[$i]" + '-'
	                        }
	                        $sSid = "$sSid" + "$oSid[$($oSid.GetUpperBound(0))]"
	                        $sSid = '{' + "$sSid" + '}'
	                        
	                        $sTrustee = $oTrustee.Name
	                        $sDomain = $oTrustee.Domain
	                        $sAccessMask = $oAce.AccessMask
	                        
	                        $aPermissions = Convert-AccessMask -Mask $sAccessMask
	                        $sAceType = $oAce.AceType
	                        
	                        ForEach ($sPermission in $aPermissions)
	                        {
	                            If ($sPermission -ne 0)
	                            {
					$sSiteName = $oVdir.SiteName
						[string] $sLine = "$sComputer,$sSiteName,$sVDirPath,$Path,$sDomain,$sTrustee,$sPermission"
						WriteTo-Csv $sLine

									#$oObject = New-Object pscustomobject
									#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Computer' -Value $([string] $sComputer)
									#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'SiteName' -Value $([string] $oVdir.SiteName)
									#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'VDirPath' -Value $([string] $sVDirPath)
									#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'PhysicalPath' -Value $([string] $Path)
									#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'UserDomain' -Value $([string] $sDomain)
									#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'UserAccount' -Value $([string] $sTrustee)
									#Add-Member -InputObject $oObject -MemberType NoteProperty -Name 'Permission' -Value $([string] $sPermission)
									#$global:aObjects += @($oObject)
	                            }
	                        }
	                    }
					}
                    $dDuration = Stop-Timer
                    Write-Host "Done! [$dDuration]"
                }
            }
        }
	#$global:aObjects | Export-Csv -Path $global:oOutputFile -NoTypeInformation
	#$global:aObjects | Format-Table -AutoSize

    }
}

Start-GlobalTimer
ProcessArguments
Main
Stop-GlobalTimer











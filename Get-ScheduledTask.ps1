param(
	$computername = "localhost",
    [switch]$RootFolder
)

#region Functions
function Get-AllTaskSubFolders {
    [cmdletbinding()]
    param (
        # Set to use $Schedule as default parameter so it automatically list all files
        # For current schedule object if it exists.
        $FolderRef = $Schedule.getfolder("\")
    )
    if ($RootFolder) {
        $FolderRef
    } else {
        $FolderRef
        $ArrFolders = @()
        if(($folders = $folderRef.getfolders(1))) {
            foreach ($folder in $folders) {
                $ArrFolders += $folder
                if($folder.getfolders(1)) {
                    Get-AllTaskSubFolders -FolderRef $folder
                }
            }
        }
        $ArrFolders
    }
}
#endregion Functions


try {
	$schedule = new-object -com("Schedule.Service") 
} catch {
	Write-Warning "Schedule.Service COM Object not found, this script requires this object"
	return
}

$Schedule.connect($ComputerName) 
$AllFolders = Get-AllTaskSubFolders

foreach ($Folder in $AllFolders) {
    if (($Tasks = $Folder.GetTasks(0))) {
        $TASKS | % {[array]$results += $_}
        $Tasks | Foreach-Object {
	        New-Object -TypeName PSCustomObject -Property @{
	            'Name' = $_.name
                'Path' = $_.path
                'State' = $_.state
                'Enabled' = $_.enabled
                'LastRunTime' = $_.lastruntime
                'LastTaskResult' = $_.lasttaskresult
                'NumberOfMissedRuns' = $_.numberofmissedruns
                'NextRunTime' = $_.nextruntime
                'Author' =  ([xml]$_.xml).Task.RegistrationInfo.Author
                'UserId' = ([xml]$_.xml).Task.Principals.Principal.UserID
                'Description' = ([xml]$_.xml).Task.RegistrationInfo.Description
            }
        }
    }
} 
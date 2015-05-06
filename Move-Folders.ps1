Write-Host "Creating folders for moving build artifacts to CI location"
$buildlocation = "C:\StorePortal\StorePortal\*"
$cipath = "C:\ContiniousIntegration\StorePortal"
$Directory =  gci $cipath | sort LastWriteTime | select -last 1
$NewDirectory = New-Item -Name ([Int]$directory.Name + 1) -ItemType Directory -Path $cipath
Write-Host "Moving Files from build to CI location"
Move-Item -Path $buildlocation -Destination $NewDirectory -Include *
Write-Host "COmpleted"
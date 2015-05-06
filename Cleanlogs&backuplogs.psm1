function Cleanfiles{[string] $path, [string] $section, [string] $input)
Remove-item -Recurse -Path $path -include $files
}
function Backupfiles {
$destination = New-item -type directory C:\temp\$(get-date -f MM-dd-yyyy_HH_mm_ss).zip
Move-item -Recurse -Path $path -Destination $Destination -include $files  
}



function Encrypt-ConfigurationSection([int] $id, [string] $app, [string] $section, [string] $input) {
$currentDirectory = (Get-Location)
Set-Location "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\"
.\aspnet_regiis.exe -pe $section -app "/" -site $id -prov "RsaProtectedConfigurationProvider"
Set-Location $currentDirectory
}
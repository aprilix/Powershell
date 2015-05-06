function Encrypt-Config([string] $Section, [string] $Location) {
$currentDirectory = (Get-Location)
Set-Location "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\"
.\aspnet_regiis.exe -pef -Section $Section  -Location $Location -prov "RsaProtectedConfigurationProvider"
Set-Location $currentDirectory
}


function Decrypt-Config([int] $id, [string] $app, [string] $section, [string] $version){
$currentDirectory = (Get-Location)
Set-Location "C:\windows\Microsoft.Net\Framework\$version\"
.\aspnet_regiis.exe -pd $section -app $app -site $id
Set-Location $currentDirectory
}

function Encrypt-Config([int] $id, [string] $app, [string] $section, [string] $version){
$currentDirectory = (Get-Location)
import-module .\inputparam.ps1
Set-Location "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
.\aspnet_regiis.exe -pe -section $section  -app $app -site $id -prov "RsaProtectedConfigurationProvider"
Set-Location $currentDirectory
}

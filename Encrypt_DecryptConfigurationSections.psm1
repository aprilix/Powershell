function Encrypt-ConfigurationSection([int] $site, [string] $app, [string] $section ){
$currentDirectory = (Get-Location)
Set-Location "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
.\aspnet_regiis.exe -pef $section -app $app -site $id -prov "RsaProtectedConfigurationProvider"
Set-Location $currentDirectory
}
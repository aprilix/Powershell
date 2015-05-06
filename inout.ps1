function Encrypt-Config ([int] $site, [string] $app, [string] $section ){
$servers = (Get-Content .\serverlistDB.txt)
$currentDirectory = (Get-Location)
Set-Location "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
.\aspnet_regiis.exe -pe $section -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section1 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section2 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section3 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
Set-Location $currentDirectory
}

function Decrypt-Config ([int] $site, [string] $app, [string] $section){
$servers = (Get-Content .\serverlistDB.txt)
$currentDirectory = (Get-Location)
Set-Location "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
.\aspnet_regiis.exe -pd $section -app "/" -site $id 
.\aspnet_regiis.exe -pd $section1 -app "/" -site $id 
.\aspnet_regiis.exe -pd $section2 -app "/" -site $id 
.\aspnet_regiis.exe -pd $section3 -app "/" -site $id 
Set-Location $currentDirectory
}


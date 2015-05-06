$currentDirectory = (Get-Location)
Set-Location "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
.\aspnet_regiis.exe -pe $section -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section1 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section2 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section3 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
Set-Location $currentDirectory



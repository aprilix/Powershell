$path = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
set-location -path $path
.\aspnet_regiis.exe -pe $section -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section1 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section2 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section3 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
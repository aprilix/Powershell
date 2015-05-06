<#
.SYNOPSIS

We have 2 functions in this script.
1) Encrypt Config
2) Decrypt Config

The script will read the values from Input file ( Section to be encrypt, Site to be encrypted, etc )
It can be used either as a script or a module according to our convenience.

Open the PS window and navigate the script location and invoke, since the input path is hardcoded we have to make sure the input file is present on the same folder where the script is executed.
#>

$help = Get-Content "C:\Users\admins4v89kr\Desktop\Encrypt-Config.ps1" | Select-Object -First 12
function Encrypt-Config ([int] $site, [string] $app, [string] $section ){
import-module "C:\Users\admins4v89kr\Desktop\InputParamFile.ps1"
$currentDirectory = (Get-Location)
Set-Location "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
.\aspnet_regiis.exe -pe $section -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section1 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section2 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section3 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
Set-Location $currentDirectory
}

function Decrypt-Config ([int] $site, [string] $app, [string] $section){
import-module "C:\Users\admins4v89kr\Desktop\InputParamFile.ps1"
$currentDirectory = (Get-Location)
Set-Location "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
.\aspnet_regiis.exe -pd $section -app "/" -site $id 
.\aspnet_regiis.exe -pd $section1 -app "/" -site $id 
.\aspnet_regiis.exe -pd $section2 -app "/" -site $id 
.\aspnet_regiis.exe -pd $section3 -app "/" -site $id 
Set-Location $currentDirectory
}


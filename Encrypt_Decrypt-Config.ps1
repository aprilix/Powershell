<#
We have 2 functions in this script.
1) Encrypt Config
2) Decrypt Config

The script will read the values from Input file ( Section to be encrypt, Site to be encrypted, etc )
It can be used either as a script or a module according to our convenience.

Open the PS window and navigate the script location and invoke, since the input path is hardcoded we have to make sure the input file is present on the same folder where the script is executed.

Inputparam.ps1 includes the below parameters where we specify the values

1) Section = All the sections in the config which contain sensitive information which we want to encrypt ( sessionState,appSettings,connectionStrings,nlog )

2) ID = Site ID of the application we want to encrypt or decrypt.

3) app = since we specifically provide the site id, the app can be just a simple forward slash and the script will consider that as a virtual directory of the site where the config is present.
#>

$help = Get-Content ".\Encrypt_Decrypt-Config.ps1" | Select-Object -First 18
function Encrypt-Config ([int] $site, [string] $app, [string] $section ){
import-module ".\InputParamFile.ps1"
$currentDirectory = (Get-Location)
Set-Location "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
.\aspnet_regiis.exe -pe $section -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section1 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section2 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
.\aspnet_regiis.exe -pe $section3 -app $app -site $id -prov "RsaProtectedConfigurationProvider"
Set-Location $currentDirectory
}

function Decrypt-Config ([int] $site, [string] $app, [string] $section){
import-module ".\InputParamFile.ps1"
$currentDirectory = (Get-Location)
Set-Location "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
.\aspnet_regiis.exe -pd $section -app "/" -site $id 
.\aspnet_regiis.exe -pd $section1 -app "/" -site $id 
.\aspnet_regiis.exe -pd $section2 -app "/" -site $id 
.\aspnet_regiis.exe -pd $section3 -app "/" -site $id 
Set-Location $currentDirectory
}
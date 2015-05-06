function Encrypt-ConfigurationSection{ Param([parameter(Mandatory=$true,
HelpMessage="Path to file")]
$path)
Set-Location "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
.\aspnet_regiis.exe -pef $section $path 
}

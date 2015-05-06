Function Compare-Code(
[String]$source,
[String]$destination){
$Src =  gci $source -Recurse | foreach { Get-FileHash -Path $_.FullName} | ft Hash 
$Dst =  gci $destination -Recurse | foreach { Get-FileHash -Path $_.FullName} | ft Hash
$Src > C:\Src.txt
$Dst > C:\Dst.txt
if((Compare-Object -ReferenceObject (gc C:\Src.txt) -DifferenceObject (gc C:\Dst.txt) ) -ne $null) {Write-Warning "Hashvalue comparison indicates different values and code is not in sync, please double check and rerun the script"}
Else {Write-Host "Hashvalue comparison for all the files is completed, Code sync successfull"! -ForegroundColor Green}
}
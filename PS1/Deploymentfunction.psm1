Function Code-Deploy(
[String]$servers,
[String]$application,
[String]$Publishedpath
){
$srvrs = gc $servers
Foreach ($srv in $srvrs)
 {   
    Write-Host "Cleanup & Recreate $application directories and deploying code on $srv"
	$removepath = (join-path \\ -childpath (Join-Path -path $srv -ChildPath \C$\hostedsites\$application))
	if (!(test-path -path $removepath)) { Write-Host "."  -ForegroundColor Green }
	else { Remove-Item -Path $removepath -Force -Recurse }
	New-Item -Path (join-path \\ -childpath (Join-Path -path $srv -ChildPath \C$\hostedsites)) -ItemType Directory -Name $application
	Copy-Item -Path $Publishedpath -Destination (join-path \\ -childpath (Join-Path -path $srv -ChildPath \C$\hostedsites\$application\))
 }
}
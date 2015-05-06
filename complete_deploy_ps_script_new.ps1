Param(

[String]$application,

[String]$buildnumber,

[String]$environment

)

 

$Publishedpath = "D:\Builds\$application\$buildnumber\_PublishedWebsites\$application"

$artifactorypath = "D:\Builds\$application\$buildnumber"

$srvrs = get-content "C:\servers_$environment.txt"

 

#Disk Space check

foreach($srv in $srvrs) {

       $Object = Get-WmiObject -ComputerName $srv -Class Win32_logicalDisk | Where-Object { $_.DeviceID -eq "C:" } | Select DeviceID, FreeSpace;

       If ($Object.FreeSpace -lt "20033212400")

       {

              Write-Warning "LOW DISK SPACE on $srv , Clear some disk space and rerun the job"

              Break

       }

       Else

       { Write-Host "Disk Space check completed on server $srv" -ForegroundColor Green }

}

 

#check build package

if (!(Test-Path $artifactorypath))

{

       Write-Warning "$buildnumber package doesn't exist in server artifactory"

       Break

}

Else

{ Write-Host Check build package step completed "$buildnumber package exists in server artifactory" -ForegroundColor Green }

 

#IIS and service stop

Foreach ($srv in $srvrs)

{

       IISRESET /Stop $srv

       Write-host "IIS Stopped on $srv" -ForegroundColor Yellow

}

 

#Backup old code and clean up folders

$session = New-PSSession -ComputerName $srvrs

$foldername = Get-Date -Format 'yyyyMMddhhmm'

if($srvrs.Count -cgt "1"){

$backuppath = join-Path -Path \\ -ChildPath (Join-Path -Path $Srvrs.Get(0) -ChildPath \c$\HostedSites\$application)

if (!(test-path $backuppath)) 

{ Write-Host  "BACKUP failed since the $application folder is missing on "$Srvrs.Get(0)" " -ForegroundColor Yellow }

else

 {

       Rename-Item $backuppath -NewName "BACKUP$application$foldername" -Force

       Move-Item -path (join-path \\ -childpath (Join-Path -path $Srvrs.Get(0) -ChildPath \C$\hostedsites\BACKUP$application$foldername)) -Destination (join-path \\ -childpath (Join-Path -path $Srvrs.Get(0) -ChildPath \C$\BACKUP)) -Force

       Write-host "BACKUP for $application is completed and renamed as BACKUP$application$foldername and moved to C:\BACKUP archive on "$Srvrs.Get(0)" " -ForegroundColor Green

 }

}

Else{

$backuppath = join-Path -Path \\ -ChildPath (Join-Path -Path $Srvrs -ChildPath \c$\HostedSites\$application)

Rename-Item $backuppath -NewName "BACKUP$application$foldername" -Force

Move-Item -path (join-path \\ -childpath (Join-Path -path $Srvrs -ChildPath \C$\hostedsites\BACKUP$application$foldername)) -Destination (join-path \\ -childpath (Join-Path -path $Srvrs -ChildPath \C$\BACKUP)) -Force

Write-host "BACKUP for $application is completed and renamed as BACKUP$application$foldername and moved to C:\BACKUP archive on "$Srvrs" " -ForegroundColor Green

}

 

#Recreate folders and copy code

Foreach ($srv in $srvrs)

{   

    Write-Host "Cleanup and deploy $application code on $srv"

       $removepath = (join-path \\ -childpath (Join-Path -path $srv -ChildPath \C$\hostedsites\$application))

       if (!(test-path -path $removepath)) { Write-Host "."  -ForegroundColor Green }

       else { Remove-Item -Path $removepath -Force -Recurse }

       Copy-Item -Path $Publishedpath -Recurse -Destination (join-path \\ -childpath (Join-Path -path $srv -ChildPath \C$\hostedsites\ ))

}

 

#compare the code sync between build server and deployed server

$source = $publishedpath

if($srvrs.Count -cgt "1"){

$destination = (join-path \\ -childpath (Join-Path -path $Srvrs.Get(0) -ChildPath \C$\hostedsites\$application\))

$Src =  gci $source -Recurse | foreach { Get-FileHash -Path $_.FullName} | ft Hash 

$Dst =  gci $destination -Recurse | foreach { Get-FileHash -Path $_.FullName} | ft Hash

$Src > C:\Src.txt

$Dst > C:\Dst.txt

if((Compare-Object -ReferenceObject (gc C:\Src.txt) -DifferenceObject (gc C:\Dst.txt)) -ne $null) 

{

      Write-Warning "Hashvalue comparison indicates different values and code is not in sync, please double check and rerun the script" 

      Break

} 

Else {Write-Host "Hashvalue comparison for all the files is completed, Code sync successfull"! -ForegroundColor Green}

}

Else{

$destination = (join-path \\ -childpath (Join-Path -path $Srvrs -ChildPath \C$\hostedsites\$application\))

$Src =  gci $source -Recurse | foreach { Get-FileHash -Path $_.FullName} | ft Hash 

$Dst =  gci $destination -Recurse | foreach { Get-FileHash -Path $_.FullName} | ft Hash

$Src > C:\Src.txt

$Dst > C:\Dst.txt

if((Compare-Object -ReferenceObject (gc C:\Src.txt) -DifferenceObject (gc C:\Dst.txt)) -ne $null) 

{

      Write-Warning "Hashvalue comparison indicates different values and code is not in sync, please double check and rerun the script" 

      Break

} 

Else {Write-Host "Hashvalue comparison for all the files is completed, Code sync successfull"! -ForegroundColor Green}

}

 
#RENAME WEB.CONFIG FILE

Foreach ($srv in $srvrs){

Write-Host "Renaming Web_$environment.config to Web.config on $srv"

Rename-Item –Path (join-path \\ -childpath (Join-Path -path $srv -ChildPath \C$\hostedsites\$application\Web_$environment.config )) -NewName Web.config }

 
#IIS START

Foreach ($srv in $srvrs)

{

       IISRESET /Start $srv

       Write-host "IIS Started on $srv" -ForegroundColor Green

}

 
#Validate endpoint URL response code and confirm success or failure

Write-Host Validating endpoint URL response

$requesturlarray = @( "http://server1/Login.aspx", "http://server2/Login.aspx", "http://server3/Login.aspx")

foreach ($i in $requesturlarray ){

Try {$response = Invoke-WebRequest -Uri $i}

Catch

{Write-Warning "Application indicates error on $i"}

}

Write-Host "If you noticed any warnings above, Please look at the URL to identify if its server specific or applicable at application level"

 

#Create Build number file

$date = Get-Date

$output = "$application is running under $buildnumber version and deployed on $date"

$output > "C:\temp\buildnumber.htm"

Foreach ($srv in $srvrs)

{

       Copy-Item -Path "C:\temp\buildnumber.htm" -Destination (join-path \\ -childpath (Join-Path -path $srv -ChildPath \C$\hostedsites\$application\))

}

    Write-Host "$buildnumber for $application application is deployed to $srvrs and buildnumber.html file inside site root directory includes details about time and version of deployment" -ForegroundColor Green  
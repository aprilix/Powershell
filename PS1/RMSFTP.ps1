Param(
[parameter(Mandatory = $TRUE)]
$StoreID
)
Start-Transcript -Path C:\Log.txt
$Source = "C:\StoreDataTEST\RMSFTP\"
$Destination = "C:\StoreData\RMSFTP\"
$foldernamearray = @("DailyCartrk","Dailyplu","DailyRECSTR","Dailysprom","FullCartrk","FULLPLU","FULLRECSTR","Fullsprom","Mixmatch","PODownload","SCNBOLI")
foreach ($item in $foldernamearray){
$StoreNumber = Get-ChildItem -Path ($source + $item ) | Where-Object {$_.Name -clike "*$StoreID*"}
If (Test-Path -Path ($Source + $item + "\" + $StoreNumber ) -PathType Leaf ){
Copy-Item -Path (Join-Path -Path $Source$item (Join-Path -Path "\" -ChildPath "$StoreNumber")) -Destination (Join-Path -Path $Destination$item (Join-Path -Path "\" -ChildPath "$StoreNumber" )) -Recurse -Force
Write-Host "Copied $StoreNumber to $destination$item successfully" -ForegroundColor Green
}
Else {Write-Warning "File with StoreID $StoreID doesn't exist in $Source$item"}
}
Stop-Transcript
$requesturlarray = gc .\URL.txt
foreach ($i in $requesturlarray ){
Try 
{$response = Invoke-WebRequest -Uri $i} 
Catch
{Write-Warning "Application indicates error on $i"}
} Write-Host
" 1) If you find any errors above, please note the URL's to isolate if issue is server specific or application specific.
 2) If not, Feel Happy !
"
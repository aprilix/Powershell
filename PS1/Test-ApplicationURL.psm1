Function Test-ApplicationURL(){
$requesturlarray = gc "C:\Users\SVARMA\Desktop\URL.txt"
foreach ($i in $requesturlarray)
{
	Try { $response = Invoke-WebRequest -Uri $i }
	Catch
	{ Write-Warning "Application indicates error on $i" }
}
Write-Host "If you dint see any WARNING above, it means all the endpoints are validated with a 200 - OK response. Else the output will include the specific endpoints which are down"
}
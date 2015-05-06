$id = "3"
$website = Get-Website | Where-Object {$_.ID -eq "$id"}
$source = $website.physicalPath + "\" + "web.config"
$servers = "vlpmqa2", "vlwinpatchdev" 
$destination = "\\$server" + "\HostedSites\" + $website.name
foreach ( $Server in $Servers ) {copy-item -path $source  -Destination $destination -PassThru }
Function ExecutionPlan (
[string]$username,
[string]$password){
$pg = Invoke-WebRequest https://server1.com -SessionVariable svb
$svb 
$pg.Forms
$db = $pg.Forms
$db.Fields
$db.Fields["username01"]="$username"
$db.Fields["password01"]="$password"
$pgr = Invoke-WebRequest -Uri ("https://server1.com" +$db.action) -WebSession $svb -Method Post -Body $db.Fields
$pgr
}
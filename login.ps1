$pg = Invoke-WebRequest https://community.birst.com -SessionVariable svb
$svb 
$pg.Forms
$db = $pg.Forms
$db.Fields
$db.Fields["username01"]="Sjampana@birst.com"
$db.Fields["password01"]="Subbaraju9"
$pgr = Invoke-WebRequest -Uri ("https://community.birst.com/cs_login") -WebSession $svb -Method Post -Body $db.Fields
$pgr
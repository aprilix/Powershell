try {
    $w = New-Object net.WebClient
    $d = $w.downloadString('http://foo')
}
catch [Net.WebException] {
    Write-Host $_.Exception.ToString()
}


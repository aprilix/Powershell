$servers = (Get-Content .\servers.txt)
Invoke-Command -ComputerName $servers -ScriptBlock {set-executionpolicy remotesigned -force Configure-SMRemoting.ps1 -enable -force } > outputremoting.txt

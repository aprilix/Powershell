Param
([String]$servers)
$srvrs = gc $servers
$srvrs | foreach { systeminfo.exe /s $_ | findstr /c:"OS Version" /c:"Host Name" /c:"OS Name" /c:"System Type" /C:"Processor(s)" /c:"Total Physical Memory" /c:"Available Physical Memory" /c:"Virtual Memory: Max Size:" }
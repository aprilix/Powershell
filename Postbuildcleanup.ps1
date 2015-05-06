$Publishedpath =  gci C:\CVVPart\OFOS\* | sort LastWriteTime | select -last 1
cd $Publishedpath
Remove-Item -Include * -Exclude *publishedwebsites*

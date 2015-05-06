'=========================================================
' IIS Log Parsing Script for IISHC. v.1.1
'				scripted by Joon Choi, PFE
'               reviewed by Clint Huffman, PFE
'               reviewed by Mamta Shah, PFE
'=========================================================

'=========================================================
' Updated by ClintH on 9/26/2007
'=========================================================

Dim g_objShell

Dim g_TimeFrom
Dim g_TimeTo
Dim g_DateFrom
Dim g_DateTo
Dim g_UsePeriod 

Dim g_strFileName
Dim g_strHTML
Dim g_width
Dim g_LogFileName

Dim g_DateTimeStamp
Dim g_DateReport 
Dim i
Dim strCommand
Dim strQuery
Dim g_arrQuery(17)

'==============================================================
' Added by ClintH
' This section will copy all of the *.log files from one
' directory below this directory to this direcotry and
' renames the file to be similar to this ex060808.log_W3SVC1.log
'==============================================================

Set WshShell = WScript.CreateObject("WScript.Shell")
WScript.Echo "Copying log files from subdirectories to current directory..."
CopyLogFilesOneLevelBack WshShell.CurrentDirectory

'==============================================================
' You can edit the below variables to specify a period
'==============================================================
g_TimeFrom	= "00:00:00"		'HH:MM:SS
g_TimeTo	= "00:00:00"
g_DateFrom	= "0000-00-00"		'YYYY-MM-DD
g_DateTo	= "0000-00-00"
g_UsePeriod = FALSE			'Set to TRUE
'==============================================================

'==============================================================
' Please do not edit from here
'==============================================================

'Logparser Queries

'Processed Requests Review 

'1. Retrieving total requests count with total client IP
'2. TOP 20 HIT URL's for the site. 
'3. TOP 10 ASP/ASPX URL's for the site. 
'4. Hit frequency each hour
'5. (sc)Bytes per Extension 
'6. Top 20 Client IP Address. 
'7. Total Unique Client IP's each hour (Users each hour)

'Error statistics

'1. Number of Errors
'2. Error frequency each hour
'3. Status code percentages
'4. Authentication Failures <<-- TBD

'Time Taken Review
 
'1. Top 20 Average Longest requests - Min(time-taken), Max(time-taken columns will be added
'2. Top 50 Longest requests - Min(time-taken), Max(time-taken columns will be added
'3. Average response time in milliseconds each hour
'4. Processing time per Extension

'===================================================================================================
Wscript.Echo 
Wscript.Echo "IIS Log Parsing Script for IISHC. v.1.0"
Wscript.Echo
Wscript.Echo "Default running generates reports for the all log files in the current folder."
Wscript.Echo "Note that logparser.exe must exist at the current folder or in the path."
Wscript.Echo "This script is tested using logparser.exe version of 2.2.10.0"
Wscript.Echo
Wscript.Echo "		<-f> : to specify the log file name to analyze"	
Wscript.Echo "		ex) cscript IISHC_LOGPARSER.VBS -f ex0512*.log"
Wscript.Echo "		    cscript IISHC_LOGPARSER.VBS"
Wscript.Echo
Wscript.Echo "Required IIS logging fields to generate this report properly:"
Wscript.Echo "      date, time, c-ip, cs-uri-stem, sc-status, sc-win32-status"
Wscript.Echo "      time-taken, sc-bytes, cs-bytes"
Wscript.Echo
Wscript.Echo "You can edit this script to specify the period to analyze."
Wscript.Echo "	: Edit g_DateFrom, g_DateTo, g_TimeFrom, g_TimeTo with the right format."
Wscript.Echo
Wscript.Echo "Starting..."
'===================================================================================================

g_LogFileName = "u_ex*.log"

GetArguments				'Set a file name if it is specified.
GetDateTimeStamp

g_StartTimeStamp = g_DateTimeStamp 

Wscript.Echo "Press CTRL-C to stop running."

'===================================================================================================
Wscript.Echo 
Wscript.Echo "Merging all log files to perform faster processing for the further queries."
'===================================================================================================

Set g_objShell = createobject("Wscript.shell")		

IF g_UsePeriod = FALSE THEN

	strQuery = "SELECT date,time,c-ip,cs-uri-stem,sc-status,sc-win32-status,time-taken,sc-bytes,cs-bytes from " & g_LogFileName & " to MERGED_LOG.LOG"

ELSE

	strQuery = "SELECT date,time,c-ip,cs-uri-stem,sc-status,sc-win32-status,time-taken,sc-bytes,cs-bytes from " & g_LogFileName
	strQuery = 	strQuery & " to MERGED_LOG.CSV where date>='" & g_DateFrom & "' AND date<='" & g_DateTo 
	strQuery = 	strQuery & "' AND time>='" & g_TimeFrom & "' AND time<='" & g_TimeTo & "'"

End If

strCommand = "LogParser """ & strQuery & """" & " -O:W3C -e:10"

g_arrQuery(1) = strQuery
WScript.Echo strCommand
g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing

'===================================================================================================
Wscript.Echo 
Wscript.Echo "Converting W3C to CSV (W3C format will be used to run QUANTIZE(TO_TIMESTAMP(date, time),3600) function"
'===================================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT date,time,c-ip,cs-uri-stem,sc-status,sc-win32-status,time-taken,sc-bytes,cs-bytes from MERGED_LOG.LOG to MERGED_LOG.CSV"
strCommand = "LogParser """ & strQuery & """" & " -O:CSV -I:W3C -e:10"
g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE

Set g_objShell = Nothing

'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving total requests count."
Wscript.Echo "IISLOG_ANALYSIS_TOTAL_COUNT_" & g_DateTimeStamp & ".CSV"
'=========================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT count(*) from MERGED_LOG.CSV to IISLOG_ANALYSIS_TOTAL_COUNT_" & g_DateTimeStamp & ".CSV"
strCommand = "LogParser """ & strQuery & """" & " -O:CSV -e:10"
g_arrQuery(2) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing

'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving total client IP count."
Wscript.Echo "IISLOG_ANALYSIS_TOTAL_CIP_" & g_DateTimeStamp & ".CSV"
'=========================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT count(distinct c-ip) from MERGED_LOG.CSV to IISLOG_ANALYSIS_TOTAL_CIP_" & g_DateTimeStamp & ".CSV"
strCommand = "LogParser """ & strQuery & """" & " -O:CSV -e:10"
g_arrQuery(3) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing

'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving TOP 20 HIT URL's for the site."
Wscript.Echo "IISLOG_ANALYSIS_TOP20_HITS_" & g_DateTimeStamp & ".GIF"
'=========================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT TOP 20 cs-uri-stem, COUNT(*) AS Hits INTO IISLOG_ANALYSIS_TOP20_HITS_" & g_DateTimeStamp & ".GIF FROM MERGED_LOG.CSV GROUP BY cs-uri-stem ORDER BY Hits DESC"
strCommand = "LogParser """ & strQuery & """" & " -e:10 -chartType:BarStacked -groupSize:640x700 -I:CSV -chartTitle:""TOP 20 HIT URL's"""
g_arrQuery(4) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing


'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving TOP 10 ASP/ASPX URL's for the site. "
Wscript.Echo "IISLOG_ANALYSIS_TOP10_ASPX_HITS_" & g_DateTimeStamp & ".GIF"
'=========================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT TOP 10 cs-uri-stem, COUNT(*) AS Hits INTO IISLOG_ANALYSIS_TOP10_ASPX_HITS_" & g_DateTimeStamp & ".GIF FROM MERGED_LOG.CSV where cs-uri-stem like '%%.asp' or cs-uri-stem like '%%.aspx' or cs-uri-stem like '%%.asmx' GROUP BY cs-uri-stem ORDER BY Hits DESC"
strCommand = "LogParser """ & strQuery & """" & " -e:10 -chartType:BarStacked -groupSize:640x480 -I:CSV -chartTitle:""TOP 10 ASP/ASPX/ASMX HITS"""
g_arrQuery(5) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing

'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving Hit frequency each hour"
Wscript.Echo "IISLOG_ANALYSIS_HIT_FREQ_" & g_DateTimeStamp & ".GIF"
'=========================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(date, time),3600)), COUNT(*) AS Hit_Frequency INTO IISLOG_ANALYSIS_HIT_FREQ_" & g_DateTimeStamp & ".GIF FROM MERGED_LOG.LOG GROUP BY TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(date, time),3600)) ORDER BY TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(date, time),3600)) DESC" 
strCommand = "LogParser """ & strQuery & """" & " -e:10 -i:W3C -chartType:BarStacked -legend:OFF -values:OFF -groupSize:640x480 -chartTitle:""Hit Frequency (Local Time)"""
g_arrQuery(6) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing

'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving (sc)Bytes per Extension."
Wscript.Echo "IISLOG_ANALYSIS_BYTES_PER_EXT_" & g_DateTimeStamp & ".GIF"
'=========================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT EXTRACT_EXTENSION(cs-uri-stem) AS Extension, MUL(PROPSUM(sc-bytes),100.0) AS Bytes INTO IISLOG_ANALYSIS_BYTES_PER_EXT_" & g_DateTimeStamp & ".GIF FROM MERGED_LOG.CSV GROUP BY Extension ORDER BY Bytes DESC"
strCommand = "LogParser """ & strQuery & """" & " -e:10 -chartType:PieExploded3D -groupSize:640x480 -categories:off -I:CSV -chartTitle:""Bytes per Extension"""
g_arrQuery(7) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing


'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving Top 20 Client IP Address. "
Wscript.Echo "IISLOG_ANALYSIS_TOP20_CLIENT_IP_" & g_DateTimeStamp & ".GIF"
'=========================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT top 20 c-ip AS Client_IP,count(c-ip) AS Count from MERGED_LOG.CSV to IISLOG_ANALYSIS_TOP20_CLIENT_IP_" & g_DateTimeStamp & ".GIF GROUP BY c-ip ORDER BY count(c-ip) DESC"
strCommand = "LogParser """ & strQuery & """" & " -e:10 -chartType:BarStacked -groupSize:640x480 -I:CSV -chartTitle:""TOP 20 Client IP Addresses"""
g_arrQuery(8) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing


'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving Total Unique Client IP's each hour"
Wscript.Echo "IISLOG_ANALYSIS_HOURLY_UNIQUE_CIP_" & g_DateTimeStamp & ".GIF"
'=========================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "Select TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(date, time),3600)) as Times, c-ip as ClientIP into IISLOG_ANALYSIS_DIST_CLIENT_IP.LOG from MERGED_LOG.LOG group by Times, ClientIP"
strCommand = "LogParser """ & strQuery & """" & " -e:10 -I:w3c -O:CSV"
g_arrQuery(9) = strQuery
g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing

Set g_objShell = createobject("Wscript.shell")	

strQuery = "Select Times, count(*) as Count from IISLOG_ANALYSIS_DIST_CLIENT_IP.LOG to IISLOG_ANALYSIS_HOURLY_UNIQUE_CIP_" & g_DateTimeStamp & ".GIF group by Times order by Times DESC"
strCommand = "LogParser """ & strQuery & """" & " -e:10 -chartType:BarStacked -groupSize:640x480 -I:CSV -chartTitle:""Total Unique Client IP's each hour"""
g_arrQuery(10) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing

'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving number of errors."
Wscript.Echo "IISLOG_ANALYSIS_ERROR_COUNT_" & g_DateTimeStamp & ".CSV"
'=========================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT cs-uri-stem, sc-status,sc-win32-status,COUNT(cs-uri-stem) from MERGED_LOG.CSV to IISLOG_ANALYSIS_ERROR_COUNT_" & g_DateTimeStamp & ".CSV where sc-status>=400 GROUP BY cs-uri-stem,sc-status,sc-win32-status ORDER BY COUNT(cs-uri-stem) DESC"
strCommand = "LogParser """ & strQuery & """" & " -e:10 -O:CSV -I:CSV"
g_arrQuery(11) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing


'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving error frequency each hour"
Wscript.Echo "IISLOG_ANALYSIS_ERROR_FREQ_" & g_DateTimeStamp & ".CSV"
'=========================================================================================


Set g_objShell = createobject("Wscript.shell")	

strQuery = "SELECT TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(date, time),3600)), COUNT(*) AS Error_Frequency FROM MERGED_LOG.LOG TO IISLOG_ANALYSIS_ERROR_FREQ_" & g_DateTimeStamp & ".GIF WHERE sc-status >= 500 GROUP BY TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(date, time),3600)) ORDER BY TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(date, time),3600)) DESC"
strCommand = "LogParser """ & strQuery & """" & " -e:10 -chartType:BarStacked -groupSize:640x480 -I:w3c -chartTitle:""Error frequency each hour"""
g_arrQuery(12) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing



'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving status code percentages"
Wscript.Echo "IISLOG_ANALYSIS_STATUS_CODE_" & g_DateTimeStamp & ".CSV"
'=========================================================================================


Set g_objShell = createobject("Wscript.shell")	

strQuery = "SELECT sc-status, COUNT(*) AS Times from MERGED_LOG.CSV to IISLOG_ANALYSIS_STATUS_CODE_" & g_DateTimeStamp & ".GIF GROUP BY sc-status ORDER BY Times DESC"
strCommand = "LogParser """ & strQuery & """" & " -e:10 -chartType:PieExploded3D -groupSize:640x480 -I:CSV -chartTitle:""Status Code Percentages"""

g_arrQuery(13) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing


'=========================================================================================
Wscript.Echo 
Wscript.Echo "Time Taken Review"
Wscript.Echo "Top 20 Average Longest requests"
Wscript.Echo "IISLOG_ANALYSIS_TOP20_AVG_LONGEST_" & g_DateTimeStamp & ".CSV"
'=========================================================================================


Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT top 20 cs-uri-stem,count(cs-uri-stem) As Count,avg(sc-bytes) as sc-bytes,avg(cs-bytes) as cs-bytes,max(time-taken) as Max,min(time-taken) as Min,avg(time-taken) as Avg from MERGED_LOG.CSV to IISLOG_ANALYSIS_TOP20_AVG_LONGEST_" & g_DateTimeStamp & ".CSV GROUP BY cs-uri-stem ORDER BY avg(time-taken) DESC"
strCommand = "LogParser """ & strQuery & """" & " -e:10 -O:CSV -I:CSV"
g_arrQuery(14) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing


'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving Top 50 Longest. "
Wscript.Echo "IISLOG_ANALYSIS_TOP50_LONGEST_" & g_DateTimeStamp & ".CSV"
'=========================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT top 50 TO_LOWERCASE(cs-uri-stem),time,sc-bytes,cs-bytes,time-taken INTO IISLOG_ANALYSIS_TOP50_LONGEST_" & g_DateTimeStamp & ".CSV FROM MERGED_LOG.CSV ORDER BY time-taken DESC"
strCommand = "LogParser """ & strQuery & """" & " -e:10 -O:CSV -I:CSV"
g_arrQuery(15) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing


'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving average response time in ms (local time) "
Wscript.Echo "IISLOG_ANALYSIS_AVG_RESP_TIME_" & g_DateTimeStamp & ".GIF"
'=========================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(date, time),3600)), avg(time-taken) INTO IISLOG_ANALYSIS_AVG_RESP_TIME_" & g_DateTimeStamp & ".GIF FROM MERGED_LOG.LOG WHERE sc-status=200 AND (cs-uri-stem like '%%.asp' or cs-uri-stem like '%%.aspx') GROUP BY TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(date, time),3600)) ORDER BY TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(date, time),3600)) DESC"
strCommand = "LogParser """ & strQuery & """" & " -i:W3C -chartType:BarStacked -legend:OFF -values:OFF -groupSize:640x480 -chartTitle:""Avg Response Time in ms (Local Time)"" -e:10"
g_arrQuery(16) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing


'=========================================================================================
Wscript.Echo 
Wscript.Echo "Retrieving processing time per Extension."
Wscript.Echo "IISLOG_ANALYSIS_PROCTIME_PER_EXT_" & g_DateTimeStamp & ".GIF"
'=========================================================================================

Set g_objShell = createobject("Wscript.shell")		

strQuery = "SELECT EXTRACT_EXTENSION(cs-uri-stem) AS Extension, MUL(PROPSUM(time-taken),100.0) AS Processing_Time INTO IISLOG_ANALYSIS_PROCTIME_PER_EXT_" & g_DateTimeStamp & ".GIF FROM MERGED_LOG.CSV GROUP BY Extension ORDER BY Processing_Time DESC"
strCommand = "LogParser """ & strQuery & """" & " -e:10 -chartType:PieExploded3D -groupSize:640x480 -categories:off -I:CSV -chartTitle:""Processing time per Extension"""
g_arrQuery(17) = strQuery

g_objShell.Run strCommand,MINIMIZE_NOACTIVATE,TRUE
Set g_objShell = Nothing


'=========================================================================================
Wscript.Echo 
Wscript.Echo "Generating HTML Report - IISLOG_HTMLREPORT_" & g_DateTimeStamp & ".HTM ..." 
'=========================================================================================

GenerateHTMLReport

'=========================================================================================
Wscript.Echo 
Wscript.Echo "The report is generated."
'=========================================================================================

Function GetDateTimeStamp()
	
	Dim AMorPM
	Dim Seconds
	Dim Minutes
	Dim Hours
	Dim theDay
	Dim theMonth

	Hours = Hour(Now)
	Minutes = Minute(Now)
	Seconds = Second(Now)
	theDay = Day(Now)
	theMonth = Month(Now)
	AMorPM = Right(Now(),2)
	
	If Len(Hours) = 1 Then Hours = "0" & Hours
	If Len(Minutes) = 1 Then Minutes = "0" & Minutes
	If Len(Seconds) = 1 Then Seconds = "0" & Seconds
	If Len(theDay) = 1 Then theDay = "0" & theDay
	If Len(theMonth) = 1 Then theMonth = "0" & theMonth
	
	g_DateTimeStamp = "Date_" & theMonth & "-" & theDay & "-" & Year(Now) & "_" & Hours & "-" & Minutes & "-" & Seconds & AMorPM
	g_DateReport = theMonth & "-" & theDay & "-" & Year(Now) & " " & Hours & ":" & Minutes 
		
End Function

Function GetArguments()

	dim ArgsCount
	dim objArgs
	dim strAux
	Dim strErrMsg

	Set objArgs = Wscript.Arguments
	ArgsCount = objArgs.count

	if ArgsCount>0 Then

		For i=0 to ArgsCount-1
			strAux = strAux & CStr(objArgs(i)) & " "
		Next

		For i=0 to ArgsCount-1
	
			If UCase(objArgs(i)) = "-F" Then			
				g_LogFileName = objArgs(i+1)
			End if
			

			If UCase(objArgs(i)) = "-?" Then
			
				Wscript.Echo "<-F> : Specify the log file name to analyze (ex) -f ex060311.log"	
				Wscript.Echo "<-?> : Display this message."
				wscript.quit 0
			End if
		Next		

	ELSE
				
	End If
		
End Function


Function GenerateHTMLReport()

Dim objFSO
Dim objFile
Dim strLine
Dim strItem
Dim TextStream
Dim arrItems 
Dim strFileName

'=========================================================================================
' SET REPORT TITLE
'=========================================================================================

g_strHTML = "<HTML><HEAD><title>IIS LOG ANALYSIS REPORT</title></HEAD><BODY>" & vbNewLine
g_strHTML = g_strHTML & "<p><center><font face=""Tahoma"" size=""5""><strong>IIS LOG Analysis Report</strong></font></span></p><br><br>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""right""><font face=""Tahoma"" size=""2""><strong>Reported by IISHC Logparser Script v1.0</strong></font></p><br>" & vbNewLine
'=========================================================================================
' SET Table of Contents
'=========================================================================================

g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""4""><strong>Table of Contents</strong></font></p><br>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & vbNewLine
g_strHTML = g_strHTML & "<strong>I. Processed Requests Review</strong><br><br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC1-1"" TARGET=""_self""> 1. Total requests count and client IP's</A><br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC1-2"" TARGET=""_self""> 2. TOP 20 HIT URL's for the site. </A><br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC1-3"" TARGET=""_self""> 3. TOP 10 ASP/ASPX URL's for the site.</A> <br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC1-4"" TARGET=""_self""> 4. Hit frequency each hour</A><br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC1-5"" TARGET=""_self""> 5. (sc)Bytes per Extension </A><br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC1-6"" TARGET=""_self""> 6. Top 20 Client IP Address. </A><br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC1-7"" TARGET=""_self""> 7. Total Unique Client IP's each hour (Users each hour)</A><br><br>" & vbNewLine
g_strHTML = g_strHTML & "<strong>II. Error statistics </strong><br><br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC2-1"" TARGET=""_self""> 1. Number of Errors</A><br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC2-2"" TARGET=""_self""> 2. Error frequency each hour</A><br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC2-3"" TARGET=""_self""> 3. Status code percentages</A><br><br>" & vbNewLine
g_strHTML = g_strHTML & "<strong>III. Time Taken Review</strong><br> <br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC3-1"" TARGET=""_self""> 1. Top 20 Average Longest requests</A><br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC3-2"" TARGET=""_self""> 2. Top 50 Longest requests </A><br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC3-3"" TARGET=""_self""> 3. Average response time in milliseconds each hour</A><br>" & vbNewLine
g_strHTML = g_strHTML & "<A HREF=""#TOPIC3-4"" TARGET=""_self""> 4. Processing time per Extension</A><br><br></font></p><hr>" & vbNewLine

'=========================================================================================
' Attaching Tables and Images using HTML 
'=========================================================================================

'=========================================================================================
' I. Processed Requests Review
'=========================================================================================
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""3""><strong>I. Processed Requests Review</strong></font></span></p>" & vbNewLine

g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC1-1""></A><font face=""Tahoma"" size=""3""><strong>1. Total requests count and client IP's</strong></font></span></p>" & vbNewLine

MakeHTMLTable "IISLOG_ANALYSIS_TOTAL_COUNT_" & g_DateTimeStamp & ".CSV", "30"
MakeHTMLTable "IISLOG_ANALYSIS_TOTAL_CIP_" & g_DateTimeStamp & ".CSV", "30"

g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">Merging IIS log files before using the following queries.</p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(1) & "</p><br>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(2) & "</p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(3) & "</p><br><hr><br>" & vbNewLine

g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC1-2""></A><font face=""Tahoma"" size=""3""><strong>2. TOP 20 HIT URL's for the site. </strong></font></span></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left"" style='text-align:center'><img src=""" & "IISLOG_ANALYSIS_TOP20_HITS_" & g_DateTimeStamp & ".GIF" & """></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(4) & "</p><br><hr><br>" & vbNewLine


g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC1-3""></A><font face=""Tahoma"" size=""3""><strong>3. TOP 10 ASP/ASPX URL's for the site.</strong></font></span></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left"" style='text-align:center'><img src=""" & "IISLOG_ANALYSIS_TOP10_ASPX_HITS_" & g_DateTimeStamp & ".GIF" & """></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(5) & "</p><br><hr><br>" & vbNewLine


g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC1-4""></A><font face=""Tahoma"" size=""3""><strong>4. Hit frequency each hour</strong></font></span></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left"" style='text-align:center'><img src=""" & "IISLOG_ANALYSIS_HIT_FREQ_" & g_DateTimeStamp & ".GIF" & """></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(6) & "</p><br><hr><br>" & vbNewLine


g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC1-5""></A><font face=""Tahoma"" size=""3""><strong>5. (sc)Bytes per Extension</strong></font></span></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left"" style='text-align:center'><img src=""" & "IISLOG_ANALYSIS_BYTES_PER_EXT_" & g_DateTimeStamp & ".GIF" & """></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(7) & "</p><br><hr><br>" & vbNewLine


g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC1-6""></A><font face=""Tahoma"" size=""3""><strong>6. Top 20 Client IP Address.</strong></font></span></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left"" style='text-align:center'><img src=""" & "IISLOG_ANALYSIS_TOP20_CLIENT_IP_" & g_DateTimeStamp & ".GIF" & """></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(8) & "</p><br><hr><br>" & vbNewLine


g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC1-7""></A><font face=""Tahoma"" size=""3""><strong>7. Total Unique Client IP's each hour (Users each hour)</strong></font></span></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left"" style='text-align:center'><img src=""" & "IISLOG_ANALYSIS_HOURLY_UNIQUE_CIP_" & g_DateTimeStamp & ".GIF" & """></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(9) & "</p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(10) & "</p><br><hr><br>" & vbNewLine


'=========================================================================================
' II. Error statistics
'=========================================================================================

g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""3""><strong>II. Error statistics</strong></font></span></p>" & vbNewLine

g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC2-1""><font face=""Tahoma"" size=""3""><b>1. Number of Errors</b></font></span></p>" & vbNewLine
MakeHTMLTable "IISLOG_ANALYSIS_ERROR_COUNT_" & g_DateTimeStamp & ".CSV", 90
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used (including 4xx errors)</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(11) & "</p><br><hr><br>" & vbNewLine


g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC2-2""></A><font face=""Tahoma"" size=""3""><strong>2. Error frequency each hour</strong></font></span></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left"" style='text-align:center'><img src=""" & "IISLOG_ANALYSIS_ERROR_FREQ_" & g_DateTimeStamp & ".GIF" & """></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used (5xx errors)</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(12) & "</p><br><hr><br>" & vbNewLine


g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC2-3""></A><font face=""Tahoma"" size=""3""><strong>3. Status code percentages</strong></font></span></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left"" style='text-align:center'><img src=""" & "IISLOG_ANALYSIS_STATUS_CODE_" & g_DateTimeStamp & ".GIF" & """></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(13) & "</p><br><hr><br>" & vbNewLine


'=========================================================================================
' III. Time Taken Review
'=========================================================================================

g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""3""><strong>III. Time Taken Review</strong></font></span></p>" & vbNewLine

g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC3-1""><font face=""Tahoma"" size=""3""><b>1. Top 20 Average Longest requests</b></font></span></p>" & vbNewLine
MakeHTMLTable "IISLOG_ANALYSIS_TOP20_AVG_LONGEST_" & g_DateTimeStamp & ".CSV", 90
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(14) & "</p><br><hr><br>" & vbNewLine


g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC3-2""><font face=""Tahoma"" size=""3""><b>2. Top 50 Longest requests</b></font></span></p>" & vbNewLine
MakeHTMLTable "IISLOG_ANALYSIS_TOP50_LONGEST_" & g_DateTimeStamp & ".CSV", 90
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(15) & "</p><br><hr><br>" & vbNewLine


g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC3-3""></A><font face=""Tahoma"" size=""3""><strong>3. Average response time in milliseconds each hour</strong></font></span></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left"" style='text-align:center'><img src=""" & "IISLOG_ANALYSIS_AVG_RESP_TIME_" & g_DateTimeStamp & ".GIF" & """></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(16) & "</p><br><hr><br>" & vbNewLine


g_strHTML = g_strHTML & "<p align=""left""><A NAME=""TOPIC3-4""></A><font face=""Tahoma"" size=""3""><strong>4. Processing time per Extension</strong></font></span></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left"" style='text-align:center'><img src=""" & "IISLOG_ANALYSIS_PROCTIME_PER_EXT_" & g_DateTimeStamp & ".GIF" & """></p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2""><b>Query Used</b></p><p>" & vbNewLine
g_strHTML = g_strHTML & "<p align=""left""><font face=""Tahoma"" size=""2"">" & g_arrQuery(17) & "</p><br><hr><br>" & vbNewLine


'=========================================================================================
' Page Footer
'=========================================================================================
g_strHTML = g_strHTML & "<center><font size=""2"">Last generated at " & g_DateReport & "</font></center>"
g_strHTML = g_strHTML & "</body></html>"

'=========================================================================================
' Writing HTML
'=========================================================================================
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set TextStream = objFSO.CreateTextFile("IISLOG_ANALYSIS_" & g_DateTimeStamp & ".HTM")
TextStream.Write(g_strHTML)
TextStream.Close

Set g_objShell = createobject("Wscript.shell")		
strCommand = "IISLOG_ANALYSIS_" & g_DateTimeStamp & ".HTM"
g_objShell.Run strCommand
Set g_objShell = Nothing

End Function

Function MakeHTMLTable(g_strFileName, g_width)

Dim objFSO
Dim objFile
Dim strLine
Dim strItem
Dim arrItems 
Dim strData
Dim j

Set objFSO = CreateObject("Scripting.FileSystemObject")

'Added by ClintH
If objFSO.FileExists(g_strFileName) = False Then
    Exit Function    
End If

Set objFile = objFSO.OpenTextFile(g_strFileName, 1)

i = 1

strData = "<table bgColor='#ffffff' width='" & g_width & "%' cellpadding='3' cellspacing='0' border='1' height='8' align=""center"">"  & vbNewLine

'=========================================================================================
' Reading CSV File
'=========================================================================================

Do Until objFile.AtEndOfStream

	strData = strData & "<tr>"
	strLine = objFile.ReadLine
	arrItems = Split(strLine, ",", -1, 1)

	j = 1
	For Each strItem in arrItems
		
		IF strItem = "" THEN
			strItem = "&nbsp"   
		END IF
		
		IF i = 1 THEN
			strData = strData & "<td bgColor='#666666' align=""center""><font face='Tahoma' color='white' size='2'><b>" & strItem & "</b></font></td>"
		ELSE
			if j = 1 THEN
				strData = strData & "<td><font face='Tahoma' size='2'>" & strItem & "</font></td>"
			ELSE
				strData = strData & "<td align=""right""><font face='Tahoma' size='2'> " & strItem & "</font></td>"
			END IF
		END IF
		j = j + 1
	Next

	strData = strData & "</tr>"  & vbNewLine
	i = i + 1
Loop

strData = strData & "</table>"  & vbNewLine
g_strHTML = g_strHTML & strData

objFile.Close
Set objFile = Nothing
Set objFSO = Nothing

End Function

'==============================================================
' Added by ClintH
' This section will copy all of the *.log files from one
' directory below this directory to this direcotry and
' renames the file to be similar to this ex060808.log_W3SVC1.log
'==============================================================
Sub CopyLogFilesOneLevelBack(sDir)
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    Set objParentFolder = objFSO.GetFolder(sDir)
    Set colFolders = objParentFolder.SubFolders

    For each objFolder in colFolders
        Set colFiles = objFolder.Files
        For Each objFile in colFiles
            If Instr(1,objFile.shortpath,".log",1) > 0 Then
                'iLoc = Instr(18, objFile.parentfolder, "\")
                'sName = Mid(objFile.parentfolder, iLoc+1) 
                sName = objFile.ParentFolder.Name
                sDestination = sDir & "\" & objFile.Name & "_" & sName & ".log"
                objFSO.CopyFile objFile.shortpath, sDestination            
            End If
        Next    
    Next
End Sub

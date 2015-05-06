'// EventLogCollator.vbs
'// Purpose: This script is designed for use in Health Checks.
'//  It gathers the system and application event logs from multiple servers and merges them together for to see if there is correlation between events on each server.
'//
'// Syntax:
'// CScript CreateAndStartPerfmonLogs.vbs <computer[;computer]>
'//  <computer[;computer]>  List of computers to create and start the perfmon log.
'// 
'// Written by: Clint Huffman (clinth@microsoft.com
'// Last Modified: 3/7/2007
'// 

Dim g_aComputers
Dim xmldoc
Const OUTPUT_CSV_FILE = "MergedEventLogs.csv"
Const OUTPUT_DIRECTORY = "output"
Const NUMBER_OF_DAYS_TO_COLLECT = 7

Main

Sub Main()
    ProcessArguments
    'OpenOrCreateOutputXML OUTPUT_XML_FILE
    GetData   
End Sub

Sub GetData()
'    Set oXMLRoot = oXMLDoc.documentElement
    Set oFSO = Createobject("Scripting.FileSystemObject")
    ON ERROR RESUME NEXT
    oFSO.CreateFolder OUTPUT_DIRECTORY
    ON ERROR GOTO 0
    Set oFile = oFSO.CreateTextFile(OUTPUT_DIRECTORY & "\" & OUTPUT_CSV_FILE, True)
    WScript.Echo "Writing to " & chr(34) & OUTPUT_CSV_FILE & chr(34) & "..."
    'oFile.WriteLine "Time,ComputerName,Type,Category,Source,EventID,User,Description"
    oFile.WriteLine "Time" & "," & "ComputerName" & "," & "Type" & "," & "Category" & "," & "Source" & "," & "EventID" & "," & "User" & "," & "Description"
    sPeriods = ""
    
    ' Build an earlier date
    iNumOfDateToCollect = CInt("-" & NUMBER_OF_DAYS_TO_COLLECT)
    dEarlierDate = DateAdd("d", iNumOfDateToCollect, Now())
    sWMIEarlierDate = NormalDateToWMIDateConversion(dEarlierDate)
    sWMIEarlierDate = Left(sWMIEarlierDate, 8)
    
    For i = 0 to UBound(g_aComputers)
        WScript.Echo "Gathering Application and System Event Logs from " & chr(34) & g_aComputers(i) & chr(34) & "..."
        GetWin32NTLogEvent g_aComputers(i), xmldoc, oFile, sWMIEarlierDate 
    Next
    oFile.Close
End Sub

Sub GetWin32NTLogEvent(sComputer, oXMLDoc, oFile, sWMIEarlierDate)    
    ON ERROR RESUME NEXT
    Set oWMIService = ConnectToWMIService(sComputer,"root\cimv2", "", "")
    If Err.number <> 0 Then
        WScript.Echo "No Connection"
        Exit Sub
    End If
    ON ERROR GOTO 0
    
    ' WQL Query: Returns all of the application and system event log events that have occurred in sWMIEarlierDate earlier days.
    '   For example, if sWMIEarlierDate equal 2, then this query will return the last 2 days of events.
    WQL = "SELECT TimeGenerated, ComputerName, Type, CategoryString, SourceName, EventCode, User, Message FROM Win32_NTLogEvent WHERE (logfile = 'application' OR logfile = 'system') AND TimeGenerated > " & sWMIEarlierDate
    'WQL = "SELECT TimeGenerated FROM Win32_NTLogEvent WHERE (logfile = 'application' OR logfile = 'system') AND TimeGenerated > " & sWMIEarlierDate
    WScript.Echo "WQL: " & WQL
    'WScript.Quit
    Set oCollectionOfWin32NTLogEvent = oWMIService.ExecQuery(WQL)
    
    ON ERROR RESUME NEXT
    For Each oInstance in oCollectionOfWin32NTLogEvent     
        If IsNull(oInstance.Message) = True Then
            sMessage = ""
        Else
            sMessage = FilterText(CStr(oInstance.Message))
        End If
               
        oFile.WriteLine WMIDateToNormalDateConversion(oInstance.TimeGenerated) & "," & oInstance.ComputerName & "," & oInstance.Type & "," & oInstance.CategoryString & "," & oInstance.SourceName & "," & oInstance.EventCode & "," & oInstance.User & "," & sMessage         
    Next
    ON ERROR GOTO 0
End Sub

Function FilterText(sText)
    sNewText = sText
    sNewText = Replace(sText, ",", " ") ' remove commas
    sNewText = Replace(sNewText, chr(10), " ") ' remove linefeeds.
    sNewText = Replace(sNewText, chr(13), " ") ' remove C return characters.
    FilterText = CStr(sNewText)
End Function

Function ConnectToWMIService(sComputer, sWMINamespace, sUserName, sPassword)
    If sWMINamespace = "" Then
        sWMINamespace = "root\cimv2"
    End If
    
    Set oWMILocator = CreateObject("WbemScripting.SWbemLocator")
    
    ON ERROR RESUME NEXT
    Set oWMIService = oWMILocator.ConnectServer(sComputer, sWMINamespace)    
    If Err.number <> 0 Then
        WScript.Echo "Failed to connect to server " & chr(34) & sComputer & chr(34)
        ConnectToWMIService = Nothing
    Else
        Set ConnectToWMIService = oWMIService
    End If
    ON ERROR GOTO 0    
End Function

Sub ProcessArguments()
    sSyntax = "CScript EventLogCollator.vbs <computer[;computer]>" & vbNewLine & _
    " <computer[;computer]>  List of computers to create and start the perfmon log." & vbNewLine
    
    Set oArgs = WScript.Arguments
    
    SELECT CASE oArgs.Count
        CASE 0
            WScript.Echo sSyntax
            WScript.Quit
        CASE 1
            sComputers = oArgs(0)
        CASE Else
            WScript.Echo sSyntax
            WScript.Quit
    END SELECT
    
    ' Change any localhost entryies to be a period for WMI.
    g_aComputers = Split(sComputers, ";")
    For i = 0 to UBound(g_aComputers)
        If LCase(g_aComputers(i)) = "localhost" Then
            g_aComputers(i) = "."
        End If
    Next        
End Sub

Function DomainRoleTranslator(iDomainRole)
    Select Case iDomainRole 
        Case 0
            DomainRoleTranslator = "Standalone Workstation"
        Case 1        
            DomainRoleTranslator = "Member Workstation"
        Case 2 
            DomainRoleTranslator = "Standalone Server"
        Case 3
            DomainRoleTranslator = "Server"
        Case 4
            DomainRoleTranslator = "Backup Domain Controller"
        Case 5
            DomainRoleTranslator = "Primary Domain Controller"
        Case Else
            DomainRoleTranslator = "Unknown"
    End Select
End Function

Function WMIDateToNormalDateConversion(sWMIDateTime)
    ' Example: 20061107222706.000000-000
    ' Remove all of the data on the right side of the period.
    sDateTime = sWMIDateTime
    iLocPeriod = Instr(1, sDateTime, ".")
    sNewDateTime = Mid(sDateTime,1,iLocPeriod-1)

    ' Break down the date time string into components.
    sYear = Left(sNewDateTime, 4)
    'WScript.Echo "Year: " & sYear
    sMonth = Mid(sNewDateTime, 5, 2)
    'WScript.Echo "sMonth: " & sMonth
    sDay = Mid(sNewDateTime, 7, 2)
    'WScript.Echo "sDay: " & sDay
    sHour = Mid(sNewDateTime, 9, 2)
    'WScript.Echo "sHour: " & sHour
    sMinute = Mid(sNewDateTime, 11, 2)
    'WScript.Echo "sMinute: " & sMinute
    sSecond = Mid(sNewDateTime, 13, 2)
    'WScript.Echo "sSecond: " & sSecond

    ' Convert to date and time values
    sNewDate = DateSerial(sYear, sMonth, sDay)
    'WScript.Echo "sNewDate: " & sNewDate
    sNewTime = TimeSerial(sHour, sMinute, sSecond)
    'WScript.Echo "sNewTime: " & sNewTime
    sNewDateTime = CDate(sNewDate & " " & sNewTime)
    'WScript.Echo "sNewDateTime: " & sNewDateTime
    WMIDateToNormalDateConversion = sNewDateTime
End Function

Function NormalDateToWMIDateConversion(sNormalDateTime)
    ' Example: 11/07/2006 10:27:06 PM to 20061107222706.000000-000
    ' Remove all of the data on the right side of the period.
    sDateTime = sNormalDateTime
    
    sYear = Year(sDateTime)
    sMonth = Month(sDateTime)
    sDay = Day(sDateTime)
    sHour = Hour(sDateTime)
    sMinute = Minute(sDateTime)
    sSecond = Second(sDateTime)
    
    sDateTime = sYear & sMonth & sDay & sHour & Minute & Second
    WScript.Echo sDateTime
    NormalDateToWMIDateConversion = sDateTime
End Function

Function NormalDateToWMIDateConversion(sNormalDateTime)
    ' Example: 11/07/2006 10:27:06 PM to 20061107222706.000000-000
    ' Remove all of the data on the right side of the period.
    sDateTime = sNormalDateTime
    
    sYear = Year(sDateTime)
    sMonth = Month(sDateTime)
    If Len(sMonth) = 1 Then
        sMonth = "0" & CStr(sMonth)
    End If
    
    sDay = Day(sDateTime)
    If Len(sDay) = 1 Then
        sDay = "0" & CStr(sDay)
    End If
    
    sHour = Hour(sDateTime)
    If Len(sHour) = 1 Then
        sHour = "0" & CStr(sHour)
    End If    
    
    sMinute = Minute(sDateTime)
    If Len(sMinute) = 1 Then
        sMinute = "0" & CStr(sMinute)
    End If 
        
    sSecond = Second(sDateTime)
    If Len(sSecond) = 1 Then
        sSecond = "0" & CStr(sSecond)
    End If     
    
    sDateTime = sYear & sMonth & sDay & sHour & sMinute & sSecond
    NormalDateToWMIDateConversion = sDateTime
End Function
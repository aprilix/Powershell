'//
'// CScript ConvertEventLogCSVIntoFriendlyHTMLTable.vbs <CSVFilePath>
'//
'// Description: This script converts a CSV file that contains 
'//  event log data into an HTML based table.
'//  It will output an HTM file. This script is intented to be 
'//  used after using the EventLogCollator.vbs script.
'//  
'// Written by: Clint Huffman (clinth@microsoft.com)
'//
'// Last Modified: 3/14/2007
'//

Dim g_CSVFilePath
Const OUTPUT_FILE = "ConvertEventLogCSVIntoFriendlyHTMLTable.htm"

Main

Sub Main()
    ProcessArguments
    aCSV = GetData()
    CreatOutputHTML aCSV
    WScript.Echo "The HTML file " & chr(34) & OUTPUT_FILE & chr(34) & " has been created."
End Sub

Sub CreatOutputHTML(aCSV)
    Dim sOutput    
    'Time,ComputerName,Type,Category,Source,EventID,User,Description    
    sOutput = sOutput & "<HTML>" & vbNewLine
    sOutput = sOutput & "<TABLE BORDER=1 WIDTH=500>"  & vbNewLine
    sOutput = sOutput & "<TR><TH BGCOLOR=""Black"" WIDTH=250><FONT COLOR=""White"">Event</FONT></TH><TH BGCOLOR=""Black""><FONT COLOR=""White"">Comment</FONT></TH></TR>" & vbNewLine
    For x = 0 to UBound(aCSV, 1)
        sOutput = sOutput & _
        "<TR><TD ALIGN=Left VALIGN=TOP BGCOLOR=""LightGrey"">" & vbNewLine & _
        "<B>Time:</B> " & aCSV(x,0) & "<BR>" & vbNewLine & _
        "<B>ComputerName:</B> " & aCSV(x,1) & "<BR>" & vbNewLine & _
        "<B>Type:</B> <FONT COLOR=" & EventTypeColorTranslator(aCSV(x,2)) & ">" & aCSV(x,2) & "</FONT><BR>" & vbNewLine & _
        "<B>Category:</B> " & aCSV(x,3) & "<BR>" & vbNewLine & _
        "<B>Source:</B> " & aCSV(x,4) & "<BR>" & vbNewLine & _
        "<B>EventID:</B> " & aCSV(x,5) & "<BR>" & vbNewLine & _
        "<B>User:</B> " & aCSV(x,6) & "<BR>" & vbNewLine & _
        "<B>Description:</B> " & aCSV(x,7) & "<BR>" & vbNewLine & _
        "</TD><TD ALIGN=Left VALIGN=TOP>" & "</TD></TR>" & vbNewLine    
    Next
    sOutput = sOutput & "</TABLE>" & vbNewLine
    sOutput = sOutput & "</HTML>" & vbNewLine
    
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    Set oFile = oFSO.CreateTextFile(OUTPUT_FILE, True)
    oFile.Write sOutput
    oFile.Close
End Sub

Function EventTypeColorTranslator(sEventType)
    SELECT CASE sEventType
        CASE "Information"
            EventTypeColorTranslator = "Blue"
        CASE "Warning"
            EventTypeColorTranslator = "Orange"
        CASE "Error"
            EventTypeColorTranslator = "Red"
        CASE Else
            EventTypeColorTranslator = "Black"
    END SELECT
End Function

Function GetData()
    GetData = CSVToArray(g_CSVFilePath, ",")
End Function

Sub ProcessArguments()
    sSyntax = "CScript ConvertEventLogCSVIntoFriendlyHTMLTable.vbs <CSVFilePath>"    
    Set oArgs = WScript.Arguments    
    SELECT CASE oArgs.Count
        CASE 0
            WScript.Echo sSyntax
            WScript.Quit
        CASE 1
            g_CSVFilePath = oArgs(0)
        CASE Else
            WScript.Echo sSyntax
            WScript.Quit
    END SELECT    
End Sub

Function CSVToArray(strCSVFilePath, strDelimitedBy)
	'Requires DelimtedStringToArray()
	Const ForReading = 1, ForWriting = 2, ForAppending = 8
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set objCSVFileRead = fso.OpenTextFile(strCSVFilePath, ForReading, False)

	'<Count the number of lines in the CSV file so we can initialize the arrays>
		intRowNumber = 0
		intColNumber = 0
		objCSVFileRead.Skipline
		Do While objCSVFileRead.AtEndOfStream <> True
			strReadLine = objCSVFileRead.ReadLine
			'WScript.Echo strReadLine
'			If intRowNumber = 0 Then
'				'<Convert the delimited string from the CSV into a temporary array>
					arrayTemp = Split(strReadLine, strDelimitedBy)
'				'</Convert the delimited string from the CSV into a temporary array>
				intColNumber = UBound(arrayTemp)
'			End If
			intRowNumber = intRowNumber + 1
		Loop
		objCSVFileRead.Close
	'</Count the number of lines in the CSV file so we can initialize the arrays>
	
	'<Initialize the array>
		intRowNumber = intRowNumber - 1
		ReDim arrayOfCSVValues(intRowNumber, intColNumber)
	'</Initialize the array>

	'<Read the CSV file and place values into the array>
		Set objCSVFileRead = fso.OpenTextFile(strCSVFilePath, ForReading, False)
		x = 0
		objCSVFileRead.SkipLine 'skipping headers
		Do While objCSVFileRead.AtEndOfStream <> True
			strReadLine = objCSVFileRead.ReadLine
			'<Convert the delimited string from the CSV into a temporary array>
				arrayTemp = Split(strReadLine, strDelimitedBy)
			'</Convert the delimited string from the CSV into a temporary array>
			'<Assign the values from the temporary array to the main array>
				For i = 0 To UBound(arrayOfCSVValues,2)
					arrayOfCSVValues(x,i) = arrayTemp(i)
				Next
			'</Assign the values from the temporary array to the main array>
			x = x + 1
		Loop
	'</Read the CSV file and place values into the array>
	CSVToArray = arrayOfCSVValues
	'Debug Output	
	'For i = 0 To intRowNumber
	'	WScript.Echo "arrayOfCSVValues(" & i & ",0): " & arrayOfCSVValues(i,0)
	'	WScript.Echo "arrayOfCSVValues(" & i & ",1): " & arrayOfCSVValues(i,1)
	'Next	
End Function

Function DelimtedStringToArray(strStringToParse, strDelimitedBy)
    Dim arrayOfStrings()
    If InStr(1, strStringToParse, strDelimitedBy) > 0 Then
        IntStartingCommaCursor = 1
        IntEndingCommaCursor = InStr(1, strStringToParse, strDelimitedBy)
        ReDim arrayOfStrings(0)
        arrayOfStrings(0) = Trim(Mid(strStringToParse, IntStartingCommaCursor, IntEndingCommaCursor - IntStartingCommaCursor))        
        LoopCounter = 1
        Do Until InStr(IntEndingCommaCursor + 1, strStringToParse, strDelimitedBy) = 0
            IntStartingCommaCursor = IntEndingCommaCursor + 1
            IntEndingCommaCursor = InStr(IntEndingCommaCursor + 1, strStringToParse, strDelimitedBy)
            ReDim Preserve arrayOfStrings(LoopCounter)
            arrayOfStrings(LoopCounter) = Trim(Mid(strStringToParse, IntStartingCommaCursor, IntEndingCommaCursor - IntStartingCommaCursor))
            LoopCounter = LoopCounter + 1
        Loop        
        If InStr(IntEndingCommaCursor + 1, strStringToParse, strDelimitedBy) = 0 And IntEndingCommaCursor + 1 < Len(strStringToParse) Then
            ReDim Preserve arrayOfStrings(LoopCounter)
            arrayOfStrings(LoopCounter) = Trim(Mid(strStringToParse, IntEndingCommaCursor + 1, Len(strStringToParse)))
        End If
    Else
        ReDim arrayOfStrings(0)
        arrayOfStrings(0) = Trim(strStringToParse)
    End If    
    DelimtedStringToArray = arrayOfStrings
End Function
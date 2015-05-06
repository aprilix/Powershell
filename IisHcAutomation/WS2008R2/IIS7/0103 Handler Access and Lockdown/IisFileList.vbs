Const CSV_FILE_NAME = "IIS6FileList"

ON ERROR RESUME NEXT

Dim oFSO, oCsvOutputFile
Dim sIisWebVirtualDirPath, sIisWebVirtualDirLocation, sIisWebVirtualDirAppFriendlyName
Dim sXmlFilePath
Dim oWmiLocator, oWmiService
Dim sComputer, sLocalComputerName

Set oFSO = CreateObject("Scripting.FileSystemObject")

sSyntax = "" & _
" Syntax:" & chr(10) & chr(10) & _
"   CScript IisFileList.vbs [/?] MetabaseXmlFile" & Chr(10) & Chr(10) & _
"   [/?]                Optional. Show this help text." & Chr(10) & _
"   Computer            Required. The computer to run against." & Chr(10) & _
"   MetabaseXmlFile     Required. File path to an IIS metabase XML file" & Chr(10)

Set oArgs = WScript.Arguments
If oArgs.Count < 1 Then
	WScript.Echo sSyntax
	WScript.Echo ""
	WScript.Quit
Else
	For i = 0 to oArgs.Count -1
		If InStr(1, oArgs(i), "?") > 0 Then
			WScript.Echo sSyntax
			WScript.Echo ""
			WScript.Quit
		Else
		    sXmlFilePath = oArgs(0)
		End If
	Next
End If

Set oWmiLocator = CreateObject("wbemscripting.swbemlocator")
Set oWmiService = oWmiLocator.ConnectServer(".", "root/cimv2")
Set oWmiCollectionOfInstances = oWmiService.ExecQuery("SELECT Name FROM Win32_ComputerSystem")
For Each oWmiInstance in oWmiCollectionOfInstances
    sLocalComputerName = oWmiInstance.Name
Next

sCsvFileName = CSV_FILE_NAME & "_" & sLocalComputerName & ".csv"
Set oCsvOutputFile = oFSO.CreateTextFile(sCsvFileName, True)

If LCase(sLocalComputerName) <> LCase(sComputer) AND sComputer <> "127.0.0.1" AND sComputer <> "." AND LCase(sComputer) <> "localhost" Then
    Set oWmiService = oWmiLocator.ConnectServer(sComputer, "root/cimv2")
End If

If oFSO.FileExists(sXmlFilePath) = False Then
    WScript.Echo "Error: " & chr(34) & sXmlFilePath & chr(34)
    WScript.Echo vbTab & "...does not exist."
End If

Set xmldoc = CreateObject("Msxml2.DOMDocument")
xmldoc.async = False
xmldoc.Load sXmlFilePath
Set oXmlRoot = xmldoc.documentElement

'// Headers
sCsvLine = "Computer,AppFriendlyName,VirtualDirMetabaseLocation,VirtualDirectoryDirPath,FileName,Extension,FilePath"
WScript.Echo sCsvLine
WriteCsvLine sCsvLine 

For Each oXmlNode in oXmlRoot.SelectNodes("//IIsWebVirtualDir")    
    sIisWebVirtualDirPath = oXmlNode.GetAttribute("Path")
	'WScript.Echo sIisWebVirtualDirPath
    sIisWebVirtualDirLocation = oXmlNode.GetAttribute("Location")
    sIisWebVirtualDirAppFriendlyName = oXmlNode.GetAttribute("AppFriendlyName")
    If LCase(sIisWebVirtualDirPath) <> "null" AND IsNull(sIisWebVirtualDirAppFriendlyName) = False Then
        If oFSO.FolderExists(sIisWebVirtualDirPath) Then
	    WScript.Echo sIisWebVirtualDirLocation
            EnumFileList(sIisWebVirtualDirPath)
        Else
            WScript.Echo sIisWebVirtualDirAppFriendlyName & "," & sIisWebVirtualDirLocation & "," & sIisWebVirtualDirPath
            WScript.Echo vbTab & "...does not exist."
        End If    
    End If    
Next
oCsvOutputFile.Close()
WScript.Echo "Done!"

Sub WriteCsvLine(sLine)
    oCsvOutputFile.WriteLine(sLine)
End Sub

Sub EnumFileList(sDirectoryPath)
    'If oFSO.FolderExists(sDirectoryPath) = False Then
    '    EnumFileList = ""
    '    Exit Sub
    'End If
    
    '// Data
    Set oFolder = oFSO.GetFolder(sDirectoryPath)
    For Each oFile in oFolder.Files
	'WScript.Echo vbTab & oFile.Name
        aString = Split(oFile.Name,".")
        sFileExtension = aString(UBound(aString))
	    sCsvLine = sLocalComputerName & "," & sIisWebVirtualDirAppFriendlyName & "," & sIisWebVirtualDirLocation & "," & sIisWebVirtualDirPath & "," & oFile.Name & "," & sFileExtension & "," & oFile.Type & "," & oFile.Path
	    'WScript.Echo sCsvLine
	    WriteCsvLine sCsvLine      
    Next
End Sub


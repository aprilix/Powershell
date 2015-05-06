Const LOCAL_DISK = 3
Dim g_aComputers
Dim xmldoc
Const OUTPUT_XML_FILE = "output.xml"

Main

Sub Main()
    ProcessArguments
    OpenOrCreateOutputXML OUTPUT_XML_FILE
    GetData   
End Sub

Sub GetData()
    For i = 0 to UBound(g_aComputers)
        GetWMIData g_aComputers(i), xmldoc
    Next
End Sub

Sub GetWMIData(sComputer, oXMLDoc)
    Set oXMLRoot = oXMLDoc.documentElement
    Set oServerNode = LocateOrCreateServerNode(xmldoc, sComputer)
    ON ERROR RESUME NEXT
    Set oWMIService = ConnectToWMIService(sComputer,"root\cimv2", "", "")
    If Err.number <> 0 Then
        WScript.Echo "No Connection"
        Exit Sub
    End If
    ON ERROR GOTO 0

    sWQL = "SELECT * FROM Win32_Volume WHERE DriveType = " & LOCAL_DISK
    WScript.Echo "===================================="
    WScript.Echo " " & sComputer
    WScript.Echo "===================================="    
    Set oCollectionOfWMIClass = oWMIService.ExecQuery(sWQL)
    For Each oInstance in oCollectionOfWMIClass
        iReturnValue = oInstance.DefragAnalysis(bDefragRecommended, objDefragAnalysis)
        If iReturnValue = 0 Then
            WScript.Echo "Caption: " & oInstance.Caption
            WScript.Echo "DefragRecommended: " & bDefragRecommended
            WScript.Echo "PercentFragemented: " & objDefragAnalysis.FilePercentFragmentation
            WScript.Echo "AvgFileSize: " & objDefragAnalysis.AverageFileSize\1024 & " KB"
            WScript.Echo "======================="

            Set newClassNode = oXMLDoc.createNode(1, "WMICLASSINSTANCE", "")
            newClassNode.SetAttribute "WMIClass", "Win32_DefragAnalysis"
            newClassNode.SetAttribute "Caption", oInstance.Caption        
            newClassNode.SetAttribute "DefragRecommended", bDefragRecommended
            newClassNode.SetAttribute "PercentFragemented", objDefragAnalysis.FilePercentFragmentation
            newClassNode.SetAttribute "AvgFileSize", objDefragAnalysis.AverageFileSize\1024 & " KB"
            oXMLRoot.appendChild newClassNode
        Else
            WScript.Echo "ERROR: " & TranslateWin32DefragAnalysisReturnValue(iReturnValue)
        End If
        WScript.Echo ""
        oXMLDoc.save OUTPUT_XML_FILE                
    Next    
End Sub

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

Function OpenOrCreateOutputXML(sOutputXMLFile)
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    Set xmldoc = CreateObject("Msxml2.DOMDocument")
    xmldoc.async = False
    
    ' Check to see if the XML output file exists yet. If so, open it. Otherwise, create a new one.
    If oFSO.FileExists(sOutputXMLFile) Then
        xmldoc.load sOutputXMLFile
    Else
        xmldoc.loadXML "<HealthCheck></HealthCheck>"
        Set XMLRoot = xmldoc.documentElement
        XMLRoot.SetAttribute "CreationDate", Now()
        xmldoc.save sOutputXMLFile
    End If
    Set OpenOrCreateOutputXML = xmldoc
End Function

Function LocateOrCreateServerNode(oXMLDoc, sServerName)
    ' Locates or creates the respective server node in the output xml document.
    Set oXMLRoot = oXMLDoc.documentElement
    Set oNodes = oXMLRoot.SelectNodes("//SERVER")
    bFound = False
    For Each oNode in oNodes
        sNodeName = oNode.GetAttribute("Name")
        If LCase(sNodeName) = LCase(sServerName) Then
            bFound = True
            Set LocateOrCreateServerNode = oNode
        End If
    Next    
    If bFound = False Then
        Set newProcessNode = oXMLDoc.createNode(1, "SERVER", "")
        newProcessNode.SetAttribute "Name", sServerName
        oXMLRoot.appendChild newProcessNode
        oXMLDoc.save OUTPUT_XML_FILE
        
        Set oNodes = oXMLRoot.SelectNodes("//SERVER")
        bFound = False
        For Each oNode in oNodes
            sNodeServerName = oNode.GetAttribute("Name")
            If LCase(sNodeServerName) = LCase(sServerName) Then
                bFound = True
                Set LocateOrCreateServerNode = oNode
                oXmlDoc.save OUTPUT_XML_FILE
            End If
        Next
    End If    
End Function


Sub ProcessArguments()
    sSyntax = "CScript DefragAnalysis.vbs <computer[;computer]>"
    
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


Function TranslateWin32DefragAnalysisReturnValue(iReturnValue)
    SELECT CASE iReturnValue
        CASE 0
            TranslateWin32DefragAnalysisReturnValue = "Success"
        CASE 1
            TranslateWin32DefragAnalysisReturnValue = "Access denied"
        CASE 2
            TranslateWin32DefragAnalysisReturnValue = "Not supported"
        CASE 3
            TranslateWin32DefragAnalysisReturnValue = "Volume dirty bit is set"
        CASE 4
            TranslateWin32DefragAnalysisReturnValue = "Not enough free space"
        CASE 5
            TranslateWin32DefragAnalysisReturnValue = "Corrupt Master File Table detected"
        CASE 6
            TranslateWin32DefragAnalysisReturnValue = "Call canceled"
        CASE 7
            TranslateWin32DefragAnalysisReturnValue = "Call cancellation request too late"
        CASE 8
            TranslateWin32DefragAnalysisReturnValue = "Defrag engine is already running"
        CASE 9
            TranslateWin32DefragAnalysisReturnValue = "Unable to connect to defrage engine"
        CASE 10
            TranslateWin32DefragAnalysisReturnValue = "Defrag engine error"
        CASE 11
            TranslateWin32DefragAnalysisReturnValue = "Unknown error"
        CASE Else
            TranslateWin32DefragAnalysisReturnValue = "Unknown error"
    END SELECT
End Function
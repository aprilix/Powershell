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
    
    'Set oCollectionOfWMIClass = oWMIService.InstancesOf("Win32_Processor")
    Set oInstance = oWMIService.Get("Win32_Processor.DeviceID='CPU0'")
    'For Each oInstance in oCollectionOfWMIClass
        WScript.Echo "WMIClass: " & "Win32_Processor"
        WScript.Echo "Name: " & oInstance.Name
        WScript.Echo "Architecture: " & ArchitectureTranslator(oInstance.Architecture)
        WScript.Echo "AddressWidth: " & oInstance.AddressWidth        
        WScript.Echo "CurrentClockSpeed: " & oInstance.CurrentClockSpeed
        WScript.Echo "DataWidth: " & oInstance.DataWidth
        WScript.Echo "Description: " & oInstance.Description
        WScript.Echo "Manufacturer: " & oInstance.Manufacturer
        WScript.Echo "MaxClockSpeed: " & oInstance.MaxClockSpeed
        ON ERROR RESUME NEXT
        ' Vista/Longhorn properties. Will throw an error on earlier systems.
        WScript.Echo "NumberOfCores: " & oInstance.NumberOfCores
        WScript.Echo "NumberOfLogicalProcessors: " & oInstance.NumberOfLogicalProcessors
        If Err.number <> 0 Then
            WScript.Echo "NumberOfCores: " & "Unknown"
            WScript.Echo "NumberOfLogicalProcessors: " & "Unknown"
        End If
        ON ERROR GOTO 0             
        WScript.Echo ""
        
        Set newClassNode = oXMLDoc.createNode(1, "WMICLASSINSTANCE", "")
        newClassNode.SetAttribute "WMIClass", "Win32_Processor"
        newClassNode.SetAttribute "Name", oInstance.Name
        newClassNode.SetAttribute "Architecture", ArchitectureTranslator(oInstance.Architecture)
        newClassNode.SetAttribute "AddressWidth", oInstance.AddressWidth        
        newClassNode.SetAttribute "CurrentClockSpeed", oInstance.CurrentClockSpeed
        newClassNode.SetAttribute "DataWidth", oInstance.DataWidth
        newClassNode.SetAttribute "Description", oInstance.Description
        newClassNode.SetAttribute "Manufacturer", oInstance.Manufacturer
        newClassNode.SetAttribute "MaxClockSpeed", oInstance.MaxClockSpeed
        
        ON ERROR RESUME NEXT
        ' Vista/Longhorn properties. Will throw an error on earlier systems.
        newClassNode.SetAttribute "NumberOfCores", oInstance.NumberOfCores
        newClassNode.SetAttribute "NumberOfLogicalProcessors", oInstance.NumberOfLogicalProcessors
        If Err.number <> 0 Then
            newClassNode.SetAttribute "NumberOfCores", "Unknown"
            newClassNode.SetAttribute "NumberOfLogicalProcessors", "Unknown"
        End If
        ON ERROR GOTO 0

        oServerNode.appendChild newClassNode
        oXMLDoc.save OUTPUT_XML_FILE                
    'Next    
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
    sSyntax = "CScript GetWin32Processor.vbs <computer[;computer]>"
    
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

Function ArchitectureTranslator(iArch)
    SELECT CASE iArch
        CASE 0
            ArchitectureTranslator = "x86"
        CASE 1
            ArchitectureTranslator "This is a MIPS cpu."
        CASE 2
            ArchitectureTranslator = "This is an Alpha cpu."
        CASE 3
            ArchitectureTranslator = "This is a PowerPC cpu."
        CASE 6
            ArchitectureTranslator = "This is an ia64 cpu."
        CASE ELSE        
            ArchitectureTranslator = iArch
    END SELECT
End Function


' Arguments
' - Computers to gather from.



' Connect to each computer.

' Get Win32_Computer System

' Save the results to output.xml.
' Output to command prompt
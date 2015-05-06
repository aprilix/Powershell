'//
'// Written by Clint Huffman (clinth@microsoft.com)
'// Version: v1.2.1
'//

Dim g_aComputers
Dim xmldoc
Const OUTPUT_XML_FILE = "output.xml"
ON ERROR RESUME NEXT
Main

Sub Main()
    ProcessArguments
    OpenOrCreateOutputXML OUTPUT_XML_FILE
    GetData   
End Sub

Sub GetData()
    For i = 0 to UBound(g_aComputers)
        GetWin32ComputerSystemData g_aComputers(i), xmldoc
    Next
End Sub

Sub GetWin32ComputerSystemData(sComputer, oXMLDoc)
    Set oXMLRoot = oXMLDoc.documentElement
    Set oServerNode = LocateOrCreateServerNode(oXMLDoc, sComputer)
    'ON ERROR RESUME NEXT
    Set oWMIService = ConnectToWMIService(sComputer,"root\cimv2", "", "")
    If Err.number <> 0 Then
        WScript.Echo "No Connection"
        Exit Sub
    End If
    'ON ERROR GOTO 0
    
    Set oCollectionOfWin32ComputerSystem = oWMIService.InstancesOf("Win32_ComputerSystem")
    For Each oInstance in oCollectionOfWin32ComputerSystem
        WScript.Echo "Name: " & oInstance.Name
        WScript.Echo "Manufacturer: " & oInstance.Manufacturer
        WScript.Echo "Model: " & oInstance.Model
        WScript.Echo "NumberOfProcessors: " & oInstance.NumberOfProcessors
        WScript.Echo "PartOfDomain: " & oInstance.PartOfDomain
        WScript.Echo "Domain: " & oInstance.Domain
        WScript.Echo "DomainRole: " & DomainRoleTranslator(oInstance.DomainRole)
        WScript.Echo "SystemType: " & oInstance.SystemType
        WScript.Echo "TotalPhysicalMemoryInGB: " & Round(oInstance.TotalPhysicalMemory / 1024 / 1000 / 1000, 1)
        If IsArray(oInstance.Roles) = True Then
            WScript.Echo "Roles: " & Join(oInstance.Roles,";")
        Else
            WScript.Echo "Roles: " & oInstance.Roles
        End If
        
        'ON ERROR RESUME NEXT
        ' Win2000/XP/2003 properties. Will throw an error on Vista/Longhorn.
        'WScript.Echo "SystemStartupOptions: " & Join(oInstance.SystemStartupOptions,";")
        WScript.Echo "SystemStartupSetting: " & oInstance.SystemStartupOptions(oInstance.SystemStartupSetting)

        If Err.number <> 0 Then
            'WScript.Echo "SystemStartupOptions: " & "Unknown"
            WScript.Echo "SystemStartupSetting: " & "Unknown"
        End If
        'ON ERROR GOTO 0                
        WScript.Echo ""
        
        Set newClassNode = oXMLDoc.createNode(1, "WMICLASSINSTANCE", "")
        newClassNode.SetAttribute "Name", oInstance.Name
        newClassNode.SetAttribute "WMIClass", "Win32_ComputerSystem"
        newClassNode.SetAttribute "ExecutionTime", Now()
        newClassNode.SetAttribute "Manufacturer", oInstance.Manufacturer
        newClassNode.SetAttribute "Model", oInstance.Model
        newClassNode.SetAttribute "NumberofProcessors", oInstance.NumberOfProcessors
        'ON ERROR RESUME NEXT        
        If oInstance.PartOfDomain = True Then
            bPartOfDomain = "True"
        Else
            bPartOfDomain = "False"
        End if
        newClassNode.SetAttribute "PartOfDomain", bPartOfDomain
        'ON ERROR GOTO 0
        newClassNode.SetAttribute "Domain", oInstance.Domain
        newClassNode.SetAttribute "DomainRole", DomainRoleTranslator(oInstance.DomainRole)        
        newClassNode.SetAttribute "SystemType", oInstance.SystemType
        iPhysicalMemory = oInstance.TotalPhysicalMemory / 1024 / 1000 / 1000
        iPhysicalMemory = Round(iPhysicalMemory, 1)        
        newClassNode.SetAttribute "TotalPhysicalMemoryInGB", iPhysicalMemory
        If IsArray(oInstance.Roles) = True Then
            newClassNode.SetAttribute "Roles", Join(oInstance.Roles,";")
        Else
            newClassNode.SetAttribute "Roles", oInstance.Roles
        End If
        
        'ON ERROR RESUME NEXT
        ' Win2000/XP/2003 properties. Will throw an error on Vista/Longhorn.
        'newClassNode.SetAttribute "SystemStartupOptions", Join(oInstance.SystemStartupOptions,";")
        newClassNode.SetAttribute "SystemStartupSetting", oInstance.SystemStartupOptions(oInstance.SystemStartupSetting)
        If Err.number <> 0 Then
            'newClassNode.SetAttribute "SystemStartupOptions", "Unknown"
            newClassNode.SetAttribute "SystemStartupSetting", "Unknown"
        End If
        'ON ERROR GOTO 0
                
        oServerNode.appendChild newClassNode
        oXMLDoc.save OUTPUT_XML_FILE                
    Next    
End Sub

Function ConnectToWMIService(sComputer, sWMINamespace, sUserName, sPassword)
    If sWMINamespace = "" Then
        sWMINamespace = "root\cimv2"
    End If
    
    Set oWMILocator = CreateObject("WbemScripting.SWbemLocator")
    
    'ON ERROR RESUME NEXT
    Set oWMIService = oWMILocator.ConnectServer(sComputer, sWMINamespace)    
    If Err.number <> 0 Then
        WScript.Echo "Failed to connect to server " & chr(34) & sComputer & chr(34)
        ConnectToWMIService = Nothing
    Else
        Set ConnectToWMIService = oWMIService
    End If
    'ON ERROR GOTO 0    
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
    sSyntax = "CScript GetWin32ComputerSystem.vbs <computer[;computer]>"
    
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


' Arguments
' - Computers to gather from.



' Connect to each computer.

' Get Win32_Computer System

' Save the results to output.xml.
' Output to command prompt
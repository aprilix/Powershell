'// Version v1.1
Const HKEY_CLASSES_ROOT  = &H80000000
Const HKEY_CURRENT_USER  = &H80000001
Const HKEY_LOCAL_MACHINE = &H80000002
Const HKEY_USERS         = &H80000003
Const REG_SZ = 1
Const REG_EXPAND_SZ = 2
Const REG_BINARY = 3
Const REG_DWORD = 4
Const REG_MULTI_SZ = 7

Dim g_aComputers
Dim g_RegKeyFile
Dim xmldoc
Const OUTPUT_XML_FILE = "output.xml"

Main

Sub Main()
    ProcessArguments
    OpenOrCreateOutputXML OUTPUT_XML_FILE
    aRegKeyObjects = GetData()
End Sub

Function GetData()
    For i = 0 to UBound(g_aComputers)
        aRegKeys = ReadFileIntoArray(g_RegKeyFile)
        GetData = GetRegistryData(g_aComputers(i), xmldoc, aRegKeys)        
    Next
End Function

Function GetRegistryKeyFromPath(sRegKeyPath)
    iLocBackSlash = Instr(1, sRegKeyPath, "\", 1)
    GetRegistryKeyFromPath = Mid(sRegKeyPath, iLocBackSlash + 1)    
End Function

Function GetRegistryHiveFromPath(sRegKeyPath)
    iLocBackSlash = Instr(1, sRegKeyPath, "\", 1)
    sRegHive = Left(sRegKeyPath, iLocBackSlash - 1)
    SELECT CASE sRegHive
        CASE "HKEY_CLASSES_ROOT"
            GetRegistryHiveFromPath = HKEY_CLASSES_ROOT
        CASE "HKCR"
            GetRegistryHiveFromPath = HKEY_CLASSES_ROOT
        CASE "HKEY_CURRENT_USER"
            GetRegistryHiveFromPath = HKEY_CURRENT_USER
        CASE "HKCU"
            GetRegistryHiveFromPath = HKEY_CURRENT_USER        
        CASE "HKEY_LOCAL_MACHINE"
            GetRegistryHiveFromPath = HKEY_LOCAL_MACHINE
        CASE "HKLM"
            GetRegistryHiveFromPath = HKEY_LOCAL_MACHINE       
        CASE "HKEY_USERS"
            GetRegistryHiveFromPath = HKEY_USERS
        CASE Else
            GetRegistryHiveFromPath = HKEY_LOCAL_MACHINE                   
    END SELECT    
End Function

Function GetRegistryData(sComputer, oXMLDoc, aRegKeys)
    Dim aRegistryObjects(), o, i
    Set oXMLRoot = oXMLDoc.documentElement
    Set oServerNode = LocateOrCreateServerNode(xmldoc, sComputer)
    ON ERROR RESUME NEXT
    Set oWMIService = ConnectToWMIService(sComputer,"root\default", "", "")
    If Err.number <> 0 Then
        WScript.Echo "No Connection"
        Exit Function
    End If
    ON ERROR GOTO 0
    Set oRegistry = oWMIService.Get("StdRegProv")
    Set oXMLRoot = xmldoc.documentElement
    Set oXMLServerNode = LocateOrCreateServerNode(xmldoc, sComputer)    
    o = 0
    For r = 0 to UBound(aRegKeys)
        iLocBackSlash = Instr(1, aRegKeys(r), "\", 1)
        sRegHive = Left(aRegKeys(r), iLocBackSlash - 1)    
        hRegHive = GetRegistryHiveFromPath(aRegKeys(r))
        sRegKeyPath = GetRegistryKeyFromPath(aRegKeys(r))
        lRC = oRegistry.EnumKey(hRegHive, sRegKeyPath, aKeys)
        If IsNull(aKeys) = False Then
            aRegistryObjectsReturned = RecursiveRegKeyEnumeration(oRegistry, sRegHive, hRegHive, sRegKeyPath, aKeys)
            ON ERROR RESUME NEXT
            iUBoundTest = UBound(aRegistryObjectsReturned)
            If Err.number = 0 Then
'                For i = 0 to UBound(aRegistryObjectsReturned)
'                    ReDim Preserve aRegistryObjects(o)
'                    Set aRegistryObjects(o) = aRegistryObjectsReturned(i)
'                    o = o + 1                        
'                Next            
                Set oXMLRegistryNode = xmldoc.createNode(1, "REGISTRY", "")
                oXMLServerNode.appendChild oXMLRegistryNode                
                For o = 0 to UBound(aRegistryObjectsReturned)
                    Set newClassNode = xmldoc.createNode(1, "KEY", "")
                    newClassNode.SetAttribute "Name", aRegistryObjectsReturned(o).Key
                    newClassNode.SetAttribute "Value", aRegistryObjectsReturned(o).Value
                    oXMLRegistryNode.appendChild newClassNode
                Next
            End If
            ON ERROR GOTO 0
            
        End If                        
    Next    
    xmldoc.save OUTPUT_XML_FILE      
End Function

Function RecursiveRegKeyEnumeration(oRegistry, sRegHive, hRegHive, sRegKeyPath, aKeys)
    Dim aRegistryObjects(), o
    o = 0
    For k = 0 to UBound(aKeys)
        sKey = sRegKeyPath & "\" & aKeys(k)
        lRC = oRegistry.EnumValues(hRegHive, sKey, aNames, aTypes)
        If IsNull(aNames) = False Then
            For n = 0 to UBound(aNames)                        
                sRegValue = CStr(GetRegistryKeyValue(oRegistry, hRegHive, sKey, aNames(n), aTypes(n)))                        
                sFullRegKey = sRegHive & "\" & sKey & "\" & aNames(n)
                Set oRegKey = New ObjectRegistryKey
                oRegKey.Key = sFullRegKey                        
                oRegKey.Value = sRegValue
                WScript.Echo sFullRegKey & ": " & sRegValue
                ReDim Preserve aRegistryObjects(o)
                Set aRegistryObjects(o) = oRegKey
                o = o + 1
            Next        
        End If
        lRC = oRegistry.EnumKey(hRegHive, sKey, aSubKeys)
        If IsNull(aSubKeys) = False Then
            aSubRegKeyObjects = RecursiveRegKeyEnumeration(oRegistry, sRegHive, hRegHive, sKey, aSubKeys)
            ON ERROR RESUME NEXT
            iUBoundTest = UBound(aSubRegKeyObjects)
            If Err.number = 0 Then
                For Each oSubRegKey in aSubRegKeyObjects
                    ReDim Preserve aRegistryObjects(o)
                    Set aRegistryObjects(o) = oSubRegKey
                    o = o + 1        
                Next                    
            End If
        End If
    Next
    RecursiveRegKeyEnumeration = aRegistryObjects
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
    sSyntax = "CScript GetRegistryKeyValues.vbs <computer[;computer]> [RegKeyTxtFile]"
    
    Set oArgs = WScript.Arguments
    
    SELECT CASE oArgs.Count
        CASE 0
            WScript.Echo sSyntax
            WScript.Quit
        CASE 1
            sComputers = oArgs(0)
            g_RegKeyFile = "IISHCRegKeys.txt"
        CASE 2
            sComputers = oArgs(0)
            g_RegKeyFile = oArgs(1)            
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

Function ReadFileIntoArray(sFilePath)
	Dim aRegKeys(), i
	Const ForReading = 1, ForWriting = 2, ForAppending = 8
	Set oFSO = CreateObject("Scripting.FileSystemObject")
	Set oFile = oFSO.OpenTextFile(sFilePath, ForReading, False)
    i = 0
	Do Until oFile.AtEndOfStream = True
		strReadLine = oFile.ReadLine
		ReDim Preserve aRegKeys(i)
		aRegKeys(i) = Trim(strReadLine)
		i = i + 1
	Loop
	oFile.Close
	ReadFileIntoArray = aRegKeys
End Function

Function GetRegistryKeyValue(oRegistry, hHive, sRegKeyPath, sRegKey, iType)
    ' Returns a string value of the registry key.
    SELECT CASE iType
        CASE REG_SZ
            oRegistry.GetStringValue hHive, sRegKeyPath, sRegKey, sValue
            GetRegistryKeyValue = CStr(sValue)
        CASE REG_EXPAND_SZ
            oRegistry.GetExpandedStringValue hHive, sRegKeyPath, sRegKey, sValue
            GetRegistryKeyValue = CStr(sValue)
        CASE REG_BINARY            
            oRegistry.GetBinaryValue hHive, sRegKeyPath, sRegKey, aValues
            GetRegistryKeyValue = CStr(Join(aValues))
        CASE REG_DWORD            
            oRegistry.GetDWORDValue hHive, sRegKeyPath, sRegKey, sValue
            GetRegistryKeyValue = CStr(sValue)
        CASE REG_MULTI_SZ            
            oRegistry.GetMultiStringValue hHive, sRegKeyPath, sRegKey, aValues
            GetRegistryKeyValue = CStr(Join(aValues))
    END SELECT
End Function

Class ObjectRegistryKey
    Public Key
    Public Value
End Class
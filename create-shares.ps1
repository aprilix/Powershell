$folderPath = 'e:\public'
$Shares=[WMICLASS]'WIN32_Share'
$ShareName='EPublic'

$trustee = ([wmiclass]‘Win32_trustee’).psbase.CreateInstance()
$trustee.Domain = "NT Authority"
$trustee.Name = “Authenticated Users”

$ace = ([wmiclass]‘Win32_ACE’).psbase.CreateInstance()
$ace.AccessMask = 1245631
$ace.AceFlags = 3
$ace.AceType = 0
$ace.Trustee = $trustee

$trustee2 = ([wmiclass]‘Win32_trustee’).psbase.CreateInstance()
$trustee2.Domain = "BUILTIN"  #Or domain name
$trustee2.Name = “Administrators”

$ace2 = ([wmiclass]‘Win32_ACE’).psbase.CreateInstance()
$ace2.AccessMask = 2032127
$ace2.AceFlags = 3
$ace2.AceType = 0
$ace2.Trustee = $trustee2

$sd = ([wmiclass]‘Win32_SecurityDescriptor’).psbase.CreateInstance()
$sd.ControlFlags = 4
$sd.DACL = $ace, $ace2
$sd.group = $trustee2
$sd.owner = $trustee2

$shares.create($FolderPath, $ShareName, 0, 100, "Description", "", $sd) | Out-Null

$Acl = Get-Acl $FolderPath
$Acl.SetAccessRuleProtection($True, $False)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule('Administrators','FullControl','ContainerInherit, ObjectInherit', 'None', 
'Allow')
$Acl.AddAccessRule($rule)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule('SYSTEM','FullControl','ContainerInherit, ObjectInherit', 'None', 'Allow')
$Acl.AddAccessRule($rule)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users",@("ReadData", "AppendData", "Synchronize"), "None", 
"None", "Allow")
$Acl.AddAccessRule($rule)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule('CREATOR OWNER','FullControl','ContainerInherit, ObjectInherit', 'InheritOnly', 
'Allow')
$Acl.AddAccessRule($rule)

Set-Acl $FolderPath $Acl | Out-Null
Get-Acl $FolderPath  | Format-List
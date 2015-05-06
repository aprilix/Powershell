#// 
#// HotfixLookup.ps1
#// Written by Clint Huffman (clinth@microsoft.com)
#// Version: 1.0
#//

If ($args.Count -eq 2)
{
	$sComputer = $args[0]
	$sOutputFile = $args[1]
}
Else
{
	Write-Host "HotfixLookup.ps1 Computer OutputFilePath"
	Break;
}

Function Get-TextFromWebPage($url,$LeftBound,$RightBound)
{
	$ie.navigate2($url)
	while ($ie.ReadyState -ne 4)
	{	
		Start-Sleep 1
	}
	$body = $ie.Document.Body.innerHtml
	$LocLeftBound = $body.IndexOf($LeftBound) + $LeftBound.Length
	$LocRightBound = $body.IndexOf($RightBound)
	$body.SubString($LocLeftBound,$LocRightBound-$LocLeftBound)
}

Function Remove-ExtraText($sText)
{
	$sText = $sText -replace "KB",""
	$sText = $sText -replace "Q",""
	$sText = $sText -replace "-v2",""
	If ($sText.Length -gt 6)
	{
		$sText = $sText.SubString(0,6)
	}
	Return $sText
}

Function IsNumeric($value)
{
	[double] $number = 0
	If ([double]::TryParse($value, [REF]$number))
	{
		Return $true
	}
	Else
	{
		Return $false
	}
}

$Hotfixes = Get-wmiobject -Query "SELECT HotFixID,ServicePackInEffect FROM Win32_QuickFixEngineering" -ComputerName $sComputer
$alHotfixes = New-Object System.Collections.ArrayList
Foreach ($h in $Hotfixes)
{
	$temp = Remove-ExtraText $h.HotFixId
	[double] $number = 0
	If (IsNumeric $temp)
	{
		If ($temp.Length -eq 6)
		{
			[void] $alHotfixes.Add($temp)
		}
	}
	Else
	{
		$temp = Remove-ExtraText $h.ServicePackInEffect
		If ([double]::TryParse($temp, [REF]$number))
		{
			If (IsNumeric $temp)
			{
				[void] $alHotfixes.Add($temp)
			}
		}
	}
}

[Void] [Reflection.Assembly]::LoadWithPartialName("System.Web")
$ie = New-Object -ComObject "InternetExplorer.Application"
$ie.visible = $false

Out-File -FilePath $sOutputFile

Foreach ($h in $alHotfixes)
{
	$url = "http://support.microsoft.com/kb/$h"
	$HotfixName = Get-TextFromWebPage $url "<H1 class=title>" "</H1>"
	"$h $HotFixName" >> $sOutputFile
	$url >> $sOutputFile
	"" >> $sOutputFile
	Write-host $h $HotfixName
	Write-host $url
	Write-Host ""
}

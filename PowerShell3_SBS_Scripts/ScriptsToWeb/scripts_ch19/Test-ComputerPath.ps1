# -----------------------------------------------------------------------------
# Script: Test-ComputerPath.ps1
# Author: ed wilson, msft
# Date: 04/22/2012 16:35:03
# Keywords: Scripting Techniques, Error Handling
# comments: 
# PowerShell 3.0 Step-by-Step, Microsoft Press, 2012
# Chapter 19
# -----------------------------------------------------------------------------
Param([string]$computer = $env:COMPUTERNAME)
if(Test-Connection -computer $computer -BufferSize 16 -Count 1 -Quiet) 
 { Get-WmiObject -class Win32_Bios -computer $computer }
Else
 { "Unable to reach $computer computer"}

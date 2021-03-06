# -----------------------------------------------------------------------------
# Script: TestTryMultipleCatchFinally.ps1
# Author: ed wilson, msft
# Date: 04/22/2012 17:12:21
# Keywords: Scripting Techniques, Error Handling
# comments: Using Try /Catch/ Finally
# PowerShell 3.0 Step-by-Step, Microsoft Press, 2012
# Chapter 19
# -----------------------------------------------------------------------------
$obj1 = "BadObject"
"Begin test ..."
$ErrorActionPreference = "stop"
Try
 {
  "`tAttempting to create new object $obj1 ..."
   $a = new-object $obj1
   "Members of the $obj1"
   "New object $obj1 created"
   $a | Get-Member
 }
Catch [System.Management.Automation.PSArgumentException]
 {
  "`tObject not found exception. `n`tCannot find the assembly for $obj1"
 }
Catch [system.exception]
 {
  "Did not catch argument exception."
  "Caught a generic system exception instead"
 }
Finally
 {
  "end of script"
 }

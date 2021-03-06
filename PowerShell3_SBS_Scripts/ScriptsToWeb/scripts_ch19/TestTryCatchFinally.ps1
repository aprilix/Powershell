# -----------------------------------------------------------------------------
# Script: TestTryCatchFinally.ps1
# Author: ed wilson, msft
# Date: 04/22/2012 17:11:29
# Keywords: Scripting Techniques, Error Handling
# comments: Using Try/catch/finally
# PowerShell 3.0 Step-by-Step, Microsoft Press, 2012
# Chapter 19
# -----------------------------------------------------------------------------
$obj1 = "Bad.Object"
"Begin test"
Try
 {
  "`tAttempting to create new object $obj1"
   $a = new-object $obj1
   "Members of the $obj1"
   "New object $obj1 created"
   $a | Get-Member
 }
Catch [system.exception]
 {
  "`tcaught a system exception"
 }
Finally
 {
  "end of script"
 }

 
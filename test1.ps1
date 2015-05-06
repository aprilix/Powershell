$test = Get-Content computers.txt

foreach ($a in $test)
{
   Set-Location \\$a\C$\temp
   invoke-command -ScriptBlock ".\Query_Value.ps1" 
}

$data = Get-Content input.txt
write-host $data.count total lines read from file
foreach ($line in $data)
{
    write-host $line
}
function Cleanfiles ([string] $files, [string] $path) {
Remove-item -recurse -path $path -include -$files -force
}
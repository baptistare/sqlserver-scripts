--tamanho discos
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='G:'" | Select-Object size. freeSpace
$disk.size
$disk.freeSpace
(($disk.size - disk.freeSpace) / $disk.size)

--blockSize 
Get-WmiObject -Class Win32_Volume | Select-Object Label, BlockSize | Format-Table -AutoSize





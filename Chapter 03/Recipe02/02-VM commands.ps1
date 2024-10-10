$disk = Get-Disk | Where-Object partitionstyle -eq 'raw'
$disk | 
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -DriveLetter F -UseMaximumSize

# Install DiskSpd before proceding
.\DiskSpd.exe -c200G -w30 -t4 -o64 -b64K -d30 -r -Sh F:
.\DiskSpd.exe -c200G -w30 -t4 -o64 -b64K -W2100 -d30 -r -Sh F:
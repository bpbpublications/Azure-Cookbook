$envPrefix = "Recipe10-04"
$location = "westeurope"
$rgName = "$envPrefix-rg"
$vmName = "AutoUpdated-VM"

New-AzTag -Tag @{PatchingGroup="Group1";} `
    -ResourceId (Get-AzVM -Name $vmName -ResourceGroupName $rgName).Id
    
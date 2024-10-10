$envPrefix = "Recipe05-01-ACI"
$location = "westeurope"
$rgName = "$envPrefix-rg"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

$aciName = "recipe05-01-helloworld-aci"

$aciObj = New-AzContainerInstanceObject -Name $aciName `
    -Image httpd:2.4 `
    -RequestCpu 1 `
    -RequestMemoryInGb 1.5 `
    -Port (New-AzContainerInstancePortObject -Port 80 -Protocol TCP)

New-AzContainerGroup -ResourceGroupName $rgName `
    -Name $aciName `
    -Container $aciObj `
    -OsType Linux `
    -IPAddressType Public `
    -Location $location
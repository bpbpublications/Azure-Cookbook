$envPrefix = "Recipe10-02"
$location = "westeurope"
$rgName = "$envPrefix-rg"
$vmName = "AutoManaged-VM"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# Upload the main.bicep file from the Chapter 10/Recipe02 folder to cloud shell

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile .\main.bicep `
    -vmName $vmName `
    -envPrefix $envPrefix
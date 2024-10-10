$envPrefix = "Recipe02-01"
$location = "westeurope"
$rgName = "$envPrefix-rg"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# Upload the main.bicep file from the Chapter 02/Recipe01 folder to cloud shell

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile .\main.bicep `
    -envPrefix $envPrefix
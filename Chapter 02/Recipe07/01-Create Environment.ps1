$envPrefix = "Recipe02-07"
$location = "westeurope"
$rgName = "$envPrefix-rg"
$dnsDomainName = "azurecookbook.info"
$dnsDomainARecordName = "zerotrust"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# Upload the main.bicep file from the Chapter 02/Recipe07 folder to cloud shell


New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile .\main.bicep `
    -envPrefix $envPrefix `
    -dnsDomainName $dnsDomainName `
    -dnsDomainARecordName $dnsDomainARecordName

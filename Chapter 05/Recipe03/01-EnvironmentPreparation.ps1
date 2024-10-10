Register-AzResourceProvider -ProviderNamespace Microsoft.App

$envPrefix = "Recipe05-03"
$location = "westeurope"
$rgName = "$envPrefix-rg"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

$environmentName = "$envPrefix-environment"

## Create Container Apps environment
New-AzContainerAppManagedEnv -ResourceGroupName $rgName `
    -Name $environmentName `
    -Location $location `
    -VnetConfigurationInternal:$false


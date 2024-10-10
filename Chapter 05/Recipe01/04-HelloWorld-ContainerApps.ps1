Register-AzResourceProvider -ProviderNamespace Microsoft.App

$envPrefix = "Recipe05-01-ContainerApps"
$location = "westeurope"
$rgName = "$envPrefix-rg"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

$cAppName = "recipe05-01-ContainerApp"
$environmentName = "$cAppName-environment"

## Create Container Apps environment
New-AzContainerAppManagedEnv -ResourceGroupName $rgName `
    -Name $environmentName `
    -Location $location `
    -VnetConfigurationInternal:$false


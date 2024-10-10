$envPrefix = "Recipe07-03"
$location = "westeurope"
$rgName = "$envPrefix-rg"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# Upload the main.bicep file from the Chapter 07/Recipe02 folder to cloud shell

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile .\main.bicep `
    -envPrefix $envPrefix `
    -Location $location

# Execute on the VM via RunCommand
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module Az.Storage -Force
Install-Moduke Az.Resources -Force
Get-Module -ListAvailable Az.Storage 
$envPrefix = "Recipe11-06"
$location = "westeurope"
$rgName = "$envPrefix-rg"
$vmName = "Demo-VM"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

if (Get-Item .\main.bicep) {
    Remove-Item .\main.bicep
}

Invoke-WebRequest -URI "https://raw.githubusercontent.com/AzureMasterchef/AzureCookbook/main/11-Azure%20Monitoring/Recipe06/main.bicep" `
    -OutFile main.bicep

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile .\main.bicep `
    -vmName $vmName `
    -envPrefix $envPrefix
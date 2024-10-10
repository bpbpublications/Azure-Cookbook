$envPrefix = "Recipe06-05"
$location = "westeurope"
$rgName = "$envPrefix-rg"

# Create the resource group
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# Create the ACR used for Bicep files
$acrName = "$($envPrefix.Replace('-', ''))$(Get-Random -Minimum 1000 -Maximum 99999999)"
$acr = Get-AzContainerRegistry -Name $acrName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if(-not $acr) {
    $acr = New-AzContainerRegistry -Name $acrName `
                -ResourceGroupName $rgName `
                -Location $location `
                -Sku Basic
}

Write-Host "ACR uri: $($acr.LoginServer)"


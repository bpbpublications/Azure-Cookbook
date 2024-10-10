$envPrefix = "Recipe01-05"
$location = "westeurope"
$rgName = "$envPrefix-rg"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

$storageAccountName = "$(($envPrefix.Replace('-','')).ToLower())$(Get-Random -Minimum 1000 -Maximum 999999999)sa"

New-AzStorageAccount -Name $storageAccountName `
    -ResourceGroupName $rgName `
    -Location $location `
    -SkuName Standard_LRS `
    -Kind StorageV2 `
    -EnableHttpsTrafficOnly $true `
    -MinimumTlsVersion TLS1_2 `
    -AccessTier Hot `
    -AllowBlobPublicAccess $true `
    -EnableHierarchicalNamespace $true
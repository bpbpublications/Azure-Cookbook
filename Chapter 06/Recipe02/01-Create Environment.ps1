$envPrefix = "Recipe06-02"
$location = "westeurope"
$rgName = "$envPrefix-rg"

# Create the resource group
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# Create the virtual network
$vnetName = "$envPrefix-vnet"
$vnetAddressPrefix = "10.0.0.0/16"
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if(-not $vnet) {
    $vnet = New-AzVirtualNetwork -Name $vnetName `
                -ResourceGroupName $rgName `
                -Location $location `
                -AddressPrefix $vnetAddressPrefix
}
Write-Host "Virtual network name: $vnetName"

# Get the Object ID of the Container Instance service principal
$ociSp = Get-AzADServicePrincipal -DisplayName "Azure Container Instance Service"
Write-Host "Azure Container Instance Service object id: $($ociSp.Id)"

# Get the virtual network parameter file and modify it
$paramFileUrl = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/demos/cloud-shell-vnet/azuredeploy.parameters.json"
Invoke-WebRequest -Uri $paramFileUrl -OutFile "vnet.parameters.json"

code vnet.parameters.json

# Deploy the virtual network updates via the ARM template
$vnetTemplateUrl = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/demos/cloud-shell-vnet/azuredeploy.json"

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateUri $vnetTemplateUrl `
    -TemplateParameterFile "vnet.parameters.json"

# Get the storage parameter file and modify it
$paramFileUrl = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/demos/cloud-shell-vnet-storage/azuredeploy.parameters.json"
Invoke-WebRequest -Uri $paramFileUrl -OutFile "storage.parameters.json"

code storage.parameters.json

# Deploy the virtual network updates via the ARM template
$storageTemplateUrl = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/demos/cloud-shell-vnet-storage/azuredeploy.json"

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateUri $storageTemplateUrl `
    -TemplateParameterFile "storage.parameters.json"

# Create a subnet for the Linux VM in our virtual network
$envPrefix = "Recipe06-02"
$location = "westeurope"
$rgName = "$envPrefix-rg"
$vnetName = "$envPrefix-vnet"
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgName
Add-AzVirtualNetworkSubnetConfig -Name "vmsubnet" -AddressPrefix "10.0.10.0/24" -VirtualNetwork $vnet | Set-AzVirtualNetwork

# Create a Linux VM
$vm = New-AzVm `
    -ResourceGroupName $rgName `
    -Name 'LinuxVM' `
    -Location $location `
    -image Debian11 `
    -size Standard_B2s `
    -VirtualNetworkName $vnetName `
    -SubnetName "vmsubnet" `
    -Credential (Get-Credential -UserName demouser -Message "Provide a password for the virtual machine")

Write-Host "Linux VM private ip: $((Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].id | Get-AzNetworkInterfaceIpConfig).PrivateIpAddress)"

ssh demouser@10.0.10.4
$envPrefix = "Recipe03-02"
$location = "westeurope"
$rgName = "$envPrefix-rg"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

$subnetList = @()
$subnetList += New-AzVirtualNetworkSubnetConfig -Name "subnet1" -AddressPrefix "10.0.0.0/25"
$subnetList += New-AzVirtualNetworkSubnetConfig -Name "AzureBastionSubnet" -AddressPrefix "10.0.0.128/25"

$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName `
    -Name "$envPrefix-VNET" `
    -AddressPrefix "10.0.0.0/24" `
    -Location $location `
    -Subnet $subnetList

# Create a bastion to connect to the VM
$pip = New-AzPublicIpAddress -ResourceGroupName $rgName `
        -Name "$envPrefix-PIP" `
        -AllocationMethod Static `
        -Sku Standard `
        -Location $location

New-AzBastion -ResourceGroupName $rgName `
    -Name "$envPrefix-BASTION" `
    -VirtualNetworkId $vnet.Id `
    -Sku Basic `
    -PublicIpAddressId $pip.Id `
    -ScaleUnit 2

# Create the VM and its disk
$adminPassword = Read-Host -Prompt "Enter the password for the VM" -AsSecureString
$credential = New-Object PSCredential "adminUser", $adminPassword
$nic = New-AzNetworkInterface -ResourceGroupName $rgName `
    -Name "$envPrefix-VM-NIC" `
    -Location $location `
    -SubnetId $vnet.Subnets[0].Id `
    -EnableAcceleratedNetworking
$diskconfig = New-AzDiskConfig `
                -Location $location `
                -Zone 1 `
                -DiskSizeGB 2048 `
                -DiskIOPSReadWrite 8800 `
                -DiskMBpsReadWrite 550 `
                -AccountType PremiumV2_LRS `
                -LogicalSectorSize 4096 `
                -CreateOption Empty
$dataDisk = New-AzDisk `
                -ResourceGroupName $rgName `
                -DiskName "$envPrefix-VM-DataDisk" `
                -Disk $diskconfig
$vmConfig = New-AzVMConfig -VMName "$envPrefix-VM" `
                -VMSize "Standard_E4bds_v5" `
                -Zone 1
Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" `
                -Offer "WindowsServer" `
                -Skus "2022-datacenter-azure-edition" `
                -Version "latest" `
                -VM $vmConfig
Set-AzVMOperatingSystem -Windows `
                -ComputerName "$envPrefix-VM" `
                -Credential $credential `
                -ProvisionVMAgent `
                -EnableAutoUpdate `
                -VM $vmConfig
$vmConfig | Add-AzVMNetworkInterface -Id $nic.Id
Add-AzVMDataDisk -VM $vmConfig `
    -Name "$envPrefix-VM-DataDisk"  `
    -CreateOption Attach `
    -ManagedDiskId $dataDisk.Id `
    -Lun 0 `
    -Caching None

$vmConfig | New-AzVM -ResourceGroupName $rgName -Location $location

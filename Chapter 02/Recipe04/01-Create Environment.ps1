$envPrefix = "Recipe02-04"
$location = "westeurope"
$rgName = "$envPrefix-rg"
$vmName = "DEMO-VM"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# Upload the main.bicep file from the Chapter 02/Recipe04 folder to cloud shell

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile .\main.bicep `
    -vmName $vmName `
    -envPrefix $envPrefix

# Create the private DNS zone and link it to the virtual network with auto-registration enabled
New-AzPrivateDnsZone -ResourceGroupName $rgName `
            -Name "internal.azurecookbook.info"

$vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name "$envPrefix-VNET"

New-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $rgName `
    -Name 'recipe02-04-vnetlink' `
    -ZoneName "internal.azurecookbook.info" `
    -VirtualNetworkId $vnet.Id `
    -EnableRegistration

# Create a CNAME record for the VM
New-AzPrivateDnsRecordSet -ResourceGroupName $rgName `
    -ZoneName "internal.azurecookbook.info" `
    -Name vm-alias `
    -RecordType CNAME `
    -Ttl 300 `
    -DnsRecords (New-AzPrivateDnsRecordConfig -Cname $vmName)



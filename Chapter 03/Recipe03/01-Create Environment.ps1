$envPrefix = "Recipe03-03"
$location = "westeurope"
$rgName = "$envPrefix-rg"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

$subnetList = @()
$subnetList += New-AzVirtualNetworkSubnetConfig -Name "subnet1" -AddressPrefix "10.0.0.0/25"
$subnetList += New-AzVirtualNetworkSubnetConfig -Name "subnet2" -AddressPrefix "10.0.0.128/25"

New-AzVirtualNetwork -ResourceGroupName $rgName `
    -Name "$envPrefix-VNET" `
    -AddressPrefix "10.0.0.0/24" `
    -Location $location `
    -Subnet $subnetList

$installIisScript = @'
New-NetFirewallRule -DisplayName "Allow Port 80" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
Install-WindowsFeature -name web-server
Write-Output "Hello from $($env:COMPUTERNAME)" | Out-File C:\inetpub\wwwroot\default.htm -Force
'@

$installIisScript | Out-File -FilePath .\Install-IIS.ps1

# Create a zone-redundant public load balancer
$pip = New-AzPublicIpAddress -ResourceGroupName $rgName `
        -Name "$envPrefix-PIP" `
        -AllocationMethod Static `
        -Sku Standard `
        -Location $location `
        -Zone 1, 2, 3

$frontendIpConfig = New-AzLoadBalancerFrontendIpConfig -Name "frontendIpConfig" `
                        -PublicIpAddress $pip

$azBackendPool = New-AzLoadBalancerBackendAddressPoolConfig -Name "azBackendPool"
$avsetBackendPool = New-AzLoadBalancerBackendAddressPoolConfig -Name "avsetBackendPool"

$healthProbe = New-AzLoadBalancerProbeConfig -Name HTTP `
                -RequestPath 'default.htm' `
                -Protocol http `
                -Port 80 `
                -IntervalInSeconds 15 `
                -ProbeCount 2

$lb = New-AzLoadBalancer -ResourceGroupName $rgName `
        -Name "$envPrefix-LB" `
        -Location $location `
        -FrontendIpConfiguration $frontendIpConfig `
        -BackendAddressPool @($azBackendPool, $avsetBackendPool) `
        -Probe $healthProbe `
        -Sku Standard


# Create the zonal VMs and add them to the load balanced pool
$adminPassword = Read-Host -Prompt "Enter the password for the VM" -AsSecureString

1 .. 3 | ForEach-Object -Parallel {
    $vm = New-AzVM -ResourceGroupName $using:rgName `
        -Name "AZ-VM$_" `
        -Location $using:location `
        -Zone $_ `
        -VirtualNetworkName "$using:envPrefix-vnet" `
        -SubnetName "subnet1" `
        -OpenPorts 80 `
        -Credential (New-Object PSCredential "adminUser", $using:adminPassword) `
        -Image Win2022AzureEdition `
        -Size "Standard_B2s"

    $nic = Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id
    $nic.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($using:azBackendPool)

    $nic | Set-AzNetworkInterface

    Invoke-AzVMRunCommand -ResourceGroupName $using:rgName `
        -VMName $vm.Name `
        -CommandId 'RunPowerShellScript' `
        -ScriptPath .\Install-IIS.ps1
}

Add-AzLoadBalancerRuleConfig -Name HTTP8080 `
    -LoadBalancer $lb `
    -FrontendIpConfiguration $frontendIpConfig `
    -BackendAddressPool $azBackendPool `
    -Probe $healthProbe `
    -Protocol Tcp `
    -FrontendPort 8080 `
    -BackendPort 80 | Set-AzLoadBalancer


# Create VMs in an availability set and add them to the load balanced pool
$avSet = New-AzAvailabilitySet -ResourceGroupName $rgName `
            -Name "$envPrefix-AVSET" `
            -Location $location `
            -Sku Aligned `
            -PlatformFaultDomainCount 3 `
            -PlatformUpdateDomainCount 3

$adminPassword = Read-Host -Prompt "Enter the password for the VM" -AsSecureString

1 .. 3 | ForEach-Object -Parallel {
    $vm = New-AzVM -ResourceGroupName $using:rgName `
        -Name "AVSET-VM$_" `
        -Location $using:location `
        -AvailabilitySetName $using:avSet.Name `
        -VirtualNetworkName "$using:envPrefix-VNET" `
        -SubnetName "subnet2" `
        -OpenPorts 80 `
        -Credential (New-Object PSCredential "adminUser", $using:adminPassword) `
        -Image Win2022AzureEdition `
        -Size "Standard_B2s"

    $nic = Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id
    $nic.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($using:avsetBackendPool)

    $nic | Set-AzNetworkInterface

    Invoke-AzVMRunCommand -ResourceGroupName $using:rgName `
        -VMName $vm.Name `
        -CommandId 'RunPowerShellScript' `
        -ScriptPath .\Install-IIS.ps1
}

Add-AzLoadBalancerRuleConfig -Name HTTP8081 `
    -LoadBalancer $lb `
    -FrontendIpConfiguration $frontendIpConfig `
    -BackendAddressPool $avsetBackendPool `
    -Probe $healthProbe `
    -Protocol Tcp `
    -FrontendPort 8081 `
    -BackendPort 80 | Set-AzLoadBalancer

# View update domain and fault domain
$avSet | Get-AzAvailabilitySet -Expand UpdateDomains, FaultDomains
$envPrefix = "Recipe02-01"
$location = "westeurope"
$rgName = "$envPrefix-rg"

# Create peerings between the spokes and the hub
$spokes = Get-AzVirtualNetwork -ResourceGroupName $rgName | Where-Object { $_.Name -like "*spoke*" }
$hub = Get-AzVirtualNetwork -ResourceGroupName $rgName | Where-Object { $_.Name -like "*hub*" }

foreach ($spoke in $spokes) {
    # Spoke to hub
    Add-AzVirtualNetworkPeering -VirtualNetwork $spoke `
        -Name "$($spoke.Name)-to-$($hub.Name)" `
        -RemoteVirtualNetworkId $hub.Id `
        -AllowForwardedTraffic
    
    # Hub to spoke
    Add-AzVirtualNetworkPeering -VirtualNetwork $hub `
        -Name "$($hub.Name)-to-$($spoke.Name)" `
        -RemoteVirtualNetworkId $spoke.Id `
        -AllowForwardedTraffic
}

# Create a route table for the spokes
$fwPrivateIp = '10.0.0.4'

$spokes = Get-AzVirtualNetwork -ResourceGroupName $rgName | Where-Object { $_.Name -like "*spoke*" }

foreach ($spoke in $spokes) {
    $rt = New-AzRouteTable -ResourceGroupName $rgName `
            -Name "$($spoke.Name)-RT" `
            -Location $location
    # UDR for other spokes
    $otherSpokes = $spokes | Where-Object id -ne $spoke.Id
    foreach ($otherSpoke in $otherSpokes) {
        $rt | Add-AzRouteConfig -Name "to-$($otherSpoke.Name)" `
            -AddressPrefix $otherSpoke.AddressSpace.AddressPrefixes[0] `
            -NextHopType VirtualAppliance `
            -NextHopIpAddress $fwPrivateIp
    }
    # UDR for internet traffic
    $rt | Add-AzRouteConfig -Name "to-internet" `
        -AddressPrefix '0.0.0.0/0' `
        -NextHopType VirtualAppliance `
        -NextHopIpAddress $fwPrivateIp
    $rt | Set-AzRouteTable
    # attach the RT to all the subnets in the spoke
    $spoke.Subnets | ForEach-Object {
        Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $spoke `
            -Name $_.Name `
            -AddressPrefix $_.AddressPrefix `
            -RouteTable $rt
    }
    $spoke | Set-AzVirtualNetwork  
}

# Create the firewall rules
New-AzFirewallPolicyRuleCollectionGroup  -Name "Recipe02-01" `
    -Priority 1000 `
    -FirewallPolicyName "AZFW-POLICY" `
    -ResourceGroupName $rgName

# Management rule
$rdpRule = New-AzFirewallPolicyNetworkRule -Name "RDP-VM1-to-VM2" `
                -Description "Allow RDP from VM1 to VM2" `
                -SourceAddress "192.168.0.10" `
                -DestinationAddress "172.16.0.10" `
                -DestinationPort "3389" `
                -Protocol "TCP"

$mgmtColl = New-AzFirewallPolicyFilterRuleCollection -Name "Allow-Management" `
                -Priority 100 `
                -ActionType "Allow" `
                -Rule $rdpRule

# Public internet rule
$extRule = New-AzFirewallPolicyNetworkRule -Name "Any-VM2-to-internet" `
                -Description "Allow DNS from VM2 to 1.1.1.1" `
                -SourceAddress "172.16.0.10" `
                -DestinationAddress "1.1.1.1" `
                -DestinationPort "53" `
                -Protocol "UDP"

$extColl = New-AzFirewallPolicyFilterRuleCollection -Name "Allow-External" `
                -Priority 200 `
                -ActionType "Allow" `
                -Rule $extRule

Set-AzFirewallPolicyRuleCollectionGroup -Name "Recipe02-01" `
    -ResourceGroupName $rgName `
    -FirewallPolicyName "AZFW-POLICY" `
    -RuleCollection $mgmtColl, $extColl `
    -Priority 200
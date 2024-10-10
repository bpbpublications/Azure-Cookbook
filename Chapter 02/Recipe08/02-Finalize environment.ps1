$envPrefix = "Recipe02-08"
$rgName = "$envPrefix-rg"

# Create the firewall rules

# Public internet rule
$webRule = New-AzFirewallPolicyApplicationRule -Name "aboutme.omegamadlab.com" `
                -Description "Allow connectivity on https://aboutme.omegamadlab.com" `
                -SourceAddress "192.168.0.10" `
                -TargetFqdn "aboutme.omegamadlab.com" `
                -Protocol "HTTPS"
                
$webColl = New-AzFirewallPolicyFilterRuleCollection -Name "Allow-Web" `
                -Priority 100 `
                -ActionType "Allow" `
                -Rule $webRule

New-AzFirewallPolicyRuleCollectionGroup  -Name "Recipe02-08-App" `
    -Priority 1000 `
    -FirewallPolicyName "AZFW-POLICY" `
    -ResourceGroupName $rgName `
    -RuleCollection $webColl

# Change DNS settings
$fw = Get-AzFirewall -Name "AZFW" -ResourceGroupName $rgName
$vnets = Get-AzVirtualNetwork -ResourceGroupName $rgName
foreach($vnet in $vnets) { 
    $vnet.DhcpOptions = New-Object -Type PSObject -Property @{"DnsServers" = $fw.IpConfigurations[0].PrivateIPAddress}
    $vnet | Set-AzVirtualNetwork
}
Get-AzVM -ResourceGroupName $rgName | Restart-AzVM
            
# RDP rule
$rdpRule = New-AzFirewallPolicyNetworkRule -Name "RDP-VM1-to-VM2" `
                -Description "Allow for RDP from VM1 to VM2" `
                -SourceAddress "192.168.0.10" `
                -DestinationFqdn "vm2.internal.azurecookbook.info" `
                -DestinationPort "3389" `
                -Protocol "TCP"

$mgmtColl = New-AzFirewallPolicyFilterRuleCollection -Name "Allow-RDP" `
                -Priority 200 `
                -ActionType "Allow" `
                -Rule $rdpRule

New-AzFirewallPolicyRuleCollectionGroup  -Name "Recipe02-08-Network" `
    -Priority 1100 `
    -FirewallPolicyName "AZFW-POLICY" `
    -ResourceGroupName $rgName `
    -RuleCollection $mgmtColl
$envPrefix = "Recipe02-05"
$location = "westeurope"
$rgName = "$envPrefix-rg"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# Upload the main.bicep file from the Chapter 02/Recipe05 folder to cloud shell

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile .\main.bicep `
    -envPrefix $envPrefix

# Install the DNS server role on the CLIENT-VM
$dnsInstallCommand = @"
# Install the DNS server role
Install-WindowsFeature -Name DNS -IncludeManagementTools
# Create a new DNS zone
Add-DnsServerPrimaryZone -Name 'recipe0205.demo' -ZoneFile 'recipe0205.dns'
# Add an A record to the zone
Add-DnsServerResourceRecordA -Name 'samplerecord' -ZoneName 'recipe0205.demo' -IPv4Address 10.0.0.200
# Output to confirm the actions
Write-Host 'DNS zone recipe0205.demo created with an A record for samplerecord pointing to 10.0.0.200'
"@

$dnsInstallCommand | Out-File -FilePath "dnsInstall.ps1" -Encoding ascii
Invoke-AzVMRunCommand -ResourceGroupName $rgName `
    -VMName "DNS-VM" `
    -CommandId "RunPowerShellScript" `
    -ScriptPath "dnsInstall.ps1"


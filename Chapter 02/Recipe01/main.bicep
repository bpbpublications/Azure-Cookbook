param location string = resourceGroup().location
param vmSize string = 'Standard_D2s_v3'
param envPrefix string
param adminUsername string = 'adminUser'
@secure()
param adminPassword string

var fwName = 'AZFW'

var vmList = [
  {
    name: 'VM1'
    ip: '192.168.0.10'
  }
  {
    name: 'VM2'
    ip: '172.16.0.10'
  } 
]

var spokeList = [
  {
    name: '${envPrefix}-SPOKE1-VNET'
    addressPrefix: '192.168.0.0/24'
    subnetPrefix: '192.168.0.0/25'
  }
  {
    name: '${envPrefix}-SPOKE2-VNET'
    addressPrefix: '172.16.0.0/24'
    subnetPrefix: '172.16.0.0/25'
  }
]

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: '${envPrefix}-HUB-VNET'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/22'
      ]
    }
  }
}

resource fwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: 'AzureFirewallSubnet'
  parent: hubVnet
  properties: {
    addressPrefix: '10.0.0.0/26'
  }
}

resource fwPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: '${fwName}-POLICY'
  location: location
  properties: {
    threatIntelMode: 'Alert'
    sku: {
      tier: 'Standard'
    }
  }
}

resource fwPip 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${fwName}-PIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource fw 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: fwName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'AzureFirewallIpConfig'
        properties: {
          subnet: {
            id: fwSubnet.id
          }
          publicIPAddress: {
            id: fwPip.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: fwPolicy.id
    }
  }
}

output fwPublicIP string = fwPip.properties.ipAddress
output fwPrivateIP string = fw.properties.ipConfigurations[0].properties.privateIPAddress

resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-04-01' = [for spoke in spokeList: {
  name: spoke.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spoke.addressPrefix
      ]
    }
  }
}]

resource spokeSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = [for (spoke, i) in spokeList: {
  name: 'spk${i+1}-subnet'
  parent: spokeVnet[i]
  properties: {
    addressPrefix: spoke.subnetPrefix
  }
}]

resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = [for (vm, i) in vmList: {
  name: '${vm.name}-NIC'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          subnet: {
            id: spokeSubnet[i].id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: vm.ip
        }
      }
    ]
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = [for (vm, i) in vmList: {
  name: vm.name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${vm.name}-OSDISK'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: 128
      }
    }
    osProfile: {
      computerName: vm.name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
  }
}]

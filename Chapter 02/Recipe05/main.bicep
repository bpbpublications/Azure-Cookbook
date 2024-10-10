param location string = resourceGroup().location
param vmSize string = 'Standard_D2s_v3'
param envPrefix string
param adminUsername string = 'adminUser'
@secure()
param adminPassword string

var vmNameList = ['DNS-VM', 'CLIENT-VM']
var dnsIp = '10.0.0.100'

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${envPrefix}-VNET'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    dhcpOptions: {
      dnsServers: [
        dnsIp
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: 'subnet1'
  parent: vnet
  properties: {
    addressPrefix: '10.0.0.0/24'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = [for (vmName, i) in vmNameList: {
  name: '${vmName}-NIC'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: i == 0 ? 'Static' : 'Dynamic'
          privateIPAddress: i == 0 ? dnsIp : null
        }
      }
    ]
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = [for (vmName, i) in vmNameList:{
  name: vmName
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
        name: '${vmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: 128
      }
    }
    osProfile: {
      computerName: vmName
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

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'contoso.com'
  location: 'global'
}

resource privateDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: 'www'
  parent: privateDnsZone
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: '10.0.0.250'
      }
    ]
  }
}

resource privateDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'vnetLink'
  location: 'global'
  parent: privateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

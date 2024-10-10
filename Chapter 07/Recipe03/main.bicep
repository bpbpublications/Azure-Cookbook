param location string = 'westeurope'
param envPrefix string = 'Recipe07-03'
param vmAdminUsername string = 'adminUser'
@secure()
param vmAdminPassword string

var vnetName = '${envPrefix}-VNET'
var subnetName = 'subnet'
var vmName = '${envPrefix}-VM'
var nicName = '${vmName}-NIC'
var storageAccountName = take(toLower('recipe0703sa${uniqueString(resourceGroup().id)}'), 24)
var dnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var peName = '${envPrefix}-STORAGE-PE'
var automationAccountName = '${envPrefix}-AUTOMATION'
var runbookName = 'recipe0703runbook'
var roleDefinitionStorageBlobDataContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinition', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var roleDefinitionReader = subscriptionResourceId('Microsoft.Authorization/roleDefinition', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/24'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/25'
        }
      }
    ]
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'recipe0703'
  parent: blobService
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: peName
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: '${peName}-ServiceConnection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'global'
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'privateDnsZoneLink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  name: '${peName}-DNSZoneGroup'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: automationAccountName
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  name: runbookName
  parent: automationAccount
  location: location
  properties: {
    runbookType: 'PowerShell'
    logProgress: true
    logVerbose: true
  }
}

resource blobRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, resourceGroup().id, roleDefinitionStorageBlobDataContributor)
  properties: {
    principalId: automationAccount.identity.principalId
    roleDefinitionId: roleDefinitionStorageBlobDataContributor
  }
  scope: storageAccount
}

resource readerRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, resourceGroup().id, roleDefinitionReader)
  properties: {
    principalId: automationAccount.identity.principalId
    roleDefinitionId: roleDefinitionReader
  }
  scope: storageAccount
}

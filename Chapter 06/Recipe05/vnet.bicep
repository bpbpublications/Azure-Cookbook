param location string = 'westeurope'
param envPrefix string = 'Recipe06-05'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: '${envPrefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

output defaultSubnetId string = vnet.properties.subnets[0].id

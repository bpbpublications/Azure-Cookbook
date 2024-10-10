param location string = 'westeurope'
param envPrefix string = 'Recipe06-05'
param adminUsername string = 'adminUser'
@secure()
param adminPassword string

module vnet 'vnet.bicep' = {
  name: '${envPrefix}-vnet'
  params: {
    location: location
    envPrefix: envPrefix
  }
}
    
module vm 'vm.bicep' = {
  name: '${envPrefix}-vm'
  params: {
    location: location
    envPrefix: envPrefix
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: vnet.outputs.defaultSubnetId
  }
}

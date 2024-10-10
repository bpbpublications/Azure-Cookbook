param location string = 'westeurope'
param envPrefix string = 'Recipe06-05'
param adminUsername string = 'adminUser'
@secure()
param adminPassword string

module vnet 'br:recipe060599938948.azurecr.io/modules/vnet:v1' = {
  name: '${envPrefix}-vnet'
  params: {
    location: location
    envPrefix: envPrefix
  }
}
    
module vm 'br:recipe060599938948.azurecr.io/modules/vm:v1' = {
  name: '${envPrefix}-vm'
  params: {
    location: location
    envPrefix: envPrefix
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: vnet.outputs.defaultSubnetId
  }
}

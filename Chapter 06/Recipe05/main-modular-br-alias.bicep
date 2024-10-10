param location string = 'westeurope'
param envPrefix string = 'Recipe06-05'
param adminUsername string = 'adminUser'
@secure()
param adminPassword string

module vnet 'br/azurecookbook:modules/vnet:v1' = {
  name: '${envPrefix}-vnet'
  params: {
    location: location
    envPrefix: envPrefix
  }
}
    
module vm 'br/azurecookbook:modules/vm:v1' = {
  name: '${envPrefix}-vm'
  params: {
    location: location
    envPrefix: envPrefix
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: vnet.outputs.defaultSubnetId
  }
}

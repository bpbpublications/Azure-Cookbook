param storageAccountName string = 'store${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${storageAccount.name}/default/documents'
  properties: {
    publicAccess: 'Blob'
    metadata: {}
  }
}

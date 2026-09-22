@description('Azure region for the container registry.')
param location string

@description('Letters and numbers only. Used to form a globally unique registry name.')
param namePrefix string

param tags object

var registryName = take(toLower('${namePrefix}acr${uniqueString(resourceGroup().id)}'), 50)

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: registryName
  location: location
  sku: {
    name: 'Basic'
  }
  tags: tags
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output containerRegistryId string = containerRegistry.id
output loginServer string = containerRegistry.properties.loginServer

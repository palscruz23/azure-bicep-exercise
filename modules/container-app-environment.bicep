@description('Azure region for the Container Apps environment.')
param location string

@description('Letters and numbers only. Used to form the environment name.')
param namePrefix string

param tags object

var environmentName = '${namePrefix}-cae-${uniqueString(resourceGroup().id)}'

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2025-01-01' = {
  name: environmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'none'
    }
  }
}

output containerAppEnvironmentId string = containerAppEnvironment.id

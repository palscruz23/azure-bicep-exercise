@description('Resource ID of the Container Apps managed environment.')
param containerAppEnvironmentId string

@description('Azure region for the Container App.')
param location string

@description('Letters and numbers only. Used to form the Container App name.')
param namePrefix string

param tags object

@description('Public image used for the starter application. Replace it with your own registry image in a later exercise.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

var containerAppName = take(toLower('${namePrefix}-app-${uniqueString(resourceGroup().id)}'), 32)

resource containerApp 'Microsoft.App/containerApps@2025-01-01' = {
  name: containerAppName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    environmentId: containerAppEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
    }
    template: {
      containers: [
        {
          name: 'web'
          image: containerImage
          resources: {
            cpu: 0.25
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
      }
    }
  }
}

output containerAppId string = containerApp.id
output applicationUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'

@description('Resource ID of the Container Apps managed environment.')
param containerAppEnvironmentId string

@description('Short unique label for this app instance, for example web or api.')
param appSuffix string

@description('Azure region for the Container App.')
param location string

@description('Letters and numbers only. Used to form the Container App name.')
param namePrefix string

param tags object

@description('Public image used for the starter application. Replace it with your own registry image in a later exercise.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

var containerAppName = take(toLower('${namePrefix}-${appSuffix}-${uniqueString(resourceGroup().id)}'), 32)

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
            // Bicep integer literals don't support decimals; preserve the minimum 0.25 vCPU value in emitted JSON.
            cpu: json('0.25')
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

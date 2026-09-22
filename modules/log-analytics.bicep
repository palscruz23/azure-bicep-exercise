@description('Azure region for the Log Analytics workspace.')
param location string

@description('Letters and numbers only. Used to form the workspace name.')
param namePrefix string

param tags object

var workspaceName = '${namePrefix}-law-${uniqueString(resourceGroup().id)}'

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

output workspaceId string = workspace.id
output workspaceName string = workspace.name

targetScope = 'resourceGroup'

@description('Azure region for all resources. Defaults to the target resource group location.')
param location string = resourceGroup().location

@description('Letters and numbers only. Used as the prefix for globally unique resource names.')
@minLength(2)
@maxLength(12)
param namePrefix string

@description('Tags applied to every resource in this deployment.')
param tags object = {
  environment: 'practice'
  managedBy: 'bicep'
}

@description('Deploy an optional Log Analytics workspace for monitoring exercises.')
param deployLogAnalytics bool = false

@description('Deploy an Azure Container Registry. It is opt-in because registry storage incurs cost.')
param deployContainerRegistry bool = false

@description('Deploy a Container Apps environment and a public sample Container App.')
param deployContainerApp bool = false

@description('Deploy PostgreSQL Flexible Server and an application database.')
param deployPostgres bool = false

@secure()
@description('PostgreSQL administrator password. Supply only at deployment time when deployPostgres is true; never place it in a parameter file.')
param postgresAdminPassword string = ''

module network 'modules/network.bicep' = {
  name: 'network-deployment'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
  }
}

module storage 'modules/storage-account.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
  }
}

module keyVault 'modules/key-vault.bicep' = {
  name: 'key-vault-deployment'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
  }
}

module logAnalytics 'modules/log-analytics.bicep' = if (deployLogAnalytics) {
  name: 'log-analytics-deployment'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
  }
}

module containerRegistry 'modules/container-registry.bicep' = if (deployContainerRegistry) {
  name: 'container-registry-deployment'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
  }
}

module containerAppEnvironment 'modules/container-app-environment.bicep' = if (deployContainerApp) {
  name: 'container-app-environment-deployment'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
  }
}

module containerApp 'modules/container-app.bicep' = if (deployContainerApp) {
  name: 'container-app-deployment'
  params: {
    containerAppEnvironmentId: containerAppEnvironment!.outputs.containerAppEnvironmentId
    location: location
    namePrefix: namePrefix
    tags: tags
  }
}

module postgresql 'modules/postgresql-flexible-server.bicep' = if (deployPostgres) {
  name: 'postgresql-deployment'
  params: {
    administratorPassword: postgresAdminPassword
    location: location
    namePrefix: namePrefix
    tags: tags
  }
}

output virtualNetworkId string = network.outputs.virtualNetworkId
output storageAccountId string = storage.outputs.storageAccountId
output keyVaultId string = keyVault.outputs.keyVaultId
output logAnalyticsWorkspaceId string = deployLogAnalytics ? logAnalytics!.outputs.workspaceId : ''
output containerRegistryId string = deployContainerRegistry ? containerRegistry!.outputs.containerRegistryId : ''
output containerAppUrl string = deployContainerApp ? containerApp!.outputs.applicationUrl : ''
output postgresqlServerId string = deployPostgres ? postgresql!.outputs.postgresqlServerId : ''

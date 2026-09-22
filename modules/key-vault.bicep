@description('Azure region for the Key Vault.')
param location string

@description('Letters and numbers only. Used to form a globally unique Key Vault name.')
param namePrefix string

param tags object

@description('Whether purge protection is enabled. Keep false in this practice repository so cleanup is straightforward.')
param enablePurgeProtection bool = false

var keyVaultName = take(toLower('${namePrefix}kv${uniqueString(resourceGroup().id)}'), 24)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: true
    enableSoftDelete: true
    publicNetworkAccess: 'Enabled'
    softDeleteRetentionInDays: 7
    sku: {
      family: 'A'
      name: 'standard'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name

@description('Azure region for PostgreSQL Flexible Server.')
param location string

@description('Resource ID of the dedicated subnet delegated to Microsoft.DBforPostgreSQL/flexibleServers.')
param delegatedSubnetResourceId string

@description('Letters and numbers only. Used to form the server name.')
param namePrefix string

param tags object

@description('Administrator login for PostgreSQL.')
param administratorLogin string = 'pgadmin'

@secure()
@description('Administrator password. Provide this through a secret pipeline variable or a local shell environment variable.')
param administratorPassword string

@description('Resource ID of the PostgreSQL private DNS zone linked to the shared virtual network.')
param privateDnsZoneArmResourceId string

@description('Name of the application database to create.')
param databaseName string = 'appdb'

var serverName = take(toLower('${namePrefix}-pg-${uniqueString(resourceGroup().id)}'), 63)

resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2025-08-01' = {
  name: serverName
  location: location
  tags: tags
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    network: {
      delegatedSubnetResourceId: delegatedSubnetResourceId
      privateDnsZoneArmResourceId: privateDnsZoneArmResourceId
      publicNetworkAccess: 'Disabled'
    }
    storage: {
      storageSizeGB: 32
    }
    version: '16'
  }
}

resource applicationDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2025-08-01' = {
  parent: postgresqlServer
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

output postgresqlServerId string = postgresqlServer.id
output fullyQualifiedDomainName string = postgresqlServer.properties.fullyQualifiedDomainName
output databaseId string = applicationDatabase.id

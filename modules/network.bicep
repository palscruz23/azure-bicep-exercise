@description('Azure region for the virtual network.')
param location string

@description('Letters and numbers only. Used to form the virtual network name.')
param namePrefix string

param tags object

@description('Address space for the practice virtual network.')
param addressSpace string = '10.20.0.0/16'

@description('Dedicated subnet for Container Apps infrastructure. The default workload profile environment requires /27 or larger.')
param containerAppsSubnetAddressPrefix string = '10.20.1.0/27'

@description('Dedicated PostgreSQL subnet. PostgreSQL Flexible Server requires a delegated /28 or larger subnet.')
param postgresqlSubnetAddressPrefix string = '10.20.2.0/28'

var postgresqlPrivateDnsZoneName = '${namePrefix}.postgres.database.azure.com'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: '${namePrefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
  }
}

resource containerAppsInfrastructureSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: virtualNetwork
  name: 'container-apps-infrastructure'
  properties: {
    addressPrefix: containerAppsSubnetAddressPrefix
    delegations: [
      {
        name: 'containerAppsDelegation'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
  }
}

resource postgresqlDelegatedSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: virtualNetwork
  name: 'postgresql'
  properties: {
    addressPrefix: postgresqlSubnetAddressPrefix
    delegations: [
      {
        name: 'postgresqlDelegation'
        properties: {
          serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
        }
      }
    ]
  }
}

resource postgresqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: postgresqlPrivateDnsZoneName
  location: 'global'
  tags: tags
}

resource postgresqlPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: postgresqlPrivateDnsZone
  name: '${virtualNetwork.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

output virtualNetworkId string = virtualNetwork.id
output containerAppsInfrastructureSubnetId string = containerAppsInfrastructureSubnet.id
output postgresqlDelegatedSubnetId string = postgresqlDelegatedSubnet.id
output postgresqlPrivateDnsZoneId string = postgresqlPrivateDnsZone.id

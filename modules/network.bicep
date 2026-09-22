@description('Azure region for the virtual network.')
param location string

@description('Letters and numbers only. Used to form the virtual network name.')
param namePrefix string

param tags object

@description('Address space for the practice virtual network.')
param addressSpace string = '10.20.0.0/16'

@description('Address prefix for the default application subnet.')
param subnetAddressPrefix string = '10.20.1.0/24'

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

resource appSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: virtualNetwork
  name: 'app'
  properties: {
    addressPrefix: subnetAddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

output virtualNetworkId string = virtualNetwork.id
output appSubnetId string = appSubnet.id

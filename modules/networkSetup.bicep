// ============================================================================
// Network Setup Module
// Handles network connection creation (if needed) and attachment to Dev Center
// ============================================================================

@description('Location for resources')
param location string

@description('Name of the Dev Center')
param devCenterName string

@description('Name of the Network Connection')
param networkConnectionName string

@description('Whether to create a new network connection')
param createNetworkConnection bool = false

// Parameters for existing network connection
@description('Resource group where existing Network Connection exists')
param networkConnectionResourceGroup string = ''

// Parameters for new network connection
@description('Name of the existing VNet (required if createNetworkConnection is true)')
param vnetName string = ''

@description('Resource group where the VNet exists')
param vnetResourceGroup string = ''

@description('Name of the subnet to use (required if createNetworkConnection is true)')
param subnetName string = ''

@description('Domain join type for the network connection')
@allowed([
  'AzureADJoin'
  'HybridAzureADJoin'
])
param domainJoinType string = 'AzureADJoin'

@description('Tags for the resource')
param tags object = {}

// ============================================================================
// Variables
// ============================================================================

var ncResourceGroup = empty(networkConnectionResourceGroup) ? resourceGroup().name : networkConnectionResourceGroup
var existingNetworkConnectionId = resourceId(ncResourceGroup, 'Microsoft.DevCenter/networkConnections', networkConnectionName)
var vnetRg = empty(vnetResourceGroup) ? resourceGroup().name : vnetResourceGroup
var subnetId = resourceId(vnetRg, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

// ============================================================================
// Reference to existing Dev Center
// ============================================================================

resource devCenter 'Microsoft.DevCenter/devcenters@2025-04-01-preview' existing = {
  name: devCenterName
}

// ============================================================================
// Create Network Connection (if createNetworkConnection is true)
// ============================================================================

resource newNetworkConnection 'Microsoft.DevCenter/networkConnections@2025-04-01-preview' = if (createNetworkConnection) {
  name: networkConnectionName
  location: location
  tags: tags
  properties: {
    domainJoinType: domainJoinType
    subnetId: subnetId
    networkingResourceGroupName: '${networkConnectionName}-network-rg'
  }
}

// ============================================================================
// Attach Network Connection to Dev Center
// ============================================================================

resource attachedNetwork 'Microsoft.DevCenter/devcenters/attachednetworks@2025-04-01-preview' = {
  parent: devCenter
  name: networkConnectionName
  properties: {
    networkConnectionId: createNetworkConnection ? newNetworkConnection.id : existingNetworkConnectionId
  }
}

// ============================================================================
// Outputs
// ============================================================================

output id string = attachedNetwork.id
output name string = attachedNetwork.name
output networkConnectionId string = createNetworkConnection ? newNetworkConnection.id : existingNetworkConnectionId

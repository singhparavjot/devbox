// ============================================================================
// Network Connection Module
// Creates a new Network Connection for Dev Center (Azure AD Join)
// ============================================================================

@description('Location for the Network Connection')
param location string

@description('Name of the Network Connection')
param networkConnectionName string

@description('Name of the existing VNet')
param vnetName string

@description('Resource group where the VNet exists')
param vnetResourceGroup string

@description('Name of the subnet to use')
param subnetName string

@description('Domain join type')
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

var subnetId = resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

// ============================================================================
// Network Connection Resource
// ============================================================================

resource networkConnection 'Microsoft.DevCenter/networkConnections@2025-04-01-preview' = {
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
// Outputs
// ============================================================================

output id string = networkConnection.id
output name string = networkConnection.name

// ============================================================================
// Dev Center Module
// ============================================================================

@description('Location for the Dev Center')
param location string

@description('Name of the Dev Center')
param devCenterName string

@description('Enable catalog per project setting')
param catalogPerProjectEnabled bool = false

@description('Tags for the resource')
param tags object = {}

// ============================================================================
// Dev Center Resource
// ============================================================================

resource devCenter 'Microsoft.DevCenter/devcenters@2025-04-01-preview' = {
  name: devCenterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    projectCatalogSettings: {
      catalogItemSyncEnableStatus: catalogPerProjectEnabled ? 'Enabled' : 'Disabled'
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================

output id string = devCenter.id
output name string = devCenter.name
output principalId string = devCenter.identity.principalId

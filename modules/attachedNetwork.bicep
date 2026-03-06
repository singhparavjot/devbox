// ============================================================================
// Attached Network Module
// Attaches an existing network connection to Dev Center
// ============================================================================

@description('Name of the Dev Center')
param devCenterName string

@description('Name of the Network Connection')
param networkConnectionName string

@description('Network Connection ID to attach')
param networkConnectionId string

// ============================================================================
// Reference to existing Dev Center
// ============================================================================

resource devCenter 'Microsoft.DevCenter/devcenters@2025-04-01-preview' existing = {
  name: devCenterName
}

// ============================================================================
// Attach Network Connection to Dev Center
// ============================================================================

resource attachedNetwork 'Microsoft.DevCenter/devcenters/attachednetworks@2025-04-01-preview' = {
  parent: devCenter
  name: networkConnectionName
  properties: {
    networkConnectionId: networkConnectionId
  }
}

// ============================================================================
// Outputs
// ============================================================================

output id string = attachedNetwork.id
output name string = attachedNetwork.name
output networkConnectionId string = networkConnectionId

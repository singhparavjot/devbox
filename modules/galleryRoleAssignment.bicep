// ============================================================================
// Gallery Role Assignment Module
// Grants Dev Center managed identity Contributor access to Compute Gallery
// This module is deployed to the gallery's resource group
// ============================================================================

@description('Name of the Azure Compute Gallery')
param galleryName string

@description('Principal ID of the Dev Center managed identity')
param devCenterPrincipalId string

// ============================================================================
// Variables
// ============================================================================

// Contributor role definition ID
var contributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

// ============================================================================
// Reference to existing Compute Gallery
// ============================================================================

resource gallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  name: galleryName
}

// ============================================================================
// Role Assignment - Grant Dev Center identity Contributor access to Gallery
// ============================================================================

resource galleryRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(gallery.id, devCenterPrincipalId, contributorRoleDefinitionId)
  scope: gallery
  properties: {
    principalId: devCenterPrincipalId
    roleDefinitionId: contributorRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

// ============================================================================
// Outputs
// ============================================================================

output roleAssignmentId string = galleryRoleAssignment.id

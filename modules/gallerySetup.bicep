// ============================================================================
// Gallery Setup Module
// Attaches Azure Compute Gallery to Dev Center and grants access
// ============================================================================

@description('Name of the Dev Center')
param devCenterName string

@description('Principal ID of the Dev Center managed identity')
param devCenterPrincipalId string

@description('Name of the Azure Compute Gallery')
param galleryName string

@description('Resource group where the gallery exists')
param galleryResourceGroup string

// ============================================================================
// Variables
// ============================================================================

var galleryResourceId = resourceId(galleryResourceGroup, 'Microsoft.Compute/galleries', galleryName)

// ============================================================================
// Reference to existing Dev Center
// ============================================================================

resource devCenter 'Microsoft.DevCenter/devcenters@2025-04-01-preview' existing = {
  name: devCenterName
}

// ============================================================================
// Module: Role Assignment (deployed to gallery's resource group)
// ============================================================================

module galleryRoleAssignment 'galleryRoleAssignment.bicep' = {
  name: 'grant-gallery-access-${devCenterName}'
  scope: resourceGroup(galleryResourceGroup)
  params: {
    galleryName: galleryName
    devCenterPrincipalId: devCenterPrincipalId
  }
}

// ============================================================================
// Attach Gallery to Dev Center
// ============================================================================

resource attachedGallery 'Microsoft.DevCenter/devcenters/galleries@2025-04-01-preview' = {
  parent: devCenter
  name: galleryName
  properties: {
    galleryResourceId: galleryResourceId
  }
  dependsOn: [
    galleryRoleAssignment
  ]
}

// ============================================================================
// Outputs
// ============================================================================

output galleryName string = attachedGallery.name
output galleryResourceId string = galleryResourceId

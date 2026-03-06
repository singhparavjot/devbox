// ============================================================================
// Dev Center Project Module
// ============================================================================

@description('Location for the Project')
param location string

@description('Name of the Project')
param projectName string

@description('Dev Center ID to associate with the project')
param devCenterId string

@description('Maximum Dev Boxes per user')
param maxDevBoxesPerUser int = 2

@description('Tags for the resource')
param tags object = {}

// ============================================================================
// Project Resource
// ============================================================================

resource project 'Microsoft.DevCenter/projects@2025-04-01-preview' = {
  name: projectName
  location: location
  tags: tags
  properties: {
    devCenterId: devCenterId
    maxDevBoxesPerUser: maxDevBoxesPerUser
  }
}

// ============================================================================
// Outputs
// ============================================================================

output id string = project.id
output name string = project.name

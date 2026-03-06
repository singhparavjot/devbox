// ============================================================================
// Projects for Dev Center Module
// Handles creation of all projects, definitions, and pools for a single Dev Center
// ============================================================================

@description('Location for all resources')
param location string

@description('Name of the Dev Center')
param devCenterName string

@description('Dev Center ID')
param devCenterId string

@description('Array of projects to create (each with pools array)')
param projects array

@description('Name of the Network Connection to use')
param networkConnectionName string

@description('Default maximum Dev Boxes per user')
param maxDevBoxesPerUser int

@description('Default auto-stop time')
param autoStopTime string

@description('Default timezone for auto-stop schedule')
param defaultTimeZone string = 'UTC'

@description('Default Dev Box SKU')
param defaultDevBoxSku string

@description('Default Dev Box Image (marketplace)')
param defaultDevBoxImage string

@description('Default storage type')
param defaultStorageType string

@description('Default local administrator setting')
@allowed([
  'Enabled'
  'Disabled'
])
param defaultLocalAdministrator string = 'Enabled'

@description('Default stop on disconnect setting')
@allowed([
  'Enabled'
  'Disabled'
])
param defaultStopOnDisconnect string = 'Enabled'

@description('Default grace period in minutes')
param defaultGracePeriodMinutes int = 60

@description('Gallery name attached to Dev Center (empty if none)')
param galleryName string = ''

@description('Tags for the resources')
param tags object = {}

// ============================================================================
// Module: Projects
// ============================================================================

module projectModules 'project.bicep' = [for (proj, i) in projects: {
  name: 'proj-${i}-${take(proj.name, 40)}'
  params: {
    location: location
    projectName: proj.name
    devCenterId: devCenterId
    maxDevBoxesPerUser: proj.?maxDevBoxesPerUser ?? maxDevBoxesPerUser
    tags: union(tags, proj.?tags ?? {})
  }
}]

// ============================================================================
// Module: Pools for each Project
// ============================================================================

module poolsModules 'poolsForProject.bicep' = [for (proj, i) in projects: {
  name: 'pools-${i}-${take(proj.name, 38)}'
  params: {
    location: location
    devCenterName: devCenterName
    projectName: proj.name
    pools: proj.pools
    networkConnectionName: networkConnectionName
    autoStopTime: autoStopTime
    defaultTimeZone: proj.?timeZone ?? defaultTimeZone
    defaultDevBoxSku: defaultDevBoxSku
    defaultDevBoxImage: defaultDevBoxImage
    defaultStorageType: defaultStorageType
    defaultLocalAdministrator: defaultLocalAdministrator
    defaultStopOnDisconnect: defaultStopOnDisconnect
    defaultGracePeriodMinutes: defaultGracePeriodMinutes
    galleryName: galleryName
  }
  dependsOn: [
    projectModules[i]
  ]
}]

// ============================================================================
// Outputs
// ============================================================================

output projectDetails array = [for (proj, i) in projects: {
  name: proj.name
  id: projectModules[i].outputs.id
  pools: poolsModules[i].outputs.poolDetails
}]

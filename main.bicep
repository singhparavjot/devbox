// ============================================================================
// Azure Dev Center and Dev Box Infrastructure - Main Orchestrator
// ============================================================================

targetScope = 'subscription'

// ============================================================================
// Parameters
// ============================================================================

@description('Default location for resources (can be overridden per Dev Center)')
param location string = 'australiaeast'

@description('Array of Dev Centers to create (each contains its projects)')
param devCenters array

@description('Dev Box SKU - compute size')
@allowed([
  'general_i_8c32gb256ssd_v2'
  'general_i_8c32gb512ssd_v2'
  'general_i_8c32gb1024ssd_v2'
  'general_i_16c64gb256ssd_v2'
  'general_i_16c64gb512ssd_v2'
  'general_i_16c64gb1024ssd_v2'
  'general_i_32c128gb512ssd_v2'
  'general_i_32c128gb1024ssd_v2'
  'general_i_32c128gb2048ssd_v2'
])
param devBoxSku string = 'general_i_8c32gb256ssd_v2'

@description('Dev Box Image')
@allowed([
  'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'
  'microsoftvisualstudio_visualstudioplustools_vs-2022-pro-general-win11-m365-gen2'
  'microsoftwindowsdesktop_windows-ent-cpc_win11-22h2-ent-cpc-m365'
  'microsoftwindowsdesktop_windows-ent-cpc_win11-23h2-ent-cpc-m365'
])
param devBoxImage string = 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'

@description('Storage type for Dev Box OS disk')
@allowed([
  'ssd_256gb'
  'ssd_512gb'
  'ssd_1024gb'
])
param storageType string = 'ssd_256gb'

@description('Auto-stop time in HH:MM format (24-hour, UTC)')
param autoStopTime string = '19:00'

@description('Maximum Dev Boxes per user')
param maxDevBoxesPerUser int = 2

@description('Default local administrator setting for Dev Box users')
@allowed([
  'Enabled'
  'Disabled'
])
param localAdministrator string = 'Enabled'

@description('Default stop on disconnect setting')
@allowed([
  'Enabled'
  'Disabled'
])
param stopOnDisconnect string = 'Enabled'

@description('Default grace period in minutes before stopping on disconnect')
param gracePeriodMinutes int = 60

@description('Tags for all resources')
param tags object = {}

// ============================================================================
// Module: Dev Centers
// ============================================================================

module devCenterModules 'modules/devCenter.bicep' = [for dc in devCenters: {
  name: 'deploy-devCenter-${dc.name}'
  scope: resourceGroup(dc.resourceGroup)
  params: {
    location: dc.?location ?? location
    devCenterName: dc.name
    catalogPerProjectEnabled: dc.?catalogPerProjectEnabled ?? false
    tags: tags
  }
}]

// ============================================================================
// Module: Network Setup (create if needed + attach to Dev Center)
// ============================================================================

module networkSetupModules 'modules/networkSetup.bicep' = [for (dc, i) in devCenters: {
  name: 'deploy-networkSetup-${dc.name}'
  scope: resourceGroup(dc.resourceGroup)
  params: {
    location: dc.?location ?? location
    devCenterName: dc.name
    networkConnectionName: dc.networkConnectionName
    createNetworkConnection: dc.?createNetworkConnection ?? false
    networkConnectionResourceGroup: dc.?networkConnectionResourceGroup ?? ''
    vnetName: dc.?vnetName ?? ''
    vnetResourceGroup: dc.?vnetResourceGroup ?? ''
    subnetName: dc.?subnetName ?? ''
    domainJoinType: dc.?domainJoinType ?? 'AzureADJoin'
    tags: tags
  }
  dependsOn: [
    devCenterModules[i]
  ]
}]

// ============================================================================
// Module: Gallery Setup (attach custom gallery if specified)
// ============================================================================

module gallerySetupModules 'modules/gallerySetup.bicep' = [for (dc, i) in devCenters: if (dc.?galleryName != null) {
  name: 'deploy-gallerySetup-${dc.name}'
  scope: resourceGroup(dc.resourceGroup)
  params: {
    devCenterName: dc.name
    devCenterPrincipalId: devCenterModules[i].outputs.principalId
    galleryName: dc.?galleryName ?? ''
    galleryResourceGroup: dc.?galleryResourceGroup ?? dc.resourceGroup
  }
  dependsOn: [
    devCenterModules[i]
  ]
}]

// ============================================================================
// Module: Projects and Pools (per Dev Center)
// ============================================================================

module projectsPerDevCenter 'modules/projectsForDevCenter.bicep' = [for (dc, i) in devCenters: {
  name: 'deploy-projects-${dc.name}'
  scope: resourceGroup(dc.resourceGroup)
  params: {
    location: dc.?location ?? location
    devCenterName: dc.name
    devCenterId: devCenterModules[i].outputs.id
    projects: dc.projects
    networkConnectionName: networkSetupModules[i].outputs.name
    maxDevBoxesPerUser: maxDevBoxesPerUser
    autoStopTime: autoStopTime
    defaultDevBoxSku: devBoxSku
    defaultDevBoxImage: devBoxImage
    defaultStorageType: storageType
    defaultLocalAdministrator: localAdministrator
    defaultStopOnDisconnect: stopOnDisconnect
    defaultGracePeriodMinutes: gracePeriodMinutes
    galleryName: dc.?galleryName ?? ''
    tags: tags
  }
  dependsOn: [
    gallerySetupModules
  ]
}]

// ============================================================================
// Outputs
// ============================================================================

output devCenterIds array = [for (dc, i) in devCenters: {
  name: dc.name
  id: devCenterModules[i].outputs.id
  principalId: devCenterModules[i].outputs.principalId
}]

output projectsPerDevCenter array = [for (dc, i) in devCenters: {
  devCenterName: dc.name
  projects: projectsPerDevCenter[i].outputs.projectDetails
}]

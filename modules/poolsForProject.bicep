// ============================================================================
// Pools for Project Module
// Creates Dev Box Definitions and Pools for a single project
// ============================================================================

@description('Location for all resources')
param location string

@description('Name of the Dev Center')
param devCenterName string

@description('Name of the Project')
param projectName string

@description('Array of pools to create')
param pools array

@description('Name of the Network Connection to use')
param networkConnectionName string

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

// ============================================================================
// Reference to existing Dev Center and Project
// ============================================================================

resource devCenter 'Microsoft.DevCenter/devcenters@2025-04-01-preview' existing = {
  name: devCenterName
}

resource project 'Microsoft.DevCenter/projects@2025-04-01-preview' existing = {
  name: projectName
}

// ============================================================================
// Dev Box Definitions (one per pool)
// ============================================================================

resource devBoxDefinitions 'Microsoft.DevCenter/devcenters/devboxdefinitions@2025-04-01-preview' = [for pool in pools: {
  parent: devCenter
  name: 'def-${take(pool.poolName, 50)}'
  location: location
  properties: {
    imageReference: {
      id: (pool.?galleryImageName != null && galleryName != '')
        ? '${devCenter.id}/galleries/${galleryName}/images/${pool.galleryImageName}'
        : '${devCenter.id}/galleries/Default/images/${pool.?devBoxImage ?? defaultDevBoxImage}'
    }
    sku: {
      name: pool.?devBoxSku ?? defaultDevBoxSku
    }
    osStorageType: pool.?storageType ?? defaultStorageType
    hibernateSupport: 'Disabled'
  }
}]

// ============================================================================
// Dev Box Pools
// ============================================================================

resource devBoxPools 'Microsoft.DevCenter/projects/pools@2025-04-01-preview' = [for (pool, i) in pools: {
  parent: project
  name: pool.poolName
  location: location
  properties: {
    devBoxDefinitionType: 'Reference'
    devBoxDefinitionName: devBoxDefinitions[i].name
    networkConnectionName: networkConnectionName
    virtualNetworkType: 'Unmanaged'
    licenseType: 'Windows_Client'
    localAdministrator: pool.?localAdministrator ?? defaultLocalAdministrator
    displayName: pool.?displayName ?? pool.poolName
    stopOnDisconnect: {
      status: pool.?stopOnDisconnect ?? defaultStopOnDisconnect
      gracePeriodMinutes: pool.?gracePeriodMinutes ?? defaultGracePeriodMinutes
    }
    stopOnNoConnect: {
      status: 'Disabled'
    }
    singleSignOnStatus: 'Enabled'
  }
  dependsOn: [
    devBoxDefinitions[i]
  ]
}]

// ============================================================================
// Auto-Stop Schedules
// ============================================================================

resource schedules 'Microsoft.DevCenter/projects/pools/schedules@2025-04-01-preview' = [for (pool, i) in pools: {
  parent: devBoxPools[i]
  name: 'default'
  properties: {
    type: 'StopDevBox'
    frequency: 'Daily'
    time: pool.?autoStopTime ?? autoStopTime
    timeZone: pool.?timeZone ?? defaultTimeZone
    state: 'Enabled'
  }
}]

// ============================================================================
// Outputs
// ============================================================================

output poolDetails array = [for (pool, i) in pools: {
  poolName: devBoxPools[i].name
  definitionName: devBoxDefinitions[i].name
}]

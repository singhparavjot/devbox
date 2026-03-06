// ============================================================================
// Dev Box Pool Module
// ============================================================================

@description('Location for the Dev Box Pool')
param location string

@description('Name of the Project')
param projectName string

@description('Name of the Dev Box Pool')
param devBoxPoolName string

@description('Name of the Dev Box Definition to use')
param devBoxDefinitionName string

@description('Name of the Network Connection to use')
param networkConnectionName string

@description('Auto-stop time in HH:MM format (24-hour, UTC)')
param autoStopTime string = '19:00'

@description('Enable local administrator')
param localAdministrator string = 'Enabled'

@description('Grace period in minutes before stopping on disconnect')
param stopOnDisconnectGracePeriod int = 60

// ============================================================================
// Reference to existing Project
// ============================================================================

resource project 'Microsoft.DevCenter/projects@2025-04-01-preview' existing = {
  name: projectName
}

// ============================================================================
// Dev Box Pool Resource
// ============================================================================

resource devBoxPool 'Microsoft.DevCenter/projects/pools@2025-04-01-preview' = {
  parent: project
  name: devBoxPoolName
  location: location
  properties: {
    devBoxDefinitionName: devBoxDefinitionName
    networkConnectionName: networkConnectionName
    virtualNetworkType: 'Unmanaged'
    licenseType: 'Windows_Client'
    localAdministrator: localAdministrator
    stopOnDisconnect: {
      status: 'Enabled'
      gracePeriodMinutes: stopOnDisconnectGracePeriod
    }
    singleSignOnStatus: 'Enabled'
  }
}

// ============================================================================
// Auto-Stop Schedule
// ============================================================================

resource schedule 'Microsoft.DevCenter/projects/pools/schedules@2025-04-01-preview' = {
  parent: devBoxPool
  name: 'default'
  properties: {
    type: 'StopDevBox'
    frequency: 'Daily'
    time: autoStopTime
    timeZone: 'UTC'
    state: 'Enabled'
  }
}

// ============================================================================
// Outputs
// ============================================================================

output id string = devBoxPool.id
output name string = devBoxPool.name

# Azure Dev Center Infrastructure - Bicep Templates

This repository contains Bicep templates for deploying Azure Dev Center and Dev Box infrastructure. It supports deploying **multiple Dev Centers** with **multiple Projects** across **separate resource groups** in a single subscription-scoped deployment.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Configuration](#configuration)
  - [Parameters Reference](#parameters-reference)
  - [Dev Center Configuration](#dev-center-configuration)
  - [Project Configuration](#project-configuration)
  - [Pool Configuration](#pool-configuration)
  - [Network Connection Options](#network-connection-options)
  - [Timezone Configuration](#timezone-configuration)
- [Deployment](#deployment)
  - [Local Deployment](#local-deployment)
  - [GitHub Actions Deployment](#github-actions-deployment)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## Overview

This solution deploys:

- **Dev Centers** - Central management hubs for Dev Box environments with catalog per project support
- **Network Connections** - Connect Dev Boxes to your VNets (create new or use existing)
- **Dev Box Definitions** - Templates defining VM size, image, and storage (per-pool customizable)
- **Projects** - Organizational units with timezone and tag support
- **Dev Box Pools** - Collections of Dev Boxes with per-pool configuration

### Key Features

- [x] **Subscription-scoped deployment** - Deploy multiple Dev Centers across separate resource groups
- [x] **Multiple Projects per Dev Center** - Each with custom timezone, tags, and max Dev Boxes
- [x] **Multiple Pools per Project** - Each with custom SKU, storage, image, and admin settings
- [x] **Per-pool configuration** - localAdministrator, stopOnDisconnect, gracePeriodMinutes, displayName
- [x] **Azure Compute Gallery** - Use custom images from your gallery
- [x] **Catalog per project** - Enable project-level catalog management
- [x] **IANA timezone support** - Configure auto-stop schedules per project timezone
- [x] Auto-stop and stop-on-disconnect for cost control
- [x] GitHub Actions CI/CD pipeline with OIDC authentication
- [x] API version: `2025-04-01-preview`  

---

## Architecture

```
Subscription Deployment (targetScope = 'subscription')
│
├── Dev Center (Australia East)
│   ├── Resource Group: rg-devbox-prd-aus-001
│   ├── Catalog Per Project: Enabled
│   ├── Network Connection
│   ├── Azure Compute Gallery (attached)
│   │
│   ├── Project: Team-A (timeZone: Australia/Sydney)
│   │   └── Pool: pool-standard
│   │       ├── displayName: Standard Dev Box
│   │       ├── SKU: 32c/128GB/512GB SSD
│   │       ├── localAdministrator: Disabled
│   │       └── stopOnDisconnect: 120 min
│   │
│   └── Project: Team-B (timeZone: Australia/Sydney)
│       └── Pool: pool-power-user
│           ├── displayName: Power User Dev Box
│           └── SKU: 8c/32GB/256GB SSD
│
└── Dev Center (South Central US)
    ├── Resource Group: rg-devbox-prd-scus-001
    ├── Catalog Per Project: Enabled
    ├── Network Connection
    │
    ├── Project: Team-C (timeZone: America/Chicago)
    │   └── Pool: pool-standard
    │
    ├── Project: Team-D (timeZone: America/Chicago)
    │   └── Pool: pool-standard
    │
    └── Project: Team-E (timeZone: America/Chicago)
        └── Pool: pool-standard
```

---

## Prerequisites

1. **Azure Subscription** with appropriate permissions
2. **Azure CLI** installed and configured
3. **Bicep CLI** (included with Azure CLI 2.20.0+)
4. **Existing resources** (depending on your configuration):
   - Resource Group
   - Virtual Network and Subnet (if creating new network connections)
   - Existing Network Connection (if using existing)

### Required Azure Permissions

- `Microsoft.DevCenter/*` - Full access to Dev Center resources
- `Microsoft.Network/virtualNetworks/subnets/join/action` - If creating network connections

---

## Repository Structure

```
DevCenter-Bicep/
├── main.bicep                          # Main orchestrator (subscription-scoped)
├── parameters.json                     # Deployment parameters
├── README.md                           # This file
├── role-assignments.bicep              # Role assignments for Dev Center
├── modules/
│   ├── devCenter.bicep                 # Dev Center with catalogPerProjectEnabled
│   ├── networkSetup.bicep              # Network connection (create/attach)
│   ├── networkConnection.bicep         # Standalone network connection
│   ├── attachedNetwork.bicep           # Attach network to Dev Center
│   ├── devBoxDefinition.bicep          # Dev Box Definition resource
│   ├── project.bicep                   # Project resource with timezone
│   ├── projectsForDevCenter.bicep      # Projects wrapper (handles loops)
│   ├── poolsForProject.bicep           # Pools and definitions per project
│   ├── devBoxPool.bicep                # Dev Box Pool with schedule
│   ├── gallerySetup.bicep              # Attach Compute Gallery to Dev Center
│   └── galleryRoleAssignment.bicep     # Grant Dev Center access to gallery
├── scripts/
│   └── deploy-role-assignments.ps1     # Role assignment deployment script
└── .github/
    └── workflows/
        ├── deploy-devcenter.yml        # Main deployment pipeline
        └── test-oidc.yml               # OIDC authentication test
```

### Module Descriptions

| Module | Purpose |
|--------|---------|
| `devCenter.bicep` | Creates Dev Center with managed identity and `catalogPerProjectEnabled` |
| `networkSetup.bicep` | Creates new or uses existing network connection, attaches to Dev Center |
| `poolsForProject.bicep` | Creates Dev Box Definitions and Pools per project with per-pool settings |
| `project.bicep` | Creates project with timezone (IANA format) and merged tags |
| `devBoxPool.bicep` | Creates Dev Box pool with auto-stop schedule |
| `gallerySetup.bicep` | Attaches Azure Compute Gallery to Dev Center |
| `galleryRoleAssignment.bicep` | Grants Dev Center's managed identity Reader access to gallery |

---

## Configuration

### Parameters Reference

#### Global Parameters (Defaults)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `devBoxSku` | string | `general_i_8c32gb256ssd_v2` | Default VM size for Dev Boxes |
| `devBoxImage` | string | VS 2022 Enterprise | Default OS image |
| `storageType` | string | `ssd_256gb` | Default OS disk storage type |
| `autoStopTime` | string | `19:00` | Default daily auto-stop time |
| `maxDevBoxesPerUser` | int | `2` | Default max Dev Boxes per user |
| `localAdministrator` | string | `Enabled` | Default local admin setting |
| `stopOnDisconnect` | string | `Enabled` | Default stop-on-disconnect |
| `gracePeriodMinutes` | int | `60` | Default grace period (minutes) |
| `tags` | object | `{}` | Global tags for all resources |
| `devCenters` | array | **Required** | Array of Dev Center configurations |

> **Note:** All defaults can be overridden at the project or pool level.

### Available SKUs

| SKU | vCPUs | RAM | Disk | storageType |
|-----|-------|-----|------|-------------|
| `general_i_8c32gb256ssd_v2` | 8 | 32 GB | 256 GB | `ssd_256gb` |
| `general_i_8c32gb512ssd_v2` | 8 | 32 GB | 512 GB | `ssd_512gb` |
| `general_i_8c32gb1024ssd_v2` | 8 | 32 GB | 1 TB | `ssd_1024gb` |
| `general_i_16c64gb256ssd_v2` | 16 | 64 GB | 256 GB | `ssd_256gb` |
| `general_i_16c64gb512ssd_v2` | 16 | 64 GB | 512 GB | `ssd_512gb` |
| `general_i_16c64gb1024ssd_v2` | 16 | 64 GB | 1 TB | `ssd_1024gb` |
| `general_i_32c128gb512ssd_v2` | 32 | 128 GB | 512 GB | `ssd_512gb` |
| `general_i_32c128gb1024ssd_v2` | 32 | 128 GB | 1 TB | `ssd_1024gb` |
| `general_i_32c128gb2048ssd_v2` | 32 | 128 GB | 2 TB | `ssd_2048gb` |

> **Important:** The `storageType` must match the disk size in the SKU name.

### Available Images

| Image ID | Description |
|----------|-------------|
| `microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2` | VS 2022 Enterprise + M365 |
| `microsoftvisualstudio_visualstudioplustools_vs-2022-pro-general-win11-m365-gen2` | VS 2022 Professional + M365 |
| `microsoftwindowsdesktop_windows-ent-cpc_win11-22h2-ent-cpc-m365` | Windows 11 22H2 + M365 |
| `microsoftwindowsdesktop_windows-ent-cpc_win11-23h2-ent-cpc-m365` | Windows 11 23H2 + M365 |

---

### Dev Center Configuration

Each Dev Center in the `devCenters` array supports these properties:

```json
{
  "name": "dvcenter-dbox-prd-ae-001",
  "resourceGroup": "rg-devbox-prd-aus-001",
  "location": "australiaeast",
  "catalogPerProjectEnabled": true,
  
  // Network Connection (create new):
  "createNetworkConnection": true,
  "networkConnectionName": "network-connection-devbox-prd-ae-001",
  "vnetName": "vnet-devbox-prd-ae-001",
  "vnetResourceGroup": "rg-devbox-prd-aus-001",
  "subnetName": "default",
  "domainJoinType": "AzureADJoin",
  
  // Azure Compute Gallery:
  "galleryName": "devbox_imagegallery",
  "galleryResourceGroup": "rg-devbox-prd-ae-001",
  
  // Projects (required):
  "projects": [...]
}
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | string | Yes | Dev Center name |
| `resourceGroup` | string | Yes | Resource group for this Dev Center |
| `location` | string | Yes | Azure region |
| `catalogPerProjectEnabled` | bool | No | Enable project-level catalogs |
| `createNetworkConnection` | bool | No | Create new network connection |
| `galleryName` | string | No | Azure Compute Gallery name |
| `galleryResourceGroup` | string | No | Gallery resource group |

---

### Project Configuration

Each project supports these properties:

```json
{
  "name": "devproject-team-a-prd-001",
  "timeZone": "Australia/Sydney",
  "maxDevBoxesPerUser": 3,
  "tags": {
    "team": "team-a",
    "region": "australia"
  },
  "pools": [...]
}
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | string | Yes | Project name |
| `timeZone` | string | No | IANA timezone (e.g., `Australia/Sydney`) |
| `maxDevBoxesPerUser` | int | No | Override global max |
| `tags` | object | No | Project-specific tags (merged with global) |
| `pools` | array | Yes | Array of pool configurations |

---

### Pool Configuration

Each pool supports per-pool customization:

```json
{
  "poolName": "pool-standard",
  "displayName": "Standard Dev Box",
  "devBoxSku": "general_i_32c128gb512ssd_v2",
  "storageType": "ssd_512gb",
  "autoStopTime": "19:00",
  "localAdministrator": "Disabled",
  "stopOnDisconnect": "Enabled",
  "gracePeriodMinutes": 120,
  "galleryImageName": "win11-custom"
}
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `poolName` | string | Yes | Pool resource name |
| `displayName` | string | No | User-friendly name (defaults to poolName) |
| `devBoxSku` | string | No | VM SKU (overrides global) |
| `storageType` | string | No | Disk storage type (overrides global) |
| `autoStopTime` | string | No | Auto-stop time (overrides global) |
| `localAdministrator` | string | No | `Enabled` or `Disabled` |
| `stopOnDisconnect` | string | No | `Enabled` or `Disabled` |
| `gracePeriodMinutes` | int | No | Grace period before stopping |
| `galleryImageName` | string | No | Custom image from gallery |
| `devBoxImage` | string | No | Marketplace image reference |

---

### Network Connection Options

#### Option 1: Create New Network Connection

```json
{
  "name": "my-devcenter",
  "resourceGroup": "rg-devbox",
  "location": "australiaeast",
  "createNetworkConnection": true,
  "networkConnectionName": "new-network-conn",
  "vnetName": "my-vnet",
  "vnetResourceGroup": "rg-network",
  "subnetName": "devbox-subnet",
  "domainJoinType": "AzureADJoin",
  "projects": [...]
}
```

#### Option 2: Use Existing Network Connection

```json
{
  "name": "my-devcenter",
  "resourceGroup": "rg-devbox",
  "location": "australiaeast",
  "networkConnectionName": "existing-network-conn",
  "networkConnectionResourceGroup": "rg-where-it-exists",
  "projects": [...]
}
```

---

### Timezone Configuration

Projects use **IANA timezone format** for auto-stop schedules. The timezone is configured at the project level.

#### Common IANA Timezones

| Region | IANA Timezone |
|--------|---------------|
| Australia (Sydney) | `Australia/Sydney` |
| Australia (Perth) | `Australia/Perth` |
| US Central | `America/Chicago` |
| US Eastern | `America/New_York` |
| US Pacific | `America/Los_Angeles` |
| India | `Asia/Kolkata` |
| UK | `Europe/London` |
| Singapore | `Asia/Singapore` |
| Japan | `Asia/Tokyo` |
| UAE (Dubai) | `Asia/Dubai` |

> **Reference:** [Full IANA timezone list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

---

## Deployment

### Local Deployment

This is a **subscription-scoped** deployment. Use `az deployment sub` commands.

1. **Login to Azure:**
   ```powershell
   az login
   az account set --subscription "<subscription-id>"
   ```

2. **Validate the template:**
   ```powershell
   az deployment sub validate `
     --location australiaeast `
     --template-file main.bicep `
     --parameters parameters.json
   ```

3. **Preview changes (What-If):**
   ```powershell
   az deployment sub what-if `
     --location australiaeast `
     --template-file main.bicep `
     --parameters parameters.json
   ```

4. **Deploy:**
   ```powershell
   az deployment sub create `
     --location australiaeast `
     --template-file main.bicep `
     --parameters parameters.json `
     --name "devcenter-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
   ```

5. **Deploy with verbose logging:**
   ```powershell
   az deployment sub create `
     --location australiaeast `
     --template-file main.bicep `
     --parameters parameters.json `
     --verbose
   ```

### GitHub Actions Deployment

The repository includes a GitHub Actions workflow that:

1. **Validates** Bicep syntax and template
2. **Previews** changes with What-If
3. **Deploys** on push to `main` or `test` branches

#### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | App registration client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |

#### Workflow Triggers

| Trigger | Behavior |
|---------|----------|
| Push to `main`/`test` | Full pipeline (validate → what-if → deploy) |
| Pull Request | Validate and what-if only |
| Manual (`workflow_dispatch`) | Choose: validate-only, what-if-only, deploy-only, or full-pipeline |

---

## Examples

### Example 1: Full Production Configuration

This is the current production configuration with two Dev Centers across regions:

```json
{
  "parameters": {
    "devBoxSku": { "value": "general_i_8c32gb256ssd_v2" },
    "storageType": { "value": "ssd_256gb" },
    "localAdministrator": { "value": "Enabled" },
    "stopOnDisconnect": { "value": "Enabled" },
    "gracePeriodMinutes": { "value": 60 },
    "devCenters": {
      "value": [
        {
          "name": "dvcenter-dbox-prd-ae-001",
          "resourceGroup": "rg-devbox-prd-aus-001",
          "location": "australiaeast",
          "catalogPerProjectEnabled": true,
          "createNetworkConnection": true,
          "networkConnectionName": "network-connection-devbox-prd-ae-001",
          "vnetName": "vnet-devbox-prd-ae-001",
          "vnetResourceGroup": "rg-devbox-prd-aus-001",
          "subnetName": "default",
          "domainJoinType": "AzureADJoin",
          "galleryName": "devbox_imagegallery",
          "galleryResourceGroup": "rg-devbox-prd-aus-001",
          "projects": [
            {
              "name": "devproject-team-a-prd-001",
              "timeZone": "Australia/Sydney",
              "tags": { "team": "team-a" },
              "pools": [
                {
                  "poolName": "pool-standard",
                  "displayName": "Standard Dev Box",
                  "devBoxSku": "general_i_32c128gb512ssd_v2",
                  "storageType": "ssd_512gb",
                  "localAdministrator": "Disabled",
                  "stopOnDisconnect": "Enabled",
                  "gracePeriodMinutes": 120,
                  "galleryImageName": "win11-custom"
                }
              ]
            }
          ]
        }
      ]
    }
  }
}
```

### Example 2: Multiple Pools per Project

```json
{
  "name": "devproject-team",
  "timeZone": "America/Chicago",
  "pools": [
    {
      "poolName": "Pool-Large",
      "displayName": "Large - 32c/128GB",
      "devBoxSku": "general_i_32c128gb512ssd_v2",
      "storageType": "ssd_512gb"
    },
    {
      "poolName": "Pool-Standard",
      "displayName": "Standard - 8c/32GB",
      "devBoxSku": "general_i_8c32gb256ssd_v2",
      "storageType": "ssd_256gb"
    }
  ]
}
```

### Example 3: Mixed Marketplace and Gallery Images

```json
{
  "pools": [
    {
      "poolName": "Pool-Custom",
      "galleryImageName": "win11-custom",
      "devBoxSku": "general_i_32c128gb512ssd_v2",
      "storageType": "ssd_512gb"
    },
    {
      "poolName": "Pool-Marketplace",
      "devBoxImage": "microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2",
      "devBoxSku": "general_i_8c32gb256ssd_v2",
      "storageType": "ssd_256gb"
    }
  ]
}
```

### Example 4: India Region Configuration

```json
{
  "name": "dvcenter-dbox-prd-ci-001",
  "resourceGroup": "rg-devbox-prd-ci-001",
  "location": "centralindia",
  "catalogPerProjectEnabled": true,
  "createNetworkConnection": true,
  "networkConnectionName": "network-connection-devbox-prd-ci-001",
  "vnetName": "vnet-devbox-prd-ci-001",
  "vnetResourceGroup": "rg-devbox-prd-ci-001",
  "subnetName": "default",
  "domainJoinType": "AzureADJoin",
  "projects": [
    {
      "name": "devproject-India-prd-ci-001",
      "timeZone": "Asia/Kolkata",
      "tags": { "team": "India", "region": "india" },
      "pools": [
        {
          "poolName": "Pool-CI-Dev",
          "displayName": "Dev Pool India",
          "devBoxSku": "general_i_8c32gb256ssd_v2",
          "storageType": "ssd_256gb"
        }
      ]
    }
  ]
}
```

---

## Monitoring & Diagnostics

### Diagnostic Settings

Enable diagnostic settings on Dev Center resources to capture logs and metrics.

#### Supported Log Categories

| Log Category | Description |
|--------------|-------------|
| `DevCenterDiagnosticLogs` | Dev Center operations and management events |
| `DataPlaneRequests` | API requests to Dev Center data plane |
| `DevBoxProvisioningLogs` | Dev Box creation and provisioning events |
| `EnvironmentProvisioningLogs` | Environment deployment events |

#### Diagnostic Settings Configuration

```powershell
# Enable diagnostics for Dev Center
az monitor diagnostic-settings create `
  --name "devbox-diagnostics" `
  --resource "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.DevCenter/devcenters/<dc-name>" `
  --workspace "<log-analytics-workspace-id>" `
  --logs '[{"category":"DevCenterDiagnosticLogs","enabled":true},{"category":"DataPlaneRequests","enabled":true}]' `
  --metrics '[{"category":"AllMetrics","enabled":true}]'
```

### Key Metrics

| Metric | Description | Unit |
|--------|-------------|------|
| `DevBoxCount` | Total number of Dev Boxes | Count |
| `DevBoxRunning` | Number of running Dev Boxes | Count |
| `DevBoxStopped` | Number of stopped Dev Boxes | Count |
| `ProvisioningSuccessRate` | Percentage of successful provisions | Percent |
| `ProvisioningDuration` | Time to provision a Dev Box | Seconds |
| `CustomizationTaskDuration` | Time to complete customization tasks | Seconds |
| `CustomizationTaskSuccessRate` | Percentage of successful customizations | Percent |
| `PoolUtilization` | Pool capacity utilization | Percent |
| `UserSessionCount` | Active user sessions | Count |

### Recommended Alerts

| Alert | Condition | Severity |
|-------|-----------|----------|
| Provisioning Failures | `ProvisioningSuccessRate < 95%` | Sev 2 |
| High Provisioning Time | `ProvisioningDuration > 30 min` | Sev 3 |
| Customization Failures | `CustomizationTaskSuccessRate < 90%` | Sev 2 |
| Pool Near Capacity | `PoolUtilization > 80%` | Sev 3 |
| Network Connection Unhealthy | Health check failed | Sev 1 |

### Azure Monitor Queries (KQL)

#### Dev Box Provisioning Failures

```kql
DevCenterDiagnosticLogs
| where OperationName == "ProvisionDevBox"
| where ResultType == "Failed"
| project TimeGenerated, DevBoxName, ProjectName, PoolName, ErrorMessage
| order by TimeGenerated desc
```

#### Customization Task Status

```kql
DevCenterDiagnosticLogs
| where OperationName contains "Customization"
| summarize 
    SuccessCount = countif(ResultType == "Success"),
    FailedCount = countif(ResultType == "Failed")
    by bin(TimeGenerated, 1h)
| render timechart
```

#### Dev Box Usage by Project

```kql
DevCenterDiagnosticLogs
| where OperationName == "StartDevBox" or OperationName == "StopDevBox"
| summarize Count = count() by ProjectName, OperationName, bin(TimeGenerated, 1d)
| render columnchart
```

#### Network Connection Health

```kql
DevCenterDiagnosticLogs
| where OperationName == "NetworkConnectionHealthCheck"
| project TimeGenerated, NetworkConnectionName, HealthStatus, ErrorDetails
| order by TimeGenerated desc
```

### Useful Monitoring Commands

```powershell
# Check network connection health
az devcenter admin network-connection show-health-details `
  --name "<network-connection-name>" `
  --resource-group "<rg>"

# List Dev Boxes with status
az devcenter dev dev-box list `
  --dev-center "<dc-name>" `
  --project "<project-name>" `
  --query "[].{Name:name, State:provisioningState, User:user}" -o table

# Get pool statistics
az devcenter admin pool show `
  --name "<pool-name>" `
  --project-name "<project-name>" `
  --resource-group "<rg>"
```

---

## Troubleshooting

### Common Errors

#### `ValidationError` or Generic Deployment Failures

**Solution:** Get detailed error information:
```powershell
# For subscription deployments
az deployment sub show --name <deployment-name> --query "properties.error" -o json

# For resource group deployments
az deployment operation group list --name <deployment-name> --resource-group <rg> --query "[?properties.provisioningState=='Failed']"
```

#### `storageType` Mismatch

**Error:** Invalid storage type for the selected SKU.

**Cause:** The `storageType` must match the disk size in the SKU.

**Solution:**
| SKU Disk Size | storageType |
|---------------|-------------|
| 256GB | `ssd_256gb` |
| 512GB | `ssd_512gb` |
| 1024GB | `ssd_1024gb` |
| 2048GB | `ssd_2048gb` |

#### `ProjectDevCenterCannotBeUpdated`

**Error:** "The DevCenter associated with this project cannot be updated."

**Cause:** The project already exists and is linked to a different Dev Center.

**Solution:**
- Use a different project name, OR
- Delete the existing project first:
  ```powershell
  az devcenter admin project delete --name "project-name" --resource-group "rg-name" --yes
  ```

#### Invalid Timezone

**Error:** Invalid timezone format.

**Cause:** Using Windows timezone format instead of IANA.

**Solution:**
| ❌ Windows Format | ✅ IANA Format |
|-------------------|----------------|
| `AUS Eastern Standard Time` | `Australia/Sydney` |
| `Central Standard Time` | `America/Chicago` |
| `India Standard Time` | `Asia/Kolkata` |

#### Network Connection Not Found

**Error:** Resource not found for network connection.

**Solution:**
- Verify the network connection exists:
  ```powershell
  az devcenter admin network-connection list --resource-group "rg-name" -o table
  ```
- Or set `createNetworkConnection: true` to create a new one

#### Gallery Image Not Found

**Error:** Image reference not found or access denied.

**Solution:**
- Verify the gallery and image exist:
  ```powershell
  az sig show --gallery-name "myGallery" --resource-group "rg-images"
  az sig image-definition list --gallery-name "myGallery" --resource-group "rg-images" -o table
  ```
- Ensure Dev Center identity has Reader access (template does this automatically)

### Useful Commands

```powershell
# List all Dev Centers
az devcenter admin devcenter list --resource-group <rg> -o table

# List all projects
az devcenter admin project list --resource-group <rg> -o table

# List network connections
az devcenter admin network-connection list --resource-group <rg> -o table

# List Dev Box definitions
az devcenter admin devbox-definition list --dev-center-name <dc-name> --resource-group <rg> -o table

# List pools in a project
az devcenter admin pool list --project-name <project> --resource-group <rg> -o table

# Get deployment error details
az deployment sub show --name <deployment-name> --query "properties.error" -o json
```

---

## API Version

This solution uses Azure Dev Center API version **`2025-04-01-preview`**.

---

## License

This project is provided as-is for infrastructure deployment purposes.

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

For major changes, please open an issue first to discuss the proposed changes.

Enterprise Microsoft Dev Box Deployment Blueprint
=================================================

<!-- GitHub renders a TOC automatically via the file header menu -->

* * *


<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">1. Purpose & Business Value</h3>

</div>

---------------------------

### Purpose

This Intellectual Property (IP) provides a standardized, secure, and automated blueprint for deploying **Microsoft Dev Box at enterprise scale**. It establishes Dev Box as a **managed platform service**, fully integrated with enterprise identity, networking, security, and governance models.
The blueprint enables organizations to move away from ad‑hoc end‑user compute (EUC) patterns and adopt a **repeatable, governed, and supportable developer environment platform**.

### Business Value

| Benefit | Description |
| --- | --- |
| ⏱️ **Faster Onboarding** | Reduces developer onboarding time from **weeks to hours** |
| 🎯 **Consistent Experience** | Delivers a **consistent developer experience** across teams |
| 🔒 **Enhanced Security** | Improves security posture for **BYOD and non‑enterprise devices** |
| 🛡️ **Enterprise Controls** | Enforces enterprise controls using **RBAC and Conditional Access** |
| 📊 **Operational Visibility** | Provides **monitoring and alerting** for capacity, provisioning health, and usage trends |
| 🔄 **Repeatability** | Uses **Infrastructure‑as‑Code (Bicep)** and **GitHub Actions** for repeatability |

* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">2. High‑Level Architecture Overview</h3>

</div>

-----------------------------------

### Architecture Diagram


``` mermaid


graph TB

    subgraph Subscription["Azure Subscription (Subscription-Scoped Deployment)"]

        subgraph RGAE["RG: rg-devbox-prd-aus-001"]

            DCAE[("Dev Center<br/>Australia East")]

            NCAE["Network Connection"]

            subgraph ProjAE1["Project: Team-A"]

                PoolAE1["Pool: pool-standard<br/>32vCPU/128GB/512GB"]

            end

            subgraph ProjAE2["Project: Team-B"]

                PoolAE2["Pool: pool-power-user<br/>8vCPU/32GB/256GB"]

            end

        end

        subgraph Gallery["Azure Compute Gallery"]

            direction LR

            IMGAE["Image Version<br/>Australia East"] -.->|"Replication"| IMGSCUS["Image Replica<br/>South Central US"]

        end

        subgraph RGSCUS["RG: rg-devbox-prd-scus-001"]

            DCSCUS[("Dev Center<br/>South Central US")]

            NCSCUS["Network Connection"]

            subgraph ProjSCUS1["Project: Team-C"]

                PoolSCUS1["Pool: pool-standard<br/>16vCPU/64GB/256GB"]

            end

            subgraph ProjSCUS2["Project: Team-D"]

                PoolSCUS2["Pool: pool-standard<br/>16vCPU/64GB/256GB"]

            end

            subgraph ProjSCUS3["Project: Team-E"]

                PoolSCUS3["Pool: pool-standard<br/>32vCPU/128GB/512GB"]

            end

        end

    end

    DCAE --> NCAE

    DCAE --> Gallery

    DCAE --> ProjAE1

    DCAE --> ProjAE2

    DCSCUS --> NCSCUS

    DCSCUS --> Gallery

    DCSCUS --> ProjSCUS1

    DCSCUS --> ProjSCUS2

    DCSCUS --> ProjSCUS3

    style Subscription fill:#ffffff,stroke:#333

    style RGAE fill:#f5f5f5,stroke:#333

    style RGSCUS fill:#f5f5f5,stroke:#333

    style DCAE fill:#0078D4,color:#fff

    style DCSCUS fill:#0078D4,color:#fff

    style Gallery fill:#00A4EH,color:#333

    style IMGAE fill:#9B59B6,color:#fff

    style IMGSCUS fill:#9B59B6,color:#fff

    style ProjAE1 fill:#fff,stroke:#333

    style ProjAE2 fill:#fff,stroke:#333

    style ProjSCUS1 fill:#fff,stroke:#333

    style ProjSCUS2 fill:#fff,stroke:#333

    style ProjSCUS3 fill:#fff,stroke:#333
```
### Core Components

| Component | Description |
| --- | --- |
| **Dev Center** | Central governance and management plane for Dev Box with managed identity |
| **Projects (per team)** | Logical isolation, access boundary, and ownership model |
| **Dev Box Pools** | VM SKU, image, network, and policy definition with per-pool customization |
| **Network Connections** | Enterprise-managed VNet integration with Azure AD Join support |
| **Azure Compute Gallery** | Custom image management and distribution |
| **Microsoft Entra ID + RBAC** | Group‑based access control model |

This architecture supports both centralized governance and decentralized team ownership.

* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">3. Repository Structure</h3>

</div>

-----------------------

### Actual Repository Layout

    DevCenter-Bicep/
    ├── main.bicep                          # Main orchestrator (subscription-scoped)
    ├── parameters.json                     # Production deployment parameters
    ├── parameters.gallery-example.json     # Gallery configuration example
    ├── README.md                           # Technical documentation
    │
    ├── modules/
    │   ├── devCenter.bicep                 # Dev Center with managed identity
    │   ├── project.bicep                   # Project resource with timezone
    │   ├── devBoxPool.bicep                # Dev Box Pool with auto-stop schedule
    │   ├── devBoxDefinition.bicep          # Dev Box Definition resource
    │   ├── networkSetup.bicep              # Network connection (create/attach)
    │   ├── networkConnection.bicep         # Standalone network connection
    │   ├── attachedNetwork.bicep           # Attach network to Dev Center
    │   ├── projectsForDevCenter.bicep      # Projects wrapper (handles loops)
    │   ├── poolsForProject.bicep           # Pools and definitions per project
    │   ├── gallerySetup.bicep              # Attach Compute Gallery to Dev Center
    │   └── galleryRoleAssignment.bicep     # Grant Dev Center access to gallery
    │
    ├── scripts/
    │   └── (deployment scripts)
    │
    └── .github/
        └── workflows/
            └── deploy-devcenter.yml        # Main deployment pipeline
            
    

### Module Dependency Diagram

``` mermaid
flowchart TD
    MAIN["main.bicep (Subscription Scope)"] --> DC["devCenter.bicep"]
    MAIN --> NS["networkSetup.bicep"]
    MAIN --> GS["gallerySetup.bicep"]
    MAIN --> PFD["projectsForDevCenter.bicep"]

    DC --> |"outputs: id, principalId"| NS
    DC --> |"outputs: principalId"| GS

    NS --> NC["networkConnection.bicep"]
    NS --> AN["attachedNetwork.bicep"]

    GS --> GRA["galleryRoleAssignment.bicep"]

    PFD --> PROJ["project.bicep"]
    PFD --> PFP["poolsForProject.bicep"]

    PFP --> DBD["devBoxDefinition.bicep"]
    PFP --> DBP["devBoxPool.bicep"]

    style MAIN fill:#0078D4,color:#fff
    style DC fill:#68217A,color:#fff
    style PFD fill:#107C10,color:#fff
```


### Module Descriptions

| Module | Purpose | API Version |
| --- | --- | --- |
| `devCenter.bicep` | Creates Dev Center with managed identity and `catalogPerProjectEnabled` | `2025-04-01-preview` |
| `networkSetup.bicep` | Creates new or uses existing network connection, attaches to Dev Center | `2025-04-01-preview` |
| `poolsForProject.bicep` | Creates Dev Box Definitions and Pools per project with per-pool settings | `2025-04-01-preview` |
| `project.bicep` | Creates project with timezone (IANA format) and merged tags | `2025-04-01-preview` |
| `devBoxPool.bicep` | Creates Dev Box pool with auto-stop schedule | `2025-04-01-preview` |
| `gallerySetup.bicep` | Attaches Azure Compute Gallery to Dev Center | `2025-04-01-preview` |
| `galleryRoleAssignment.bicep` | Grants Dev Center's managed identity Reader access to gallery | - |

* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">4. Deployment Plan – Design Inputs</h3>

</div>

----------------------------------

### 4.1 Region Strategy

Select a primary Azure region aligned with:
*   Developer geographic distribution
    
*   Data residency and compliance requirements
    
*   VM SKU availability and subscription quota
    

> [TIP]  
> Deploy Dev Center, projects, pools, and VNets in the **same region** to reduce latency and operational complexity.

#### Current Production Regions

| Region | Dev Center | Resource Group | Timezone |
| --- | --- | --- | --- |
| Australia East | `dvcenter-dbox-prd-aus-001` | `rg-devbox-prd-aus-001` | `Australia/Sydney` |
| South Central US | `dvcenter-dbox-prd-scus-001` | `rg-devbox-prd-scus-001` | `America/Chicago` |

### 4.2 Dev Center & Project Model

#### Dev Center Strategy

*   **One Dev Center per region** for low-latency access
    
*   Centralized governance and policy ownership
    
*   Catalog per project enabled
    

#### Project Strategy

*Separate Project per Team*
| Benefit | Description |
| --- | --- |
| Clear ownership | Each team owns their project |
| Clean RBAC scoping | Access boundaries per team |
| Cost tracking | Improved chargeback via tags |
| Audit support | Easier access reviews |

* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">5. Available SKUs & Images</h3>

</div>

--------------------------

### Dev Box SKUs

| SKU | vCPUs | RAM | Disk | storageType | Use Case |
| --- | --- | --- | --- | --- | --- |
| `general_i_8c32gb256ssd_v2` | 8 | 32 GB | 256 GB | `ssd_256gb` | Standard development |
| `general_i_8c32gb512ssd_v2` | 8 | 32 GB | 512 GB | `ssd_512gb` | Standard with more storage |
| `general_i_16c64gb256ssd_v2` | 16 | 64 GB | 256 GB | `ssd_256gb` | Heavy workloads |
| `general_i_16c64gb512ssd_v2` | 16 | 64 GB | 512 GB | `ssd_512gb` | Heavy workloads + storage |
| `general_i_32c128gb512ssd_v2` | 32 | 128 GB | 512 GB | `ssd_512gb` | Power users, large builds |
| `general_i_32c128gb1024ssd_v2` | 32 | 128 GB | 1 TB | `ssd_1024gb` | Power users + storage |
| `general_i_32c128gb2048ssd_v2` | 32 | 128 GB | 2 TB | `ssd_2048gb` | Maximum storage |

> [!IMPORTANT]  
> The `storageType` must match the disk size in the SKU name.

### Available Images

| Image ID | Description |
| --- | --- |
| `microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2` | VS 2022 Enterprise + M365 |
| `microsoftvisualstudio_visualstudioplustools_vs-2022-pro-general-win11-m365-gen2` | VS 2022 Professional + M365 |
| `microsoftwindowsdesktop_windows-ent-cpc_win11-22h2-ent-cpc-m365` | Windows 11 22H2 + M365 |
| `microsoftwindowsdesktop_windows-ent-cpc_win11-23h2-ent-cpc-m365` | Windows 11 23H2 + M365 |

* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">6. Pool Configuration</h3>

</div>

---------------------

### Pool Configuration Options

Each pool supports per-pool customization:
| Property | Type | Description |
| --- | --- | --- |
| `poolName` | string | Pool resource name (required) |
| `displayName` | string | User-friendly name shown in portal |
| `devBoxSku` | string | VM SKU (overrides global default) |
| `storageType` | string | Disk storage type |
| `autoStopTime` | string | Auto-stop time in HH:MM format |
| `localAdministrator` | string | `Enabled` or `Disabled` |
| `stopOnDisconnect` | string | `Enabled` or `Disabled` |
| `gracePeriodMinutes` | int | Grace period before stopping |
| `galleryImageName` | string | Custom image from gallery |

* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">7. Network Architecture</h3>

</div>

-----------------------

### Networking Principles

*   Dev Boxes are deployed into **enterprise‑managed VNets**
    
*   Azure AD Join for domain integration
    
*   Outbound traffic governed by **NSGs, Firewall, or NVA**
    
*   DNS aligned with corporate standards
    

### Network Connection Options

**Option 1: Create New Network Connection**

    {
      "createNetworkConnection": true,
      "networkConnectionName": "network-connection-devbox-prd-aus-001",
      "vnetName": "vnet-devbox-prd-aus-001",
      "vnetResourceGroup": "rg-devbox-prd-aus-001",
      "subnetName": "default",
      "domainJoinType": "AzureADJoin"
    }
    

**Option 2: Use Existing Network Connection**

    {
      "createNetworkConnection": false,
      "networkConnectionName": "existing-network-conn",
      "networkConnectionResourceGroup": "rg-where-it-exists"
    }
    

### Reference Topology
``` mermaid

graph TB

    subgraph Hub["Hub VNet"]

        FW["Azure Firewall"]

        DNS["DNS Server"]

        SHARED["Shared Services"]

    end

    subgraph SpokeAE["Spoke: Dev Box VNet AUS "]

        SUBAE["Subnet: default"]

        DEVBOXAE["Dev Boxes"]

    end

    subgraph SpokeSCUS["Spoke: DevBox VNet SCUS"]

        SUBSCUS["Subnet: default"]

        DEVBOXSCUS["Dev Boxes"]

    end

    Hub <--> |"VNet Peering"| SpokeAE

    Hub <--> |"VNet Peering"| SpokeSCUS

    SUBAE --> DEVBOXAE

    SUBSCUS --> DEVBOXSCUS

    style Hub fill:#0078D4,color:#fff

    style FW fill:#E74C3C,color:#fff

```
* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">8. Deployment</h3>

</div>

-------------

### Deployment Flow

``` mermaid  
sequenceDiagram  
participant User  
participant GitHub  
participant Azure

    User->>GitHub: Push to main/test branch
    GitHub->>GitHub: Trigger workflow
    GitHub->>Azure: OIDC Authentication
    Azure-->>GitHub: Token
    GitHub->>Azure: az deployment sub validate
    Azure-->>GitHub: Validation Result
    GitHub->>Azure: az deployment sub what-if
    Azure-->>GitHub: What-If Preview
    GitHub->>Azure: az deployment sub create
    Azure-->>GitHub: Deployment Result
    GitHub-->>User: Pipeline Complete
    

```

### Local Deployment

    # Login to Azure
    az login
    az account set --subscription "<subscription-id>"
    
    # Validate the template
    az deployment sub validate `
      --location australiaeast `
      --template-file main.bicep `
      --parameters parameters.json
    
    # Preview changes (What-If)
    az deployment sub what-if `
      --location australiaeast `
      --template-file main.bicep `
      --parameters parameters.json
    
    # Deploy
    az deployment sub create `
      --location australiaeast `
      --template-file main.bicep `
      --parameters parameters.json `
      --name "devcenter-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    

### GitHub Actions Pipeline

#### Required Secrets

| Secret | Description |
| --- | --- |
| `AZURE_CLIENT_ID` | App registration client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |

#### Pipeline Stages

| Stage | Trigger | Action |
| --- | --- | --- |
| Validate | All pushes & PRs | Bicep build and lint |
| What-If | All pushes & PRs | Preview changes |
| Deploy | Push to `main`/`test` | Full deployment |

* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">9. Security Model</h3>

</div>


-----------------

##Conditional Access Design

**How Conditional Access Enables This Model**

  

Microsoft Entra Conditional Access serves as the central policy enforcement point for Dev Box access. During each connection attempt, Entra ID performs a real-time evaluation of multiple contextual signals:

  

| Signal | Evaluation Criteria |
| --- | --- |
| **Identity** | User authentication status, MFA completion, group membership |
| **Device** | Management state (Intune-enrolled vs. unmanaged), compliance posture, OS version |
| **Location** | Geographic location, IP reputation, named/trusted locations |
| **Risk** | Sign-in risk level, user risk score, anomaly detection (impossible travel, atypical usage patterns) |


Based on this evaluation, Conditional Access renders an access decision: **grant**, **grant with conditions** (e.g., require MFA, limit session), or **block**.

 

**Policy Design for BYOD Scenarios**

  

| Policy | Target Users | Device Type | Requirements | Session Controls |
| --- | --- | --- | --- | --- |
| **Corporate Devices** | All employees | Intune-managed | MFA + Device compliance | Full access |
| **BYOD/Personal Devices** | Developers, Contractors | Unmanaged | MFA + Risk evaluation | **Clipboard disabled, Drive redirection blocked** |
| **High-Risk Access** | Any user | Any device | Block or step-up MFA | Block if risk is high |
| **Admin Access** | Platform admins | Managed only | Phishing-resistant MFA + Trusted location | Full access, PIM required |

  

**Data Loss Prevention: Keeping Code in the Cloud**


For BYOD scenarios, session controls enforce that sensitive data cannot leave the Dev Box:

 
| Control | Setting | Purpose |
| --- | --- | --- |
| **Clipboard Redirection** | Disabled | Prevents copy/paste from Dev Box to local device |
| **Drive Redirection** | Disabled | Prevents mounting local drives inside Dev Box |
| **Printer Redirection** | Disabled | Prevents printing sensitive content locally |
| **Download Blocking** | Enabled | Files cannot be transferred to local device |


> **Result:** Developers can code, build, and deploy from anywhere—but source code and credentials never touch the personal device.

  

**Business Outcomes**

  

| Benefit | Description |
| --- | --- |
| **Rapid Contractor Onboarding** | Contractors productive on day 1—no hardware shipping required |
| **Global Workforce Enablement** | Work-from-home and offshore teams access same secure environment |
| **Zero Data on BYOD** | Intellectual property remains in Azure, not on personal devices |
| **Compliance Ready** | Audit trail of all access via Entra ID sign-in logs |
| **Cost Reduction** | No need to purchase/ship/manage physical laptops for contractors |

  
  
  

### RBAC‑Based Access Model

Role-Based Access Control (RBAC) governs who can perform actions on Dev Box resources. This blueprint enforces a **group-based access model**—users are never assigned permissions directly. Instead, access is inherited through Microsoft Entra ID security groups.

**Why Group-Based Access?**

- **Scalability**: Add/remove users from groups rather than individual assignments
- **Auditability**: Easier to review "who has access" by examining group membership
- **Consistency**: Reduces configuration drift and orphaned permissions
- **Automation**: Groups can be managed via HR systems or identity governance workflows

  

**Access Hierarchy:**

  

| Scope | Role | Access Level | Typical Assignees |
| --- | --- | --- | --- |
| **Dev Center** | DevCenter Admin | Full control over Dev Center settings, catalogs, and policies | Platform team, Cloud COE |
| **Project** | Project Admin | Manage pools, definitions, and settings within a project | Team leads, Engineering managers |
| **Project** | Dev Box User | Create, start, stop, and delete own Dev Boxes | Developers, Contractors |
| **Pool** | (Inherited) | Access specific pools within a project | Persona-based (Standard, Power User) |

  

**Example Group Naming Convention:**

- `SG-DevBox-PlatformAdmins` → Dev Center-level access
- `SG-DevBox-TeamA-Admins` → Project admin for Team-A
- `SG-DevBox-TeamA-Users` → Dev Box users for Team-A

  

> **Best Practice:** Use Privileged Identity Management (PIM) for just-in-time elevation of admin roles, ensuring administrators only have elevated access when actively needed.

  

### Security Controls Summary

  
  

The Dev Box platform implements a **defense-in-depth** security model across four interconnected pillars. This layered approach ensures that if one control is bypassed, multiple additional barriers protect the environment.

  

| Pillar | Purpose | Key Question Answered |
|--------|---------|----------------------|
| **Identity** | Controls authentication and authorization | *Who* can access Dev Boxes? |
| **Network** | Secures data in transit and network boundaries | *Where* can traffic flow? |
| **Platform** | Hardens the compute environment itself | *What* runs on Dev Boxes? |
| **Monitoring** | Provides visibility, detection, and response | *How* do we detect issues? |

  

**Identity Controls**

- **Entra ID Authentication**: All users authenticate via Microsoft Entra ID (formerly Azure AD)

- **Group-based RBAC**: Permissions assigned through security groups, not individual users

- **Conditional Access**: Context-aware policies enforce device compliance and MFA

- **MFA Enforcement**: Multi-factor authentication required for all Dev Box access

  

**Network Controls**

- **Enterprise VNets**: Dev Boxes deployed into customer-managed virtual networks

- **NSG Controls**: Network Security Groups restrict inbound/outbound traffic

- **Azure Firewall**: Centralized egress filtering and threat intelligence

- **Private Endpoints**: PaaS services accessed over private IP addresses (no public internet)

  

**Platform Controls**

- **Hardened Images**: Security-compliant base images with CIS benchmarks applied

- **No Local Admin**: Users operate without local administrator rights (configurable per pool)

- **Security Agents**: Microsoft Defender for Endpoint pre-installed on all Dev Boxes

- **Image Versioning**: Controlled rollout of image updates with rollback capability

  

**Monitoring Controls**

- **Azure Monitor**: Centralized collection of logs and metrics

- **Diagnostic Logs**: Provisioning events, connection logs, and health checks

- **Alerting**: Proactive notifications for failures, capacity issues, and anomalies

- **Audit Trails**: Immutable record of administrative actions for compliance
``` mermaid
flowchart LR
    SC[Security Controls]

    SC --> ID[Identity]
    SC --> NW[Network]
    SC --> PL[Platform]
    SC --> MO[Monitoring]

    ID --> ID1[Entra ID Authentication]
    ID --> ID2[Group-based RBAC]
    ID --> ID3[Conditional Access]
    ID --> ID4[MFA Enforcement]

    NW --> NW1[Enterprise VNets]
    NW --> NW2[NSG Controls]
    NW --> NW3[Azure Firewall]
    NW --> NW4[Private Endpoints]

    PL --> PL1[Hardened Images]
    PL --> PL2[No Local Admin]
    PL --> PL3[Security Agents]
    PL --> PL4[Image Versioning]

    MO --> MO1[Azure Monitor]
    MO --> MO2[Diagnostic Logs]
    MO --> MO3[Alerting]
    MO --> MO4[Audit Trails]
```


* * *


<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">10. Cost Governance</h3>

</div>

-------------------
### Cost Controls

| Control | Implementation |
| --- | --- |
| **Tagging** | Mandatory tags via IaC: `CostCenter`, `team`, `environment` |
| **Auto-Stop** | Daily auto-stop at 19:00 local time |
| **Stop-on-Disconnect** | 60-120 minute grace period |
| **Max Dev Boxes** | 2-3 per user per project |
| **SKU Right-Sizing** | Persona-based SKU selection |

### Current Tag Configuration

    {
      "environment": "prd",
      "managedBy": "bicep",
      "gitrepo": "<repository-url>"
    }
    

* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">11. Timezone Configuration</h3>

</div>

-------------------

Projects use **IANA timezone format** for auto-stop schedules.

### Common IANA Timezones

| Region | IANA Timezone |
| --- | --- |
| Australia (Sydney) | `Australia/Sydney` |
| Australia (Perth) | `Australia/Perth` |
| US Central | `America/Chicago` |
| US Eastern | `America/New_York` |
| US Pacific | `America/Los_Angeles` |
| India | `Asia/Kolkata` |
| UK | `Europe/London` |
| Singapore | `Asia/Singapore` |

> [!WARNING]  
> Do not use Windows timezone format (e.g., `AUS Eastern Standard Time`). Use IANA format only.

* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">12. Monitoring & Operations — Session Analytics</h3>


``` mermaid

flowchart TB

    subgraph Sources["Data Sources"]

        DC["Dev Center"]

        PROJ["Projects"]

        POOL["Dev Box Pools"]

        NC["Network Connections"]

    end

  

    subgraph Collection["Data Collection"]

        DIAG["Diagnostic Settings"]

        LOGS["Azure Monitor Logs"]

        METRICS["Platform Metrics"]

    end

  

    subgraph Analysis["Analysis & Alerting"]

        LAW["Log Analytics Workspace"]

        ALERTS["Azure Alerts"]

        DASH["Azure Dashboards"]

        WB["Azure Workbooks"]

    end

  

    subgraph Actions["Response Actions"]

        AG["Action Groups"]

        EMAIL["Email Notifications"]

        WEBHOOK["Webhooks/Logic Apps"]

        ITSM["ITSM Integration"]

    end

  

    DC --> DIAG

    PROJ --> DIAG

    POOL --> DIAG

    NC --> DIAG

  

    DIAG --> LOGS

    DIAG --> METRICS

  

    LOGS --> LAW

    METRICS --> LAW

  

    LAW --> ALERTS

    LAW --> DASH

    LAW --> WB

  

    ALERTS --> AG

    AG --> EMAIL

    AG --> WEBHOOK

    AG --> ITSM

  

    style LAW fill:#0078D4,color:#fff

    style ALERTS fill:#E74C3C,color:#fff

    style DASH fill:#107C10,color:#fff

```


</div>

---------------------------

> **Purpose:** Dev Box monitoring based on `DevCenterConnectionLogs` and `DevCenterResourceOperationLogs`.
> Audience: Operations teams, session monitoring, connection analytics.
>
> **Data Sources:**
> - `DevCenterConnectionLogs` — State lifecycle (`Started` / `Connected` / `Completed`)
> - `DevCenterResourceOperationLogs` — Dev Box ownership mapping

---

### Section 1: Real-Time Session Monitoring

#### 1.1 Currently Active Sessions

> All Dev Boxes with currently active user sessions.
> Based on connection `State = "Connected"` with no subsequent `"Completed"` event.

```kusto
let devBoxOwnership =
    DevCenterResourceOperationLogs
    | where OperationName in ("CreateDevBox", "DevBoxStartAction", "Schedule", "DevBoxStopAction")
    | extend DevBoxName = tostring(split(SubResourceId, "/")[-1])
    | extend DevBoxUser = tostring(split(SubResourceId, "/")[-3])
    | extend DevProject = tostring(split(AdditionalProperties.ProjectId, "/")[-1])
    | where isnotempty(DevBoxName) and isnotempty(DevBoxUser)
    | summarize arg_max(TimeGenerated, DevBoxUser, DevProject) by DevBoxName;

DevCenterConnectionLogs
| summarize arg_max(TimeGenerated, State, SessionHostName) by DevBoxName
| where State == "Connected"
| extend SessionStartTime = TimeGenerated
| extend ActiveDuration = round(datetime_diff("minute", now(), SessionStartTime) / 60.0, 2)
| join kind=leftouter devBoxOwnership on DevBoxName
| project DevBoxName,
          SessionHostName,
          DevBoxUser,
          DevProject,
          SessionStartTime,
          ActiveHours = ActiveDuration
| order by ActiveHours desc
```

#### 1.2 Active Session Summary (KPI)

> Real-time KPI showing current active sessions — ideal for a dashboard tile.

```kusto
let devBoxOwnership =
    DevCenterResourceOperationLogs
    | where OperationName in ("CreateDevBox", "DevBoxStartAction", "Schedule", "DevBoxStopAction")
    | extend DevBoxName = tostring(split(SubResourceId, "/")[-1])
    | extend DevBoxUser = tostring(split(SubResourceId, "/")[-3])
    | extend DevProject = tostring(split(AdditionalProperties.ProjectId, "/")[-1])
    | where isnotempty(DevBoxName) and isnotempty(DevBoxUser)
    | summarize arg_max(TimeGenerated, DevBoxUser, DevProject) by DevBoxName;

DevCenterConnectionLogs
| summarize arg_max(TimeGenerated, State, SessionHostName) by DevBoxName
| where State == "Connected"
| join kind=leftouter devBoxOwnership on DevBoxName
| summarize 
      TotalActiveSessions = count(),
      UniqueDevBoxes      = dcount(DevBoxName),
      UniqueSessionHosts  = dcount(SessionHostName),
      UniqueUsers         = dcount(DevBoxUser),
      UniqueProjects      = dcount(DevProject)
```

#### 1.3 Long Running Active Sessions Alert

> Active sessions exceeding threshold duration (default: **12 hours**).
> Use case: cost alerts, forgotten sessions, auto-disconnect policy.

```kusto
let threshold_hours = 12;

let devBoxOwnership =
    DevCenterResourceOperationLogs
    | where OperationName in ("CreateDevBox", "DevBoxStartAction", "Schedule", "DevBoxStopAction")
    | extend DevBoxName = tostring(split(SubResourceId, "/")[-1])
    | extend DevBoxUser = tostring(split(SubResourceId, "/")[-3])
    | extend DevProject = tostring(split(AdditionalProperties.ProjectId, "/")[-1])
    | where isnotempty(DevBoxName) and isnotempty(DevBoxUser)
    | summarize arg_max(TimeGenerated, DevBoxUser, DevProject) by DevBoxName;

DevCenterConnectionLogs
| summarize arg_max(TimeGenerated, State, SessionHostName) by DevBoxName
| where State == "Connected"
| extend SessionStartTime = TimeGenerated
| extend ActiveHours = round(datetime_diff("minute", now(), SessionStartTime) / 60.0, 2)
| where ActiveHours > threshold_hours
| join kind=leftouter devBoxOwnership on DevBoxName
| project DevBoxName,
          SessionHostName,
          DevBoxUser,
          DevProject,
          SessionStartTime,
          ActiveHours
| order by ActiveHours desc
```

---

### Section 2: Session History & Patterns

#### 2.1 Daily Session Summary (Last 7 Days)

> Daily session count and duration per Dev Box. Pairs `Connected` → `Completed` events.

```kusto
let devBoxOwnership =
    DevCenterResourceOperationLogs
    | where OperationName in ("CreateDevBox", "DevBoxStartAction", "Schedule", "DevBoxStopAction")
    | extend DevBoxName = tostring(split(SubResourceId, "/")[-1])
    | extend DevBoxUser = tostring(split(SubResourceId, "/")[-3])
    | extend DevProject = tostring(split(AdditionalProperties.ProjectId, "/")[-1])
    | where isnotempty(DevBoxName) and isnotempty(DevBoxUser)
    | summarize arg_max(TimeGenerated, DevBoxUser, DevProject) by DevBoxName;

DevCenterConnectionLogs
| where TimeGenerated > ago(8d)
| where State in ("Connected", "Completed")
| sort by DevBoxName asc, TimeGenerated asc
| serialize
| extend NextState = next(State, 1)
| extend NextTime  = next(TimeGenerated, 1)
| extend NextBox   = next(DevBoxName, 1)
| extend NextHost  = next(SessionHostName, 1)
| where State == "Connected"
      and NextState == "Completed"
      and NextBox == DevBoxName
| extend SessionMinutes = max_of(0, datetime_diff("minute", NextTime, TimeGenerated))
| where SessionMinutes > 0 and SessionMinutes < 1440  // Max 24h per session
| extend Date = startofday(TimeGenerated)
| summarize 
      TotalSessions       = count(),
      TotalSessionMinutes = sum(SessionMinutes),
      AvgSessionMinutes   = round(avg(SessionMinutes), 1),
      LongestSession      = max(SessionMinutes),
      SessionHostName     = any(SessionHostName)
  by Date, DevBoxName
| extend TotalSessionHours   = round(TotalSessionMinutes / 60.0, 2)
| extend AvgSessionHours     = round(AvgSessionMinutes / 60.0, 2)
| extend LongestSessionHours = round(LongestSession / 60.0, 2)
| where Date >= ago(7d)
| join kind=leftouter devBoxOwnership on DevBoxName
| project Date, DevBoxName, SessionHostName, DevBoxUser, DevProject,
          TotalSessions, TotalSessionHours, AvgSessionHours, LongestSessionHours
| order by Date desc, TotalSessionHours desc
```

#### 2.2 Weekly Session Summary (Last 4 Weeks)

> Weekly session aggregation per Dev Box for capacity planning.

```kusto
let devBoxOwnership =
    DevCenterResourceOperationLogs
    | where OperationName in ("CreateDevBox", "DevBoxStartAction", "Schedule", "DevBoxStopAction")
    | extend DevBoxName = tostring(split(SubResourceId, "/")[-1])
    | extend DevBoxUser = tostring(split(SubResourceId, "/")[-3])
    | extend DevProject = tostring(split(AdditionalProperties.ProjectId, "/")[-1])
    | where isnotempty(DevBoxName) and isnotempty(DevBoxUser)
    | summarize arg_max(TimeGenerated, DevBoxUser, DevProject) by DevBoxName;

DevCenterConnectionLogs
| where TimeGenerated > ago(29d)
| where State in ("Connected", "Completed")
| sort by DevBoxName asc, TimeGenerated asc
| serialize
| extend NextState = next(State, 1)
| extend NextTime  = next(TimeGenerated, 1)
| extend NextBox   = next(DevBoxName, 1)
| where State == "Connected"
      and NextState == "Completed"
      and NextBox == DevBoxName
| extend SessionMinutes = max_of(0, datetime_diff("minute", NextTime, TimeGenerated))
| where SessionMinutes > 0 and SessionMinutes < 10080  // Max 7 days
| extend WeekStart = startofweek(TimeGenerated)
| summarize 
      TotalSessions       = count(),
      TotalSessionMinutes = sum(SessionMinutes),
      AvgSessionMinutes   = round(avg(SessionMinutes), 1),
      SessionHostName     = any(SessionHostName)
  by WeekStart, DevBoxName
| extend TotalSessionHours = round(TotalSessionMinutes / 60.0, 2)
| extend AvgSessionHours   = round(AvgSessionMinutes / 60.0, 2)
| where WeekStart >= startofweek(ago(28d))
| join kind=leftouter devBoxOwnership on DevBoxName
| project WeekStart, DevBoxName, SessionHostName, DevBoxUser, DevProject,
          TotalSessions, TotalSessionHours, AvgSessionHours
| order by WeekStart desc, TotalSessionHours desc
```

#### 2.3 Session Trend (Last 30 Days) — Aggregated

> Daily total session count and hours across all Dev Boxes. Ideal for a line chart.

```kusto
DevCenterConnectionLogs
| where TimeGenerated > ago(31d)
| where State in ("Connected", "Completed")
| sort by DevBoxName asc, TimeGenerated asc
| serialize
| extend NextState = next(State, 1)
| extend NextTime  = next(TimeGenerated, 1)
| extend NextBox   = next(DevBoxName, 1)
| where State == "Connected"
      and NextState == "Completed"
      and NextBox == DevBoxName
| extend SessionMinutes = max_of(0, datetime_diff("minute", NextTime, TimeGenerated))
| where SessionMinutes > 0 and SessionMinutes < 1440
| extend Date = startofday(TimeGenerated)
| summarize 
      TotalSessions       = count(),
      TotalSessionMinutes = sum(SessionMinutes),
      UniqueDevBoxes      = dcount(DevBoxName)
  by Date
| extend TotalSessionHours = round(TotalSessionMinutes / 60.0, 2)
| extend AvgSessionHours   = round(TotalSessionMinutes / toreal(TotalSessions) / 60.0, 2)
| where Date >= ago(30d)
| project Date, TotalSessions, TotalSessionHours, UniqueDevBoxes, AvgSessionHours
| order by Date asc
```

#### 2.4 Session Duration Distribution

> Statistical distribution of session lengths.
> Buckets: `<15min`, `15-60min`, `1-4h`, `4-8h`, `8-12h`, `>12h`

```kusto
DevCenterConnectionLogs
| where TimeGenerated > ago(30d)
| where State in ("Connected", "Completed")
| sort by DevBoxName asc, TimeGenerated asc
| serialize
| extend NextState = next(State, 1)
| extend NextTime  = next(TimeGenerated, 1)
| extend NextBox   = next(DevBoxName, 1)
| where State == "Connected"
      and NextState == "Completed"
      and NextBox == DevBoxName
| extend SessionMinutes = max_of(0, datetime_diff("minute", NextTime, TimeGenerated))
| where SessionMinutes > 0 and SessionMinutes < 1440
| extend DurationBucket = case(
      SessionMinutes < 15,                   "< 15 minutes",
      SessionMinutes >= 15 and SessionMinutes < 60,  "15-60 minutes",
      SessionMinutes >= 60 and SessionMinutes < 240, "1-4 hours",
      SessionMinutes >= 240 and SessionMinutes < 480, "4-8 hours",
      SessionMinutes >= 480 and SessionMinutes < 720, "8-12 hours",
                                              "> 12 hours")
| summarize SessionCount = count() by DurationBucket
| extend TotalSessions = toscalar(
    DevCenterConnectionLogs
    | where TimeGenerated > ago(30d)
    | where State in ("Connected", "Completed")
    | sort by DevBoxName asc, TimeGenerated asc
    | serialize
    | extend NextState = next(State, 1)
    | extend NextBox = next(DevBoxName, 1)
    | where State == "Connected" and NextState == "Completed" and NextBox == DevBoxName
    | count)
| extend Percentage = round(100.0 * SessionCount / TotalSessions, 1)
| project DurationBucket, SessionCount, Percentage
| order by SessionCount desc
```

---

### Section 3: Connection Performance Analytics

#### 3.1 Connection Latency by Day (Last 30 Days)

> Time from `Started` → `Connected` state (connection establishment).
> High latency (>60s) may indicate cold starts or resource contention.

```kusto
DevCenterConnectionLogs
| where TimeGenerated > ago(30d)
| where State in ("Started", "Connected")
| sort by DevBoxName asc, TimeGenerated asc
| serialize
| extend NextState = next(State, 1)
| extend NextTime  = next(TimeGenerated, 1)
| extend NextBox   = next(DevBoxName, 1)
| where State == "Started"
      and NextState == "Connected"
      and NextBox == DevBoxName
| extend LatencySeconds = datetime_diff("second", NextTime, TimeGenerated)
| where LatencySeconds between (1 .. 600)  // Filter outliers (1s-10min)
| extend Date = startofday(TimeGenerated)
| summarize 
      AvgLatencySeconds = round(avg(LatencySeconds), 1),
      P50               = percentile(LatencySeconds, 50),
      P90               = percentile(LatencySeconds, 90),
      P95               = percentile(LatencySeconds, 95),
      P99               = percentile(LatencySeconds, 99),
      Samples           = count()
  by Date
| order by Date desc
```

#### 3.2 Connection Latency by Dev Box (Last 30 Days)

> Connection performance per individual Dev Box for troubleshooting.

```kusto
DevCenterConnectionLogs
| where TimeGenerated > ago(30d)
| where State in ("Started", "Connected")
| sort by DevBoxName asc, TimeGenerated asc
| serialize
| extend NextState = next(State, 1)
| extend NextTime  = next(TimeGenerated, 1)
| extend NextBox   = next(DevBoxName, 1)
| extend NextHost  = next(SessionHostName, 1)
| where State == "Started"
      and NextState == "Connected"
      and NextBox == DevBoxName
| extend LatencySeconds = datetime_diff("second", NextTime, TimeGenerated)
| where LatencySeconds between (1 .. 600)
| summarize 
      AvgLatencySeconds  = round(avg(LatencySeconds), 1),
      P90                = percentile(LatencySeconds, 90),
      P95                = percentile(LatencySeconds, 95),
      TotalConnections   = count(),
      SessionHostName    = any(NextHost)
  by DevBoxName
| order by P90 desc
```

#### 3.3 Slow Connections Alert (Last 7 Days)

> Recent connections exceeding latency threshold (default: **60 seconds**).

```kusto
let threshold_seconds = 60;

DevCenterConnectionLogs
| where TimeGenerated > ago(7d)
| where State in ("Started", "Connected")
| sort by DevBoxName asc, TimeGenerated asc
| serialize
| extend NextState = next(State, 1)
| extend NextTime  = next(TimeGenerated, 1)
| extend NextBox   = next(DevBoxName, 1)
| extend NextHost  = next(SessionHostName, 1)
| where State == "Started"
      and NextState == "Connected"
      and NextBox == DevBoxName
| extend LatencySeconds = datetime_diff("second", NextTime, TimeGenerated)
| where LatencySeconds > threshold_seconds and LatencySeconds < 600
| project TimeGenerated,
          DevBoxName,
          SessionHostName = NextHost,
          LatencySeconds
| order by LatencySeconds desc
```

---

### Section 4: Capacity & Concurrency Analytics

#### 4.1 Peak Concurrent Sessions (Last 30 Days)

> Maximum simultaneous active sessions. Uses 15-minute time buckets.
> Use case: capacity planning, license requirements, infrastructure sizing.

```kusto
let bucket = 15m;
let lookback = 30d;

let sessions =
    DevCenterConnectionLogs
    | where TimeGenerated > ago(lookback)
    | where State in ("Connected", "Completed")
    | sort by DevBoxName asc, TimeGenerated asc
    | serialize
    | extend NextState = next(State, 1)
    | extend NextTime  = next(TimeGenerated, 1)
    | extend NextBox   = next(DevBoxName, 1)
    | where State == "Connected"
          and NextState == "Completed"
          and NextBox == DevBoxName
    | project DevBoxName, SessionStart = TimeGenerated, SessionEnd = NextTime;

let minTime = toscalar(sessions | summarize min(SessionStart));
let maxTime = now();

range TimeBucket from bin(minTime, bucket) to maxTime step bucket
| extend dummy = 1
| join kind=inner (sessions | extend dummy = 1) on dummy
| where TimeBucket >= SessionStart and TimeBucket < SessionEnd
| summarize 
      ConcurrentSessions = count(),
      UniqueDevBoxes    = dcount(DevBoxName)
  by TimeBucket
| order by ConcurrentSessions desc
| take 100
```

#### 4.2 Hourly Connection Pattern (Last 30 Days)

> Connection activity by hour of day. Useful for auto-scaling policies.

```kusto
DevCenterConnectionLogs
| where TimeGenerated > ago(30d)
| where State == "Connected"
| extend HourOfDay = hourofday(TimeGenerated)
| summarize TotalConnections = count() by HourOfDay
| extend AvgConnectionsPerDay = round(TotalConnections / 30.0, 1)
| project HourOfDay, TotalConnections, AvgConnectionsPerDay
| order by HourOfDay asc
```

#### 4.3 Session Activity Heatmap (Day of Week x Hour)

> Session patterns by day of week and hour for heatmap visualization.

```kusto
DevCenterConnectionLogs
| where TimeGenerated > ago(30d)
| where State == "Connected"
| extend DayOfWeek = dayofweek(TimeGenerated) / 1d
| extend DayName = case(
      DayOfWeek == 0, "Sunday",
      DayOfWeek == 1, "Monday",
      DayOfWeek == 2, "Tuesday",
      DayOfWeek == 3, "Wednesday",
      DayOfWeek == 4, "Thursday",
      DayOfWeek == 5, "Friday",
      DayOfWeek == 6, "Saturday",
      "Unknown")
| extend HourOfDay = hourofday(TimeGenerated)
| summarize SessionCount = count() by DayOfWeek, DayName, HourOfDay
| order by DayOfWeek asc, HourOfDay asc
```

---

### Section 5: Dev Box Activity Tracking

#### 5.1 Most Active Dev Boxes (Last 30 Days)

> Dev Boxes ranked by total session hours. Useful for capacity optimization.

```kusto
let devBoxOwnership =
    DevCenterResourceOperationLogs
    | where OperationName in ("CreateDevBox", "DevBoxStartAction", "Schedule", "DevBoxStopAction")
    | extend DevBoxName = tostring(split(SubResourceId, "/")[-1])
    | extend DevBoxUser = tostring(split(SubResourceId, "/")[-3])
    | extend DevProject = tostring(split(AdditionalProperties.ProjectId, "/")[-1])
    | where isnotempty(DevBoxName) and isnotempty(DevBoxUser)
    | summarize arg_max(TimeGenerated, DevBoxUser, DevProject) by DevBoxName;

DevCenterConnectionLogs
| where TimeGenerated > ago(30d)
| where State in ("Connected", "Completed")
| sort by DevBoxName asc, TimeGenerated asc
| serialize
| extend NextState = next(State, 1)
| extend NextTime  = next(TimeGenerated, 1)
| extend NextBox   = next(DevBoxName, 1)
| where State == "Connected"
      and NextState == "Completed"
      and NextBox == DevBoxName
| extend SessionMinutes = max_of(0, datetime_diff("minute", NextTime, TimeGenerated))
| where SessionMinutes > 0 and SessionMinutes < 43200
| summarize 
      TotalSessions       = count(),
      TotalSessionMinutes = sum(SessionMinutes),
      AvgSessionMinutes   = round(avg(SessionMinutes), 1),
      LastActive          = max(TimeGenerated),
      SessionHostName     = any(SessionHostName)
  by DevBoxName
| extend TotalSessionHours = round(TotalSessionMinutes / 60.0, 2)
| extend AvgSessionHours   = round(AvgSessionMinutes / 60.0, 2)
| join kind=leftouter devBoxOwnership on DevBoxName
| project DevBoxName, SessionHostName, DevBoxUser, DevProject, TotalSessions,
          TotalSessionHours, AvgSessionHours, LastActive
| order by TotalSessionHours desc
```

#### 5.2 Inactive Dev Boxes (No Recent Connections)

> Dev Boxes with no connection activity in threshold period (default: **14 days**).
> Use case: identify unused resources, cleanup candidates.

```kusto
let threshold_days = 14;

let devBoxOwnership =
    DevCenterResourceOperationLogs
    | where OperationName in ("CreateDevBox", "DevBoxStartAction", "Schedule", "DevBoxStopAction")
    | extend DevBoxName = tostring(split(SubResourceId, "/")[-1])
    | extend DevBoxUser = tostring(split(SubResourceId, "/")[-3])
    | extend DevProject = tostring(split(AdditionalProperties.ProjectId, "/")[-1])
    | where isnotempty(DevBoxName) and isnotempty(DevBoxUser)
    | summarize arg_max(TimeGenerated, DevBoxUser, DevProject) by DevBoxName;

let allKnownBoxes =
    DevCenterConnectionLogs
    | where State == "Connected"
    | summarize arg_max(TimeGenerated, SessionHostName) by DevBoxName;

allKnownBoxes
| extend LastConnection = TimeGenerated
| extend DaysSinceConnection = datetime_diff("day", now(), LastConnection)
| where DaysSinceConnection >= threshold_days
| join kind=leftouter devBoxOwnership on DevBoxName
| project DevBoxName, SessionHostName, DevBoxUser, DevProject, LastConnection, DaysSinceConnection
| order by DaysSinceConnection desc
```

#### 5.3 Connection Frequency by Dev Box (Last 30 Days)

> How often each Dev Box is connected per day. Identifies daily vs occasional users.

```kusto
let devBoxOwnership =
    DevCenterResourceOperationLogs
    | where OperationName in ("CreateDevBox", "DevBoxStartAction", "Schedule", "DevBoxStopAction")
    | extend DevBoxName = tostring(split(SubResourceId, "/")[-1])
    | extend DevBoxUser = tostring(split(SubResourceId, "/")[-3])
    | extend DevProject = tostring(split(AdditionalProperties.ProjectId, "/")[-1])
    | where isnotempty(DevBoxName) and isnotempty(DevBoxUser)
    | summarize arg_max(TimeGenerated, DevBoxUser, DevProject) by DevBoxName;

DevCenterConnectionLogs
| where TimeGenerated > ago(30d)
| where State == "Connected"
| extend Date = startofday(TimeGenerated)
| summarize 
      ConnectionsPerDay = count(),
      SessionHostName   = any(SessionHostName)
  by DevBoxName, Date
| summarize 
      TotalConnections     = sum(ConnectionsPerDay),
      DaysActive           = count(),
      AvgConnectionsPerDay = round(avg(ConnectionsPerDay), 1),
      SessionHostName      = any(SessionHostName)
  by DevBoxName
| join kind=leftouter devBoxOwnership on DevBoxName
| project DevBoxName, SessionHostName, DevBoxUser, DevProject, TotalConnections, DaysActive, AvgConnectionsPerDay
| order by TotalConnections desc
```

* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">13. End‑to‑End Lifecycle Flow</h3>

</div>

-----------------------------

``` mermaid  
gantt  
title Dev Box Deployment Lifecycle  
dateFormat YYYY-MM-DD  
section Phase 1 - Plan  
Define teams/projects :a1, 2026-01-01, 7d  
Define personas :a2, after a1, 5d  
Network baseline :a3, after a2, 5d  
section Phase 2 - Deploy  
Deploy Dev Center :b1, after a3, 3d  
Deploy projects :b2, after b1, 3d  
Configure networks :b3, after b1, 2d  
Create pools :b4, after b2, 3d  
section Phase 3 - Secure  
Enable Conditional Access :c1, after b4, 3d  
Provision users :c2, after c1, 5d  
section Phase 4 - Operate  
Monitor & tune :d1, after c2, 30d  
```

### Lifecycle Phases

| Phase | Activities |
| --- | --- |
| **Plan** | Define teams, personas, network baseline, image strategy |
| **Deploy** | Deploy Dev Center, projects, network connections, pools via IaC |
| **Secure** | Enable Conditional Access, provision users via Entra ID groups |
| **Operate** | Monitor dashboards, tune capacity, maintain images, review access |

* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">14. Dev Box USER Customizations YAML Example</h3>

</div>

-------------------------
## Dev Box Customizations

### Overview

Dev Box supports customization tasks that run during provisioning. These tasks are defined in YAML format and can automate software installation, configuration, and environment setup.

### Example: Install WSL with Ubuntu

This customization task installs Windows Subsystem for Linux (WSL) with Ubuntu 24.04:

```yaml
$schema: "1.0"
tasks:
  - name: powershell
    description: "Install WSL"
    runAs: User
    parameters:
      command: |
        echo "Starting WSL installation...";

        # Set WSL 2 as default
        wsl --set-default-version 2;

        # Download Ubuntu without launching it (avoids interactive prompts)
        wsl --install Ubuntu-24.04 --no-launch;

        echo "WSL installation complete. A reboot is required to finish setup."
```

* * *

<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">15. Troubleshooting</h3>

</div>

-------------------

### Common Errors

| Error | Cause | Solution |
| --- | --- | --- |
| `storageType` Mismatch | Storage doesn't match SKU | Match `storageType` to SKU disk size |
| `ProjectDevCenterCannotBeUpdated` | Project linked to different Dev Center | Delete project or use new name |
| Invalid Timezone | Windows format used | Use IANA format (e.g., `Australia/Sydney`) |
| Network Connection Not Found | Connection doesn't exist | Set `createNetworkConnection: true` |
| Gallery Image Not Found | Image missing or no access | Grant Dev Center Reader access to gallery |
|User Customization Stuck| Dev Box Agent missing on the Dev Box | No error/warning on Network Connection

### Useful Commands

    # List all Dev Centers
    az devcenter admin devcenter list --resource-group <rg> -o table
    
    # List all projects
    az devcenter admin project list --resource-group <rg> -o table
    
    # List network connections
    az devcenter admin network-connection list --resource-group <rg> -o table
    
    # Get deployment error details
    az deployment sub show --name <deployment-name> --query "properties.error" -o json
    

* * *

### Dev Box Agent Missing

  

If customization tasks fail, verify the Dev Box Agent is installed:

  

**Agent Path:**

```

C:\ProgramData\Microsoft\DevBox\Agent

```

  

**Quick Check:**

```powershell

# Check if agent exists

Test-Path "C:\ProgramData\Microsoft\DevBox\Agent"

  

# List agent files

Get-ChildItem "C:\ProgramData\Microsoft\DevBox\Agent" -Recurse

```

  

**If agent is missing:**

- Check if all the network requirements are met for dev box - refer - [Network requirements for Windows 365 | Microsoft Learn](https://learn.microsoft.com/en-us/windows-365/enterprise/requirements-network?tabs=enterprise%2Cent#windows-365-service) and [Understanding the IP address of your IoT hub | Microsoft Learn](https://learn.microsoft.com/en-us/azure/iot-hub/iot-hub-understand-ip-address)
- Once network connection is green check if Dev Box Agent service is running and 2 applications are running on Dev Box. 
<br> <img width="703" height="66" alt="image" src="https://github.com/user-attachments/assets/b6368e6e-606a-49e5-9fc2-14282a3ad7fe" />

<br>
<img width="1236" height="428" alt="image" src="https://github.com/user-attachments/assets/c15f3c85-fb78-4a5e-9cf3-14f26e5cd4b5" />





> [!CAUTION]
> **GitHub Enterprise Server Not Supported**
> 
> As of January 2026, Azure Dev Center **does not support GitHub Enterprise Server** for the following features:
> - **Catalogs** – Cannot connect to GitHub Enterprise Server repositories for catalog definitions
> - **Customizations** – Cannot source customization task YAML files from GitHub Enterprise Server
> 
> **Supported Sources:**
> 
> | Source | Catalogs | Customizations |
> |--------|----------|----------------|
> | GitHub.com (Public/Private) | ✅ Supported | ✅ Supported |
> | Azure DevOps | ✅ Supported | ✅ Supported |
> | GitHub Enterprise Server | ❌ Not Supported | ❌ Not Supported |
> 
> **Workaround:** Use Azure DevOps repositories or migrate catalog/customization files to GitHub.com.
> 
> ⚠️ *This limitation may change in future releases. Always verify the latest supported sources in the [official Microsoft documentation](https://learn.microsoft.com/en-us/azure/dev-box/) before deployment.*


* * *
<div style="background-color:#0078D4; color:white; padding:10px; border-radius:5px; margin:10px 0;">

<h3 style="margin:0; color:white;">16. IP Asset Deliverables</h3>

</div>

-------------------------

This IP is delivered with:
| Asset | Description |
| --- | --- |
| 📄 Bicep Templates | Modular IaC for Dev Center, projects, pools, networking |
| 🔧 GitHub Actions | CI/CD workflows with OIDC authentication |
| 📋 Parameter Files | Production-ready configuration templates |
| 📖 Documentation | This wiki + README.md |




API Version
-----------

This solution uses Azure Dev Center API version **`2025-04-01-preview`**.

* * *

References
----------

*   [Azure Dev Center Documentation](https://learn.microsoft.com/en-us/azure/dev-box/)
    
*   [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
    
*   [IANA Timezone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

* [Understanding the IP address of your IoT hub | Microsoft Learn](https://learn.microsoft.com/en-us/azure/iot-hub/iot-hub-understand-ip-address)

* [Network requirements for Windows 365 | Microsoft Learn](https://learn.microsoft.com/en-us/windows-365/enterprise/requirements-network?tabs=enterprise%2Cent#windows-365-service)

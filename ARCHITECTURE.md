# Architecture Overview

## Deployment Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Actions Workflow                   │
│                                                                   │
│  Trigger: Manual (workflow_dispatch) or Push (main branch)      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Authentication & Setup                        │
│                                                                   │
│  • Azure Login (OIDC)                                            │
│  • Install PowerShell & Azure Modules                            │
│  • Load Configuration Parameters                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Deploy-FabricAssets.ps1                        │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 1. Get Access Token                                      │   │
│  │    • Authenticate with Fabric API                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                     │
│  ┌─────────────────────────▼─────────────────────────────────┐ │
│  │ 2. Create Workspace                                        │ │
│  │    POST /v1/workspaces                                     │ │
│  └─────────────────────────┬─────────────────────────────────┘ │
│                             │                                     │
│  ┌─────────────────────────▼─────────────────────────────────┐ │
│  │ 3. Add Admin User (Optional)                              │ │
│  │    POST /v1/workspaces/{id}/roleAssignments               │ │
│  └─────────────────────────┬─────────────────────────────────┘ │
│                             │                                     │
│  ┌─────────────────────────▼─────────────────────────────────┐ │
│  │ 4. Create Lakehouse (Optional)                            │ │
│  │    POST /v1/workspaces/{id}/items                         │ │
│  └─────────────────────────┬─────────────────────────────────┘ │
│                             │                                     │
│  ┌─────────────────────────▼─────────────────────────────────┐ │
│  │ 5. Create Data Agent (Optional)                           │ │
│  │    Manual gateway configuration                            │ │
│  └─────────────────────────┬─────────────────────────────────┘ │
│                             │                                     │
│  ┌─────────────────────────▼─────────────────────────────────┐ │
│  │ 6. Create SQL Mirror (Optional)                           │ │
│  │    POST /v1/workspaces/{id}/items                         │ │
│  └─────────────────────────┬─────────────────────────────────┘ │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Microsoft Fabric Workspace                    │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │  Lakehouse   │  │  Data Agent  │  │  SQL DB Mirror     │   │
│  │              │  │              │  │                    │   │
│  │  • Tables    │  │  • Gateway   │  │  • Mirrored Data   │   │
│  │  • Files     │  │  • Connectors│  │  • Real-time Sync  │   │
│  └──────────────┘  └──────────────┘  └────────────────────┘   │
│                                                                   │
│  Admin Users: user@example.com                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Repository Structure                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  📁 .github/workflows/                                           │
│     └── deploy-fabric.yml      ← Main workflow                  │
│                                                                   │
│  📁 config/                                                      │
│     ├── parameters.json         ← Active config (gitignored)    │
│     ├── parameters.example.json ← Template                      │
│     ├── parameters.dev.json     ← Dev environment               │
│     └── parameters.prod.json    ← Prod environment              │
│                                                                   │
│  📁 scripts/                                                     │
│     ├── Deploy-FabricAssets.ps1       ← Main deployment         │
│     ├── Validate-Config.ps1           ← Config validation       │
│     └── Test-LocalDeployment.ps1      ← Local testing           │
│                                                                   │
│  📄 README.md                   ← Full documentation             │
│  📄 QUICKSTART.md              ← Quick start guide               │
│  📄 CONTRIBUTING.md            ← Contribution guidelines         │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Authentication Flow

```
┌──────────────┐
│   GitHub     │
│   Actions    │
└──────┬───────┘
       │
       │ OIDC Token
       │
       ▼
┌──────────────────┐
│   Azure AD       │
│   (Federated)    │
└──────┬───────────┘
       │
       │ Access Token
       │
       ▼
┌──────────────────┐         ┌──────────────────┐
│  Fabric API      │◄────────┤  Graph API       │
│  (Power BI)      │         │  (User Management)│
└──────────────────┘         └──────────────────┘
       │
       │ Create/Update Resources
       │
       ▼
┌──────────────────────────────────────┐
│    Microsoft Fabric Workspace         │
│                                       │
│  • Workspace                          │
│  • Lakehouse                          │
│  • Data Agent                         │
│  • SQL Mirror                         │
└───────────────────────────────────────┘
```

## Configuration Priority

```
Manual Trigger (workflow_dispatch)
         │
         ├─ Workflow Inputs (Highest Priority)
         │
         ▼
Push Trigger (main branch)
         │
         ├─ config/parameters.json
         │
         ▼
Default Values (in script)
         │
         └─ Built-in Defaults (Lowest Priority)
```

## Security Model

```
┌────────────────────────────────────────┐
│         Security Boundaries             │
├────────────────────────────────────────┤
│                                         │
│  🔐 GitHub Secrets (Encrypted)         │
│     • AZURE_CLIENT_ID                  │
│     • AZURE_TENANT_ID                  │
│     • AZURE_SUBSCRIPTION_ID            │
│     • SQL_CONNECTION_STRING            │
│                                         │
│  🚫 Not in Git                         │
│     • config/parameters.json           │
│     • Credentials                      │
│     • Connection strings               │
│                                         │
│  ✅ In Git (Safe)                      │
│     • Templates                        │
│     • Scripts                          │
│     • Documentation                    │
│                                         │
└────────────────────────────────────────┘
```

## API Interactions

```
PowerShell Script
       │
       ├──► Fabric REST API
       │    • POST /workspaces
       │    • POST /workspaces/{id}/items
       │    • POST /workspaces/{id}/roleAssignments
       │
       ├──► Microsoft Graph API
       │    • GET /users/{email}
       │    • For user principal lookup
       │
       └──► Azure Resource Manager
            • For authentication
            • For token acquisition
```

## Deployment Stages

```
Stage 1: Validation
├─ Configuration file syntax
├─ Required parameters present
├─ Format validation (GUID, email, etc.)
└─ Authentication check

Stage 2: Core Resources
├─ Create workspace
└─ Verify workspace creation

Stage 3: Access Control (Optional)
├─ Lookup user principal
├─ Add role assignment
└─ Verify permissions

Stage 4: Data Assets (Optional)
├─ Create lakehouse
├─ Configure data agent
└─ Setup SQL mirror

Stage 5: Validation
├─ Verify all resources created
├─ Check resource IDs
└─ Report status
```

## Error Handling Strategy

```
Error Occurs
     │
     ├─ Log error details
     │
     ├─ Warning vs Critical?
     │  │
     │  ├─ Warning: Continue with next step
     │  │            Log warning message
     │  │
     │  └─ Critical: Stop execution
     │               Report failure
     │               Exit with error code
     │
     └─ Return status to GitHub Actions
```

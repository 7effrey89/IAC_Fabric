# Usage Examples

This directory contains example configurations for common deployment scenarios.

## Examples

### 1. Minimal Workspace
**File:** `minimal-workspace.json`

Creates just a workspace with no additional resources. Perfect for getting started.

```json
{
  "tenantId": "12345678-1234-1234-1234-123456789abc",
  "workspaceName": "MinimalWorkspace",
  "workspaceDescription": "Basic workspace for testing",
  "adminUserEmail": "",
  "lakehouseName": "",
  "dataAgentName": "",
  "sqlMirror": {
    "name": "",
    "serverName": "",
    "databaseName": "",
    "connectionString": ""
  }
}
```

**What it creates:**
- ✅ Fabric Workspace

---

### 2. Workspace with Lakehouse
**File:** `workspace-with-lakehouse.json`

Creates a workspace with a lakehouse for data storage and analytics.

```json
{
  "tenantId": "12345678-1234-1234-1234-123456789abc",
  "workspaceName": "Analytics-Workspace",
  "workspaceDescription": "Analytics workspace with lakehouse",
  "adminUserEmail": "data-engineer@example.com",
  "lakehouseName": "AnalyticsLakehouse",
  "dataAgentName": "",
  "sqlMirror": {
    "name": "",
    "serverName": "",
    "databaseName": "",
    "connectionString": ""
  }
}
```

**What it creates:**
- ✅ Fabric Workspace
- ✅ Admin user access
- ✅ Lakehouse

**Use case:** Data analytics, data lake storage, Delta tables

---

### 3. Full Stack Deployment
**File:** `full-stack.json`

Complete deployment with all features enabled.

```json
{
  "tenantId": "12345678-1234-1234-1234-123456789abc",
  "workspaceName": "Production-Full-Stack",
  "workspaceDescription": "Production environment with all features",
  "adminUserEmail": "admin@example.com",
  "lakehouseName": "ProdLakehouse",
  "dataAgentName": "ProdGateway",
  "sqlMirror": {
    "name": "ProdSQLMirror",
    "serverName": "prod-server.database.windows.net",
    "databaseName": "ProductionDB",
    "connectionString": ""
  }
}
```

**What it creates:**
- ✅ Fabric Workspace
- ✅ Admin user access
- ✅ Lakehouse
- ✅ Data Agent configuration
- ✅ Azure SQL DB Mirror

**Use case:** Production data platform, real-time data replication

---

### 4. Multi-Environment Setup

#### Development
**File:** `dev-environment.json`

```json
{
  "tenantId": "12345678-1234-1234-1234-123456789abc",
  "workspaceName": "DEV-DataPlatform",
  "workspaceDescription": "Development environment",
  "adminUserEmail": "dev-team@example.com",
  "lakehouseName": "DevLakehouse",
  "dataAgentName": "",
  "sqlMirror": {
    "name": "",
    "serverName": "",
    "databaseName": "",
    "connectionString": ""
  }
}
```

#### Staging
**File:** `staging-environment.json`

```json
{
  "tenantId": "12345678-1234-1234-1234-123456789abc",
  "workspaceName": "STAGING-DataPlatform",
  "workspaceDescription": "Staging environment for testing",
  "adminUserEmail": "qa-team@example.com",
  "lakehouseName": "StagingLakehouse",
  "dataAgentName": "",
  "sqlMirror": {
    "name": "StagingSQLMirror",
    "serverName": "staging-server.database.windows.net",
    "databaseName": "StagingDB",
    "connectionString": ""
  }
}
```

#### Production
**File:** `prod-environment.json`

```json
{
  "tenantId": "12345678-1234-1234-1234-123456789abc",
  "workspaceName": "PROD-DataPlatform",
  "workspaceDescription": "Production environment",
  "adminUserEmail": "prod-admin@example.com",
  "lakehouseName": "ProdLakehouse",
  "dataAgentName": "ProdDataGateway",
  "sqlMirror": {
    "name": "ProdSQLMirror",
    "serverName": "prod-server.database.windows.net",
    "databaseName": "ProductionDB",
    "connectionString": ""
  }
}
```

**Deployment strategy:**
1. Deploy to DEV first
2. Test and validate
3. Deploy to STAGING
4. Run integration tests
5. Deploy to PROD

---

### 5. Team Collaboration
**File:** `team-workspace.json`

Workspace for team collaboration with admin access.

```json
{
  "tenantId": "12345678-1234-1234-1234-123456789abc",
  "workspaceName": "DataScience-Team",
  "workspaceDescription": "Collaborative workspace for data science team",
  "adminUserEmail": "team-lead@example.com",
  "lakehouseName": "TeamLakehouse",
  "dataAgentName": "",
  "sqlMirror": {
    "name": "",
    "serverName": "",
    "databaseName": "",
    "connectionString": ""
  }
}
```

**Note:** Additional team members can be added manually in Fabric portal or via Graph API.

---

### 6. Data Migration Project
**File:** `migration-project.json`

Setup for migrating data from Azure SQL to Fabric.

```json
{
  "tenantId": "12345678-1234-1234-1234-123456789abc",
  "workspaceName": "Migration-Project-2024",
  "workspaceDescription": "SQL to Fabric migration workspace",
  "adminUserEmail": "migration-admin@example.com",
  "lakehouseName": "MigrationLakehouse",
  "dataAgentName": "MigrationGateway",
  "sqlMirror": {
    "name": "LegacySQLMirror",
    "serverName": "legacy-server.database.windows.net",
    "databaseName": "LegacyDB",
    "connectionString": ""
  }
}
```

**Use case:** 
- Mirror existing SQL database
- Transform data in lakehouse
- Build new analytics on Fabric

---

### 7. Copy Job Example
**File:** `copy-job-example.json`

Creates a workspace with lakehouse and a copy job (data pipeline) to load data from Azure SQL Server.

```json
{
  "tenantId": "12345678-1234-1234-1234-123456789abc",
  "workspaceName": "DataIngestion-Workspace",
  "workspaceDescription": "Workspace for data ingestion from SQL Server to Lakehouse",
  "adminUserEmail": "data-engineer@example.com",
  "lakehouseName": "IngestionLakehouse",
  "dataAgentName": "",
  "sqlMirror": {
    "name": "",
    "serverName": "",
    "databaseName": "",
    "connectionString": ""
  },
  "copyJob": {
    "name": "CustomerDataCopyJob",
    "sourceServer": "sqlserver.database.windows.net",
    "sourceDatabase": "SalesDB",
    "sourceTable": "Customers",
    "destinationLakehouse": "IngestionLakehouse",
    "destinationTable": "Customers"
  }
}
```

**What it creates:**
- ✅ Fabric Workspace
- ✅ Admin user access
- ✅ Lakehouse
- ✅ Copy Job (Data Pipeline) that copies data from Azure SQL to Lakehouse

**Use case:**
- Data ingestion from Azure SQL Server
- ETL/ELT pipelines
- Regular data synchronization
- One-time or scheduled data loads

**Note:** The copy job uses the `SQL_CONNECTION_STRING` GitHub Secret for authentication to the source SQL Server.

---

## How to Use These Examples

### Method 1: Copy to your config file

```bash
# Choose an example
cp examples/workspace-with-lakehouse.json config/parameters.json

# Edit with your values
nano config/parameters.json

# Commit and push (triggers deployment)
git add config/parameters.json
git commit -m "Deploy analytics workspace"
git push
```

### Method 2: Use in GitHub Actions workflow

1. Go to **Actions** → **Deploy Microsoft Fabric Assets**
2. Click **Run workflow**
3. Copy values from example
4. Fill in the workflow inputs
5. Click **Run workflow**

### Method 3: Local deployment

```powershell
# Use example configuration for local testing
./scripts/Test-LocalDeployment.ps1 -ConfigPath "./examples/minimal-workspace.json" -DryRun
```

---

## Customization Tips

### 1. Naming Conventions

Use consistent naming:
- **Environment prefix:** `DEV-`, `STAGING-`, `PROD-`
- **Team prefix:** `DataScience-`, `Analytics-`, `Engineering-`
- **Purpose suffix:** `-Workspace`, `-Lakehouse`, `-Mirror`

Example: `PROD-Analytics-Workspace`

### 2. Security Best Practices

- Use different admin users per environment
- Never commit connection strings (use GitHub Secrets)
- Use separate tenant IDs for dev/prod if possible
- Apply least privilege access

### 3. Resource Organization

Consider this structure:
```
Workspace: DEV-DataPlatform
├── Lakehouse: DevLakehouse
├── SQL Mirror: DevSQLMirror (if needed)
└── Data Agent: DevGateway (if needed)
```

### 4. Scaling Strategy

**Single workspace per environment:**
```
DEV-Workspace    → Quick setup, simpler management
STAGING-Workspace → Testing and validation
PROD-Workspace    → Production workloads
```

**Multiple workspaces per environment:**
```
PROD-Sales-Workspace
PROD-Marketing-Workspace
PROD-Finance-Workspace
```

---

## Testing Your Configuration

Before deploying:

```powershell
# 1. Validate configuration
./scripts/Validate-Config.ps1 -ConfigPath "./examples/your-config.json"

# 2. Dry run
./scripts/Test-LocalDeployment.ps1 -ConfigPath "./examples/your-config.json" -DryRun

# 3. Deploy to dev first
./scripts/Test-LocalDeployment.ps1 -ConfigPath "./examples/dev-environment.json"
```

---

## Example Workflows

### Scenario 1: New Analytics Project

1. Start with `minimal-workspace.json`
2. Deploy and verify
3. Add lakehouse (use `workspace-with-lakehouse.json`)
4. Add SQL mirror if needed (use `full-stack.json`)

### Scenario 2: Team Onboarding

1. Use `team-workspace.json`
2. Deploy with team lead as admin
3. Team lead adds other members in Fabric portal
4. Configure additional resources as needed

### Scenario 3: Production Migration

1. Deploy dev: `dev-environment.json`
2. Test migration scripts
3. Deploy staging: `staging-environment.json`
4. Run integration tests
5. Deploy prod: `prod-environment.json`
6. Monitor and validate

---

## Need Help?

- 📖 [Main README](../README.md)
- 🚀 [Quick Start Guide](../QUICKSTART.md)
- 🔧 [Troubleshooting](../TROUBLESHOOTING.md)
- 🏗️ [Architecture](../ARCHITECTURE.md)

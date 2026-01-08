# IAC_Fabric - Infrastructure as Code for Microsoft Fabric

This repository provides Infrastructure as Code (IaC) solutions for deploying Microsoft Fabric assets using GitHub Actions.

## Features

- 🚀 Automated deployment of Microsoft Fabric workspaces
- 👤 Optional workspace admin user management
- 🏠 Lakehouse creation and configuration
- 🔌 Data Agent (Gateway) setup support
- 🔄 Azure SQL Database Mirroring
- ⚙️ Easy-to-modify configuration via JSON parameters
- 🔐 Secure credential management with GitHub Secrets

## Prerequisites

- Azure subscription with Microsoft Fabric enabled
- Azure AD application for authentication (Service Principal or OIDC)
- GitHub repository secrets configured
- Appropriate Fabric capacity and licensing

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy-fabric.yml       # GitHub Actions workflow
├── config/
│   ├── parameters.json             # Configuration file (modify this)
│   └── parameters.example.json     # Example configuration
├── scripts/
│   └── Deploy-FabricAssets.ps1     # PowerShell deployment script
└── README.md
```

## Quick Start

### 1. Configure GitHub Secrets

Add the following secrets to your GitHub repository (Settings → Secrets and variables → Actions):

- `AZURE_CLIENT_ID`: Azure AD application client ID
- `AZURE_TENANT_ID`: Azure AD tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
- `SQL_CONNECTION_STRING`: (Optional) SQL Database connection string for mirroring

For OIDC authentication, configure federated credentials in your Azure AD application.

### 2. Configure Parameters

Edit `config/parameters.json` with your desired settings:

```json
{
  "tenantId": "your-tenant-id",
  "workspaceName": "MyFabricWorkspace",
  "workspaceDescription": "Workspace created via GitHub Actions",
  "adminUserEmail": "admin@example.com",
  "lakehouseName": "MyLakehouse",
  "dataAgentName": "",
  "sqlMirror": {
    "name": "MySQLMirror",
    "serverName": "myserver.database.windows.net",
    "databaseName": "MyDatabase",
    "connectionString": ""
  }
}
```

### 3. Deploy

**Option A: Automatic Deployment (Push-based)**

1. Modify `config/parameters.json`
2. Commit and push to the `main` branch
3. GitHub Actions will automatically deploy the changes

**Option B: Manual Deployment (Workflow Dispatch)**

1. Go to Actions → Deploy Microsoft Fabric Assets
2. Click "Run workflow"
3. Fill in the required parameters
4. Click "Run workflow"

## Configuration Parameters

### Core Parameters

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `tenantId` | Yes | Azure AD Tenant ID | `12345678-1234-1234-1234-123456789abc` |
| `workspaceName` | Yes | Name of the Fabric workspace | `MyFabricWorkspace` |
| `workspaceDescription` | No | Description of the workspace | `Production workspace` |
| `adminUserEmail` | No | Email of user to add as admin | `admin@example.com` |

### Lakehouse Parameters

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `lakehouseName` | No | Name of the lakehouse to create | `MyLakehouse` |

### Data Agent Parameters

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `dataAgentName` | No | Name of the data agent | `MyDataAgent` |

**Note**: Data Agents (On-premises gateways) require manual installation and configuration. See [Microsoft Documentation](https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-install).

### SQL Mirror Parameters

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `sqlMirror.name` | No | Name of the SQL mirror | `MySQLMirror` |
| `sqlMirror.serverName` | Conditional* | Azure SQL server name | `myserver.database.windows.net` |
| `sqlMirror.databaseName` | Conditional* | Database name | `MyDatabase` |
| `sqlMirror.connectionString` | Conditional* | SQL connection string (store in secrets) | Stored in GitHub secrets |

*Required if creating a SQL mirror

## PowerShell Script Usage

You can also run the deployment script manually:

```powershell
# Install required modules
Install-Module -Name Az.Accounts -Force

# Connect to Azure
Connect-AzAccount

# Run deployment
./scripts/Deploy-FabricAssets.ps1 `
    -TenantId "your-tenant-id" `
    -WorkspaceName "MyWorkspace" `
    -WorkspaceDescription "My workspace description" `
    -AdminUserEmail "admin@example.com" `
    -LakehouseName "MyLakehouse" `
    -SqlMirrorName "MySQLMirror" `
    -SqlServerName "myserver.database.windows.net" `
    -SqlDatabaseName "MyDatabase" `
    -SqlConnectionString "Server=..."
```

## GitHub Actions Workflow

The workflow supports two trigger methods:

### 1. Push Trigger
- Triggered when `config/parameters.json` is modified and pushed to `main`
- Reads all parameters from the config file

### 2. Manual Trigger (workflow_dispatch)
- Manually trigger from GitHub Actions UI
- Override parameters via workflow inputs

## Authentication

This solution uses Azure AD authentication with OIDC (OpenID Connect) for secure, passwordless authentication. 

### Setup OIDC Authentication

1. Create an Azure AD application
2. Configure federated credentials for GitHub Actions
3. Assign appropriate permissions (Fabric Admin or Workspace permissions)
4. Add secrets to GitHub repository

For detailed setup instructions, see [Azure OIDC Documentation](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure).

## Security Best Practices

- ✅ Store sensitive data in GitHub Secrets, not in code
- ✅ Use OIDC authentication instead of client secrets when possible
- ✅ Apply least privilege access to service principals
- ✅ Regularly rotate credentials
- ✅ Use separate configurations for dev/test/prod environments
- ✅ Review and audit access logs regularly

## Troubleshooting

### Common Issues

**Issue**: "Failed to get access token"
- **Solution**: Ensure you're properly authenticated with `Connect-AzAccount` or GitHub OIDC is configured

**Issue**: "Workspace creation failed"
- **Solution**: Verify you have Fabric Admin permissions or appropriate workspace creation rights

**Issue**: "SQL Mirror creation failed"
- **Solution**: Ensure you have a Fabric capacity that supports mirroring and proper SQL Database permissions

**Issue**: "Data Agent creation requires manual setup"
- **Solution**: This is expected. Install the on-premises data gateway manually and configure it

## API References

- [Microsoft Fabric REST API](https://learn.microsoft.com/en-us/rest/api/fabric/)
- [Power BI REST API](https://learn.microsoft.com/en-us/rest/api/power-bi/)
- [Microsoft Graph API](https://learn.microsoft.com/en-us/graph/overview)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is provided as-is for educational and reference purposes.

## Support

For issues and questions:
- Open an issue in this repository
- Refer to [Microsoft Fabric Documentation](https://learn.microsoft.com/en-us/fabric/)

## Changelog

### v1.0.0 (Initial Release)
- GitHub Actions workflow for automated deployment
- PowerShell script for Fabric asset creation
- Support for Workspace, Lakehouse, Data Agent, and SQL Mirror
- JSON-based configuration management
- OIDC authentication support

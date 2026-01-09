# Scripts Documentation

This directory contains PowerShell scripts for deploying and managing Microsoft Fabric assets.

## Scripts Overview

### Deploy-FabricAssets.ps1

Main deployment script that creates Fabric resources.

**Purpose**: Automate the creation of Fabric workspaces and related assets.

**Usage**:
```powershell
./Deploy-FabricAssets.ps1 `
    -TenantId "your-tenant-id" `
    -WorkspaceName "MyWorkspace" `
    -LakehouseName "MyLakehouse"
```

**Parameters**:
- `TenantId` (Required): Azure AD tenant ID
- `WorkspaceName` (Required): Name for the workspace
- `WorkspaceDescription` (Optional): Description
- `AdminUserEmail` (Optional): Email of admin user to add
- `LakehouseName` (Optional): Name for lakehouse
- `DataAgentName` (Optional): Name for data agent
- `SqlMirrorName` (Optional): Name for SQL mirror
- `SqlServerName` (Optional): SQL server name
- `SqlDatabaseName` (Optional): SQL database name
- `SqlConnectionString` (Optional): SQL connection string

### Validate-Config.ps1

Validates configuration files before deployment.

**Purpose**: Ensure configuration is valid and complete.

**Usage**:
```powershell
./Validate-Config.ps1 -ConfigPath "../config/parameters.json"
```

**Parameters**:
- `ConfigPath` (Optional): Path to config file (default: ../config/parameters.json)

**Validation Checks**:
- ✓ File exists and is valid JSON
- ✓ Required fields are present
- ✓ Tenant ID is valid GUID format
- ✓ Workspace name length is valid
- ✓ Email format is valid (if provided)
- ⚠ Warns about incomplete SQL mirror configuration

### Test-LocalDeployment.ps1

Test deployment locally before running in GitHub Actions.

**Purpose**: Validate and test deployment in local environment.

**Usage**:
```powershell
# Dry run (validation only)
./Test-LocalDeployment.ps1 -DryRun

# Actual deployment
./Test-LocalDeployment.ps1 -ConfigPath "../config/parameters.dev.json"
```

**Parameters**:
- `ConfigPath` (Optional): Path to config file
- `DryRun` (Switch): Run validation only, no deployment

**Process**:
1. Validates configuration
2. Checks Azure authentication
3. Loads configuration
4. Executes deployment (or shows what would be deployed in dry-run mode)

## Prerequisites

### PowerShell Modules

Install required modules:
```powershell
Install-Module -Name Az.Accounts -Force -AllowClobber
Install-Module -Name Az.Resources -Force -AllowClobber
```

### Authentication

Login to Azure:
```powershell
Connect-AzAccount
```

Or for service principal:
```powershell
Connect-AzAccount -ServicePrincipal -TenantId "tenant-id" -Credential $cred
```

## Common Workflows

### Development Workflow

1. Create/modify configuration:
   ```powershell
   cp config/parameters.example.json config/parameters.json
   # Edit parameters.json
   ```

2. Validate configuration:
   ```powershell
   cd scripts
   ./Validate-Config.ps1
   ```

3. Test deployment (dry run):
   ```powershell
   ./Test-LocalDeployment.ps1 -DryRun
   ```

4. Deploy to dev environment:
   ```powershell
   ./Test-LocalDeployment.ps1 -ConfigPath "../config/parameters.dev.json"
   ```

### Production Deployment

Use GitHub Actions workflow for production deployments to ensure:
- Proper authentication and security
- Audit trail
- Automated validation
- Consistent environment

## Error Handling

All scripts use `$ErrorActionPreference = "Stop"` to ensure errors stop execution.

Common errors:
- **Authentication failed**: Run `Connect-AzAccount`
- **Invalid tenant ID**: Check GUID format
- **API errors**: Check permissions and Fabric capacity
- **Missing parameters**: Review validation output

## Security Notes

- Never commit credentials or secrets to git
- Use GitHub Secrets for sensitive data
- Connection strings should be in secrets, not config files
- Review files before committing
- Use service principals with least privilege

## Extending Scripts

To add new functionality:

1. Add parameters to `Deploy-FabricAssets.ps1`
2. Create function for new asset type
3. Add validation in `Validate-Config.ps1`
4. Update configuration schema
5. Update documentation

Example:
```powershell
function New-FabricDataWarehouse {
    param (
        [string]$WorkspaceId,
        [string]$Name,
        [string]$AccessToken
    )
    
    # Implementation
}
```

## Testing

Test in this order:
1. Configuration validation
2. Dry run
3. Dev environment deployment
4. Prod environment deployment (via GitHub Actions)

## Support

For issues:
- Check script output for error messages
- Review Azure/Fabric permissions
- Verify API endpoints are accessible
- Check [Microsoft Fabric Documentation](https://learn.microsoft.com/en-us/fabric/)

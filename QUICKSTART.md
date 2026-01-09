# Quick Start Guide

Get started with deploying Microsoft Fabric assets in 5 minutes!

## Prerequisites Checklist

- [ ] Azure subscription with Microsoft Fabric enabled
- [ ] Azure AD application (Service Principal) created
- [ ] Fabric Admin permissions or appropriate workspace permissions
- [ ] GitHub repository access

## 5-Minute Setup

### Step 1: Configure GitHub Secrets (2 minutes)

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add these secrets:

```
AZURE_CLIENT_ID       → Your Azure AD app client ID
AZURE_TENANT_ID       → Your Azure AD tenant ID
AZURE_SUBSCRIPTION_ID → Your Azure subscription ID
```

Optional (for SQL mirroring):
```
SQL_CONNECTION_STRING → SQL Database connection string
```

### Step 2: Configure Parameters (2 minutes)

Option A: Use the workflow UI (easiest)
- Go to **Actions** → **Deploy Microsoft Fabric Assets**
- Click **Run workflow**
- Fill in the parameters
- Click **Run workflow**

Option B: Edit config file
1. Copy the example: `cp config/parameters.example.json config/parameters.json`
2. Edit `config/parameters.json` with your values
3. Commit and push to `main` branch

### Step 3: Deploy (1 minute)

**Manual Trigger:**
- Go to **Actions** tab
- Select **Deploy Microsoft Fabric Assets**
- Click **Run workflow**
- Fill in parameters
- Click **Run workflow** button

**Automatic Trigger:**
- Modify `config/parameters.json`
- Commit and push to `main` branch
- Deployment starts automatically

## Minimal Configuration Example

```json
{
  "tenantId": "12345678-1234-1234-1234-123456789abc",
  "workspaceName": "MyWorkspace",
  "workspaceDescription": "My first workspace",
  "adminUserEmail": "",
  "lakehouseName": "MyLakehouse",
  "dataAgentName": "",
  "sqlMirror": {
    "name": "",
    "serverName": "",
    "databaseName": "",
    "connectionString": ""
  }
}
```

This will create:
- ✅ A workspace named "MyWorkspace"
- ✅ A lakehouse named "MyLakehouse"

## What Gets Created?

Based on your configuration:

| Parameter | Creates | Required |
|-----------|---------|----------|
| `workspaceName` | Fabric Workspace | ✅ Yes |
| `adminUserEmail` | Adds user as admin | ❌ No |
| `lakehouseName` | Lakehouse in workspace | ❌ No |
| `dataAgentName` | Data agent config | ❌ No |
| `sqlMirror.*` | SQL DB mirror | ❌ No |

## Testing Locally (Optional)

Before deploying via GitHub Actions, test locally:

```powershell
# Install Azure PowerShell
Install-Module -Name Az.Accounts -Force

# Login to Azure
Connect-AzAccount

# Validate configuration
cd scripts
./Validate-Config.ps1

# Dry run (no deployment)
./Test-LocalDeployment.ps1 -DryRun

# Actual deployment
./Test-LocalDeployment.ps1
```

## Common First-Time Issues

### "Failed to get access token"
**Solution**: Check that your Azure AD app has the correct permissions:
- Power BI Service: Workspace.ReadWrite.All
- Microsoft Graph: User.Read.All (for adding admin users)

### "Workspace creation failed"
**Solution**: Ensure you have:
- Fabric Admin role OR
- Permission to create workspaces
- Active Fabric capacity

### "SQL Mirror creation failed"
**Solution**: SQL mirroring requires:
- Fabric capacity with mirroring enabled
- SQL Database access
- Connection string in GitHub Secrets

## Next Steps

1. ✅ Deploy your first workspace
2. 📖 Read the full [README.md](README.md) for advanced configuration
3. 🔧 Explore [scripts/README.md](scripts/README.md) for local testing
4. 🎯 Configure environment-specific parameters (dev/prod)

## Support

- 📖 [Full Documentation](README.md)
- 🐛 [Report Issues](../../issues)
- 💡 [Contributing Guide](CONTRIBUTING.md)

## Resources

- [Microsoft Fabric Documentation](https://learn.microsoft.com/en-us/fabric/)
- [Fabric REST API Reference](https://learn.microsoft.com/en-us/rest/api/fabric/)
- [Azure OIDC Setup](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure)

---

**Ready to deploy?** Go to **Actions** → **Deploy Microsoft Fabric Assets** → **Run workflow** 🚀

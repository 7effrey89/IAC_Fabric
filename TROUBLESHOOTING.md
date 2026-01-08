# Troubleshooting Guide

Common issues and solutions for deploying Microsoft Fabric assets.

## Table of Contents

- [Authentication Issues](#authentication-issues)
- [Workspace Creation Issues](#workspace-creation-issues)
- [Lakehouse Issues](#lakehouse-issues)
- [SQL Mirror Issues](#sql-mirror-issues)
- [Data Agent Issues](#data-agent-issues)
- [GitHub Actions Issues](#github-actions-issues)
- [Configuration Issues](#configuration-issues)

---

## Authentication Issues

### Error: "Failed to get access token"

**Symptoms:**
```
Failed to get access token. Ensure you're logged in with Connect-AzAccount
```

**Causes:**
1. Not authenticated with Azure
2. OIDC not configured correctly
3. Service principal lacks permissions

**Solutions:**

**For Local Testing:**
```powershell
# Login to Azure
Connect-AzAccount

# Or with service principal
$credential = Get-Credential
Connect-AzAccount -ServicePrincipal -TenantId "your-tenant-id" -Credential $credential
```

**For GitHub Actions:**
1. Verify secrets are set:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

2. Check OIDC configuration in Azure AD app:
   - Go to Azure AD → App Registrations
   - Select your app
   - Certificates & secrets → Federated credentials
   - Ensure GitHub OIDC is configured

### Error: "Unauthorized" or "Forbidden"

**Symptoms:**
```
401 Unauthorized
403 Forbidden
```

**Causes:**
- Service principal lacks required permissions
- Fabric Admin role not assigned
- API permissions not granted

**Solutions:**

1. **Assign Fabric Admin role:**
   - Go to Fabric Admin Portal
   - Add service principal as Fabric Admin

2. **Grant API permissions:**
   - Azure AD → App Registrations → Your App
   - API Permissions → Add permission
   - Power BI Service: `Workspace.ReadWrite.All`
   - Microsoft Graph: `User.Read.All`
   - Grant admin consent

3. **Verify workspace permissions:**
   ```powershell
   # Check current user context
   Get-AzContext
   ```

---

## Workspace Creation Issues

### Error: "Workspace already exists"

**Symptoms:**
```
Failed to create workspace: Workspace with this name already exists
```

**Solutions:**
1. Check existing workspaces in Fabric portal
2. Use a different workspace name
3. Delete the existing workspace if appropriate

### Error: "Capacity not available"

**Symptoms:**
```
Failed to create workspace: No capacity available
```

**Causes:**
- No Fabric capacity assigned
- Capacity is paused or suspended
- Capacity limits reached

**Solutions:**
1. Check Fabric capacity status in Azure
2. Ensure capacity is running
3. Assign capacity to the workspace
4. Upgrade capacity if needed

---

## Lakehouse Issues

### Error: "Failed to create lakehouse"

**Symptoms:**
```
Failed to create lakehouse: Invalid workspace or permissions
```

**Causes:**
- Workspace doesn't exist yet
- Insufficient permissions
- Lakehouse name already in use

**Solutions:**
1. Ensure workspace is created first
2. Verify workspace ID is correct
3. Use unique lakehouse name
4. Check Fabric capacity supports lakehouses

### Lakehouse Creation Timeout

**Symptoms:**
- API call succeeds but lakehouse not visible
- Creation takes too long

**Solutions:**
1. Wait a few minutes for provisioning
2. Check Fabric portal for status
3. Verify capacity is not overloaded

---

## SQL Mirror Issues

### Error: "SQL Mirroring not supported"

**Symptoms:**
```
Failed to create SQL Mirror: Feature not available
```

**Causes:**
- Fabric capacity doesn't support mirroring
- License issue
- Feature not enabled in region

**Solutions:**
1. **Check capacity SKU:**
   - SQL Mirroring requires F64 or higher
   - Upgrade capacity if needed

2. **Verify licensing:**
   - Ensure Fabric license includes mirroring
   - Check region availability

3. **Enable mirroring:**
   - Fabric Admin Portal → Settings
   - Enable SQL Database Mirroring

### Error: "Invalid connection string"

**Symptoms:**
```
Failed to create SQL Mirror: Connection failed
```

**Causes:**
- Incorrect connection string format
- SQL Server firewall blocking access
- Invalid credentials

**Solutions:**
1. **Verify connection string format:**
   ```
   Server=myserver.database.windows.net;Database=mydb;User Id=user;Password=pass;
   ```

2. **Check SQL Server firewall:**
   - Azure Portal → SQL Server → Networking
   - Add Azure services to allowed IPs
   - Add Fabric service IP ranges

3. **Test connection:**
   ```powershell
   # Test SQL connection locally
   Test-NetConnection -ComputerName myserver.database.windows.net -Port 1433
   ```

4. **Store connection string in secrets:**
   - Never commit connection strings to git
   - Use GitHub Secrets: `SQL_CONNECTION_STRING`

---

## Data Agent Issues

### Warning: "Data Agent requires manual setup"

**This is expected behavior.** Data Agents (On-premises Data Gateways) cannot be fully automated.

**Steps to complete setup:**

1. **Install gateway:**
   - Download from: https://aka.ms/on-premises-data-gateway
   - Install on a server with network access to your data sources
   - Run the installer

2. **Configure gateway:**
   - Sign in with your Azure account
   - Register a new gateway or join existing cluster
   - Name the gateway (use the name from your config)

3. **Connect to Fabric:**
   - Fabric Portal → Settings → Manage connections and gateways
   - Locate your gateway
   - Configure data source connections

4. **Grant permissions:**
   - Add service principal as gateway admin
   - Configure data source credentials

**Reference:**
- [Install on-premises data gateway](https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-install)

---

## GitHub Actions Issues

### Workflow fails at "Azure Login" step

**Symptoms:**
```
Error: Unable to get OIDC token
```

**Solutions:**
1. Verify workflow has correct permissions:
   ```yaml
   permissions:
     id-token: write
     contents: read
   ```

2. Check secrets are set in repository settings

3. Verify federated credentials in Azure AD app

### Workflow fails at "Install PowerShell" step

**Symptoms:**
```
Unable to locate package powershell
```

**Solutions:**
1. Check runner OS is Ubuntu (workflow uses apt-get)
2. If using different OS, modify installation steps
3. Verify internet access for package downloads

### Parameters not loading from config file

**Symptoms:**
- Workflow runs but uses wrong values
- Empty parameters

**Causes:**
- Config file path incorrect
- JSON syntax error
- File not committed

**Solutions:**
1. **Verify file exists:**
   ```bash
   ls -la config/parameters.json
   ```

2. **Validate JSON:**
   ```bash
   cat config/parameters.json | python -m json.tool
   ```

3. **Check file is committed:**
   ```bash
   git ls-files config/parameters.json
   ```

---

## Configuration Issues

### Error: "Configuration validation failed"

**Symptoms:**
```
Validation FAILED with errors
```

**Solutions:**

Run validation script:
```powershell
cd scripts
./Validate-Config.ps1
```

Common issues:
- **Tenant ID format:** Must be valid GUID
- **Email format:** Must be valid email address
- **Missing required fields:** workspaceName, tenantId

### JSON Syntax Errors

**Symptoms:**
```
ConvertFrom-Json: Invalid JSON
```

**Solutions:**

1. **Validate JSON online:** https://jsonlint.com

2. **Common mistakes:**
   ```json
   ❌ Trailing comma:
   {
     "name": "value",
   }
   
   ✅ Correct:
   {
     "name": "value"
   }
   
   ❌ Single quotes:
   { 'name': 'value' }
   
   ✅ Correct:
   { "name": "value" }
   ```

3. **Use validation script:**
   ```powershell
   ./scripts/Validate-Config.ps1
   ```

---

## Debugging Tips

### Enable Verbose Logging

**For PowerShell scripts:**
```powershell
$VerbosePreference = "Continue"
./Deploy-FabricAssets.ps1 -Verbose
```

**For GitHub Actions:**
- Re-run workflow with debug logging enabled
- Actions → Workflow → Re-run jobs → Enable debug logging

### Check API Responses

Add debug output to script:
```powershell
$response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
Write-Host "Response: $($response | ConvertTo-Json -Depth 10)"
```

### Test Locally First

Before using GitHub Actions:
```powershell
# 1. Validate
./scripts/Validate-Config.ps1

# 2. Dry run
./scripts/Test-LocalDeployment.ps1 -DryRun

# 3. Deploy to dev
./scripts/Test-LocalDeployment.ps1 -ConfigPath "../config/parameters.dev.json"
```

### Check Fabric Portal

Always verify in the Fabric portal:
1. Go to https://app.fabric.microsoft.com
2. Check workspaces
3. Verify resources created
4. Review any error messages

---

## Getting Help

### Resources

- 📖 [Microsoft Fabric Documentation](https://learn.microsoft.com/en-us/fabric/)
- 🔧 [Fabric REST API Reference](https://learn.microsoft.com/en-us/rest/api/fabric/)
- 💬 [Microsoft Fabric Community](https://community.fabric.microsoft.com/)
- 🐛 [Report Issues in this repo](../../issues)

### Collecting Debug Information

When reporting issues, include:

1. **Error message** (full text)
2. **Configuration** (sanitized, no secrets)
3. **PowerShell version:** `$PSVersionTable`
4. **Azure PowerShell version:** `Get-Module -ListAvailable Az.*`
5. **Steps to reproduce**
6. **Expected vs actual behavior**

### Support Channels

1. **GitHub Issues:** For issues with this code
2. **Microsoft Support:** For Fabric platform issues
3. **Stack Overflow:** Tag: `microsoft-fabric`

---

## Common Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 401 | Unauthorized | Check authentication token |
| 403 | Forbidden | Verify permissions |
| 404 | Not Found | Check resource IDs and URLs |
| 409 | Conflict | Resource already exists |
| 429 | Too Many Requests | Rate limiting, wait and retry |
| 500 | Server Error | Azure/Fabric service issue, retry later |
| 503 | Service Unavailable | Service temporarily down, retry later |

---

## Still Having Issues?

1. ✅ Check this guide
2. ✅ Review [QUICKSTART.md](QUICKSTART.md)
3. ✅ Read [README.md](README.md)
4. ✅ Test locally with validation scripts
5. ✅ Check Fabric service status
6. 🐛 [Open an issue](../../issues) with details

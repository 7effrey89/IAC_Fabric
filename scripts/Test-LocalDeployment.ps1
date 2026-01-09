<#
.SYNOPSIS
    Test deployment script locally before running in GitHub Actions.

.DESCRIPTION
    This script helps test the deployment locally with proper Azure authentication.
    It validates the configuration and runs a dry-run of the deployment.

.PARAMETER ConfigPath
    Path to the configuration file (default: ../config/parameters.json)

.PARAMETER DryRun
    Run in dry-run mode (validation only, no actual deployment)

.EXAMPLE
    ./Test-LocalDeployment.ps1 -DryRun
    ./Test-LocalDeployment.ps1 -ConfigPath "../config/parameters.dev.json"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "../config/parameters.json",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "======================================"
Write-Host "Local Deployment Test"
Write-Host "======================================"
Write-Host ""

# Step 1: Validate configuration
Write-Host "Step 1: Validating configuration..."
$validateScript = Join-Path $PSScriptRoot "Validate-Config.ps1"
& $validateScript -ConfigPath $ConfigPath

if ($LASTEXITCODE -ne 0) {
    Write-Error "Configuration validation failed"
    exit 1
}

Write-Host ""

# Step 2: Check Azure authentication
Write-Host "Step 2: Checking Azure authentication..."
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Not logged in to Azure. Running Connect-AzAccount..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    else {
        Write-Host "✓ Logged in as: $($context.Account.Id)"
        Write-Host "✓ Subscription: $($context.Subscription.Name)"
    }
}
catch {
    Write-Error "Failed to authenticate with Azure. Please run Connect-AzAccount"
    exit 1
}

Write-Host ""

# Step 3: Load configuration
Write-Host "Step 3: Loading configuration..."

# Check if config file exists
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found: $ConfigPath"
    exit 1
}

try {
    $resolvedPath = Resolve-Path $ConfigPath
    $config = Get-Content -Path $resolvedPath -Raw | ConvertFrom-Json
}
catch {
    Write-Error "Failed to load configuration: $_"
    exit 1
}

Write-Host "Configuration loaded from: $resolvedPath"
Write-Host "  Tenant ID: $($config.tenantId)"
Write-Host "  Workspace: $($config.workspaceName)"

Write-Host ""

# Step 4: Execute deployment or dry run
if ($DryRun) {
    Write-Host "Step 4: DRY RUN MODE - No actual deployment will occur" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The following actions would be performed:"
    Write-Host "  1. Create workspace: $($config.workspaceName)"
    
    if ($config.adminUserEmail) {
        Write-Host "  2. Add admin user: $($config.adminUserEmail)"
    }
    
    if ($config.lakehouseName) {
        Write-Host "  3. Create lakehouse: $($config.lakehouseName)"
    }
    
    if ($config.dataAgentName) {
        Write-Host "  4. Configure data agent: $($config.dataAgentName)"
    }
    
    if ($config.sqlMirror.name) {
        Write-Host "  5. Create SQL mirror: $($config.sqlMirror.name)"
    }
    
    if ($config.copyJob.name) {
        Write-Host "  6. Create copy job: $($config.copyJob.name)"
        Write-Host "     Source: $($config.copyJob.sourceServer).$($config.copyJob.sourceDatabase).$($config.copyJob.sourceTable)"
        Write-Host "     Destination: $($config.copyJob.destinationLakehouse).$($config.copyJob.destinationTable)"
    }
    
    Write-Host ""
    Write-Host "✓ Dry run completed successfully" -ForegroundColor Green
}
else {
    Write-Host "Step 4: Executing deployment..." -ForegroundColor Cyan
    Write-Host ""
    
    # Build parameters
    $params = @{
        TenantId        = $config.tenantId
        WorkspaceName   = $config.workspaceName
    }
    
    if ($config.workspaceDescription) { 
        $params.WorkspaceDescription = $config.workspaceDescription 
    }
    if ($config.adminUserEmail) { 
        $params.AdminUserEmail = $config.adminUserEmail 
    }
    if ($config.lakehouseName) { 
        $params.LakehouseName = $config.lakehouseName 
    }
    if ($config.dataAgentName) { 
        $params.DataAgentName = $config.dataAgentName 
    }
    if ($config.sqlMirror.name) { 
        $params.SqlMirrorName = $config.sqlMirror.name 
    }
    if ($config.sqlMirror.serverName) { 
        $params.SqlServerName = $config.sqlMirror.serverName 
    }
    if ($config.sqlMirror.databaseName) { 
        $params.SqlDatabaseName = $config.sqlMirror.databaseName 
    }
    if ($config.sqlMirror.connectionString) { 
        $params.SqlConnectionString = $config.sqlMirror.connectionString 
    }
    if ($config.copyJob.name) {
        $params.CopyJobName = $config.copyJob.name
    }
    if ($config.copyJob.sourceServer) {
        $params.CopyJobSourceServer = $config.copyJob.sourceServer
    }
    if ($config.copyJob.sourceDatabase) {
        $params.CopyJobSourceDatabase = $config.copyJob.sourceDatabase
    }
    if ($config.copyJob.sourceTable) {
        $params.CopyJobSourceTable = $config.copyJob.sourceTable
    }
    if ($config.copyJob.destinationLakehouse) {
        $params.CopyJobDestinationLakehouse = $config.copyJob.destinationLakehouse
    }
    if ($config.copyJob.destinationTable) {
        $params.CopyJobDestinationTable = $config.copyJob.destinationTable
    }
    
    # Execute deployment script
    $deployScript = Join-Path $PSScriptRoot "Deploy-FabricAssets.ps1"
    & $deployScript @params
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✓ Deployment completed successfully" -ForegroundColor Green
    }
    else {
        Write-Error "Deployment failed"
        exit 1
    }
}

Write-Host ""
Write-Host "======================================"
Write-Host "Test completed"
Write-Host "======================================"

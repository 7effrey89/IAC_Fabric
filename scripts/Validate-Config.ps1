<#
.SYNOPSIS
    Validate configuration parameters before deployment.

.DESCRIPTION
    This script validates the parameters.json file to ensure all required fields are present
    and properly formatted before attempting deployment.

.PARAMETER ConfigPath
    Path to the configuration file (default: ../config/parameters.json)

.EXAMPLE
    ./Validate-Config.ps1 -ConfigPath "../config/parameters.json"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "../config/parameters.json"
)

$ErrorActionPreference = "Stop"

Write-Host "======================================"
Write-Host "Configuration Validation"
Write-Host "======================================"
Write-Host ""

# Check if file exists
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found: $ConfigPath"
    exit 1
}

Write-Host "✓ Configuration file found: $ConfigPath"

# Load configuration
try {
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    Write-Host "✓ Configuration file is valid JSON"
}
catch {
    Write-Error "Failed to parse configuration file: $_"
    exit 1
}

# Validate required fields
$errors = @()
$warnings = @()

if (-not $config.tenantId -or $config.tenantId -eq "YOUR_TENANT_ID") {
    $errors += "tenantId is missing or not configured"
}

if (-not $config.workspaceName) {
    $errors += "workspaceName is required"
}

# Validate GUID format for tenant ID
if ($config.tenantId -and $config.tenantId -ne "YOUR_TENANT_ID") {
    try {
        [System.Guid]::Parse($config.tenantId) | Out-Null
        Write-Host "✓ Tenant ID format is valid"
    }
    catch {
        $errors += "tenantId is not a valid GUID format"
    }
}

# Validate workspace name
if ($config.workspaceName) {
    if ($config.workspaceName.Length -lt 1 -or $config.workspaceName.Length -gt 200) {
        $errors += "workspaceName must be between 1 and 200 characters"
    }
    Write-Host "✓ Workspace name is valid: $($config.workspaceName)"
}

# Validate admin email if provided
if ($config.adminUserEmail) {
    if ($config.adminUserEmail -notmatch "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$") {
        $warnings += "adminUserEmail format may be invalid: $($config.adminUserEmail)"
    }
    else {
        Write-Host "✓ Admin email format is valid"
    }
}

# Validate SQL Mirror configuration
if ($config.sqlMirror.name) {
    Write-Host "✓ SQL Mirror configuration detected"
    
    if (-not $config.sqlMirror.serverName) {
        $warnings += "SQL Mirror name is provided but serverName is missing"
    }
    
    if (-not $config.sqlMirror.databaseName) {
        $warnings += "SQL Mirror name is provided but databaseName is missing"
    }
    
    Write-Host "  Note: SQL connection string should be stored in GitHub Secrets"
}

# Validate Lakehouse name
if ($config.lakehouseName) {
    Write-Host "✓ Lakehouse will be created: $($config.lakehouseName)"
}

# Validate Data Agent name
if ($config.dataAgentName) {
    Write-Host "✓ Data Agent name provided: $($config.dataAgentName)"
    Write-Host "  Note: Data agents require manual gateway installation"
}

Write-Host ""
Write-Host "======================================"

# Report errors
if ($errors.Count -gt 0) {
    Write-Host "❌ Validation FAILED with $($errors.Count) error(s):" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
    exit 1
}

# Report warnings
if ($warnings.Count -gt 0) {
    Write-Host "⚠ Validation completed with $($warnings.Count) warning(s):" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
}

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✅ Validation PASSED - Configuration is valid!" -ForegroundColor Green
}

Write-Host "======================================"
exit 0

<#
.SYNOPSIS
    Deploy Microsoft Fabric assets including Workspace, Lakehouse, Data Agent, and Azure SQL DB Mirror.

.DESCRIPTION
    This script automates the deployment of Microsoft Fabric assets using the Fabric REST API.
    It can create a workspace, add optional admin users, create a lakehouse, data agent, and Azure SQL DB mirror.

.PARAMETER TenantId
    Azure AD Tenant ID

.PARAMETER WorkspaceName
    Name of the Fabric workspace to create

.PARAMETER WorkspaceDescription
    Description for the workspace (optional)

.PARAMETER AdminUserEmail
    Optional email address of user to add as workspace admin

.PARAMETER LakehouseName
    Name of the Lakehouse to create (optional)

.PARAMETER DataAgentName
    Name of the Data Agent to create (optional)

.PARAMETER SqlMirrorName
    Name of the Azure SQL DB Mirror to create (optional)

.PARAMETER SqlServerName
    Azure SQL Server name for the mirror (required if creating SQL mirror)

.PARAMETER SqlDatabaseName
    Azure SQL Database name for the mirror (required if creating SQL mirror)

.PARAMETER SqlConnectionString
    Connection string for Azure SQL Database (required if creating SQL mirror)

.EXAMPLE
    ./Deploy-FabricAssets.ps1 -TenantId "xxx" -WorkspaceName "MyWorkspace" -LakehouseName "MyLakehouse"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$WorkspaceName,

    [Parameter(Mandatory = $false)]
    [string]$WorkspaceDescription = "",

    [Parameter(Mandatory = $false)]
    [string]$AdminUserEmail = "",

    [Parameter(Mandatory = $false)]
    [string]$LakehouseName = "",

    [Parameter(Mandatory = $false)]
    [string]$DataAgentName = "",

    [Parameter(Mandatory = $false)]
    [string]$SqlMirrorName = "",

    [Parameter(Mandatory = $false)]
    [string]$SqlServerName = "",

    [Parameter(Mandatory = $false)]
    [string]$SqlDatabaseName = "",

    [Parameter(Mandatory = $false)]
    [string]$SqlConnectionString = ""
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Fabric API endpoint
$fabricApiBaseUrl = "https://api.fabric.microsoft.com/v1"

# Function to get access token
function Get-FabricAccessToken {
    Write-Host "Getting access token for Fabric API..."
    
    try {
        # Try to get token using Azure PowerShell context
        $token = (Get-AzAccessToken -ResourceUrl "https://api.fabric.microsoft.com").Token
        return $token
    }
    catch {
        Write-Error "Failed to get access token. Ensure you're logged in with Connect-AzAccount"
        throw
    }
}

# Function to create workspace
function New-FabricWorkspace {
    param (
        [string]$Name,
        [string]$Description,
        [string]$AccessToken
    )

    Write-Host "Creating Fabric workspace: $Name"

    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }

    $body = @{
        displayName = $Name
    }

    if ($Description) {
        $body.description = $Description
    }

    $uri = "$fabricApiBaseUrl/workspaces"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($body | ConvertTo-Json)
        Write-Host "Workspace created successfully. ID: $($response.id)"
        return $response
    }
    catch {
        Write-Error "Failed to create workspace: $_"
        throw
    }
}

# Function to add workspace admin
function Add-WorkspaceAdmin {
    param (
        [string]$WorkspaceId,
        [string]$UserEmail,
        [string]$AccessToken
    )

    Write-Host "Adding admin user: $UserEmail to workspace"

    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }

    # Get user principal using Microsoft Graph API
    $graphToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token
    $graphHeaders = @{
        "Authorization" = "Bearer $graphToken"
        "Content-Type"  = "application/json"
    }

    try {
        $userUri = "https://graph.microsoft.com/v1.0/users/$UserEmail"
        $user = Invoke-RestMethod -Uri $userUri -Method Get -Headers $graphHeaders

        $body = @{
            identifier      = $user.id
            principalType   = "User"
            groupUserAccessRight = "Admin"
        }

        $uri = "$fabricApiBaseUrl/workspaces/$WorkspaceId/roleAssignments"
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($body | ConvertTo-Json)
        Write-Host "Admin user added successfully"
        return $response
    }
    catch {
        Write-Warning "Failed to add admin user: $_"
    }
}

# Function to create lakehouse
function New-FabricLakehouse {
    param (
        [string]$WorkspaceId,
        [string]$Name,
        [string]$AccessToken
    )

    Write-Host "Creating Lakehouse: $Name"

    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }

    $body = @{
        displayName = $Name
        type        = "Lakehouse"
    }

    $uri = "$fabricApiBaseUrl/workspaces/$WorkspaceId/items"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($body | ConvertTo-Json)
        Write-Host "Lakehouse created successfully. ID: $($response.id)"
        return $response
    }
    catch {
        Write-Error "Failed to create lakehouse: $_"
        throw
    }
}

# Function to create data agent (On-premises data gateway)
function New-FabricDataAgent {
    param (
        [string]$WorkspaceId,
        [string]$Name,
        [string]$AccessToken
    )

    Write-Host "Creating Data Agent: $Name"
    Write-Host "Note: Data agents (gateways) typically require pre-configuration and cannot be fully created via API."
    Write-Host "This will create a placeholder/configuration for the data agent."

    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }

    # Note: Data agents are typically created through Power BI Gateway configuration
    # This is a placeholder that would need to be adapted based on your specific gateway setup
    
    Write-Warning "Data Agent creation requires manual gateway installation and configuration."
    Write-Warning "Please refer to: https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-install"
    
    return $null
}

# Function to create Azure SQL DB Mirror
function New-FabricSqlMirror {
    param (
        [string]$WorkspaceId,
        [string]$Name,
        [string]$ServerName,
        [string]$DatabaseName,
        [string]$ConnectionString,
        [string]$AccessToken
    )

    Write-Host "Creating Azure SQL DB Mirror: $Name"

    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }

    $body = @{
        displayName = $Name
        type        = "SQLEndpoint"
        definition  = @{
            parts = @(
                @{
                    path        = "mirroredDatabase.json"
                    payload     = @{
                        name        = $Name
                        source      = @{
                            type                = "AzureSQLDatabase"
                            serverName          = $ServerName
                            databaseName        = $DatabaseName
                            connectionString    = $ConnectionString
                        }
                    } | ConvertTo-Json -Depth 10
                    payloadType = "InlineBase64"
                }
            )
        }
    }

    $uri = "$fabricApiBaseUrl/workspaces/$WorkspaceId/items"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)
        Write-Host "Azure SQL DB Mirror created successfully. ID: $($response.id)"
        return $response
    }
    catch {
        Write-Warning "Failed to create SQL Mirror: $_"
        Write-Warning "SQL Mirroring may require specific Fabric capacity and licensing."
    }
}

# Main execution
try {
    Write-Host "======================================"
    Write-Host "Microsoft Fabric Assets Deployment"
    Write-Host "======================================"
    Write-Host ""

    # Get access token
    $accessToken = Get-FabricAccessToken

    # Create workspace
    $workspace = New-FabricWorkspace -Name $WorkspaceName -Description $WorkspaceDescription -AccessToken $accessToken
    $workspaceId = $workspace.id

    # Add admin user if specified
    if ($AdminUserEmail) {
        Add-WorkspaceAdmin -WorkspaceId $workspaceId -UserEmail $AdminUserEmail -AccessToken $accessToken
    }

    # Create lakehouse if specified
    if ($LakehouseName) {
        New-FabricLakehouse -WorkspaceId $workspaceId -Name $LakehouseName -AccessToken $accessToken
    }

    # Create data agent if specified
    if ($DataAgentName) {
        New-FabricDataAgent -WorkspaceId $workspaceId -Name $DataAgentName -AccessToken $accessToken
    }

    # Create SQL mirror if specified
    if ($SqlMirrorName -and $SqlServerName -and $SqlDatabaseName) {
        if (-not $SqlConnectionString) {
            Write-Warning "SQL Connection String not provided. Skipping SQL Mirror creation."
        }
        else {
            New-FabricSqlMirror -WorkspaceId $workspaceId -Name $SqlMirrorName `
                -ServerName $SqlServerName -DatabaseName $SqlDatabaseName `
                -ConnectionString $SqlConnectionString -AccessToken $accessToken
        }
    }

    Write-Host ""
    Write-Host "======================================"
    Write-Host "Deployment completed successfully!"
    Write-Host "Workspace ID: $workspaceId"
    Write-Host "======================================"
}
catch {
    Write-Error "Deployment failed: $_"
    exit 1
}

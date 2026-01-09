<#
.SYNOPSIS
    Deploy Microsoft Fabric assets including Workspace, Lakehouse, Data Agent, Azure SQL DB Mirror, and Copy Job.

.DESCRIPTION
    This script automates the deployment of Microsoft Fabric assets using the Fabric REST API.
    It can create a workspace, add optional admin users, create a lakehouse, data agent, Azure SQL DB mirror, and copy jobs.

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

.PARAMETER CopyJobName
    Name of the Copy Job (Data Pipeline) to create (optional)

.PARAMETER CopyJobSourceServer
    Azure SQL Server name for the copy job source (required if creating copy job)

.PARAMETER CopyJobSourceDatabase
    Database name for the copy job source (required if creating copy job)

.PARAMETER CopyJobSourceTable
    Table name to copy from Azure SQL (required if creating copy job)

.PARAMETER CopyJobDestinationLakehouse
    Destination lakehouse name for the copy job (required if creating copy job)

.PARAMETER CopyJobDestinationTable
    Destination table name in the lakehouse (required if creating copy job)

.EXAMPLE
    ./Deploy-FabricAssets.ps1 -TenantId "xxx" -WorkspaceName "MyWorkspace" -LakehouseName "MyLakehouse"

.EXAMPLE
    ./Deploy-FabricAssets.ps1 -TenantId "xxx" -WorkspaceName "MyWorkspace" -LakehouseName "MyLakehouse" -CopyJobName "SQLToCopyJob" -CopyJobSourceServer "server.database.windows.net" -CopyJobSourceDatabase "MyDB" -CopyJobSourceTable "Customers" -CopyJobDestinationLakehouse "MyLakehouse" -CopyJobDestinationTable "Customers"
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
    [string]$SqlConnectionString = "",

    [Parameter(Mandatory = $false)]
    [string]$CopyJobName = "",

    [Parameter(Mandatory = $false)]
    [string]$CopyJobSourceServer = "",

    [Parameter(Mandatory = $false)]
    [string]$CopyJobSourceDatabase = "",

    [Parameter(Mandatory = $false)]
    [string]$CopyJobSourceTable = "",

    [Parameter(Mandatory = $false)]
    [string]$CopyJobDestinationLakehouse = "",

    [Parameter(Mandatory = $false)]
    [string]$CopyJobDestinationTable = ""
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
        [string]$AccessToken,
        [string]$GraphToken
    )

    Write-Host "Adding admin user: $UserEmail to workspace"

    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }

    # Use provided Graph token
    $graphHeaders = @{
        "Authorization" = "Bearer $GraphToken"
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

    # Create the definition payload and encode it to base64
    $definitionPayload = @{
        name        = $Name
        source      = @{
            type                = "AzureSQLDatabase"
            serverName          = $ServerName
            databaseName        = $DatabaseName
            connectionString    = $ConnectionString
        }
    } | ConvertTo-Json -Depth 10
    
    # Encode to base64 as required by InlineBase64 payload type
    $base64Payload = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($definitionPayload))

    $body = @{
        displayName = $Name
        type        = "SQLEndpoint"
        definition  = @{
            parts = @(
                @{
                    path        = "mirroredDatabase.json"
                    payload     = $base64Payload
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

# Function to create copy job (data pipeline) from Azure SQL to Lakehouse
function New-FabricCopyJob {
    param (
        [string]$WorkspaceId,
        [string]$Name,
        [string]$SourceServer,
        [string]$SourceDatabase,
        [string]$SourceTable,
        [string]$DestinationLakehouse,
        [string]$DestinationTable,
        [string]$ConnectionString,
        [string]$AccessToken
    )

    Write-Host "Creating Copy Job (Data Pipeline): $Name"

    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }

    # Create a data pipeline with copy activity
    # The pipeline definition includes source (Azure SQL) and sink (Lakehouse)
    $pipelineDefinition = @{
        name = $Name
        properties = @{
            activities = @(
                @{
                    name = "CopyFromSQLToLakehouse"
                    type = "Copy"
                    inputs = @(
                        @{
                            referenceName = "AzureSqlSource"
                            type = "DatasetReference"
                        }
                    )
                    outputs = @(
                        @{
                            referenceName = "LakehouseDestination"
                            type = "DatasetReference"
                        }
                    )
                    typeProperties = @{
                        source = @{
                            type = "AzureSqlSource"
                            sqlReaderQuery = "SELECT * FROM [$SourceTable]"
                        }
                        sink = @{
                            type = "LakehouseTableSink"
                            tableName = $DestinationTable
                        }
                        enableStaging = $false
                    }
                }
            )
            parameters = @{}
        }
        datasets = @{
            AzureSqlSource = @{
                type = "AzureSqlTable"
                linkedServiceName = @{
                    referenceName = "AzureSqlDatabase"
                    type = "LinkedServiceReference"
                }
                typeProperties = @{
                    tableName = $SourceTable
                }
            }
            LakehouseDestination = @{
                type = "LakehouseTable"
                typeProperties = @{
                    lakehouse = $DestinationLakehouse
                    table = $DestinationTable
                }
            }
        }
        linkedServices = @{
            AzureSqlDatabase = @{
                type = "AzureSqlDatabase"
                typeProperties = @{
                    connectionString = $ConnectionString
                }
            }
        }
    } | ConvertTo-Json -Depth 20
    
    # Encode to base64 as required by InlineBase64 payload type
    $base64Payload = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($pipelineDefinition))

    $body = @{
        displayName = $Name
        type        = "DataPipeline"
        definition  = @{
            parts = @(
                @{
                    path        = "pipeline-content.json"
                    payload     = $base64Payload
                    payloadType = "InlineBase64"
                }
            )
        }
    }

    $uri = "$fabricApiBaseUrl/workspaces/$WorkspaceId/items"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)
        Write-Host "Copy Job (Data Pipeline) created successfully. ID: $($response.id)"
        Write-Host "Pipeline: Copy data from $SourceServer.$SourceDatabase.$SourceTable to Lakehouse $DestinationLakehouse.$DestinationTable"
        return $response
    }
    catch {
        Write-Warning "Failed to create Copy Job: $_"
        Write-Warning "Ensure the source SQL server is accessible and destination lakehouse exists."
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

    # Get Graph token once for reuse if needed
    $graphToken = $null
    if ($AdminUserEmail) {
        try {
            $graphToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token
        }
        catch {
            Write-Warning "Failed to get Graph API token. Admin user will not be added."
        }
    }

    # Create workspace
    $workspace = New-FabricWorkspace -Name $WorkspaceName -Description $WorkspaceDescription -AccessToken $accessToken
    $workspaceId = $workspace.id

    # Add admin user if specified
    if ($AdminUserEmail -and $graphToken) {
        Add-WorkspaceAdmin -WorkspaceId $workspaceId -UserEmail $AdminUserEmail -AccessToken $accessToken -GraphToken $graphToken
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

    # Create copy job if specified
    if ($CopyJobName -and $CopyJobSourceServer -and $CopyJobSourceDatabase -and $CopyJobSourceTable -and $CopyJobDestinationLakehouse -and $CopyJobDestinationTable) {
        if (-not $SqlConnectionString) {
            Write-Warning "SQL Connection String not provided. Skipping Copy Job creation."
        }
        else {
            New-FabricCopyJob -WorkspaceId $workspaceId -Name $CopyJobName `
                -SourceServer $CopyJobSourceServer -SourceDatabase $CopyJobSourceDatabase `
                -SourceTable $CopyJobSourceTable -DestinationLakehouse $CopyJobDestinationLakehouse `
                -DestinationTable $CopyJobDestinationTable -ConnectionString $SqlConnectionString `
                -AccessToken $accessToken
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

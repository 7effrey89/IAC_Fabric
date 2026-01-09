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

.PARAMETER CopyJobSourceSchema
    Schema name for tables to copy (e.g., 'SalesLT') (required if creating copy job)

.PARAMETER CopyJobSourceTables
    Array of table names to copy from Azure SQL (required if creating copy job)

.PARAMETER CopyJobDestinationLakehouse
    Destination lakehouse name for the copy job (required if creating copy job)

.PARAMETER CopyJobIncrementalColumn
    Column name for incremental load (e.g., 'ModifiedDate') (optional)

.PARAMETER CopyJobServicePrincipalTenant
    Service principal tenant ID for authentication (required if creating copy job)

.PARAMETER CopyJobServicePrincipalClientId
    Service principal client ID for authentication (required if creating copy job)

.PARAMETER CopyJobServicePrincipalSecret
    Service principal secret for authentication (required if creating copy job)

.PARAMETER CopyJobScheduleIntervalHours
    Schedule interval in hours for copy job execution (default: 24)

.EXAMPLE
    ./Deploy-FabricAssets.ps1 -TenantId "xxx" -WorkspaceName "MyWorkspace" -LakehouseName "MyLakehouse"

.EXAMPLE
    ./Deploy-FabricAssets.ps1 -TenantId "xxx" -WorkspaceName "MyWorkspace" -LakehouseName "Bronze" -CopyJobName "SalesLTCopyJob" -CopyJobSourceServer "customer001fm.database.windows.net" -CopyJobSourceDatabase "customer001_adventureworks" -CopyJobSourceSchema "SalesLT" -CopyJobSourceTables @("Address","Customer","CustomerAddress") -CopyJobDestinationLakehouse "Bronze" -CopyJobIncrementalColumn "ModifiedDate" -CopyJobServicePrincipalTenant "xxx" -CopyJobServicePrincipalClientId "xxx" -CopyJobServicePrincipalSecret "xxx" -CopyJobScheduleIntervalHours 24
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
    [string]$CopyJobSourceSchema = "",

    [Parameter(Mandatory = $false)]
    [string[]]$CopyJobSourceTables = @(),

    [Parameter(Mandatory = $false)]
    [string]$CopyJobDestinationLakehouse = "",

    [Parameter(Mandatory = $false)]
    [string]$CopyJobIncrementalColumn = "",

    [Parameter(Mandatory = $false)]
    [string]$CopyJobServicePrincipalTenant = "",

    [Parameter(Mandatory = $false)]
    [string]$CopyJobServicePrincipalClientId = "",

    [Parameter(Mandatory = $false)]
    [string]$CopyJobServicePrincipalSecret = "",

    [Parameter(Mandatory = $false)]
    [int]$CopyJobScheduleIntervalHours = 24
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
        [string]$SourceSchema,
        [string[]]$SourceTables,
        [string]$DestinationLakehouse,
        [string]$IncrementalColumn,
        [string]$ServicePrincipalTenant,
        [string]$ServicePrincipalClientId,
        [string]$ServicePrincipalSecret,
        [int]$ScheduleIntervalHours,
        [string]$AccessToken
    )

    Write-Host "Creating Copy Job (Data Pipeline): $Name"
    Write-Host "  Source: $SourceServer.$SourceDatabase.$SourceSchema"
    Write-Host "  Tables: $($SourceTables -join ', ')"
    Write-Host "  Destination: Lakehouse '$DestinationLakehouse'"
    if ($IncrementalColumn) {
        Write-Host "  Incremental Load: Using column '$IncrementalColumn'"
    }
    Write-Host "  Schedule: Every $ScheduleIntervalHours hours"

    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }

    # Build connection string with service principal authentication
    $connectionString = "Data Source=$SourceServer;Initial Catalog=$SourceDatabase;Authentication=Active Directory Service Principal;User Id=$ServicePrincipalClientId@$ServicePrincipalTenant;Password=$ServicePrincipalSecret;Encrypt=True;"

    # Create activities for each table
    $activities = @()
    $datasets = @{}
    
    foreach ($table in $SourceTables) {
        $fullTableName = "$SourceSchema.$table"
        $sanitizedName = $table -replace '[^a-zA-Z0-9]', '_'
        
        # Create copy activity for this table
        $copyActivity = @{
            name = "Copy_$sanitizedName"
            type = "Copy"
            dependsOn = @()
            policy = @{
                timeout = "0.12:00:00"
                retry = 3
                retryIntervalInSeconds = 30
            }
            userProperties = @()
            typeProperties = @{
                source = @{
                    type = "AzureSqlSource"
                    queryTimeout = "02:00:00"
                    partitionOption = "None"
                }
                sink = @{
                    type = "LakehouseTableSink"
                    tableActionOption = "Append"
                    writeBehavior = "Insert"
                }
                enableStaging = $false
                translator = @{
                    type = "TabularTranslator"
                    typeConversion = $true
                    typeConversionSettings = @{
                        allowDataTruncation = $true
                        treatBooleanAsNumber = $false
                    }
                }
            }
            inputs = @(
                @{
                    referenceName = "AzureSqlTable_$sanitizedName"
                    type = "DatasetReference"
                }
            )
            outputs = @(
                @{
                    referenceName = "LakehouseTable_$sanitizedName"
                    type = "DatasetReference"
                }
            )
        }
        
        # Add incremental load if specified
        if ($IncrementalColumn) {
            $copyActivity.typeProperties.source.sqlReaderQuery = "SELECT * FROM [$fullTableName] WHERE [$IncrementalColumn] > '@{pipeline().parameters.windowStart}' AND [$IncrementalColumn] <= '@{pipeline().parameters.windowEnd}'"
        }
        else {
            $copyActivity.typeProperties.source.sqlReaderQuery = "SELECT * FROM [$fullTableName]"
        }
        
        $activities += $copyActivity
        
        # Create source dataset
        $datasets["AzureSqlTable_$sanitizedName"] = @{
            name = "AzureSqlTable_$sanitizedName"
            properties = @{
                linkedServiceName = @{
                    referenceName = "AzureSqlDatabase"
                    type = "LinkedServiceReference"
                }
                annotations = @()
                type = "AzureSqlTable"
                schema = @()
                typeProperties = @{
                    schema = $SourceSchema
                    table = $table
                }
            }
        }
        
        # Create destination dataset
        $datasets["LakehouseTable_$sanitizedName"] = @{
            name = "LakehouseTable_$sanitizedName"
            properties = @{
                linkedServiceName = @{
                    referenceName = "Lakehouse_$DestinationLakehouse"
                    type = "LinkedServiceReference"
                }
                annotations = @()
                type = "LakehouseTable"
                schema = @()
                typeProperties = @{
                    table = $table
                }
            }
        }
    }

    # Pipeline parameters for incremental load
    $pipelineParameters = @{}
    if ($IncrementalColumn) {
        $pipelineParameters = @{
            windowStart = @{
                type = "String"
                defaultValue = "1900-01-01T00:00:00Z"
            }
            windowEnd = @{
                type = "String"
                defaultValue = "@{utcnow()}"
            }
        }
    }

    # Create the pipeline definition
    $pipelineDefinition = @{
        name = $Name
        properties = @{
            activities = $activities
            parameters = $pipelineParameters
            annotations = @()
            lastPublishTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
    }

    # Create linked services
    $linkedServices = @{
        AzureSqlDatabase = @{
            name = "AzureSqlDatabase"
            properties = @{
                annotations = @()
                type = "AzureSqlDatabase"
                typeProperties = @{
                    connectionString = $connectionString
                }
            }
        }
        "Lakehouse_$DestinationLakehouse" = @{
            name = "Lakehouse_$DestinationLakehouse"
            properties = @{
                annotations = @()
                type = "Lakehouse"
                typeProperties = @{
                    workspaceId = $WorkspaceId
                    artifactId = $DestinationLakehouse
                }
            }
        }
    }

    # Create the complete package
    $packageDefinition = @{
        pipeline = $pipelineDefinition
        datasets = $datasets.Values
        linkedServices = $linkedServices.Values
    }

    # Add trigger for scheduling
    if ($ScheduleIntervalHours -gt 0) {
        $trigger = @{
            name = "${Name}_Trigger"
            properties = @{
                annotations = @()
                runtimeState = "Started"
                pipelines = @(
                    @{
                        pipelineReference = @{
                            referenceName = $Name
                            type = "PipelineReference"
                        }
                        parameters = @{}
                    }
                )
                type = "ScheduleTrigger"
                typeProperties = @{
                    recurrence = @{
                        frequency = "Hour"
                        interval = $ScheduleIntervalHours
                        startTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                        timeZone = "UTC"
                    }
                }
            }
        }
        $packageDefinition.trigger = $trigger
    }

    $definitionJson = $packageDefinition | ConvertTo-Json -Depth 20
    
    # Encode to base64 as required by InlineBase64 payload type
    $base64Payload = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($definitionJson))

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
        Write-Host "✓ Copy Job (Data Pipeline) created successfully. ID: $($response.id)"
        Write-Host "  Pipeline will copy $($SourceTables.Count) table(s) from $SourceServer.$SourceDatabase"
        Write-Host "  to Lakehouse '$DestinationLakehouse' every $ScheduleIntervalHours hours"
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
    if ($CopyJobName -and $CopyJobSourceServer -and $CopyJobSourceDatabase -and $CopyJobSourceSchema -and $CopyJobSourceTables.Count -gt 0 -and $CopyJobDestinationLakehouse) {
        if (-not $CopyJobServicePrincipalTenant -or -not $CopyJobServicePrincipalClientId -or -not $CopyJobServicePrincipalSecret) {
            Write-Warning "Service Principal credentials not provided. Skipping Copy Job creation."
            Write-Warning "Required: CopyJobServicePrincipalTenant, CopyJobServicePrincipalClientId, CopyJobServicePrincipalSecret"
        }
        else {
            New-FabricCopyJob -WorkspaceId $workspaceId -Name $CopyJobName `
                -SourceServer $CopyJobSourceServer -SourceDatabase $CopyJobSourceDatabase `
                -SourceSchema $CopyJobSourceSchema -SourceTables $CopyJobSourceTables `
                -DestinationLakehouse $CopyJobDestinationLakehouse `
                -IncrementalColumn $CopyJobIncrementalColumn `
                -ServicePrincipalTenant $CopyJobServicePrincipalTenant `
                -ServicePrincipalClientId $CopyJobServicePrincipalClientId `
                -ServicePrincipalSecret $CopyJobServicePrincipalSecret `
                -ScheduleIntervalHours $CopyJobScheduleIntervalHours `
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

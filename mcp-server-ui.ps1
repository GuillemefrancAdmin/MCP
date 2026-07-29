# MCP Server Setup UI - Interactive PowerShell Menu
# Simplifies Data API Builder MCP setup and management

$ErrorActionPreference = "SilentlyContinue"

# Get script directory (works regardless of current working directory)
$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $script:ScriptDir) {
    $script:ScriptDir = Get-Location
}

# Configuration file for saving user preferences (absolute path)
$script:ConfigFile = Join-Path $script:ScriptDir "mcp-config.json"
$script:DABConfigFile = Join-Path $script:ScriptDir "dab-config.json"

$script:SessionConfig = @{
    Server     = ""
    Database   = ""
    Username   = ""
    AuthMethod = "1"
    LastUser   = ""
}

function Load-SessionConfig {
    if (Test-Path $script:ConfigFile) {
        try {
            $saved = Get-Content $script:ConfigFile | ConvertFrom-Json
            $script:SessionConfig = @{
                Server     = $saved.Server
                Database   = $saved.Database
                Username   = $saved.Username
                AuthMethod = $saved.AuthMethod
                LastUser   = $saved.LastUser
            }
            return $true
        }
        catch {
            return $false
        }
    }
    return $false
}

function Save-SessionConfig {
    try {
        $script:SessionConfig | ConvertTo-Json | Set-Content -Path $script:ConfigFile -Force
        return $true
    }
    catch {
        return $false
    }
}

function Get-CurrentUser {
    return [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

function Show-Banner {
    Clear-Host
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "     Azure Data API Builder - MCP Server Setup & Manager        " -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    $currentUser = Get-CurrentUser
    Write-Host "Current User: $currentUser" -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-MainMenu {
    Show-Banner
    Write-Host "Main Menu" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "1. Setup MCP Server (First Time Setup)" -ForegroundColor White
    Write-Host "2. Start MCP Server" -ForegroundColor White
    Write-Host "3. Check MCP Server Status" -ForegroundColor Magenta
    Write-Host "4. Test Connection" -ForegroundColor White
    Write-Host "5. View Configuration" -ForegroundColor White
    Write-Host "6. Update Database Credentials" -ForegroundColor White
    Write-Host "7. Validate Table Schema" -ForegroundColor Cyan
    Write-Host "8. Switch Windows User" -ForegroundColor Yellow
    Write-Host "9. Exit" -ForegroundColor White
    Write-Host ""
}

function Check-Prerequisites {
    Write-Host "" -ForegroundColor Cyan
    Write-Host "[*] Checking Prerequisites..." -ForegroundColor Cyan

    # Check .NET
    $dotnet = dotnet --version 2>$null
    if ($dotnet) {
        Write-Host "[OK] .NET installed: $dotnet" -ForegroundColor Green
    }
    else {
        Write-Host "[ERROR] .NET 8 or later required. Download from: https://dotnet.microsoft.com/download" -ForegroundColor Red
        return $false
    }

    # Check DAB
    $dab = dab --version 2>$null
    if ($dab) {
        Write-Host "[OK] DAB installed: $dab" -ForegroundColor Green
    }
    else {
        Write-Host "[WARN] DAB not found. Installing..." -ForegroundColor Yellow
        dotnet tool install --global Microsoft.DataApiBuilder
        $dab = dab --version
        Write-Host "[OK] DAB installed: $dab" -ForegroundColor Green
    }

    return $true
}

function Get-AuthMethod {
    Show-Banner
    Write-Host "Authentication Method" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "1. Windows Authentication (AD)" -ForegroundColor White
    Write-Host "2. SQL Server Authentication (Username/Password)" -ForegroundColor White
    Write-Host ""
    $choice = Read-Host "Select option (1-2)"

    return $choice
}

function Get-ConnectionString {
    Show-Banner
    Write-Host "Database Connection Setup" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray

    # Get server name
    if ($script:SessionConfig.Server) {
        Write-Host "Saved Server: $($script:SessionConfig.Server)" -ForegroundColor Gray
        $serverPrompt = "SQL Server name (Enter to use saved: $($script:SessionConfig.Server))"
        $server = Read-Host $serverPrompt
        if ([string]::IsNullOrWhiteSpace($server)) {
            $server = $script:SessionConfig.Server
        }
    }
    else {
        $server = Read-Host "SQL Server name (e.g., db-dev.uqac.ca)"
    }

    # Get database name
    if ($script:SessionConfig.Database) {
        Write-Host "Saved Database: $($script:SessionConfig.Database)" -ForegroundColor Gray
        $dbPrompt = "Database name (Enter to use saved: $($script:SessionConfig.Database))"
        $database = Read-Host $dbPrompt
        if ([string]::IsNullOrWhiteSpace($database)) {
            $database = $script:SessionConfig.Database
        }
    }
    else {
        $database = Read-Host "Database name"
    }

    # Show saved auth method preference
    if ($script:SessionConfig.AuthMethod) {
        $authDefault = if ($script:SessionConfig.AuthMethod -eq "1") { "Windows Auth" } else { "SQL Auth" }
        Write-Host ""
        Write-Host "Saved Authentication: $authDefault" -ForegroundColor Gray
        $authPrompt = "Change authentication? Enter for saved, 1=Windows, 2=SQL"
        $authChoice = Read-Host $authPrompt
        if ([string]::IsNullOrWhiteSpace($authChoice)) {
            $authMethod = $script:SessionConfig.AuthMethod
        }
        else {
            $authMethod = $authChoice
        }
    }
    else {
        $authMethod = Get-AuthMethod
    }

    if ($authMethod -eq "1") {
        $connectionString = "Server=$server;Database=$database;Integrated Security=true;"
        Write-Host ""
        Write-Host "[OK] Using Windows Authentication" -ForegroundColor Green
        $username = ""
    }
    else {
        # Get username
        if ($script:SessionConfig.Username) {
            Write-Host "Saved Username: $($script:SessionConfig.Username)" -ForegroundColor Gray
            $userPrompt = "Username (Enter to use saved: $($script:SessionConfig.Username))"
            $username = Read-Host $userPrompt
            if ([string]::IsNullOrWhiteSpace($username)) {
                $username = $script:SessionConfig.Username
            }
        }
        else {
            $username = Read-Host "SQL Username"
        }

        # Always ask for password (security)
        $password = Read-Host "SQL Password" -AsSecureString
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($password))
        $connectionString = "Server=$server;Database=$database;User Id=$username;Password=$plainPassword;"
        Write-Host ""
        Write-Host "[OK] Using SQL Server Authentication" -ForegroundColor Green
    }

    # Save preferences
    $script:SessionConfig.Server = $server
    $script:SessionConfig.Database = $database
    $script:SessionConfig.Username = $username
    $script:SessionConfig.AuthMethod = $authMethod
    Save-SessionConfig | Out-Null

    return @{
        Server           = $server
        Database         = $database
        ConnectionString = $connectionString
        AuthMethod       = $authMethod
    }
}

function Test-DABConfigValid {
    param([string]$ConfigPath)

    if (-not (Test-Path $ConfigPath)) {
        return $false
    }

    try {
        Push-Location $script:ScriptDir
        $output = dab describe --config (Split-Path -Leaf $ConfigPath) 2>&1
        Pop-Location
        return $LASTEXITCODE -eq 0
    } catch {
        Pop-Location
        return $false
    }
}

function Initialize-DABConfig {
    param(
        [string]$ConfigPath,
        [hashtable]$ConnectionInfo
    )

    Write-Host ""
    Write-Host "[*] Initializing DAB Configuration..." -ForegroundColor Cyan

    # Check if config exists and is valid
    if (Test-Path $ConfigPath) {
        if (Test-DABConfigValid -ConfigPath $ConfigPath) {
            Write-Host "[OK] Config file is valid. Skipping initialization." -ForegroundColor Green
            return $true
        } else {
            Write-Host "[WARN] Config file is broken. Recreating..." -ForegroundColor Yellow
            Remove-Item $ConfigPath -Force
        }
    }

    try {
        dab init --database-type mssql `
            --connection-string $ConnectionInfo.ConnectionString `
            --config $ConfigPath `
            --host-mode development

        Write-Host "[OK] Configuration file created: $ConfigPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[ERROR] Failed to initialize config: $_" -ForegroundColor Red
        return $false
    }
}

function Discover-Tables {
    param(
        [hashtable]$ConnectionInfo
    )

    Write-Host ""
    Write-Host "[*] Discovering database tables..." -ForegroundColor Cyan

    $query = "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME"

    try {
        Write-Host "DEBUG: Server: $($ConnectionInfo.Server)" -ForegroundColor Gray
        Write-Host "DEBUG: Database: $($ConnectionInfo.Database)" -ForegroundColor Gray

        $output = & sqlcmd -S $ConnectionInfo.Server -d $ConnectionInfo.Database -E -Q $query
        Write-Host "DEBUG: Exit code: $LASTEXITCODE" -ForegroundColor Gray
        Write-Host "DEBUG: Output lines: $($output.Count)" -ForegroundColor Gray

        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "DEBUG: Full output:" -ForegroundColor Red
            $output | ForEach-Object { Write-Host "  $_" }
            throw "sqlcmd failed with exit code $LASTEXITCODE"
        }

        $lines = $output | Where-Object { $_ -and $_ -notmatch "^-+$" }
        $tables = @()
        $skipHeader = $true

        foreach ($line in $lines) {
            # Skip header line (contains TABLE_SCHEMA and TABLE_NAME)
            if ($skipHeader -and $line -like "*TABLE_SCHEMA*") {
                $skipHeader = $false
                continue
            }

            # Skip empty lines
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }

            # Parse line: schema name is first word, table name is last word
            $parts = $line.Trim().Split([char[]]@(' '), [System.StringSplitOptions]::RemoveEmptyEntries)
            if ($parts.Count -ge 2) {
                $schema = $parts[0]
                $tableName = $parts[-1]  # Get last element
                $tables += @{ Schema = $schema; Name = $tableName }
            }
        }

        Write-Host "[OK] Found $($tables.Count) tables" -ForegroundColor Green
        return $tables
    }
    catch {
        Write-Host "[ERROR] Failed to discover tables: $_" -ForegroundColor Red
        return $null
    }
}

function Add-TablesToConfig {
    param(
        [string]$ConfigPath,
        [array]$Tables
    )

    Write-Host ""
    Write-Host "[*] Adding tables to configuration..." -ForegroundColor Cyan

    $addedCount = 0
    $skippedCount = 0
    $startTime = Get-Date
    $totalTables = $Tables.Count

    foreach ($table in $Tables) {
        try {
            dab add $table.Name `
                --source "$($table.Schema).$($table.Name)" `
                --source.type table `
                --permissions "authenticated:*" `
                --config $ConfigPath | Out-Null

            $addedCount++

            $percentComplete = [math]::Round(($addedCount / $totalTables) * 100)
            $elapsedTime = (Get-Date) - $startTime
            $avgTimePerTable = $elapsedTime.TotalSeconds / $addedCount
            $remainingTables = $totalTables - $addedCount
            $estimatedRemaining = [math]::Round($avgTimePerTable * $remainingTables)

            $barLength = 30
            $filledLength = [math]::Round($percentComplete / 100 * $barLength)
            $progressBar = "=" * $filledLength + " " * ($barLength - $filledLength)

            # Overwrite same line (no scrolling)
            $progressLine = "  [$progressBar] $percentComplete% | $addedCount/$totalTables | ETA: ${estimatedRemaining}s"
            Write-Host -NoNewline "`r$progressLine" -ForegroundColor Cyan

            # Pad line to clear any previous longer text
            $padding = " " * (80 - $progressLine.Length)
            Write-Host -NoNewline $padding

        }
        catch {
            $skippedCount++
        }
    }

    Write-Host ""
    Write-Host ""
    Write-Host "[OK] Configuration Complete!" -ForegroundColor Green
    Write-Host "    Tables added:  $addedCount" -ForegroundColor Green
    Write-Host "    Tables skipped: $skippedCount" -ForegroundColor Yellow

    $totalTime = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
    Write-Host "    Total time: ${totalTime}s" -ForegroundColor Gray
}

function Setup-MCP {
    Show-Banner
    Write-Host "Setting Up MCP Server" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray

    if (-not (Check-Prerequisites)) {
        Read-Host "Press Enter to continue"
        return $false
    }

    # Check if valid config already exists
    Write-Host ""
    Write-Host "[*] Checking for existing configuration..." -ForegroundColor Cyan

    if (Test-Path $script:DABConfigFile) {
        Write-Host "[OK] Configuration file found: $script:DABConfigFile" -ForegroundColor Green

        # Validate the existing config
        Write-Host "[*] Validating configuration..." -ForegroundColor Cyan
        $validation = dab validate --config $script:DABConfigFile 2>&1
        $validationSuccess = $validation | Select-String -Pattern "config satisfies the schema requirements" -Quiet

        if ($validationSuccess) {
            Write-Host "[OK] Configuration is VALID" -ForegroundColor Green
            Write-Host ""

            # Show menu for user choice
            Write-Host "Configuration Options:" -ForegroundColor Cyan
            Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray
            Write-Host "1. Keep existing configuration (Skip setup)" -ForegroundColor White
            Write-Host "2. Regenerate configuration from database" -ForegroundColor White
            Write-Host "3. Cancel" -ForegroundColor White
            Write-Host ""

            $configChoice = Read-Host "Select option (1-3)"

            switch ($configChoice) {
                "1" {
                    # Keep existing config
                    Write-Host ""
                    Write-Host "[*] Verifying Claude Code MCP configuration..." -ForegroundColor Cyan
                    $mcpDir = ".\.claude"
                    if (-not (Test-Path "$mcpDir\mcp.json")) {
                        if (-not (Test-Path $mcpDir)) {
                            New-Item -ItemType Directory -Path $mcpDir | Out-Null
                        }

                        $mcpConfig = @{
                            mcpServers = @{
                                sigaremcp = @{
                                    command = "dab"
                                    args    = @("start", "--mcp-stdio")
                                    env     = @{
                                        DAB_CONFIG = "$script:DABConfigFile"
                                    }
                                }
                            }
                        } | ConvertTo-Json

                        $mcpConfig | Set-Content -Path "$mcpDir\mcp.json"
                        Write-Host "[OK] Created: $mcpDir\mcp.json" -ForegroundColor Green
                    } else {
                        Write-Host "[OK] MCP configuration already exists" -ForegroundColor Green
                    }

                    Write-Host ""
                    Write-Host "[+] Setup already complete. Ready to start the server!" -ForegroundColor Green
                    Read-Host "Press Enter to continue"
                    return $true
                }
                "2" {
                    # Regenerate config - continue with setup process
                    Write-Host ""
                    Write-Host "[*] Starting configuration regeneration..." -ForegroundColor Yellow
                    Write-Host "This may take a few minutes..." -ForegroundColor Yellow
                    # Fall through to regenerate
                }
                "3" {
                    Write-Host "[CANCEL] Setup cancelled." -ForegroundColor Yellow
                    Read-Host "Press Enter to continue"
                    return $false
                }
                default {
                    Write-Host "Invalid option." -ForegroundColor Red
                    Read-Host "Press Enter to continue"
                    return $false
                }
            }
        } else {
            Write-Host "[ERROR] Configuration validation failed" -ForegroundColor Red
            $confirm = Read-Host "Recreate configuration? (Y/N)"
            if ($confirm -ne "Y") {
                Read-Host "Press Enter to continue"
                return $false
            }
        }
    }

    $connectionInfo = Get-ConnectionString
    $configPath = "$script:DABConfigFile"

    if (-not (Initialize-DABConfig -ConfigPath $configPath -ConnectionInfo $connectionInfo)) {
        Read-Host "Press Enter to continue"
        return $false
    }

    $tables = Discover-Tables -ConnectionInfo $connectionInfo
    if ($null -eq $tables) {
        Read-Host "Press Enter to continue"
        return $false
    }

    $confirm = Read-Host "Add all $($tables.Count) tables to configuration? (Y/N)"
    if ($confirm -ne "Y") {
        Write-Host "[SKIP] Table configuration skipped." -ForegroundColor Yellow
    }
    else {
        Add-TablesToConfig -ConfigPath $configPath -Tables $tables
    }

    # Create .claude/mcp.json
    Write-Host ""
    Write-Host "[*] Creating Claude Code MCP configuration..." -ForegroundColor Cyan
    $mcpDir = ".\.claude"
    if (-not (Test-Path $mcpDir)) {
        New-Item -ItemType Directory -Path $mcpDir | Out-Null
    }

    $mcpConfig = @{
        mcpServers = @{
            sigaremcp = @{
                command = "dab"
                args    = @("start", "--mcp-stdio")
                env     = @{
                    DAB_CONFIG = "$script:DABConfigFile"
                }
            }
        }
    } | ConvertTo-Json

    $mcpConfig | Set-Content -Path "$mcpDir\mcp.json"
    Write-Host "[OK] Created: $mcpDir\mcp.json" -ForegroundColor Green

    Write-Host ""
    Write-Host "Setup Complete!" -ForegroundColor Green
    Write-Host "You can now start the MCP server from the main menu." -ForegroundColor Green
    Read-Host "Press Enter to continue"

    return $true
}

function Start-MCPServer {
    Show-Banner
    Write-Host "Starting MCP Server" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray

    if (-not (Test-Path ".\dab-config.json")) {
        Write-Host "[ERROR] Configuration file not found. Run Setup first." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host ""
    Write-Host "[*] Starting DAB in MCP mode..." -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Yellow
    Write-Host ""

    try {
        dab start --mcp-stdio
    }
    catch {
        Write-Host "[ERROR] Failed to start server: $_" -ForegroundColor Red
    }
}

function Check-MCPStatus {
    Show-Banner
    Write-Host "MCP Server Status" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""

    # Get current user
    $currentUser = Get-CurrentUser
    Write-Host "[USER]" -ForegroundColor Cyan
    Write-Host "  Logged in as: $currentUser" -ForegroundColor White
    Write-Host ""

    # Check if DAB process is running
    Write-Host "[PROCESS]" -ForegroundColor Cyan
    $dabProcess = Get-Process -Name dotnet -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*dab*" }

    if ($dabProcess) {
        Write-Host "  Status: RUNNING" -ForegroundColor Green
        Write-Host "  Process ID: $($dabProcess.Id)" -ForegroundColor White
        Write-Host "  Started: $($dabProcess.StartTime)" -ForegroundColor White
        Write-Host "  Memory: $([math]::Round($dabProcess.WorkingSet / 1MB, 2)) MB" -ForegroundColor White
    } else {
        Write-Host "  Status: NOT RUNNING" -ForegroundColor Yellow
    }
    Write-Host ""

    # Check configuration
    Write-Host "[CONFIGURATION]" -ForegroundColor Cyan
    if (Test-Path $script:DABConfigFile) {
        try {
            $config = Get-Content $script:DABConfigFile | ConvertFrom-Json
            Write-Host "  Config File: Found" -ForegroundColor Green
            Write-Host "  Database: $($config.'data-source'.database_name)" -ForegroundColor White
            Write-Host "  Server: $($config.'data-source'.server)" -ForegroundColor White
            Write-Host "  Entities: $($config.entities.PSObject.Properties.Count)" -ForegroundColor White

            # Check REST and MCP endpoints
            Write-Host "  REST Enabled: $($config.runtime.rest.enabled)" -ForegroundColor White
            Write-Host "  REST Path: $($config.runtime.rest.path)" -ForegroundColor White
            Write-Host "  MCP Enabled: $($config.runtime.mcp.enabled)" -ForegroundColor White
            Write-Host "  MCP Path: $($config.runtime.mcp.path)" -ForegroundColor White
        }
        catch {
            Write-Host "  Error reading config: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  Config File: NOT FOUND" -ForegroundColor Red
    }
    Write-Host ""

    # Check listening ports
    Write-Host "[NETWORK]" -ForegroundColor Cyan
    $ports = @(5000, 8080, 8081, 3000, 4000)
    $portOpen = $false

    foreach ($port in $ports) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $result = $tcp.BeginConnect("localhost", $port, $null, $null)
            $success = $result.AsyncWaitHandle.WaitOne(1000, $false)

            if ($success -and $tcp.Connected) {
                Write-Host "  Port ${port}: OPEN (Listening)" -ForegroundColor Green
                $portOpen = $true
                $tcp.Close()
            }
        } catch {
            # Port not open
        }
    }

    if (-not $portOpen) {
        Write-Host "  No listening ports detected" -ForegroundColor Yellow
        Write-Host "  (Server may be in MCP stdio mode)" -ForegroundColor Gray
    }
    Write-Host ""

    # Summary
    Write-Host "`[SUMMARY`]" -ForegroundColor Cyan
    if ($dabProcess) {
        Write-Host "  [+] Server is ACTIVE and ready to use" -ForegroundColor Green
    } else {
        Write-Host "  [-] Server is NOT running - use option 2 to start" -ForegroundColor Yellow
    }
    Write-Host ""

    Read-Host "Press Enter to continue"
}

function Test-MCPConnection {
    Show-Banner
    Write-Host "Testing Connection" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray

    if (-not (Test-Path $script:DABConfigFile)) {
        Write-Host "[ERROR] Configuration file not found. Run Setup first." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host ""
    Write-Host "[*] Testing database connection..." -ForegroundColor Cyan

    try {
        $output = dab describe --config "dab-config.json" 2>&1
        if ($output) {
            Write-Host "[OK] Connection successful!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Entities in configuration:" -ForegroundColor Cyan
            $output | Select-Object -First 20
            Write-Host "(showing first 20 entities)" -ForegroundColor Gray
        }
        else {
            Write-Host "[ERROR] No response from DAB." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "[ERROR] Connection test failed: $_" -ForegroundColor Red
    }

    Read-Host "Press Enter to continue"
}

function View-Configuration {
    Show-Banner
    Write-Host "Current Configuration" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray

    $configPath = ".\dab-config.json"
    $mcpConfigPath = ".\.claude\mcp.json"

    if (Test-Path $configPath) {
        Write-Host ""
        Write-Host "[DAB Configuration]" -ForegroundColor Cyan
        $config = Get-Content $configPath | ConvertFrom-Json
        Write-Host "Data Source Type: $($config.data_source.type)" -ForegroundColor White
        Write-Host "Database: $($config.data_source.database_name)" -ForegroundColor White
        Write-Host "Host: $($config.data_source.server)" -ForegroundColor White
        Write-Host "Entities: $($config.entities.PSObject.Properties.Count)" -ForegroundColor White
    }
    else {
        Write-Host "[WARN] DAB configuration not found" -ForegroundColor Yellow
    }

    if (Test-Path $mcpConfigPath) {
        Write-Host ""
        Write-Host "[Claude MCP Configuration]" -ForegroundColor Cyan
        Get-Content $mcpConfigPath | Write-Host
    }
    else {
        Write-Host ""
        Write-Host "[WARN] Claude MCP configuration not found" -ForegroundColor Yellow
    }

    Read-Host "Press Enter to continue"
}

function Switch-WindowsUser {
    Show-Banner
    Write-Host "Switch Windows User" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray

    $currentUser = Get-CurrentUser
    Write-Host ""
    Write-Host "Current Windows User: $currentUser" -ForegroundColor Yellow
    Write-Host ""

    if ($script:SessionConfig.LastUser) {
        Write-Host "Last used user: $($script:SessionConfig.LastUser)" -ForegroundColor Gray
        $userPrompt = "Username (Enter to use last: $($script:SessionConfig.LastUser))"
        $newUser = Read-Host $userPrompt

        if ([string]::IsNullOrWhiteSpace($newUser)) {
            $newUser = $script:SessionConfig.LastUser
        }
    } else {
        Write-Host "Enter the username you want to switch to." -ForegroundColor White
        Write-Host "Format: DOMAIN\USERNAME (e.g., UQAC\fguille2)" -ForegroundColor Gray
        Write-Host ""
        $newUser = Read-Host "Username"
    }

    if ([string]::IsNullOrWhiteSpace($newUser)) {
        Write-Host "[SKIP] No username provided." -ForegroundColor Yellow
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host ""
    Write-Host "You will be prompted for the password." -ForegroundColor Cyan
    Write-Host ""

    try {
        # Save the user for next time
        $script:SessionConfig.LastUser = $newUser
        Save-SessionConfig | Out-Null

        # Run this script as the new user
        $scriptPath = $MyInvocation.ScriptName
        Write-Host "[*] Switching to user: $newUser" -ForegroundColor Cyan
        Write-Host "The script will restart with the new user..." -ForegroundColor Yellow

        Start-Process powershell -Credential (Get-Credential -UserName $newUser -Message "Enter password for $newUser") `
            -ArgumentList "-NoExit -File `"$scriptPath`""

        Write-Host "[OK] New process started as $newUser" -ForegroundColor Green
        Write-Host "You can close this window now." -ForegroundColor Yellow

        Start-Sleep -Seconds 2
        exit
    }
    catch {
        Write-Host "[ERROR] Failed to switch user: $_" -ForegroundColor Red
    }

    Read-Host "Press Enter to continue"
}

function Update-UserCredentials {
    Show-Banner
    Write-Host "Update User/Credentials" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray

    Write-Host ""
    Write-Host "Current Settings:" -ForegroundColor Cyan
    Write-Host "  Server: $($script:SessionConfig.Server)" -ForegroundColor White
    Write-Host "  Database: $($script:SessionConfig.Database)" -ForegroundColor White
    Write-Host "  Username: $($script:SessionConfig.Username)" -ForegroundColor White
    Write-Host "  Auth Method: $(if ($script:SessionConfig.AuthMethod -eq '1') { 'Windows Auth' } else { 'SQL Auth' })" -ForegroundColor White

    Write-Host ""
    Write-Host "Select what to change:" -ForegroundColor Green
    Write-Host "1. Server" -ForegroundColor White
    Write-Host "2. Database" -ForegroundColor White
    Write-Host "3. Authentication Method" -ForegroundColor White
    Write-Host "4. Username (SQL Auth only)" -ForegroundColor White
    Write-Host "5. Clear all settings" -ForegroundColor White
    Write-Host "6. Back to menu" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "Select option (1-6)"

    switch ($choice) {
        "1" {
            $newServer = Read-Host "New server name"
            if ($newServer) {
                $script:SessionConfig.Server = $newServer
                Write-Host "[OK] Server updated" -ForegroundColor Green
            }
        }
        "2" {
            $newDb = Read-Host "New database name"
            if ($newDb) {
                $script:SessionConfig.Database = $newDb
                Write-Host "[OK] Database updated" -ForegroundColor Green
            }
        }
        "3" {
            Write-Host ""
            Write-Host "1. Windows Authentication" -ForegroundColor White
            Write-Host "2. SQL Server Authentication" -ForegroundColor White
            Write-Host ""
            $authChoice = Read-Host "Select authentication (1-2)"
            if ($authChoice -eq "1" -or $authChoice -eq "2") {
                $script:SessionConfig.AuthMethod = $authChoice
                $authType = if ($authChoice -eq "1") { "Windows Auth" } else { "SQL Auth" }
                Write-Host "[OK] Authentication method changed to: $authType" -ForegroundColor Green
            }
        }
        "4" {
            $newUser = Read-Host "New username"
            if ($newUser) {
                $script:SessionConfig.Username = $newUser
                Write-Host "[OK] Username updated" -ForegroundColor Green
            }
        }
        "5" {
            $confirm = Read-Host "Clear all settings? (Y/N)"
            if ($confirm -eq "Y") {
                $script:SessionConfig.Server = ""
                $script:SessionConfig.Database = ""
                $script:SessionConfig.Username = ""
                $script:SessionConfig.AuthMethod = "1"
                Write-Host "[OK] All settings cleared" -ForegroundColor Green
            }
        }
        "6" {
            return
        }
    }

    Save-SessionConfig | Out-Null
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Validate-TableSchema {
    Show-Banner
    Write-Host "Validate Table Schema" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray

    if (-not $script:SessionConfig.Server -or -not $script:SessionConfig.Database) {
        Write-Host "[ERROR] Database credentials not configured. Run Setup first." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host ""
    Write-Host "[*] Validating schema for: $($script:SessionConfig.Database)" -ForegroundColor Cyan
    Write-Host ""

    $query = @"
SELECT
    t.TABLE_SCHEMA,
    t.TABLE_NAME,
    COUNT(c.COLUMN_NAME) as ColumnCount,
    STRING_AGG(c.COLUMN_NAME + ' (' + c.DATA_TYPE + ')', ', ') as Columns
FROM INFORMATION_SCHEMA.TABLES t
LEFT JOIN INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_NAME = c.TABLE_NAME AND t.TABLE_SCHEMA = c.TABLE_SCHEMA
WHERE t.TABLE_TYPE = 'BASE TABLE'
GROUP BY t.TABLE_SCHEMA, t.TABLE_NAME
ORDER BY t.TABLE_NAME
"@

    try {
        $output = sqlcmd -S $script:SessionConfig.Server -d $script:SessionConfig.Database -E -Q $query 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to validate schema" -ForegroundColor Red
            Read-Host "Press Enter to continue"
            return
        }

        $lines = $output | Where-Object { $_ -and $_ -notmatch "^-+$" }
        $tableCount = 0
        $issuesFound = 0

        Write-Host "Validation Results:" -ForegroundColor Green
        Write-Host ""

        foreach ($line in $lines) {
            if ($line -like "*TABLE_SCHEMA*") {
                continue
            }

            $parts = $line.Trim().Split([char[]]@('|'), [System.StringSplitOptions]::RemoveEmptyEntries)
            if ($parts.Count -ge 3) {
                $tableCount++
                $schema = $parts[0].Trim()
                $tableName = $parts[1].Trim()
                $columnCount = $parts[2].Trim()

                if ([string]::IsNullOrWhiteSpace($columnCount) -or $columnCount -eq "0") {
                    Write-Host "  WARNING: $schema.$tableName - NO COLUMNS (Issue)" -ForegroundColor Yellow
                    $issuesFound++
                } else {
                    Write-Host "  OK: $schema.$tableName - $columnCount columns" -ForegroundColor Green
                }

                if ($tableCount % 50 -eq 0) {
                    Write-Host "  ... validated $tableCount tables ..." -ForegroundColor Gray
                }
            }
        }

        Write-Host ""
        Write-Host "Summary:" -ForegroundColor Cyan
        Write-Host "  Total tables: $tableCount" -ForegroundColor White
        Write-Host "  Tables with issues: $issuesFound" -ForegroundColor $(if ($issuesFound -gt 0) { "Yellow" } else { "Green" })
        Write-Host ""

        if ($issuesFound -gt 0) {
            Write-Host "[!] WARNING: Found tables with potential issues" -ForegroundColor Yellow
            Write-Host "    These tables may not work properly with MCP" -ForegroundColor Yellow
        } else {
            Write-Host "[OK] All tables have valid schema" -ForegroundColor Green
        }

    } catch {
        Write-Host "[ERROR] Validation failed: $_" -ForegroundColor Red
    }

    Write-Host ""
    Read-Host "Press Enter to continue"
}

# Load saved configuration on startup
Load-SessionConfig | Out-Null

# Main Loop
while ($true) {
    Show-MainMenu
    $choice = Read-Host "Select option (1-9)"

    switch ($choice) {
        "1" { Setup-MCP }
        "2" { Start-MCPServer }
        "3" { Check-MCPStatus }
        "4" { Test-MCPConnection }
        "5" { View-Configuration }
        "6" { Update-UserCredentials }
        "7" { Validate-TableSchema }
        "8" { Switch-WindowsUser }
        "9" {
            Write-Host "Goodbye!" -ForegroundColor Cyan
            exit
        }
        default {
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
            Read-Host "Press Enter to continue"
        }
    }
}

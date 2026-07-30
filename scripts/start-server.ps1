#!/usr/bin/env pwsh
<#
.SYNOPSIS
Start the MCP SQL Server with AD/Windows Authentication support

.DESCRIPTION
Starts the SQL Server MCP server with environment variables from .env or command line.
Supports both SQL authentication and Active Directory (Windows) authentication.

.EXAMPLE
# SQL Authentication
./start-server.ps1 -SqlHost "localhost" -SqlUser "sa" -SqlPassword "password"

# Windows/AD Authentication (uses current user)
./start-server.ps1 -SqlHost "sql-server.company.com" -SqlAuth "windows"

# Windows/AD Authentication (use specific AD user)
./start-server.ps1 -SqlHost "sql-server.company.com" -SqlAuth "windows" -AdUser "DOMAIN\username"

# From .env file
./start-server.ps1 -EnvFile ".env"

.PARAMETER SqlHost
SQL Server hostname or IP address (required)

.PARAMETER SqlPort
SQL Server port (default: 1433)

.PARAMETER SqlUser
Database username (required for SQL auth, optional for Windows auth)

.PARAMETER SqlPassword
Database password (required for SQL auth, not used for Windows auth)

.PARAMETER SqlDatabase
Default database name

.PARAMETER SqlAuth
Authentication type: 'sql' or 'windows' (default: sql)

.PARAMETER AdUser
Active Directory user for Windows auth (optional, uses current user if not specified)
Format: DOMAIN\username or user@domain.com

.PARAMETER EnvFile
Path to .env file to load variables from (default: .env)
#>

param(
    [string]$SqlHost = "",
    [int]$SqlPort = 0,
    [string]$SqlUser = "",
    [string]$SqlPassword = "",
    [string]$SqlDatabase = "",
    [string]$SqlAuth = "",
    [string]$AdUser = "",
    [string]$EnvFile = ".env"
)

# Color output helper
function Write-Status {
    param([string]$Message, [string]$Status = "INFO")
    $colors = @{
        "INFO"    = "Cyan"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
    }
    Write-Host $Message -ForegroundColor $colors[$Status]
}

Write-Host ""
Write-Status "MCP SQL Server Startup" "INFO"
Write-Status "======================" "INFO"
Write-Host ""

# Import parameter helper
. "$PSScriptRoot\Get-ServerParameters.ps1"

# Get parameters (interactive if not provided)
$params = Get-ServerParameters -SqlHost $SqlHost -SqlPort $SqlPort -SqlUser $SqlUser `
    -SqlPassword $SqlPassword -SqlDatabase $SqlDatabase -SqlAuth $SqlAuth -AdUser $AdUser -EnvFile $EnvFile

# Apply returned parameters
$SqlHost = $params.SqlHost
$SqlPort = $params.SqlPort
$SqlUser = $params.SqlUser
$SqlPassword = $params.SqlPassword
$SqlDatabase = $params.SqlDatabase
$SqlAuth = $params.SqlAuth
$AdUser = $params.AdUser
$EnvFile = $params.EnvFile

# Validate required parameters
if (-not $SqlHost) {
    Write-Status "ERROR: SQLSERVER_HOST is required" "ERROR"
    Write-Host ""
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host "  SQL Auth:"
    Write-Host "    ./start-server.ps1 -SqlHost 'localhost' -SqlUser 'sa' -SqlPassword 'password'"
    Write-Host ""
    Write-Host "  Windows/AD Auth (current user):"
    Write-Host "    ./start-server.ps1 -SqlHost 'sql-server' -SqlAuth 'windows'"
    Write-Host ""
    Write-Host "  Windows/AD Auth (specific user):"
    Write-Host "    ./start-server.ps1 -SqlHost 'sql-server' -SqlAuth 'windows' -AdUser 'DOMAIN\username'"
    Write-Host ""
    exit 1
}

# Validate SQL Authentication
if ($SqlAuth -eq "sql") {
    if (-not $SqlUser -or -not $SqlPassword) {
        Write-Status "ERROR: SQL authentication requires SQLSERVER_USER and SQLSERVER_PASSWORD" "ERROR"
        exit 1
    }
}

# Validate and setup Windows/AD Authentication
if ($SqlAuth -eq "windows") {
    Write-Status "Setting up Windows/Active Directory authentication..." "INFO"

    # Get current user if no AD user specified
    if (-not $AdUser) {
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $AdUser = $currentUser.Name
        Write-Status "Using current user: $AdUser" "INFO"
    }

    # Validate AD user exists
    try {
        $adUserObj = [System.Security.Principal.NTAccount]::new($AdUser)
        $sid = $adUserObj.Translate([System.Security.Principal.SecurityIdentifier])
        Write-Status "AD user validated: $AdUser" "SUCCESS"
    }
    catch {
        Write-Status "ERROR: Could not validate AD user: $AdUser" "ERROR"
        Write-Status "Make sure the user exists and is in correct format (DOMAIN\username or user@domain.com)" "WARNING"
        exit 1
    }

    # For Windows auth, don't use username/password in environment variables
    $SqlUser = ""
    $SqlPassword = ""
}

# Set environment variables
Write-Status "Configuring connection..." "INFO"
$env:SQLSERVER_HOST = $SqlHost
$env:SQLSERVER_PORT = $SqlPort
$env:SQLSERVER_DATABASE = $SqlDatabase
$env:SQLSERVER_AUTH = $SqlAuth

if ($SqlAuth -eq "sql") {
    $env:SQLSERVER_USER = $SqlUser
    $env:SQLSERVER_PASSWORD = $SqlPassword
}

# Display configuration
Write-Host ""
Write-Status "Connection Configuration:" "INFO"
Write-Host "  Server: $SqlHost"
Write-Host "  Port: $SqlPort"
Write-Host "  Database: $(if ($SqlDatabase) { $SqlDatabase } else { '(default)' })"
Write-Host "  Authentication: $SqlAuth"

if ($SqlAuth -eq "sql") {
    Write-Host "  User: $SqlUser"
}
else {
    Write-Host "  User: $AdUser (Windows/AD)"
}

Write-Host ""

# Build TypeScript
Write-Status "Building TypeScript..." "INFO"
npm run build 2>&1 | ForEach-Object {
    if ($_ -match "error") {
        Write-Status $_ "ERROR"
    }
}

if ($LASTEXITCODE -ne 0) {
    Write-Status "Build failed" "ERROR"
    exit 1
}

Write-Status "Build successful" "SUCCESS"
Write-Host ""

# Start server
Write-Status "Starting MCP SQL Server..." "SUCCESS"
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

npm start

Write-Host ""
Write-Status "Server stopped" "WARNING"

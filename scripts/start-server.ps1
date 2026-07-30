#!/usr/bin/env pwsh
<#
.SYNOPSIS
Start the MCP SQL Server

.DESCRIPTION
Starts the SQL Server MCP server with environment variables from .env or command line

.EXAMPLE
./start-server.ps1
./start-server.ps1 -Host "localhost" -User "sa" -Password "password" -Database "master"
./start-server.ps1 -EnvFile ".env"

.PARAMETER Host
SQL Server hostname

.PARAMETER Port
SQL Server port (default: 1433)

.PARAMETER User
Database username (for SQL auth)

.PARAMETER Password
Database password (for SQL auth)

.PARAMETER Database
Database name

.PARAMETER Auth
Authentication type: 'sql' or 'windows' (default: sql)

.PARAMETER EnvFile
Path to .env file to load variables from
#>

param(
    [string]$SqlHost = $env:SQLSERVER_HOST,
    [int]$SqlPort = $(if ($env:SQLSERVER_PORT) { [int]$env:SQLSERVER_PORT } else { 1433 }),
    [string]$SqlUser = $env:SQLSERVER_USER,
    [string]$SqlPassword = $env:SQLSERVER_PASSWORD,
    [string]$SqlDatabase = $env:SQLSERVER_DATABASE,
    [string]$SqlAuth = $(if ($env:SQLSERVER_AUTH) { $env:SQLSERVER_AUTH } else { "sql" }),
    [string]$EnvFile = ".env"
)

# Load .env file if it exists
if (Test-Path $EnvFile) {
    Write-Host "Loading environment from $EnvFile..." -ForegroundColor Cyan
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
        $parts = $_ -split '=', 2
        if ($parts.Count -eq 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            if ($key -and $value) {
                [System.Environment]::SetEnvironmentVariable($key, $value)
            }
        }
    }
}

# Use environment variables if parameters not provided
if (-not $SqlHost) { $SqlHost = $env:SQLSERVER_HOST }
if (-not $SqlUser) { $SqlUser = $env:SQLSERVER_USER }
if (-not $SqlPassword) { $SqlPassword = $env:SQLSERVER_PASSWORD }
if (-not $SqlDatabase) { $SqlDatabase = $env:SQLSERVER_DATABASE }

# Validate required parameters
if (-not $SqlHost) {
    Write-Host "ERROR: SQLSERVER_HOST is required" -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage: ./start-server.ps1 -SqlHost 'your-server' -SqlUser 'sa' -SqlPassword 'password'" -ForegroundColor Yellow
    exit 1
}

if ($SqlAuth -eq "sql") {
    if (-not $SqlUser -or -not $SqlPassword) {
        Write-Host "ERROR: SQLSERVER_USER and SQLSERVER_PASSWORD required for SQL authentication" -ForegroundColor Red
        exit 1
    }
}

# Set environment variables
Write-Host "Configuring SQL Server connection..." -ForegroundColor Cyan
$env:SQLSERVER_HOST = $SqlHost
$env:SQLSERVER_PORT = $SqlPort
$env:SQLSERVER_DATABASE = $SqlDatabase
$env:SQLSERVER_AUTH = $SqlAuth
$env:SQLSERVER_USER = $SqlUser
$env:SQLSERVER_PASSWORD = $SqlPassword

# Display configuration
Write-Host ""
Write-Host "Server Configuration:" -ForegroundColor Green
Write-Host "   Host: $SqlHost"
Write-Host "   Port: $SqlPort"
Write-Host "   Database: $(if ($SqlDatabase) { $SqlDatabase } else { '(default)' })"
Write-Host "   Auth: $SqlAuth"
Write-Host "   User: $(if ($SqlUser) { $SqlUser } else { '(Windows)' })"
Write-Host ""

# Build and start
Write-Host "Building TypeScript..." -ForegroundColor Cyan
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Starting MCP SQL Server..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

npm start

Write-Host ""
Write-Host "Server stopped" -ForegroundColor Yellow

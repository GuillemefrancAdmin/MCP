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
    [string]$Host = $env:SQLSERVER_HOST,
    [int]$Port = if ($env:SQLSERVER_PORT) { [int]$env:SQLSERVER_PORT } else { 1433 },
    [string]$User = $env:SQLSERVER_USER,
    [string]$Password = $env:SQLSERVER_PASSWORD,
    [string]$Database = $env:SQLSERVER_DATABASE,
    [string]$Auth = $env:SQLSERVER_AUTH ?? "sql",
    [string]$EnvFile = ".env"
)

# Load .env file if it exists
if (Test-Path $EnvFile) {
    Write-Host "📋 Loading environment from $EnvFile..." -ForegroundColor Cyan
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
        $key, $value = $_ -split '=', 2
        $key = $key.Trim()
        $value = $value.Trim()
        if ($key -and $value) {
            [System.Environment]::SetEnvironmentVariable($key, $value)
        }
    }
}

# Use environment variables if parameters not provided
if (-not $Host) { $Host = $env:SQLSERVER_HOST }
if (-not $User) { $User = $env:SQLSERVER_USER }
if (-not $Password) { $Password = $env:SQLSERVER_PASSWORD }
if (-not $Database) { $Database = $env:SQLSERVER_DATABASE }

# Validate required parameters
if (-not $Host) {
    Write-Host "❌ Error: SQLSERVER_HOST is required" -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage: ./start-server.ps1 -Host 'your-server' -User 'sa' -Password 'password'" -ForegroundColor Yellow
    exit 1
}

if ($Auth -eq "sql" -and (-not $User -or -not $Password)) {
    Write-Host "❌ Error: SQLSERVER_USER and SQLSERVER_PASSWORD required for SQL authentication" -ForegroundColor Red
    exit 1
}

# Set environment variables
Write-Host "🔧 Configuring SQL Server connection..." -ForegroundColor Cyan
$env:SQLSERVER_HOST = $Host
$env:SQLSERVER_PORT = $Port
$env:SQLSERVER_DATABASE = $Database
$env:SQLSERVER_AUTH = $Auth
$env:SQLSERVER_USER = $User
$env:SQLSERVER_PASSWORD = $Password

# Display configuration
Write-Host ""
Write-Host "📌 Server Configuration:" -ForegroundColor Green
Write-Host "   Host: $Host"
Write-Host "   Port: $Port"
Write-Host "   Database: $(if ($Database) { $Database } else { '(default)' })"
Write-Host "   Auth: $Auth"
Write-Host "   User: $(if ($User) { $User } else { '(Windows)' })"
Write-Host ""

# Build and start
Write-Host "🏗️  Building TypeScript..." -ForegroundColor Cyan
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🚀 Starting MCP SQL Server..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

npm start

Write-Host ""
Write-Host "✋ Server stopped" -ForegroundColor Yellow

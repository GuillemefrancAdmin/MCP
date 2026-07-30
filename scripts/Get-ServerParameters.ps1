#!/usr/bin/env pwsh
<#
.SYNOPSIS
Interactive parameter collection for MCP SQL Server scripts

.DESCRIPTION
Prompts user for server configuration if parameters are not provided
#>

function Get-ServerParameters {
    param(
        [string]$SqlHost,
        [int]$SqlPort,
        [string]$SqlUser,
        [string]$SqlPassword,
        [string]$SqlDatabase,
        [string]$SqlAuth,
        [string]$AdUser,
        [string]$EnvFile,
        [switch]$Interactive
    )

    # Check if any parameters provided
    $hasParameters = -not [string]::IsNullOrWhiteSpace($SqlHost) -or `
                     -not [string]::IsNullOrWhiteSpace($SqlUser) -or `
                     -not [string]::IsNullOrWhiteSpace($SqlPassword) -or `
                     -not [string]::IsNullOrWhiteSpace($SqlDatabase) -or `
                     -not [string]::IsNullOrWhiteSpace($SqlAuth) -or `
                     -not [string]::IsNullOrWhiteSpace($AdUser) -or `
                     ($EnvFile -ne ".env")

    # If parameters provided, use them
    if ($hasParameters -and -not $Interactive) {
        return @{
            SqlHost = $SqlHost
            SqlPort = $SqlPort
            SqlUser = $SqlUser
            SqlPassword = $SqlPassword
            SqlDatabase = $SqlDatabase
            SqlAuth = $SqlAuth
            AdUser = $AdUser
            EnvFile = $EnvFile
        }
    }

    # Load .env file if it exists
    if (Test-Path $EnvFile) {
        Write-Host "Found $EnvFile, loading configuration..." -ForegroundColor Cyan
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

        # Use .env values if no parameters provided
        if (-not $hasParameters) {
            return @{
                SqlHost = $env:SQLSERVER_HOST
                SqlPort = if ($env:SQLSERVER_PORT) { [int]$env:SQLSERVER_PORT } else { 1433 }
                SqlUser = $env:SQLSERVER_USER
                SqlPassword = $env:SQLSERVER_PASSWORD
                SqlDatabase = $env:SQLSERVER_DATABASE
                SqlAuth = $env:SQLSERVER_AUTH
                AdUser = $null
                EnvFile = $EnvFile
            }
        }
    }

    # Interactive mode - ask user
    Write-Host ""
    Write-Host "No parameters provided. Configuring SQL Server connection interactively..." -ForegroundColor Cyan
    Write-Host ""

    # Get SQL Server Host
    $defaultHost = if ($env:SQLSERVER_HOST) { $env:SQLSERVER_HOST } else { "localhost" }
    $SqlHost = Read-Host "Enter SQL Server hostname (default: $defaultHost)"
    if ([string]::IsNullOrWhiteSpace($SqlHost)) { $SqlHost = $defaultHost }

    # Get Port
    $defaultPort = if ($env:SQLSERVER_PORT) { $env:SQLSERVER_PORT } else { "1433" }
    $portInput = Read-Host "Enter SQL Server port (default: $defaultPort)"
    $SqlPort = if ([string]::IsNullOrWhiteSpace($portInput)) { [int]$defaultPort } else { [int]$portInput }

    # Get Database
    $defaultDb = if ($env:SQLSERVER_DATABASE) { $env:SQLSERVER_DATABASE } else { "master" }
    $SqlDatabase = Read-Host "Enter database name (default: $defaultDb)"
    if ([string]::IsNullOrWhiteSpace($SqlDatabase)) { $SqlDatabase = $defaultDb }

    # Get Authentication Type
    Write-Host ""
    Write-Host "Authentication type:" -ForegroundColor Cyan
    Write-Host "  1. Windows/AD (Current user)"
    Write-Host "  2. Windows/AD (Specific user)"
    Write-Host "  3. SQL Server"
    Write-Host ""

    $authChoice = Read-Host "Select authentication (1-3, default: 1)"
    if ([string]::IsNullOrWhiteSpace($authChoice)) { $authChoice = "1" }

    switch ($authChoice) {
        "1" {
            $SqlAuth = "windows"
            $AdUser = $null
            Write-Host "Using current Windows user for authentication" -ForegroundColor Green
        }
        "2" {
            $SqlAuth = "windows"
            $AdUser = Read-Host "Enter AD user (format: DOMAIN\username or user@domain.com)"
            Write-Host "Using AD user: $AdUser" -ForegroundColor Green
        }
        "3" {
            $SqlAuth = "sql"
            $SqlUser = Read-Host "Enter SQL Server username"
            $secPassword = Read-Host "Enter SQL Server password" -AsSecureString
            $SqlPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($secPassword))
            Write-Host "Using SQL authentication with user: $SqlUser" -ForegroundColor Green
        }
        default {
            $SqlAuth = "windows"
            $AdUser = $null
            Write-Host "Invalid choice. Using Windows authentication (current user)" -ForegroundColor Yellow
        }
    }

    Write-Host ""

    return @{
        SqlHost = $SqlHost
        SqlPort = $SqlPort
        SqlUser = $SqlUser
        SqlPassword = $SqlPassword
        SqlDatabase = $SqlDatabase
        SqlAuth = $SqlAuth
        AdUser = $AdUser
        EnvFile = $EnvFile
    }
}

# Function is dot-sourced, no need for Export-ModuleMember

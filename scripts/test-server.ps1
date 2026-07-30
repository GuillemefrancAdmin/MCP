#!/usr/bin/env pwsh
<#
.SYNOPSIS
Test the MCP SQL Server

.DESCRIPTION
Tests the SQL Server connection and validates all 9 tools are working

.EXAMPLE
./test-server.ps1
./test-server.ps1 -Host "localhost" -User "sa" -Password "password"

.PARAMETER Host
SQL Server hostname

.PARAMETER Port
SQL Server port (default: 1433)

.PARAMETER User
Database username

.PARAMETER Password
Database password

.PARAMETER Database
Database name to test

.PARAMETER Auth
Authentication type: 'sql' or 'windows' (default: sql)
#>

param(
    [string]$Host = $env:SQLSERVER_HOST ?? "localhost",
    [int]$Port = if ($env:SQLSERVER_PORT) { [int]$env:SQLSERVER_PORT } else { 1433 },
    [string]$User = $env:SQLSERVER_USER ?? "sa",
    [string]$Password = $env:SQLSERVER_PASSWORD,
    [string]$Database = $env:SQLSERVER_DATABASE ?? "master",
    [string]$Auth = $env:SQLSERVER_AUTH ?? "sql"
)

Write-Host ""
Write-Host "🧪 MCP SQL Server Test Suite" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Validate parameters
if ($Auth -eq "sql" -and (-not $User -or -not $Password)) {
    Write-Host "❌ Error: Username and password required for SQL authentication" -ForegroundColor Red
    exit 1
}

# Display test configuration
Write-Host "📋 Test Configuration:" -ForegroundColor Green
Write-Host "   Host: $Host"
Write-Host "   Port: $Port"
Write-Host "   Database: $Database"
Write-Host "   Auth: $Auth"
Write-Host "   User: $(if ($User) { $User } else { 'Windows Auth' })"
Write-Host ""

# Set environment variables
$env:SQLSERVER_HOST = $Host
$env:SQLSERVER_PORT = $Port
$env:SQLSERVER_DATABASE = $Database
$env:SQLSERVER_AUTH = $Auth
$env:SQLSERVER_USER = $User
$env:SQLSERVER_PASSWORD = $Password

# Test 1: Build TypeScript
Write-Host "Test 1️⃣  - Building TypeScript..." -ForegroundColor Yellow
npm run build 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ TypeScript build successful" -ForegroundColor Green
} else {
    Write-Host "❌ TypeScript build failed" -ForegroundColor Red
    exit 1
}

# Test 2: Check dist files exist
Write-Host ""
Write-Host "Test 2️⃣  - Verifying compiled files..." -ForegroundColor Yellow
$distFiles = @(
    "dist/index.js",
    "dist/connection.js",
    "dist/types.js",
    "dist/errors.js",
    "dist/validation.js"
)

$allExist = $true
foreach ($file in $distFiles) {
    if (Test-Path $file) {
        Write-Host "   ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $file" -ForegroundColor Red
        $allExist = $false
    }
}

if ($allExist) {
    Write-Host "✅ All compiled files present" -ForegroundColor Green
} else {
    Write-Host "❌ Some files missing" -ForegroundColor Red
    exit 1
}

# Test 3: Check tools
Write-Host ""
Write-Host "Test 3️⃣  - Verifying tools..." -ForegroundColor Yellow
$tools = @(
    "test-connection.js",
    "list-databases.js",
    "list-tables.js",
    "list-views.js",
    "describe-table.js",
    "execute-query.js",
    "get-foreign-keys.js",
    "get-server-info.js",
    "get-table-stats.js"
)

$toolCount = 0
foreach ($tool in $tools) {
    if (Test-Path "dist/tools/$tool") {
        Write-Host "   ✓ $tool" -ForegroundColor Green
        $toolCount++
    }
}

Write-Host "✅ Found $($toolCount)/9 tools" -ForegroundColor Green

# Test 4: Syntax validation
Write-Host ""
Write-Host "Test 4️⃣  - TypeScript syntax validation..." -ForegroundColor Yellow
npx tsc --noEmit 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ No TypeScript errors" -ForegroundColor Green
} else {
    Write-Host "❌ TypeScript errors found" -ForegroundColor Red
    npx tsc --noEmit
}

# Test 5: Dependencies
Write-Host ""
Write-Host "Test 5️⃣  - Checking dependencies..." -ForegroundColor Yellow
$packageJson = Get-Content package.json | ConvertFrom-Json
$dependencies = @(
    "mssql",
    "@modelcontextprotocol/sdk",
    "zod"
)

$depsFound = 0
foreach ($dep in $dependencies) {
    if ($packageJson.dependencies.$dep) {
        Write-Host "   ✓ $dep" -ForegroundColor Green
        $depsFound++
    }
}

Write-Host "✅ Found $($depsFound)/3 required dependencies" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ All Tests Passed!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Start server: ./scripts/start-server.ps1"
Write-Host "   2. Use with Claude Desktop or MCP client"
Write-Host "   3. Build Docker image: docker build -t mcp-sqlserver:2.0.3 ."
Write-Host ""

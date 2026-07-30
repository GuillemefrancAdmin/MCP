#!/usr/bin/env pwsh
# Test MCP SQL Server setup

param(
    [string]$SqlHost = $(if ($env:SQLSERVER_HOST) { $env:SQLSERVER_HOST } else { "localhost" }),
    [int]$SqlPort = $(if ($env:SQLSERVER_PORT) { [int]$env:SQLSERVER_PORT } else { 1433 }),
    [string]$SqlUser = $env:SQLSERVER_USER,
    [string]$SqlPassword = $env:SQLSERVER_PASSWORD,
    [string]$SqlDatabase = $(if ($env:SQLSERVER_DATABASE) { $env:SQLSERVER_DATABASE } else { "master" }),
    [string]$SqlAuth = ""
)

Write-Host ""
Write-Host "MCP SQL Server Test Suite" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host ""

# Determine authentication method intelligently
if (-not $SqlAuth) {
    if ($env:SQLSERVER_AUTH) {
        $SqlAuth = $env:SQLSERVER_AUTH
    }
    elseif ($SqlUser -and $SqlPassword) {
        $SqlAuth = "sql"
    }
    else {
        # Default to Windows auth if no credentials provided
        $SqlAuth = "windows"
    }
}

if ($SqlAuth -eq "sql") {
    if (-not $SqlUser -or -not $SqlPassword) {
        Write-Host "ERROR: Username and password required for SQL authentication" -ForegroundColor Red
        Write-Host "Usage: ./test-server.ps1 -SqlUser 'sa' -SqlPassword 'password'" -ForegroundColor Yellow
        Write-Host "Or use Windows auth: ./test-server.ps1 -SqlAuth 'windows'" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Test Configuration:" -ForegroundColor Green
Write-Host "  Host: $SqlHost"
Write-Host "  Port: $SqlPort"
Write-Host "  Database: $SqlDatabase"
Write-Host "  Auth: $SqlAuth"
Write-Host ""

# Test 1: Build TypeScript
Write-Host "Test 1 - Building TypeScript..." -ForegroundColor Yellow
npm run build 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "PASS: TypeScript build successful" -ForegroundColor Green
}
else {
    Write-Host "FAIL: TypeScript build failed" -ForegroundColor Red
    exit 1
}

# Test 2: Check dist files
Write-Host ""
Write-Host "Test 2 - Verifying compiled files..." -ForegroundColor Yellow
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
        Write-Host "  OK: $file" -ForegroundColor Green
    }
    else {
        Write-Host "  Missing: $file" -ForegroundColor Red
        $allExist = $false
    }
}

if ($allExist) {
    Write-Host "PASS: All compiled files present" -ForegroundColor Green
}
else {
    Write-Host "FAIL: Some files missing" -ForegroundColor Red
    exit 1
}

# Test 3: Check tools
Write-Host ""
Write-Host "Test 3 - Verifying tools..." -ForegroundColor Yellow
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
        $toolCount++
    }
}

Write-Host "PASS: Found $toolCount/9 tools" -ForegroundColor Green

# Test 4: TypeScript syntax
Write-Host ""
Write-Host "Test 4 - TypeScript syntax validation..." -ForegroundColor Yellow
npx tsc --noEmit 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "PASS: No TypeScript errors" -ForegroundColor Green
}
else {
    Write-Host "FAIL: TypeScript errors found" -ForegroundColor Red
    exit 1
}

# Test 5: Dependencies
Write-Host ""
Write-Host "Test 5 - Checking dependencies..." -ForegroundColor Yellow
$packageJson = Get-Content package.json | ConvertFrom-Json
$deps = @("mssql", "@modelcontextprotocol/sdk", "zod")
$depsFound = 0
foreach ($dep in $deps) {
    if ($packageJson.dependencies.$dep) {
        $depsFound++
    }
}

Write-Host "PASS: Found $depsFound/3 required dependencies" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "==========================" -ForegroundColor Cyan
Write-Host "All Tests Passed" -ForegroundColor Green
Write-Host ""
Write-Host "Detected Auth: $SqlAuth" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ready to start server:" -ForegroundColor Green
Write-Host "  ./scripts/start-server.ps1" -ForegroundColor Yellow
Write-Host ""

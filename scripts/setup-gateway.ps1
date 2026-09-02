# Simple Docker MCP Gateway Setup Script
# Builds images, creates catalog, and runs gateway

$ErrorActionPreference = 'Stop'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Docker MCP Gateway Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Check Docker
Write-Host "Step 1: Checking Docker..." -ForegroundColor Green
$dockerVersion = docker --version
Write-Host "OK: $dockerVersion`n" -ForegroundColor Green

# Step 2: Build images
Write-Host "Step 2: Building Docker images..." -ForegroundColor Green
Write-Host "Building pdf-reader-mcp..." -ForegroundColor Yellow
docker build -t pdf-reader-mcp:latest ./pdf-reader-mcp
Write-Host "OK: pdf-reader-mcp built`n" -ForegroundColor Green

Write-Host "Building putty-mcp..." -ForegroundColor Yellow
docker build -t putty-mcp:latest ./putty-mcp
Write-Host "OK: putty-mcp built`n" -ForegroundColor Green

# Step 3: Setup catalog directory
Write-Host "Step 3: Setting up MCP catalog directory..." -ForegroundColor Green
$catalogDir = "$env:APPDATA\docker\mcp\catalogs"
New-Item -ItemType Directory -Path $catalogDir -Force | Out-Null
Write-Host "OK: Catalog directory at $catalogDir`n" -ForegroundColor Green

# Step 4: Copy mcp.yaml files
Write-Host "Step 4: Copying mcp.yaml files..." -ForegroundColor Green
Copy-Item ".\pdf-reader-mcp\mcp.yaml" "$catalogDir\pdf-reader-mcp.yaml" -Force
Copy-Item ".\putty-mcp\mcp.yaml" "$catalogDir\putty-mcp.yaml" -Force
Write-Host "OK: Files copied`n" -ForegroundColor Green

# Step 5: Create catalog
Write-Host "Step 5: Creating MCP catalog..." -ForegroundColor Green
docker mcp catalog create uqac-mcp-catalog:latest `
  --title "UQAC MCP Catalog (PDF + PuTTY)" `
  --server file://pdf-reader-mcp.yaml `
  --server file://putty-mcp.yaml
Write-Host "OK: Catalog created`n" -ForegroundColor Green

# Step 6: Run gateway
Write-Host "Step 6: Starting Docker MCP Gateway..." -ForegroundColor Green
Write-Host "Gateway will run on http://localhost:9000" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the gateway`n" -ForegroundColor Yellow

docker mcp gateway run `
  --catalog uqac-mcp-catalog:latest `
  --servers pdf-reader-mcp,putty-mcp

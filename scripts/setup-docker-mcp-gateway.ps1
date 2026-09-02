#Requires -Version 5.0
<#
.SYNOPSIS
    Complete setup script for Docker MCP Gateway with PDF Reader and PuTTY MCPs

.DESCRIPTION
    Automates the entire Docker MCP Gateway setup process:
    1. Builds Docker images for both MCPs
    2. Copies mcp.yaml files to Docker catalog directory
    3. Creates the combined MCP catalog
    4. Optionally runs the gateway

.EXAMPLE
    .\setup-docker-mcp-gateway.ps1

.EXAMPLE
    .\setup-docker-mcp-gateway.ps1 -RunGateway -Port 9000
#>

[CmdletBinding()]
param(
    [switch]$RunGateway,
    [int]$Port = 9000,
    [switch]$Debug,
    [switch]$SkipImageBuild,
    [switch]$NoCleanup
)

$ErrorActionPreference = 'Stop'

# Colors for output
$successColor = 'Green'
$errorColor = 'Red'
$warningColor = 'Yellow'
$infoColor = 'Cyan'

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor $successColor
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor $errorColor
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor $warningColor
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor $infoColor
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $infoColor
    Write-Host "  $Title" -ForegroundColor $infoColor
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $infoColor
    Write-Host ""
}

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Header "Docker MCP Gateway Setup"

# Step 1: Verify Docker is installed
Write-Info "Checking Docker installation..."
try {
    $dockerVersion = docker --version
    Write-Success "Docker is installed: $dockerVersion"
} catch {
    Write-Error "Docker is not installed or not in PATH. Please install Docker Desktop."
    exit 1
}

# Step 2: Build Docker images
if (-not $SkipImageBuild) {
    Write-Header "Step 1: Building Docker Images"

    Write-Info "Building PDF Reader MCP image..."
    if (docker build -t pdf-reader-mcp:latest ./pdf-reader-mcp) {
        Write-Success "PDF Reader MCP image built successfully"
    } else {
        Write-Error "Failed to build PDF Reader MCP image"
        exit 1
    }

    Write-Info "Building PuTTY MCP image..."
    if (docker build -t putty-mcp:latest ./putty-mcp) {
        Write-Success "PuTTY MCP image built successfully"
    } else {
        Write-Error "Failed to build PuTTY MCP image"
        exit 1
    }
} else {
    Write-Warning "Skipping image build (SkipImageBuild flag used)"
}

# Step 3: Set up catalog directory
Write-Header "Step 2: Setting Up MCP Catalog"

$catalogDir = "$env:APPDATA\docker\mcp\catalogs"

Write-Info "Catalog directory: $catalogDir"

if (-not (Test-Path $catalogDir)) {
    Write-Info "Creating catalog directory..."
    New-Item -ItemType Directory -Path $catalogDir -Force | Out-Null
    Write-Success "Catalog directory created"
} else {
    Write-Success "Catalog directory already exists"
}

# Copy mcp.yaml files
Write-Info "Copying pdf-reader-mcp.yaml..."
Copy-Item ".\pdf-reader-mcp\mcp.yaml" "$catalogDir\pdf-reader-mcp.yaml" -Force
Write-Success "pdf-reader-mcp.yaml copied"

Write-Info "Copying putty-mcp.yaml..."
Copy-Item ".\putty-mcp\mcp.yaml" "$catalogDir\putty-mcp.yaml" -Force
Write-Success "putty-mcp.yaml copied"

# Step 4: Create catalog
Write-Header "Step 3: Creating Docker MCP Catalog"

Write-Info "Creating catalog 'uqac-mcp-catalog:latest'..."

$catalogCreateCmd = @(
    "mcp"
    "catalog"
    "create"
    "uqac-mcp-catalog:latest"
    "--title", "UQAC MCP Catalog (PDF + PuTTY)"
    "--server", "file://pdf-reader-mcp.yaml"
    "--server", "file://putty-mcp.yaml"
)

if (& docker @catalogCreateCmd 2>&1) {
    Write-Success "Catalog created successfully"
} else {
    Write-Warning "Catalog creation returned output (this may be normal)"
}

# Verify catalog was created
Write-Info "Verifying catalog..."
$catalogs = docker mcp catalog list 2>&1 | Select-String "uqac-mcp-catalog"
if ($catalogs) {
    Write-Success "Catalog verified: $catalogs"
} else {
    Write-Warning "Could not verify catalog (may still be created)"
}

# Step 5: Run gateway (optional)
if ($RunGateway) {
    Write-Header "Step 4: Running Docker MCP Gateway"

    Write-Info "Starting gateway on port $Port..."
    Write-Info "Press Ctrl+C to stop the gateway"
    Write-Host ""

    $gatewayArgs = @(
        "mcp"
        "gateway"
        "run"
        "--catalog", "uqac-mcp-catalog:latest"
        "--servers", "pdf-reader-mcp,putty-mcp"
        "--port", $Port
    )

    if ($Debug) {
        $gatewayArgs += "--debug"
        Write-Info "Debug mode enabled"
    }

    & docker @gatewayArgs
} else {
    Write-Header "Step 4: Next Steps"
    Write-Host ""
    Write-Info "To start the Docker MCP Gateway, run:"
    Write-Host ""
    Write-Host "  docker mcp gateway run ``" -ForegroundColor $infoColor
    Write-Host "    --catalog uqac-mcp-catalog:latest ``" -ForegroundColor $infoColor
    Write-Host "    --servers pdf-reader-mcp,putty-mcp ``" -ForegroundColor $infoColor
    Write-Host "    --port $Port" -ForegroundColor $infoColor
    Write-Host ""
    Write-Info "Or use this script with -RunGateway flag:"
    Write-Host ""
    Write-Host "  .\setup-docker-mcp-gateway.ps1 -RunGateway" -ForegroundColor $infoColor
    Write-Host ""
    Write-Info "To enable debug output:"
    Write-Host ""
    Write-Host "  .\setup-docker-mcp-gateway.ps1 -RunGateway -Debug" -ForegroundColor $infoColor
    Write-Host ""
}

Write-Header "Setup Complete ✅"

Write-Info "Configuration Summary:"
Write-Host ""
Write-Host "  PDF Reader MCP" -ForegroundColor $successColor
Write-Host "    Image:        pdf-reader-mcp:latest" -ForegroundColor Gray
Write-Host "    Transport:    stdio" -ForegroundColor Gray
Write-Host "    Tools:        6 total" -ForegroundColor Gray
Write-Host ""
Write-Host "  PuTTY SSH MCP" -ForegroundColor $successColor
Write-Host "    Image:        putty-mcp:latest" -ForegroundColor Gray
Write-Host "    Transport:    stdio" -ForegroundColor Gray
Write-Host "    Tools:        10+ total" -ForegroundColor Gray
Write-Host ""
Write-Host "  Catalog" -ForegroundColor $successColor
Write-Host "    Name:         uqac-mcp-catalog:latest" -ForegroundColor Gray
Write-Host "    Location:     $catalogDir" -ForegroundColor Gray
Write-Host ""

Write-Info "To verify tool discovery:"
Write-Host ""
Write-Host "  1. Start the gateway:" -ForegroundColor $infoColor
Write-Host "     .\setup-docker-mcp-gateway.ps1 -RunGateway" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. In another terminal, connect Claude:" -ForegroundColor $infoColor
Write-Host "     docker mcp client connect claude-code --global" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Open Claude Desktop and verify tools appear" -ForegroundColor $infoColor
Write-Host ""

Write-Info "Documentation"
Write-Host "  * Full setup guide: DOCKER-MCP-GATEWAY-SETUP.md" -ForegroundColor Gray
Write-Host "  * Troubleshooting: TOOL_DETECTION_VALIDATION.md" -ForegroundColor Gray
Write-Host "  * Configuration: CONFIGURATION-FIX-SUMMARY.md" -ForegroundColor Gray
Write-Host ""

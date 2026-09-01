<#
.SYNOPSIS
    Builds every MCP server image in this workspace and publishes them as one
    Docker MCP Toolkit catalog.

.DESCRIPTION
    Scans the immediate subdirectories of the workspace root for MCP server
    projects. A directory counts as one if it has both a Dockerfile and an
    mcp.yaml manifest (the convention used by pdf-reader-mcp and putty-mcp) -
    so dropping in a third project with the same two files is enough for it
    to be picked up automatically, no edits to this script required.

    For each discovered project it:
      1. Reads the server name and image tag out of mcp.yaml.
      2. Runs `docker build -t <image> <project-dir>` (builds into the local
         Docker Desktop image store - no push to a registry).

    Once every project has built, it copies each mcp.yaml into
    ~/.docker/mcp/catalogs/ (the only place the Docker MCP Toolkit will
    resolve a file:// catalog reference from) and (re)creates a single
    catalog from all of them with `docker mcp catalog create`. Re-running
    this script is safe - catalog create replaces the existing catalog of
    the same name, and Docker's build cache skips unchanged layers.

.PARAMETER CatalogName
    Repository name for the catalog. Must be a valid lowercase OCI
    reference component (Docker rejects uppercase). Default: uqac-mcp-catalog

.PARAMETER Tag
    Tag for the catalog. Default: latest

.PARAMETER Title
    Human-readable catalog title shown by `docker mcp catalog ls`.
    Default: UQAC MCP Catalog

.PARAMETER SkipBuild
    Skip `docker build` and only (re)publish the catalog from the mcp.yaml
    files already on disk (e.g. after editing a manifest's volumes/env).

.EXAMPLE
    ./scripts/Publish-McpCatalog.ps1

.EXAMPLE
    ./scripts/Publish-McpCatalog.ps1 -SkipBuild

.EXAMPLE
    ./scripts/Publish-McpCatalog.ps1 -CatalogName my-catalog -Title "My Catalog"
#>

[CmdletBinding()]
param(
    [string]$CatalogName = "uqac-mcp-catalog",
    [string]$Tag = "latest",
    [string]$Title = "UQAC MCP Catalog",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "docker CLI not found on PATH. Install/start Docker Desktop first."
}

$workspaceRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$catalogsDir = Join-Path $HOME ".docker/mcp/catalogs"

function Get-ManifestField {
    param([string]$Content, [string]$Pattern)
    $m = [regex]::Match($Content, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return $null
}

# --- discover ---------------------------------------------------------------

$projects = Get-ChildItem -Path $workspaceRoot -Directory | Where-Object {
    (Test-Path (Join-Path $_.FullName "Dockerfile")) -and
    (Test-Path (Join-Path $_.FullName "mcp.yaml"))
}

if (-not $projects) {
    Write-Error "No MCP projects found under $workspaceRoot (looked for subdirectories with both a Dockerfile and an mcp.yaml)."
}

Write-Host "Discovered $($projects.Count) MCP project(s):" -ForegroundColor Cyan
$projects | ForEach-Object { Write-Host "  - $($_.Name)" }

# --- build --------------------------------------------------------------------

$manifests = @()
$failedProjects = @()

foreach ($project in $projects) {
    $mcpYamlPath = Join-Path $project.FullName "mcp.yaml"
    $content = Get-Content -Raw $mcpYamlPath

    $serverName = Get-ManifestField $content '(?m)^registry:\s*\r?\n\s{2}([A-Za-z0-9_.\-]+):'
    $image = Get-ManifestField $content '(?m)^\s*image:\s*(\S+)\s*$'

    if (-not $serverName -or -not $image) {
        Write-Warning "Skipping $($project.Name): could not find registry.<name>.image in mcp.yaml"
        $failedProjects += $project.Name
        continue
    }

    if (-not $SkipBuild) {
        Write-Host "`n==> Building $image from $($project.Name) ..." -ForegroundColor Cyan
        docker build -t $image $project.FullName
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "docker build failed for $($project.Name) ($image) - excluding it from the catalog."
            $failedProjects += $project.Name
            continue
        }
    }

    $manifests += [PSCustomObject]@{
        Project     = $project.Name
        ServerName  = $serverName
        Image       = $image
        SourcePath  = $mcpYamlPath
        CatalogFile = "$serverName.yaml"
    }
}

if (-not $manifests) {
    Write-Error "No project built/parsed successfully; nothing to publish."
}

# --- publish: copy manifests + (re)create the catalog --------------------------

Write-Host "`n==> Publishing catalog '${CatalogName}:${Tag}' with $($manifests.Count) server(s) ..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $catalogsDir | Out-Null

$serverArgs = @()
foreach ($m in $manifests) {
    $dest = Join-Path $catalogsDir $m.CatalogFile
    Copy-Item -Path $m.SourcePath -Destination $dest -Force
    $serverArgs += "--server"
    $serverArgs += "file://$($m.CatalogFile)"
    Write-Host "  - $($m.ServerName) -> $($m.Image)"
}

$catalogRef = "${CatalogName}:${Tag}"
docker mcp catalog create $catalogRef --title $Title @serverArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "docker mcp catalog create failed for $catalogRef"
}

Write-Host "`nPublished $catalogRef with: $(($manifests | ForEach-Object { $_.ServerName }) -join ', ')" -ForegroundColor Green
Write-Host "  docker mcp catalog server ls $catalogRef"
Write-Host "  docker mcp client connect claude-code --global   # wire it into a client"

if ($failedProjects) {
    Write-Warning "Excluded from this publish due to errors: $($failedProjects -join ', ')"
    exit 1
}

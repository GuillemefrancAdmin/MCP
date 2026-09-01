@echo off
rem Runs Publish-McpCatalog.ps1 directly - double-click this file, run it
rem bare from cmd.exe, or call it from PowerShell (.\scripts\publish-mcp-catalog.cmd).
rem Any arguments are forwarded, e.g.:
rem   publish-mcp-catalog.cmd -SkipBuild
rem   publish-mcp-catalog.cmd -CatalogName my-catalog -Title "My Catalog"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Publish-McpCatalog.ps1" %*
if errorlevel 1 pause

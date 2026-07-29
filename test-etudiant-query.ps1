# Test script - Query Etudiant table via REST API
# Run this after starting the MCP server (option 2)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Testing MCP Server - Etudiant Query" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$baseUri = "http://localhost:5000/api"

Write-Host "[1] Checking server connection..." -ForegroundColor Yellow
try {
    $test = Invoke-WebRequest -Uri "$baseUri/etudiant?`$top=1" -Method Get -ErrorAction SilentlyContinue
    Write-Host "[OK] Server is running!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Server not running. Start it with option 2 in the menu." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "[2] Querying first 10 students from etudiant table..." -ForegroundColor Yellow
Write-Host ""

try {
    $uri = "$baseUri/etudiant?`$top=10"
    $response = Invoke-RestMethod -Uri $uri -Method Get

    if ($response -is [array]) {
        Write-Host "Found $($response.Count) students:" -ForegroundColor Green
        Write-Host ""

        $response | ForEach-Object -Begin { $i = 1 } {
            Write-Host "[$i] Student:" -ForegroundColor Cyan

            # Display key fields
            $_.PSObject.Properties | Where-Object { $_.Name -like "*nom*" -or $_.Name -like "*prenom*" -or $_.Name -like "*id*" } | ForEach-Object {
                Write-Host "    $($_.Name): $($_.Value)" -ForegroundColor White
            }
            Write-Host ""
            $i++
        }
    } else {
        Write-Host "Single result found:" -ForegroundColor Green
        Write-Host $response | Format-List
    }

    Write-Host "[OK] Query successful!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Query failed: $($_)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure the MCP server is running (option 2)"
    Write-Host "2. Check that dab-config.json is valid"
    Write-Host "3. Verify the etudiant table exists in the database"
}

Write-Host ""
Read-Host "Press Enter to exit"

# Scripts

Utility scripts for managing the MCP SQL Server.

## start-server.ps1

Starts the SQL Server MCP server with configuration.

### Usage

```powershell
# Using environment variables
./start-server.ps1

# With parameters
./start-server.ps1 -Host "your-server.database.windows.net" `
                   -User "username" `
                   -Password "password" `
                   -Database "master"

# Using .env file
./start-server.ps1 -EnvFile ".env"
```

### Parameters

- `-Host` - SQL Server hostname (required)
- `-Port` - Port number (default: 1433)
- `-User` - Database username (for SQL auth)
- `-Password` - Database password (for SQL auth)
- `-Database` - Default database name
- `-Auth` - Authentication type: 'sql' or 'windows' (default: sql)
- `-EnvFile` - Path to .env file (default: .env)

## test-server.ps1

Validates the project setup and verifies all components.

### Usage

```powershell
# Test with defaults
./test-server.ps1

# Test with specific credentials
./test-server.ps1 -Host "localhost" `
                  -User "sa" `
                  -Password "password"
```

### What It Tests

1. ✅ TypeScript build
2. ✅ Compiled files exist
3. ✅ All 9 tools present
4. ✅ TypeScript syntax validation
5. ✅ Dependencies installed

## Quick Start

```powershell
# 1. Test the setup
./scripts/test-server.ps1

# 2. Start the server
./scripts/start-server.ps1

# 3. Use with Claude Desktop or MCP client
```

## Requirements

- PowerShell 7+ (or Windows PowerShell 5.1+)
- Node.js 18+
- npm dependencies installed (`npm install`)

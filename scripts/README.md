# Scripts

Utility scripts for managing the MCP SQL Server.

## start-server.ps1

Starts the SQL Server MCP server with full authentication support (SQL and Active Directory).

### Features
- **SQL Authentication** - Username and password login
- **Windows/AD Authentication** - Active Directory integrated security
- Load environment variables from `.env` file
- Automatic TypeScript build
- Connection validation
- Colorized output

### SQL Authentication

```powershell
# Basic usage
./start-server.ps1 -SqlHost "localhost" `
                   -SqlUser "sa" `
                   -SqlPassword "YourPassword123"

# With database selection
./start-server.ps1 -SqlHost "sql-server.company.com" `
                   -SqlUser "admin" `
                   -SqlPassword "password" `
                   -SqlDatabase "YourDatabase"

# Custom port
./start-server.ps1 -SqlHost "localhost" `
                   -SqlPort 1433 `
                   -SqlUser "sa" `
                   -SqlPassword "password"
```

### Windows/Active Directory Authentication

```powershell
# Use current Windows user credentials
./start-server.ps1 -SqlHost "sql-server.company.com" `
                   -SqlAuth "windows"

# Use specific AD user
./start-server.ps1 -SqlHost "sql-server.company.com" `
                   -SqlAuth "windows" `
                   -AdUser "DOMAIN\username"

# Alternative AD format
./start-server.ps1 -SqlHost "sql-server.company.com" `
                   -SqlAuth "windows" `
                   -AdUser "username@domain.com"
```

### Environment File

Create a `.env` file in the project root:

```env
SQLSERVER_HOST=sql-server.company.com
SQLSERVER_PORT=1433
SQLSERVER_DATABASE=MyDatabase
SQLSERVER_AUTH=windows
```

Then run:
```powershell
./start-server.ps1 -EnvFile ".env"
```

### Parameters

- `-SqlHost` - SQL Server hostname or IP (required)
- `-SqlPort` - Port number (default: 1433)
- `-SqlUser` - Username (required for SQL auth)
- `-SqlPassword` - Password (required for SQL auth)
- `-SqlDatabase` - Default database name
- `-SqlAuth` - 'sql' or 'windows' (default: sql)
- `-AdUser` - AD user for Windows auth (optional, uses current user if not specified)
- `-EnvFile` - Path to .env file (default: .env)

---

## test-server.ps1

Validates the entire project setup and verifies all components.

### Usage

```powershell
# Test with defaults
./test-server.ps1

# Test with specific credentials
./test-server.ps1 -SqlHost "localhost" -SqlUser "sa" -SqlPassword "password"

# Test Windows auth
./test-server.ps1 -SqlAuth "windows"
```

### Tests Performed

1. **TypeScript Build** - Compiles source code
2. **Compiled Files** - Verifies all 5 core modules exist
3. **Tools** - Confirms all 9 tools are compiled
4. **TypeScript Syntax** - Validates no type errors
5. **Dependencies** - Checks all 3 required packages installed

### Parameters

- `-SqlHost` - SQL Server hostname (default: localhost)
- `-SqlPort` - Port number (default: 1433)
- `-SqlUser` - Username (default: sa for SQL auth)
- `-SqlPassword` - Password for SQL auth
- `-SqlDatabase` - Database name (default: master)
- `-SqlAuth` - 'sql' or 'windows' (default: sql)

---

## Quick Start

### Option 1: SQL Authentication

```powershell
# 1. Test the setup
./scripts/test-server.ps1 -SqlUser "sa" -SqlPassword "password"

# 2. Start the server
./scripts/start-server.ps1 -SqlHost "localhost" `
                           -SqlUser "sa" `
                           -SqlPassword "password"
```

### Option 2: Windows/AD Authentication

```powershell
# 1. Test the setup
./scripts/test-server.ps1 -SqlAuth "windows"

# 2. Start the server (uses current user)
./scripts/start-server.ps1 -SqlHost "sql-server.company.com" `
                           -SqlAuth "windows"

# Or with specific AD user
./scripts/start-server.ps1 -SqlHost "sql-server.company.com" `
                           -SqlAuth "windows" `
                           -AdUser "DOMAIN\username"
```

### Option 3: Using .env File

1. Create `.env` file:
```env
SQLSERVER_HOST=sql-server.company.com
SQLSERVER_AUTH=windows
```

2. Run:
```powershell
./scripts/test-server.ps1 -EnvFile ".env"
./scripts/start-server.ps1 -EnvFile ".env"
```

---

## Requirements

- PowerShell 5.1+ (Windows PowerShell or PowerShell 7+)
- Node.js 18+
- npm dependencies installed (`npm install`)
- For Windows/AD auth: Domain-joined computer or network access to domain

## Troubleshooting

### "AD user not found" error
- Verify user format: `DOMAIN\username` or `username@domain.com`
- Ensure you have network access to the domain
- Check the user exists in Active Directory

### "Build failed" error
- Run `npm install` to ensure dependencies are installed
- Check for TypeScript errors: `npm run build`

### Connection timeout
- Verify SQL Server hostname and port are correct
- Check firewall rules allow connections on port 1433
- Ensure SQL Server service is running

### Permission denied
- For SQL auth: verify username and password
- For AD auth: ensure user has SELECT permissions on the database

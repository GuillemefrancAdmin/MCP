# Deployment Guide

Complete guide to deploy SQL Server MCP with Docker and Claude Code/Desktop.

## Quick Start (5 minutes)

### 1. Build Docker Image

```powershell
cd mcp-sqlserver
docker build -t ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3 .
```

### 2. Authenticate with GitHub Container Registry

```powershell
# Create PAT at: https://github.com/settings/tokens
# Then login:
docker login ghcr.io -u guillemefrancadmin
# Paste your token when prompted
```

### 3. Push to Registry

```powershell
docker push ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3
docker push ghcr.io/guillemefrancadmin/mcp-sqlserver:latest
```

### 4. Configure Claude Desktop

Edit `%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "sqlserver": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "--network",
        "host",
        "-e",
        "SQLSERVER_HOST=db-dev.uqac.ca",
        "-e",
        "SQLSERVER_AUTH=windows",
        "ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3"
      ]
    }
  }
}
```

### 5. Restart Claude Desktop

Close and reopen. SQL Server MCP is now available!

---

## Detailed Deployment

### Prerequisites

- Docker Desktop installed
- GitHub account
- GitHub Personal Access Token (write:packages scope)
- Claude Desktop or Claude Code

### Step 1: Build Docker Image

```powershell
# Navigate to project root
cd mcp-sqlserver

# Build with multiple tags
docker build -t ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3 \
             -t ghcr.io/guillemefrancadmin/mcp-sqlserver:latest \
             .
```

**Verify build:**
```powershell
docker images | findstr "mcp-sqlserver"
```

### Step 2: Set Up GitHub Container Registry Access

#### Option A: Interactive Login (Easy)

```powershell
docker login ghcr.io -u guillemefrancadmin
```

When prompted for password, paste your GitHub Personal Access Token.

#### Option B: Using Token File

Create a file with your token, then:
```powershell
Get-Content "path\to\token.txt" | docker login ghcr.io -u guillemefrancadmin --password-stdin
```

#### Option C: Environment Variable

```powershell
$env:GITHUB_TOKEN = "ghp_XXXXX..."
$env:GITHUB_TOKEN | docker login ghcr.io -u guillemefrancadmin --password-stdin
```

**Verify login:**
```powershell
docker info | findstr "Username"
# Should show: Username: guillemefrancadmin
```

### Step 3: Push Images to Registry

```powershell
# Push version-specific tag
docker push ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3

# Push latest tag
docker push ghcr.io/guillemefrancadmin/mcp-sqlserver:latest

# Verify push
docker images | findstr "mcp-sqlserver"
```

### Step 4: Configure Claude Desktop

#### Find Config File

**Windows:**
```powershell
$configPath = "$env:APPDATA\Claude\claude_desktop_config.json"
code $configPath
```

**macOS/Linux:**
```bash
nano ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

#### Windows/AD Authentication

```json
{
  "mcpServers": {
    "sqlserver": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "--network",
        "host",
        "-e",
        "SQLSERVER_HOST=db-dev.uqac.ca",
        "-e",
        "SQLSERVER_AUTH=windows",
        "-e",
        "SQLSERVER_DATABASE=YourDatabase",
        "ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3"
      ]
    }
  }
}
```

#### SQL Authentication

```json
{
  "mcpServers": {
    "sqlserver": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "--network",
        "host",
        "-e",
        "SQLSERVER_HOST=localhost",
        "-e",
        "SQLSERVER_USER=sa",
        "-e",
        "SQLSERVER_PASSWORD=YourPassword",
        "-e",
        "SQLSERVER_AUTH=sql",
        "ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3"
      ]
    }
  }
}
```

#### Using npm Package (Development)

```json
{
  "mcpServers": {
    "sqlserver": {
      "command": "mcp-sqlserver",
      "env": {
        "SQLSERVER_HOST": "db-dev.uqac.ca",
        "SQLSERVER_AUTH": "windows"
      }
    }
  }
}
```

### Step 5: Restart Claude

1. Close Claude Desktop completely
2. Reopen Claude Desktop
3. The SQL Server MCP should now be available

### Step 6: Verify Configuration

In Claude Desktop, try:
```
"Test the SQL Server connection"
```

You should see connection details confirming it's working.

---

## Using the MCP

### Available Commands

Once configured, you can use Claude with SQL queries:

```
"List all databases"
"Show me tables in the dbo schema"
"Describe the Users table"
"How many rows are in each table?"
"What are the foreign keys for the Orders table?"
"Execute: SELECT TOP 10 * FROM Users"
```

### 9 Available Tools

1. **test_connection** - Validate connection
2. **list_databases** - List all databases
3. **list_tables** - List tables in schema
4. **list_views** - List views
5. **describe_table** - Get table schema
6. **execute_query** - Run SELECT queries
7. **get_foreign_keys** - Get relationships
8. **get_server_info** - Get server info
9. **get_table_stats** - Get table statistics

---

## Troubleshooting

### Docker Push Failed

**"denied" error:**
- Check token scope includes `write:packages`
- Verify login: `docker info | findstr "Username"`
- Try logout and login again: `docker logout ghcr.io`

**"authentication required" error:**
- Generate new token at: https://github.com/settings/tokens
- Ensure token has not expired

### Claude Desktop Not Seeing MCP

- Verify JSON syntax in `claude_desktop_config.json`
- Ensure proper indentation (no tabs, 2 spaces)
- Restart Claude Desktop completely
- Check Console.log for errors

### Connection Issues

**Windows/AD authentication not working:**
- Ensure computer is domain-joined
- Verify user has database permissions
- Check firewall allows port 1433

**SQL authentication not working:**
- Verify username and password
- Check SQL Server authentication is enabled
- Confirm user has database access

### Docker Issues

**Image not found:**
```powershell
docker pull ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3
```

**Container not starting:**
```powershell
docker run --rm ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3
# Check output for errors
```

---

## Maintenance

### Update Image

When new version available:

```powershell
# Update package.json version to 2.1.0

# Build new image
docker build -t ghcr.io/guillemefrancadmin/mcp-sqlserver:2.1.0 \
             -t ghcr.io/guillemefrancadmin/mcp-sqlserver:latest \
             .

# Push new version
docker push ghcr.io/guillemefrancadmin/mcp-sqlserver:2.1.0
docker push ghcr.io/guillemefrancadmin/mcp-sqlserver:latest

# Update Claude config to use new version
```

### Clean Up Local Images

```powershell
# Remove local images
docker rmi ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3
docker rmi ghcr.io/guillemefrancadmin/mcp-sqlserver:latest

# Verify
docker images | findstr "mcp-sqlserver"
```

---

## Security Notes

⚠️ **Do NOT:**
- Commit GitHub tokens to git
- Store passwords in config files
- Use weak SQL passwords
- Enable unnecessary permissions

✅ **DO:**
- Use Windows/AD authentication when possible
- Limit SQL user permissions to read-only
- Use strong passwords for SQL auth
- Rotate GitHub tokens regularly
- Review container network settings

---

## Support

For issues:
1. Check docs/DOCKER-PUSH.md for Docker issues
2. Check docs/CLAUDE-CODE-CONFIG.md for config issues
3. Review troubleshooting section above
4. Check GitHub issues: https://github.com/GuillemefrancAdmin/MCP

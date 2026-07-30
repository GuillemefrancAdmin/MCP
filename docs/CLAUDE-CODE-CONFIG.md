# Claude Code / Claude Desktop Configuration

Configure your Claude Code or Claude Desktop to use the SQL Server MCP.

## Option 1: Using npm Package (Recommended for Development)

### Step 1: Install globally

```powershell
npm install -g @bilims/mcp-sqlserver
```

### Step 2: Find Claude Desktop Config

**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
**macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Linux:** `~/.config/Claude/claude_desktop_config.json`

### Step 3: Add MCP Server Configuration

Edit your `claude_desktop_config.json` and add:

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

### Step 4: Restart Claude Desktop

Close and reopen Claude Desktop. The SQL Server MCP should now be available.

---

## Option 2: Using Docker Image (Production)

After pushing to GitHub Container Registry, add to `claude_desktop_config.json`:

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

---

## Option 3: SQL Authentication

For SQL Server authentication instead of Windows/AD:

```json
{
  "mcpServers": {
    "sqlserver": {
      "command": "mcp-sqlserver",
      "env": {
        "SQLSERVER_HOST": "localhost",
        "SQLSERVER_USER": "sa",
        "SQLSERVER_PASSWORD": "YourPassword123",
        "SQLSERVER_DATABASE": "master",
        "SQLSERVER_AUTH": "sql"
      }
    }
  }
}
```

---

## Complete Configuration Example

```json
{
  "mcpServers": {
    "sqlserver": {
      "command": "mcp-sqlserver",
      "env": {
        "SQLSERVER_HOST": "db-dev.uqac.ca",
        "SQLSERVER_PORT": "1433",
        "SQLSERVER_DATABASE": "YourDatabase",
        "SQLSERVER_AUTH": "windows",
        "SQLSERVER_ENCRYPT": "true",
        "SQLSERVER_TRUST_CERT": "true",
        "SQLSERVER_MAX_ROWS": "1000"
      }
    }
  }
}
```

---

## Configuration Options

### Windows/AD Authentication

```json
{
  "SQLSERVER_HOST": "db-dev.uqac.ca",
  "SQLSERVER_AUTH": "windows"
}
```

### SQL Authentication

```json
{
  "SQLSERVER_HOST": "localhost",
  "SQLSERVER_USER": "sa",
  "SQLSERVER_PASSWORD": "password",
  "SQLSERVER_AUTH": "sql"
}
```

### Optional Settings

```json
{
  "SQLSERVER_PORT": "1433",
  "SQLSERVER_DATABASE": "master",
  "SQLSERVER_ENCRYPT": "true",
  "SQLSERVER_TRUST_CERT": "true",
  "SQLSERVER_CONNECTION_TIMEOUT": "30000",
  "SQLSERVER_REQUEST_TIMEOUT": "60000",
  "SQLSERVER_MAX_ROWS": "1000"
}
```

---

## Using with Claude Code

Once configured, you can use Claude with SQL Server:

```
"List all tables in the Users schema"
"Describe the structure of the Orders table"
"Show me the row count for each table"
"Execute a query to find users created in the last 30 days"
"What are the foreign key relationships in this database?"
```

The MCP server will handle these requests using the 9 available tools:
- list_databases
- list_tables
- list_views
- describe_table
- execute_query
- get_foreign_keys
- get_server_info
- get_table_stats
- test_connection

---

## Verify Configuration

After restarting Claude Desktop:

1. Open Claude Desktop
2. Try a SQL Server command: "Test the SQL Server connection"
3. You should see connection details

If it doesn't work:
- Check file location of `claude_desktop_config.json`
- Verify JSON syntax (no trailing commas)
- Check server connectivity
- Review `Console.log` in Claude Desktop

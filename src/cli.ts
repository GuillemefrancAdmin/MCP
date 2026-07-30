#!/usr/bin/env node

import { ConnectionConfigSchema } from './types.js';

function showHelp() {
  console.log(`
MCP SQL Server - A read-only Model Context Protocol server for Microsoft SQL Server

USAGE:
  mcp-sqlserver [options]

ENVIRONMENT VARIABLES:
  SQLSERVER_HOST      SQL Server hostname (required)
  SQLSERVER_USER      Database username (for SQL auth)
  SQLSERVER_PASSWORD  Database password (for SQL auth)
  SQLSERVER_DATABASE  Database name (optional, default: master)
  SQLSERVER_PORT      Port number (optional, default: 1433)
  SQLSERVER_ENCRYPT   Enable encryption (optional, default: true)
  SQLSERVER_TRUST_CERT Trust server certificate (optional, default: true)
  SQLSERVER_AUTH      Authentication type: 'sql' or 'windows' (optional, default: sql)

EXAMPLES:
  # Set environment variables and run
  export SQLSERVER_HOST="your-server.database.windows.net"
  export SQLSERVER_USER="your-username"
  export SQLSERVER_PASSWORD="your-password"
  mcp-sqlserver

  # Using Claude Desktop (add to claude_desktop_config.json):
  {
    "mcpServers": {
      "sqlserver": {
        "command": "mcp-sqlserver",
        "env": {
          "SQLSERVER_HOST": "your-server",
          "SQLSERVER_USER": "your-username",
          "SQLSERVER_PASSWORD": "your-password"
        }
      }
    }
  }

AVAILABLE TOOLS:
  test_connection     - Test SQL Server connection and permissions
  list_databases      - List all databases on the server
  list_tables         - List tables in a database or schema
  list_views          - List views in a database or schema
  describe_table      - Get detailed table schema
  execute_query       - Execute read-only SELECT queries
  get_foreign_keys    - Get foreign key relationships
  get_server_info     - Get SQL Server version and edition info
  get_table_stats     - Get table statistics and row counts

SECURITY:
  - Only read-only operations are allowed
  - SQL injection protection enabled
  - Query validation and sanitization
  - Row limits and timeouts enforced

For more information, visit: https://github.com/bilims/mcp-sqlserver
`);
}

function showVersion() {
  // Read version from package.json
  console.log('2.0.1');
}

function validateEnvironment(): boolean {
  const authType = (process.env.SQLSERVER_AUTH || 'sql').toLowerCase();

  // SQLSERVER_HOST is always required
  if (!process.env.SQLSERVER_HOST) {
    console.error('❌ Missing required environment variable:');
    console.error(`   SQLSERVER_HOST`);
    console.error('\n💡 Set this environment variable or see --help for examples.');
    return false;
  }

  // For SQL auth, user and password are required
  if (authType === 'sql') {
    const required = ['SQLSERVER_USER', 'SQLSERVER_PASSWORD'];
    const missing = required.filter(env => !process.env[env]);

    if (missing.length > 0) {
      console.error('❌ Missing required environment variables (for SQL authentication):');
      missing.forEach(env => {
        console.error(`   ${env}`);
      });
      console.error('\n💡 For Windows auth, set SQLSERVER_AUTH=windows');
      console.error('💡 For SQL auth, also set SQLSERVER_USER and SQLSERVER_PASSWORD');
      return false;
    }
  }

  // Validate configuration
  try {
    const config: any = {
      server: process.env.SQLSERVER_HOST!,
      database: process.env.SQLSERVER_DATABASE,
      port: parseInt(process.env.SQLSERVER_PORT || '1433'),
      encrypt: process.env.SQLSERVER_ENCRYPT !== 'false',
      trustServerCertificate: process.env.SQLSERVER_TRUST_CERT !== 'false',
      authentication: authType === 'windows' ? 'windows' : 'sql',
    };

    // Only add user/password for SQL auth
    if (authType === 'sql') {
      config.user = process.env.SQLSERVER_USER;
      config.password = process.env.SQLSERVER_PASSWORD;
    }

    ConnectionConfigSchema.parse(config);
    return true;
  } catch (error) {
    console.error('❌ Invalid configuration:', error);
    return false;
  }
}

export function handleCliArgs(): boolean {
  const args = process.argv.slice(2);
  
  if (args.includes('--help') || args.includes('-h')) {
    showHelp();
    return false;
  }
  
  if (args.includes('--version') || args.includes('-v')) {
    showVersion();
    return false;
  }

  if (!validateEnvironment()) {
    process.exit(1);
  }

  return true;
}
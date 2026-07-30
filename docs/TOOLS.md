# Available Tools

## Connection
- **test_connection** - Validate SQL Server connection

## Schema Discovery
- **list_databases** - List all databases on the server
- **list_tables** - List tables in a database or schema
- **list_views** - List views in a database or schema
- **describe_table** - Get detailed table schema including columns and data types

## Relationship Analysis
- **get_foreign_keys** - Get foreign key relationships for a table
- **get_table_stats** - Get table statistics including row counts and size

## Data Exploration
- **execute_query** - Execute read-only SELECT queries with safety validation
- **get_server_info** - Get SQL Server version, edition, and configuration details

## Security Features
- ✅ Read-only operations only
- ✅ SQL injection protection
- ✅ Query validation and sanitization
- ✅ Configurable row limits
- ✅ Encrypted connections

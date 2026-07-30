#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { SqlServerConnection } from './connection.js';
import { ConnectionConfigSchema } from './types.js';
import {
  ListDatabasesTool,
  ListTablesTool,
  ListViewsTool,
  DescribeTableTool,
  ExecuteQueryTool,
  GetForeignKeysTool,
  GetServerInfoTool,
  GetTableStatsTool,
  TestConnectionTool,
} from './tools/index.js';
import { handleError } from './errors.js';

class MCP_SQLServer {
  private server: Server;
  private connection!: SqlServerConnection;
  private tools: Map<string, any> = new Map();

  constructor() {
    this.server = new Server(
      { name: 'mcp-sqlserver', version: '2.0.3' },
      { capabilities: { tools: {} } }
    );
    this.setupHandlers();
  }

  private setupHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: Array.from(this.tools.values()).map(tool => ({
        name: tool.getName(),
        description: tool.getDescription(),
        inputSchema: tool.getInputSchema(),
      })),
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const tool = this.tools.get(request.params.name);
      if (!tool) {
        return {
          content: [{ type: 'text', text: JSON.stringify({ error: 'Unknown tool' }) }],
          isError: true,
        };
      }

      try {
        const result = await tool.execute(request.params.arguments || {});
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
      } catch (error) {
        const { message, code } = handleError(error);
        return {
          content: [{ type: 'text', text: JSON.stringify({ error: message, code }) }],
          isError: true,
        };
      }
    });
  }

  private initTools(maxRows: number) {
    const toolClasses = [
      TestConnectionTool,
      ListDatabasesTool,
      ListTablesTool,
      ListViewsTool,
      DescribeTableTool,
      ExecuteQueryTool,
      GetForeignKeysTool,
      GetServerInfoTool,
      GetTableStatsTool,
    ];

    for (const ToolClass of toolClasses) {
      const tool = new ToolClass(this.connection, maxRows);
      this.tools.set(tool.getName(), tool);
    }
  }

  async initialize(config: any) {
    try {
      ConnectionConfigSchema.parse(config);
      this.connection = new SqlServerConnection(config);
      this.initTools(config.maxRows || 1000);
      console.error(`MCP SQL Server initialized: ${config.server}`);
    } catch (error) {
      console.error('Initialization failed:', error);
      throw error;
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('MCP SQL Server ready');
  }
}

async function main() {
  if (process.argv.includes('--help') || process.argv.includes('-h')) {
    console.log(`MCP SQL Server v2.0.3
ENVIRONMENT VARIABLES:
  SQLSERVER_HOST - SQL Server hostname (required)
  SQLSERVER_USER - Username (for SQL auth)
  SQLSERVER_PASSWORD - Password (for SQL auth)
  SQLSERVER_DATABASE - Database name
  SQLSERVER_PORT - Port (default: 1433)
  SQLSERVER_ENCRYPT - Enable encryption (default: true)
  SQLSERVER_TRUST_CERT - Trust cert (default: true)
  SQLSERVER_AUTH - 'sql' or 'windows' (default: sql)
  SQLSERVER_MAX_ROWS - Max rows per query (default: 1000)`);
    return;
  }

  const config = {
    server: process.env.SQLSERVER_HOST || 'localhost',
    database: process.env.SQLSERVER_DATABASE,
    port: parseInt(process.env.SQLSERVER_PORT || '1433'),
    encrypt: process.env.SQLSERVER_ENCRYPT !== 'false',
    trustServerCertificate: process.env.SQLSERVER_TRUST_CERT !== 'false',
    connectionTimeout: parseInt(process.env.SQLSERVER_CONNECTION_TIMEOUT || '30000'),
    requestTimeout: parseInt(process.env.SQLSERVER_REQUEST_TIMEOUT || '60000'),
    maxRows: parseInt(process.env.SQLSERVER_MAX_ROWS || '1000'),
    authentication: (process.env.SQLSERVER_AUTH || 'sql').toLowerCase(),
    user: process.env.SQLSERVER_USER,
    password: process.env.SQLSERVER_PASSWORD,
  };

  const server = new MCP_SQLServer();
  await server.initialize(config);
  await server.run();
}

main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});

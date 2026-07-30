import { BaseTool } from './base.js';
import { DatabaseInfo } from '../types.js';

export class ListDatabasesTool extends BaseTool {
  getName(): string {
    return 'list_databases';
  }

  getDescription(): string {
    return 'List all databases on the SQL Server instance';
  }

  getInputSchema(): any {
    return { type: 'object', properties: {} };
  }

  async execute(): Promise<{ databases: DatabaseInfo[] }> {
    const query = 'SELECT name, state_desc as state FROM sys.databases ORDER BY name';
    const result = await this.executeSafeQuery<DatabaseInfo>(query);
    return { databases: result };
  }
}
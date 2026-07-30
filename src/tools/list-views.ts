import { BaseTool } from './base.js';
import { TableInfo } from '../types.js';

export class ListViewsTool extends BaseTool {
  getName(): string {
    return 'list_views';
  }

  getDescription(): string {
    return 'List views in a database or schema';
  }

  getInputSchema(): any {
    return {
      type: 'object',
      properties: {
        schema: { type: 'string', description: 'Schema name (default: dbo)' },
      },
    };
  }

  async execute(params?: { schema?: string }): Promise<{ views: TableInfo[] }> {
    const schema = params?.schema || 'dbo';
    const query = `
      SELECT table_name, table_schema, 'VIEW' as table_type
      FROM information_schema.views
      WHERE table_schema = '${schema}'
      ORDER BY table_name
    `;

    const result = await this.executeSafeQuery<TableInfo>(query);
    return { views: result };
  }
}
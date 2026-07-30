import { BaseTool } from './base.js';
import { TableInfo } from '../types.js';
import { validateSchemaName } from '../validation.js';

export class ListTablesTool extends BaseTool {
  getName(): string {
    return 'list_tables';
  }

  getDescription(): string {
    return 'List tables in a database or schema';
  }

  getInputSchema(): any {
    return {
      type: 'object',
      properties: {
        schema: { type: 'string', description: 'Schema name (default: dbo)' },
      },
    };
  }

  async execute(params?: { schema?: string }): Promise<{ tables: TableInfo[] }> {
    let query = `
      SELECT table_name, table_schema, table_type
      FROM information_schema.tables
      WHERE table_type = 'BASE TABLE'
    `;

    const schema = params?.schema;
    if (schema && validateSchemaName(schema)) {
      query += ` AND table_schema = '${schema}'`;
    } else {
      query += ` AND table_schema = 'dbo'`;
    }

    query += ` ORDER BY table_name`;
    const result = await this.executeSafeQuery<TableInfo>(query);
    return { tables: result };
  }
}
import { BaseTool } from './base.js';
import { ColumnInfo } from '../types.js';
import { validateTableName, validateSchemaName } from '../validation.js';

export class DescribeTableTool extends BaseTool {
  getName(): string {
    return 'describe_table';
  }

  getDescription(): string {
    return 'Get detailed table schema including columns and constraints';
  }

  getInputSchema(): any {
    return {
      type: 'object',
      properties: {
        table_name: { type: 'string', description: 'Table name (required)' },
        schema: { type: 'string', description: 'Schema name (default: dbo)' },
      },
      required: ['table_name'],
    };
  }

  async execute(params: { table_name: string; schema?: string }): Promise<{ columns: ColumnInfo[] }> {
    if (!params.table_name) throw new Error('table_name is required');
    if (!validateTableName(params.table_name)) throw new Error('Invalid table name');

    const schema = params.schema && validateSchemaName(params.schema) ? params.schema : 'dbo';

    const query = `
      SELECT column_name, data_type, is_nullable, character_maximum_length
      FROM information_schema.columns
      WHERE table_name = '${params.table_name}' AND table_schema = '${schema}'
      ORDER BY ordinal_position
    `;

    const result = await this.executeSafeQuery<ColumnInfo>(query);
    return { columns: result };
  }
}
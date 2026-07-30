import { BaseTool } from './base.js';
import { ForeignKeyInfo } from '../types.js';
import { validateTableName } from '../validation.js';

export class GetForeignKeysTool extends BaseTool {
  getName(): string {
    return 'get_foreign_keys';
  }

  getDescription(): string {
    return 'Get foreign key relationships for a table';
  }

  getInputSchema(): any {
    return {
      type: 'object',
      properties: {
        table_name: { type: 'string', description: 'Table name (required)' },
      },
      required: ['table_name'],
    };
  }

  async execute(params: { table_name: string }): Promise<{ foreign_keys: ForeignKeyInfo[] }> {
    if (!params.table_name) throw new Error('table_name is required');
    if (!validateTableName(params.table_name)) throw new Error('Invalid table name');

    const query = `
      SELECT CONSTRAINT_NAME as constraint_name, TABLE_NAME as table_name,
             COLUMN_NAME as column_name, REFERENCED_TABLE_NAME as referenced_table_name,
             REFERENCED_COLUMN_NAME as referenced_column_name
      FROM information_schema.referential_constraints rc
      JOIN information_schema.key_column_usage kcu
        ON rc.constraint_name = kcu.constraint_name
      WHERE kcu.table_name = '${params.table_name}'
    `;

    const result = await this.executeSafeQuery<ForeignKeyInfo>(query);
    return { foreign_keys: result };
  }
}
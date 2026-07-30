import { BaseTool } from './base.js';
import { TableStats } from '../types.js';
import { validateTableName } from '../validation.js';

export class GetTableStatsTool extends BaseTool {
  getName(): string {
    return 'get_table_stats';
  }

  getDescription(): string {
    return 'Get table statistics including row count and size';
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

  async execute(params: { table_name: string }): Promise<{ stats: TableStats[] }> {
    if (!params.table_name) throw new Error('table_name is required');
    if (!validateTableName(params.table_name)) throw new Error('Invalid table name');

    const query = `
      SELECT t.name as table_name, ps.row_count,
             (ps.in_row_data_page_count * 8) / 1024.0 as size_mb
      FROM sys.tables t
      JOIN sys.dm_db_partition_stats ps ON t.object_id = ps.object_id
      WHERE t.name = '${params.table_name}'
    `;

    const result = await this.executeSafeQuery<TableStats>(query);
    return { stats: result };
  }
}
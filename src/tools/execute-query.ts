import { BaseTool } from './base.js';
import { QueryResult } from '../types.js';
import { validateQuery } from '../validation.js';

export class ExecuteQueryTool extends BaseTool {
  getName(): string {
    return 'execute_query';
  }

  getDescription(): string {
    return 'Execute a read-only SELECT query against the database';
  }

  getInputSchema(): any {
    return {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'SQL SELECT query (read-only only)' },
        limit: { type: 'number', description: 'Max rows to return', minimum: 1, maximum: 10000 },
      },
      required: ['query'],
    };
  }

  async execute(params: { query: string; limit?: number }): Promise<QueryResult> {
    if (!params.query) throw new Error('query is required');
    if (!validateQuery(params.query)) throw new Error('Query not allowed');

    const limit = Math.min(params.limit || 1000, 10000);
    const query = `${params.query}\nOFFSET 0 ROWS FETCH NEXT ${limit} ROWS ONLY`;

    await this.connection.connect();
    const result = await this.connection.query(query);

    const columns = result.length > 0 ? Object.keys(result[0]) : [];
    const rows = result.map(row => columns.map(col => row[col]));

    return { columns, rows, rowCount: result.length };
  }
}

import { SqlServerConnection } from '../connection.js';
import { validateQuery } from '../validation.js';
import { handleError } from '../errors.js';

export abstract class BaseTool {
  protected connection: SqlServerConnection;
  protected maxRows: number;

  constructor(connection: SqlServerConnection, maxRows: number = 1000) {
    this.connection = connection;
    this.maxRows = maxRows;
  }

  protected async executeSafeQuery<T = any>(query: string): Promise<T[]> {
    try {
      if (!validateQuery(query)) {
        throw new Error('Query blocked: only SELECT, WITH, SHOW, DESCRIBE allowed');
      }

      const limitedQuery = `${query}\nOFFSET 0 ROWS FETCH NEXT ${this.maxRows} ROWS ONLY`;
      await this.connection.connect();
      return await this.connection.query<T>(limitedQuery);
    } catch (error) {
      const { message } = handleError(error);
      throw new Error(message);
    }
  }

  abstract getName(): string;
  abstract getDescription(): string;
  abstract getInputSchema(): any;
  abstract execute(params: any): Promise<any>;
}

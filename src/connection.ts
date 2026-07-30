import sql from 'mssql';
import { ConnectionConfig } from './types.js';

export class SqlServerConnection {
  private pool: sql.ConnectionPool | null = null;
  private config: ConnectionConfig;

  constructor(config: ConnectionConfig) {
    this.config = config;
  }

  async connect(): Promise<void> {
    if (this.pool?.connected) return;

    const sqlConfig: any = {
      server: this.config.server,
      database: this.config.database,
      port: this.config.port,
      options: {
        encrypt: this.config.encrypt,
        trustServerCertificate: this.config.trustServerCertificate,
        connectTimeout: this.config.connectionTimeout,
      },
    };

    if (this.config.authentication === 'windows') {
      sqlConfig.authentication = { type: 'windows' };
    } else {
      sqlConfig.user = this.config.user;
      sqlConfig.password = this.config.password;
    }

    this.pool = new sql.ConnectionPool(sqlConfig);
    await this.pool.connect();
  }

  async disconnect(): Promise<void> {
    if (this.pool) {
      await this.pool.close();
      this.pool = null;
    }
  }

  async query<T = any>(queryText: string): Promise<T[]> {
    if (!this.pool?.connected) {
      throw new Error('Not connected to database');
    }

    const request = this.pool.request();
    const result = await request.query(queryText);
    const recordset = Array.isArray(result.recordsets) ? result.recordsets[0] : result.recordset;
    return (recordset || []) as T[];
  }

  async testConnection(): Promise<boolean> {
    try {
      await this.connect();
      await this.query('SELECT 1 as test');
      return true;
    } catch {
      return false;
    }
  }

  isConnected(): boolean {
    return this.pool?.connected ?? false;
  }
}

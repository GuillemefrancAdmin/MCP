import { z } from 'zod';

export const ConnectionConfigSchema = z.object({
  server: z.string().min(1, 'Server is required'),
  database: z.string().optional(),
  user: z.string().optional(),
  password: z.string().optional(),
  port: z.number().int().default(1433),
  encrypt: z.boolean().default(true),
  trustServerCertificate: z.boolean().default(true),
  connectionTimeout: z.number().int().default(30000),
  requestTimeout: z.number().int().default(60000),
  maxRows: z.number().int().positive().default(1000),
  authentication: z.enum(['sql', 'windows']).default('sql'),
});

export type ConnectionConfig = z.infer<typeof ConnectionConfigSchema>;

export interface QueryResult {
  columns: string[];
  rows: any[][];
  rowCount: number;
}

export interface DatabaseInfo {
  name: string;
  state: string;
}

export interface TableInfo {
  table_name: string;
  table_schema: string;
  table_type: string;
}

export interface ColumnInfo {
  column_name: string;
  data_type: string;
  is_nullable: string;
  character_maximum_length: number | null;
}

export interface ForeignKeyInfo {
  constraint_name: string;
  table_name: string;
  column_name: string;
  referenced_table_name: string;
  referenced_column_name: string;
}

export interface TableStats {
  table_name: string;
  row_count: number;
  size_mb: number;
}

import { BaseTool } from './base.js';

export class TestConnectionTool extends BaseTool {
  getName(): string {
    return 'test_connection';
  }

  getDescription(): string {
    return 'Validate SQL Server connection';
  }

  getInputSchema(): any {
    return { type: 'object', properties: {} };
  }

  async execute(): Promise<{ connected: boolean; message: string }> {
    try {
      const isConnected = await this.connection.testConnection();
      return {
        connected: isConnected,
        message: isConnected ? 'Connection successful' : 'Connection failed',
      };
    } catch (error) {
      return {
        connected: false,
        message: `Connection error: ${error instanceof Error ? error.message : String(error)}`,
      };
    }
  }
}
import { BaseTool } from './base.js';

export class GetServerInfoTool extends BaseTool {
  getName(): string {
    return 'get_server_info';
  }

  getDescription(): string {
    return 'Get SQL Server version and configuration information';
  }

  getInputSchema(): any {
    return { type: 'object', properties: {} };
  }

  async execute(): Promise<any> {
    const query = `
      SELECT SERVERPROPERTY('ServerName') as server_name,
             SERVERPROPERTY('ProductVersion') as version,
             SERVERPROPERTY('Edition') as edition,
             SERVERPROPERTY('ProductLevel') as product_level
    `;

    const result = await this.executeSafeQuery(query);
    return result[0] || { error: 'Unable to retrieve server info' };
  }
}
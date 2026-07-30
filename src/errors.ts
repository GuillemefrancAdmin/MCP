export class MCPError extends Error {
  constructor(
    message: string,
    public code: string = 'ERROR'
  ) {
    super(message);
    this.name = 'MCPError';
  }
}

export function handleError(error: unknown): { message: string; code: string } {
  if (error instanceof MCPError) {
    return { message: error.message, code: error.code };
  }
  if (error instanceof Error) {
    return { message: error.message, code: 'ERROR' };
  }
  return { message: String(error), code: 'UNKNOWN_ERROR' };
}

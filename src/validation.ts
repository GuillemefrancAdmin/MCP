export function validateQuery(query: string): boolean {
  if (!query || typeof query !== 'string') return false;

  const trimmed = query.trim().toUpperCase();

  // Block dangerous operations
  const blocklist = ['INSERT', 'UPDATE', 'DELETE', 'DROP', 'CREATE', 'ALTER', 'TRUNCATE', 'EXEC', 'EXECUTE'];
  for (const keyword of blocklist) {
    if (trimmed.startsWith(keyword)) return false;
  }

  // Only allow SELECT, WITH, SHOW, DESCRIBE
  if (!['SELECT', 'WITH', 'SHOW', 'DESCRIBE'].some(kw => trimmed.startsWith(kw))) {
    return false;
  }

  return true;
}

export function validateTableName(name: string): boolean {
  if (!name || typeof name !== 'string') return false;
  return /^[\w\-\.]+$/.test(name) && name.length <= 128;
}

export function validateDatabaseName(name: string): boolean {
  if (!name || typeof name !== 'string') return false;
  return /^[\w\-]+$/.test(name) && name.length <= 128;
}

export function validateSchemaName(name: string): boolean {
  if (!name || typeof name !== 'string') return false;
  return /^[\w\-]+$/.test(name) && name.length <= 128;
}

export function escapeIdentifier(identifier: string): string {
  if (!identifier || typeof identifier !== 'string' || identifier.length > 128) {
    throw new Error('Invalid identifier');
  }
  return `[${identifier.replace(/[\[\]]/g, '')}]`;
}
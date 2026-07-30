# Development Guide

## Project Structure

```
src/
├── index.ts              - MCP server entry point
├── connection.ts         - SQL Server connection management
├── types.ts              - TypeScript type definitions
├── errors.ts             - Error handling
├── validation.ts         - Query and parameter validation
└── tools/
    ├── base.ts           - Base tool class
    ├── test-connection.ts
    ├── list-databases.ts
    ├── list-tables.ts
    ├── list-views.ts
    ├── describe-table.ts
    ├── execute-query.ts
    ├── get-foreign-keys.ts
    ├── get-server-info.ts
    ├── get-table-stats.ts
    └── index.ts          - Tool exports
```

## Build & Development

```bash
# Install dependencies
npm install

# Build TypeScript
npm run build

# Run in development
npm run dev

# Lint code
npm run lint

# Run tests
npm test
```

## Adding New Tools

1. Create `src/tools/my-tool.ts`
2. Extend `BaseTool` class
3. Implement required methods:
   - `getName()` - Tool identifier
   - `getDescription()` - Tool description
   - `getInputSchema()` - JSON Schema for parameters
   - `execute(params)` - Tool logic
4. Export from `src/tools/index.ts`
5. Add to tool list in `src/index.ts`

## Code Standards

- TypeScript strict mode enabled
- No unused imports or variables
- Query validation required
- Error handling for all database operations
- Read-only queries only

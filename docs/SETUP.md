# Setup Guide

## Installation

### Option 1: Global NPM
```bash
npm install -g @bilims/mcp-sqlserver
mcp-sqlserver --help
```

### Option 2: Local Installation
```bash
npm install
npm run build
npm start
```

### Option 3: Docker
```bash
docker build -t mcp-sqlserver:2.0.3 .
docker run -e SQLSERVER_HOST=your-server \
           -e SQLSERVER_USER=username \
           -e SQLSERVER_PASSWORD=password \
           mcp-sqlserver:2.0.3
```

## Configuration

Set environment variables:

```bash
export SQLSERVER_HOST="your-server.database.windows.net"
export SQLSERVER_USER="your-username"
export SQLSERVER_PASSWORD="your-password"
export SQLSERVER_DATABASE="your-database"
export SQLSERVER_ENCRYPT="true"
export SQLSERVER_TRUST_CERT="false"
```

### Optional Variables
- `SQLSERVER_PORT` - Default: 1433
- `SQLSERVER_AUTH` - 'sql' or 'windows' (default: sql)
- `SQLSERVER_CONNECTION_TIMEOUT` - Milliseconds (default: 30000)
- `SQLSERVER_REQUEST_TIMEOUT` - Milliseconds (default: 60000)
- `SQLSERVER_MAX_ROWS` - Default: 1000

## Verify Installation

```bash
mcp-sqlserver --help
```

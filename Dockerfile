FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY src/ ./src/
COPY tsconfig.json ./

# Build the project
RUN npm run build

# Set environment variables for SQL Server connection
ENV SQLSERVER_HOST=db-dev.uqac.ca
ENV SQLSERVER_DATABASE=Sigarebd
ENV SQLSERVER_AUTH=windows
ENV SQLSERVER_ENCRYPT=false
ENV SQLSERVER_TRUST_CERT=true

# Run the MCP server in stdio mode
CMD ["node", "dist/index.js"]

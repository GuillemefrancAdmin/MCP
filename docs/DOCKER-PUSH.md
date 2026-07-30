# Pushing Docker Image to GitHub Container Registry

## Step 1: Create GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Tokens (classic)"
3. Give it a name like "Docker Push Token"
4. Select scopes:
   - ✅ `write:packages` - Push packages
   - ✅ `read:packages` - Pull packages
   - ✅ `delete:packages` - Delete packages (optional)
5. Click "Generate token"
6. **Copy the token** (you won't see it again!)

## Step 2: Login to GitHub Container Registry

### Option A: Interactive Login (Recommended)

```powershell
docker login ghcr.io -u guillemefrancadmin
```

When prompted, paste your GitHub Personal Access Token as the password.

### Option B: Using Environment Variable

```powershell
# Set the token as environment variable
$env:GITHUB_TOKEN = "your_token_here"

# Login via stdin
$env:GITHUB_TOKEN | docker login ghcr.io -u guillemefrancadmin --password-stdin
```

## Step 3: Push the Images

Once authenticated, push the images:

```powershell
# Push version tag
docker push ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3

# Push latest tag
docker push ghcr.io/guillemefrancadmin/mcp-sqlserver:latest
```

## Step 4: Verify Push

Check the push was successful:

```powershell
docker images | findstr "mcp-sqlserver"
```

You should see:
```
ghcr.io/guillemefrancadmin/mcp-sqlserver   2.0.3    <image-id>
ghcr.io/guillemefrancadmin/mcp-sqlserver   latest   <image-id>
```

## Using the Docker Image

### Pull the image

```powershell
docker pull ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3
```

### Run with Windows/AD Authentication

```powershell
docker run -e SQLSERVER_HOST="db-dev.uqac.ca" `
           -e SQLSERVER_AUTH="windows" `
           ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3
```

### Run with SQL Authentication

```powershell
docker run -e SQLSERVER_HOST="localhost" `
           -e SQLSERVER_USER="sa" `
           -e SQLSERVER_PASSWORD="password" `
           -e SQLSERVER_AUTH="sql" `
           ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3
```

### Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  mcp-sqlserver:
    image: ghcr.io/guillemefrancadmin/mcp-sqlserver:2.0.3
    environment:
      SQLSERVER_HOST: db-dev.uqac.ca
      SQLSERVER_AUTH: windows
      SQLSERVER_DATABASE: YourDatabase
    ports:
      - "9000:9000"  # If exposing MCP server port
```

Run with:
```powershell
docker-compose up -d
```

## Troubleshooting

### "denied" error
- Make sure token has `write:packages` scope
- Verify you're logged in: `docker info | findstr "Username"`
- Try logging out first: `docker logout ghcr.io`

### "authentication required" error
- Token may have expired or been revoked
- Create a new token at: https://github.com/settings/tokens

### "repository not found"
- Make sure repository is public or your token has access
- Check image name spelling

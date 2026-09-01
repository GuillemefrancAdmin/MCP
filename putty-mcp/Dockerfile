FROM python:3.11-slim

# PUTTY_MCP_TRANSPORT is intentionally left unset here so the server's own
# default (stdio) applies — required by the Docker MCP Gateway, which
# execs this image and speaks MCP over the container's stdin/stdout.
# compose.yaml overrides these for the standalone Streamable HTTP deployment.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PUTTY_MCP_HOST=0.0.0.0 \
    PUTTY_MCP_PORT=8000

WORKDIR /app

RUN apt-get update \
    && apt-get install --no-install-recommends -y putty-tools openssh-client \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1000 --shell /usr/sbin/nologin mcp

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY putty_mcp.py ./
COPY putty_lib ./putty_lib
COPY config.docker.toml ./config.toml

RUN mkdir -p /data /keys && chown -R mcp:mcp /app /data /keys
USER mcp

# Only relevant for the HTTP deployment path (compose.yaml); the Gateway
# talks stdio and never connects to this port.
EXPOSE 8000

ENTRYPOINT ["python", "putty_mcp.py"]
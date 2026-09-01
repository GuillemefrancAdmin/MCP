FROM rust:1.92-bookworm AS builder

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY crates ./crates
COPY vendor ./vendor

RUN cargo build --release --locked -p pdf-reader-mcp-server

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install --no-install-recommends -y ca-certificates curl libssl3 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --create-home --uid 10001 citra

COPY --from=builder /app/target/release/citra-mcp-server /usr/local/bin/citra-mcp-server

USER citra
WORKDIR /documents

# MCP_TRANSPORT is intentionally left unset here so the server's own default
# (stdio) applies — required by the Docker MCP Gateway, which execs this
# image and speaks MCP over the container's stdin/stdout. compose.yaml sets
# MCP_TRANSPORT=http to override this for the standalone HTTP deployment.
ENV MCP_HTTP_HOST=0.0.0.0 \
    MCP_HTTP_PORT=3000 \
    MCP_PDF_ALLOWED_DIRS=/documents

# Only relevant for the HTTP deployment path (compose.yaml); the Gateway
# talks stdio and never connects to this port.
EXPOSE 3000

ENTRYPOINT ["citra-mcp-server"]
# syntax=docker/dockerfile:1.7

# ---- builder ----------------------------------------------------------------
FROM rust:1.81-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        pkg-config libssl-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Pre-cache deps
COPY Cargo.toml Cargo.lock* ./
RUN mkdir -p src \
    && echo 'fn main() {}' > src/main.rs \
    && echo '' > src/lib.rs \
    && cargo fetch

COPY . .

ENV SQLX_OFFLINE=true
RUN cargo build --release --bin unii-server

# ---- runtime ----------------------------------------------------------------
FROM gcr.io/distroless/cc-debian12 AS runtime

WORKDIR /app
COPY --from=builder /app/target/release/unii-server /app/unii-server
COPY --from=builder /app/migrations /app/migrations

EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/app/unii-server"]

# syntax=docker/dockerfile:1

# Sample Dockerfile for a Golang project

# ==================================================================
# Build Layer
# ==================================================================

FROM golang:latest AS build

WORKDIR /app

# --- Put your project's build commands here
COPY src/go.mod ./
RUN go mod download
COPY src/ .
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -o /app/main .
# ---
  
# ==================================================================
# Final Layer
# ==================================================================

FROM debian:stable-slim AS final

# Create non-root user
ARG APP_USER="user"
ARG APP_UID="10001"
ARG APP_GID="10001"
RUN <<EOT
    groupadd --gid $APP_GID $APP_USER
    useradd --uid $APP_UID --gid $APP_GID --create-home --shell /bin/false $APP_USER
EOT

# --- Add any required system packages
RUN <<EOT
    set -e
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOT

WORKDIR /app

# Copy the compiled binary from the 'build' stage.
COPY --from=build /app/main /app/main

# OPTIONAL: Grant user write permission to /app folder.
# RUN chown -R ${APP_USER} /app/*

# Set the non-root user as the active user.
USER ${APP_USER}

# Set the entrypoint for the container to run the compiled application.
ENTRYPOINT ["/app/main"]
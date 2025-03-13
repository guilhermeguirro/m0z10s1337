# Use a minimal base image
FROM alpine:3.18

# Add metadata labels
LABEL maintainer="Guilherme Guirro <guilherme.guirro@example.com>"
LABEL org.opencontainers.image.source="https://github.com/guilhermeguirro/chaos-engineering"
LABEL org.opencontainers.image.description="Kubernetes Chaos Engineering Toolkit"
LABEL org.opencontainers.image.licenses="MIT"

# Install required packages
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    kubectl \
    make \
    openssl \
    && rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1000 chaosuser && \
    adduser -u 1000 -G chaosuser -s /bin/bash -D chaosuser

# Set working directory
WORKDIR /app

# Copy scripts and manifests
COPY --chown=chaosuser:chaosuser scripts/ /app/scripts/
COPY --chown=chaosuser:chaosuser manifests/ /app/manifests/
COPY --chown=chaosuser:chaosuser Makefile /app/

# Make scripts executable
RUN chmod +x /app/scripts/*.sh

# Set secure permissions
RUN chmod -R 750 /app/scripts && \
    chmod -R 640 /app/manifests

# Switch to non-root user
USER chaosuser

# Set environment variables
ENV PATH="/app/scripts:${PATH}"

# Default command
ENTRYPOINT ["make"]
CMD ["help"] 
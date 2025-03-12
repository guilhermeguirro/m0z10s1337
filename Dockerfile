# Build stage
FROM node:18-alpine AS build

WORKDIR /app

# Copy package files and install dependencies
COPY app/package*.json ./
RUN npm ci --only=production

# Copy application code
COPY app/ ./

# Build the application
RUN npm run build

# Production stage
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install production dependencies only
COPY --from=build /app/package*.json ./
RUN npm ci --only=production

# Copy built application from build stage
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules

# Create non-root user
RUN addgroup -g 1000 chaosuser && \
    adduser -u 1000 -G chaosuser -s /bin/sh -D chaosuser && \
    chown -R chaosuser:chaosuser /app

# Set environment variables
ENV NODE_ENV=production \
    PORT=8080 \
    GRPC_PORT=9090

# Expose HTTP and gRPC ports
EXPOSE 8080 9090

# Switch to non-root user
USER chaosuser

# Set health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q -O - http://localhost:8080/health || exit 1

# Run the application
CMD ["node", "dist/index.js"] 
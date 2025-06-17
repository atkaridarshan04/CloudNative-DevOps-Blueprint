# ────────────── Stage 1: Build ──────────────
FROM node:20-alpine3.20 AS builder
WORKDIR /app

# Install dependencies 
COPY package.json package-lock.json ./
RUN npm ci

# Copy source files and build
COPY . .

COPY .env.docker .env
RUN npm run build

# ────────────── Stage 2: Serve ──────────────
FROM nginx:stable-alpine

# Create a non-root user
RUN addgroup -g 1001 appuser && \
    adduser -u 1001 -G appuser -s /bin/sh -D appuser

# Copy static files
COPY --from=builder /app/dist /usr/share/nginx/html

# Set correct ownership and permissions ( Nginx needs to read and write to these directories)
RUN chown -R appuser:appuser /usr/share/nginx/html && \
    chown -R appuser:appuser /var/cache/nginx && \
    chown -R appuser:appuser /var/log/nginx && \
    chown -R appuser:appuser /etc/nginx/conf.d && \
    mkdir -p /var/run && \
    touch /var/run/nginx.pid && \
    chown appuser:appuser /var/run/nginx.pid && \
    chmod -R 777 /etc/nginx/conf.d

# Switch to non-root
USER appuser

EXPOSE 80

ENTRYPOINT ["nginx", "-g", "daemon off;"]

# Multi-stage build for production
# Cache bust: 2025-07-03 - Fix prisma migrations manual directory issue
FROM oven/bun:1 AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Copy package files and prisma schema
COPY package.json bun.lock* ./
COPY prisma ./prisma
RUN bun install --frozen-lockfile

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app

# Install OpenSSL for Prisma
# The oven/bun:1 image is based on Debian, so use apt-get
RUN apt-get update -y && apt-get install -y openssl libssl-dev && apt-get clean

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Generate Prisma client
RUN bun prisma generate

# Build the application
ENV NEXT_TELEMETRY_DISABLED=1
RUN bun run build

# Production image, copy all the files and run next
FROM node:20-alpine AS runner
WORKDIR /app

# Install OpenSSL for Prisma compatibility and Node/npm for migrations
RUN apk add --no-cache openssl nodejs npm

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Create a directory for logs with proper permissions
RUN mkdir -p /tmp/logs && chown nextjs:nodejs /tmp/logs
ENV LOG_DIR=/tmp/logs

# Copy built application
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Copy prisma schema and generated client
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma

# Install Prisma CLI for migrations (as root before switching to nextjs user)
RUN npm install -g prisma@6.10.1

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
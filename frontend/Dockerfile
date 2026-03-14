# ── Stage 1: node builder ─────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /build

# Copy package files first — Docker caches this layer
# so npm install only reruns when dependencies change
COPY package.json package-lock.json* ./

RUN npm ci --frozen-lockfile

# Copy source and build
COPY . .

# VITE_API_URL is intentionally NOT set at build time.
# The Vite proxy handles /api routing at runtime — no hardcoded URLs in the bundle.
RUN npm run build


# ── Stage 2: nginx static server ──────────────────────────────────────────────
FROM nginx:1.27-alpine AS runtime

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy our custom nginx config
COPY nginx.conf /etc/nginx/conf.d/app.conf

# Copy the built React app from builder stage
COPY --from=builder /build/dist /usr/share/nginx/html

# Security: nginx runs as non-root (nginx user already exists in the base image)
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
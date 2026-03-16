# ── Stage 1: node builder ─────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /build

COPY package.json package-lock.json* ./
RUN npm ci --frozen-lockfile

COPY . .
RUN npm run build


# ── Stage 2: nginx static server ──────────────────────────────────────────────
FROM nginx:1.27-alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/app.conf
COPY --from=builder /build/dist /usr/share/nginx/html

# Fix all permission issues for rootless nginx in one layer:
# 1. Move nginx.pid to /tmp (writable by all users)
# 2. Remove the "user nginx;" directive (irrelevant when not root)
# 3. Fix ownership on all dirs nginx needs to write to
RUN sed -i 's|pid\s*/run/nginx.pid;|pid /tmp/nginx.pid;|' /etc/nginx/nginx.conf && \
    sed -i '/^user /d' /etc/nginx/nginx.conf && \
    chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chmod -R 755 /var/cache/nginx

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
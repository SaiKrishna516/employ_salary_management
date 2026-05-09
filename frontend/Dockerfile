# ──────────────────────────────────────────────────────────────────────────────
# Stage 1: build React app with Vite
# ──────────────────────────────────────────────────────────────────────────────
FROM node:20-alpine AS build

WORKDIR /app

# Install dependencies — cached unless package-lock.json changes
COPY package.json package-lock.json ./
RUN npm ci

# Pass the API URL at build time (Vite bakes it into the JS bundle)
ARG VITE_API_BASE_URL=http://localhost:3001/api/v1
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

COPY . .

# constants.json is committed and already present — Vite will bundle it.
# The Rails initializer will regenerate it when the backend boots.
RUN npm run build

# ──────────────────────────────────────────────────────────────────────────────
# Stage 2: serve static files with nginx
# ──────────────────────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine AS production

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

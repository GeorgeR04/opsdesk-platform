FROM node:20-bookworm-slim
WORKDIR /app

# Install deps (lockfile REQUIRED)
COPY apps/frontend/package.json apps/frontend/package-lock.json ./
RUN npm ci

# Copy app + run tests
COPY apps/frontend/ ./
RUN npm test

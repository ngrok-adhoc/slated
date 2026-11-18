# syntax=docker/dockerfile:1

# Keep in step with .github/workflows/ci.yml and .agents/setup.
# @ngrok/app-server needs Node 26.
FROM node:26.13.1-slim AS base
WORKDIR /app

# Build stage. Node 25+ ships no corepack, so install the pnpm version that
# package.json's "packageManager" pins with npm.
FROM base AS build
COPY package.json pnpm-lock.yaml ./
RUN npm install --global "pnpm@$(node -p 'require("./package.json").packageManager.split("@")[1].split("+")[0]')" \
    && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

# Runtime image. The `appServer` Vite plugin bundles the dependencies into the
# server build, so the build directory runs with no node_modules.
FROM base AS runtime
ENV NODE_ENV=production
# The server listens on $PORT (default 3000). LINEAR_API_KEY is provided at
# runtime via the environment, not baked into the image.
ENV PORT=3000
EXPOSE 3000
COPY --from=build /app/build ./build
USER node
CMD ["node", "build/server/app-server.js"]

FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

# Prune dev dependencies after build
RUN npm prune --production

FROM node:20-alpine AS production

WORKDIR /app

# Copy package files for reference
COPY package*.json ./

# Copy production node_modules from build stage
COPY --from=build /app/node_modules ./node_modules

# Copy built application
COPY --from=build /app/dist ./dist
COPY --from=build /app/scripts ./scripts

ENV NODE_ENV=production
ENV PORT=3001
ENV DATABASE_URL=mongodb://admin:password@database:27017/compta_db?authSource=admin
ENV JWT_SECRET=default_jwt_secret_key_replace_in_production

EXPOSE 3001

CMD ["node", "dist/server.js"]

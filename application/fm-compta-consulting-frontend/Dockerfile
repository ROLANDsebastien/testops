FROM node:20-alpine AS build

ARG NEXT_PUBLIC_API_URL_ARG
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL_ARG}

ARG NEXTAUTH_URL_ARG
ENV NEXTAUTH_URL=${NEXTAUTH_URL_ARG}

ARG NEXTAUTH_SECRET_ARG
ENV NEXTAUTH_SECRET=${NEXTAUTH_SECRET_ARG}

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

# Clean potential Next.js cache before building
RUN rm -rf .next
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
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/next.config.js ./
COPY --from=build /app/next-i18next.config.js ./

ENV NODE_ENV=production
ENV PORT=3000
ENV NEXTAUTH_URL=${NEXTAUTH_URL}
ENV NEXTAUTH_SECRET=${NEXTAUTH_SECRET}

EXPOSE 3000
CMD ["npm", "start"]

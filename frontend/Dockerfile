FROM node:20-alpine AS builder

WORKDIR /build

COPY package.json .
RUN npm install

COPY . .
RUN npm run build

FROM nginx:alpine

RUN addgroup -S pitaya && adduser -S pitaya -G pitaya

COPY --from=builder /build/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

USER pitaya

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:80/ || exit 1

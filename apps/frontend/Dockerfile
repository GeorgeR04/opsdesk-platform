# ---- build ----
FROM node:20-bookworm-slim AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ---- runtime ----
FROM nginx:1.27-alpine

# On vire toute conf par défaut
RUN rm -f /etc/nginx/conf.d/default.conf

# Copie du nginx.conf global (celui au-dessus)
COPY nginx.conf /etc/nginx/nginx.conf

# Front build
COPY --from=build /app/dist /usr/share/nginx/html

# User non-root numérique (important pour Kubernetes runAsNonRoot)
RUN addgroup -S -g 10001 app \
 && adduser  -S -D -H -u 10001 -G app app \
 # On donne accès aux dossiers nécessaires, mais nginx écrira en /tmp
 && chown -R 10001:10001 /usr/share/nginx/html /etc/nginx \
 && chmod -R g=u /usr/share/nginx/html /etc/nginx

USER 10001:10001
EXPOSE 8080

ENV NGINX_ENTRYPOINT_QUIET_LOGS=1

CMD ["nginx", "-g", "daemon off;"]

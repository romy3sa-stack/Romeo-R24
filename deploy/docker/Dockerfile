# Receipt24 static web server — serves consumer, accountant, and admin builds.
# Build: docker build -f deploy/docker/Dockerfile -t receipt24-web .
# Run:   docker run -p 8080:80 receipt24-web

FROM nginx:1.27-alpine

COPY deploy/nginx/nginx.conf /etc/nginx/nginx.conf

# Expect pre-built Flutter web artifacts copied into the image by CI.
COPY build/web/consumer /var/www/consumer
COPY build/web/accountant /var/www/accountant
COPY build/web/admin /var/www/admin

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://127.0.0.1/ || exit 1

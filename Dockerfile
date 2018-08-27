FROM nginx:1.15.2-alpine
LABEL Description="Nod32 updates mirror"

COPY ./nginx/html /usr/share/nginx/html-docker
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx/entrypoint.sh /nginx-extrypoint.sh
COPY ./scheduler/entrypoint.sh /scheduler-entrypoint.sh
COPY ./src /src

RUN \
  apk --update add bash curl wget grep sed apache2-utils unrar findutils \
  && rm -Rfv /usr/share/nginx/html \
  && mv /usr/share/nginx/html-docker /usr/share/nginx/html \
  && chown -R 'nginx:nginx' /usr/share/nginx/html \
  && mkdir -pv /data \
  && find /src -type f -name '*.sh' -exec chmod +x {} \; \
  && chmod +x /*.sh

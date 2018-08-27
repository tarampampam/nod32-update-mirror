FROM nginx:1.15.2-alpine
LABEL Description="Nod32 updates mirror"

COPY . /docker

RUN \
  rm -Rfv /usr/share/nginx/html && mv -v /docker/nginx/html /usr/share/nginx/html \
  && chown -R 'nginx:nginx' /usr/share/nginx/html \
  && mv -vf /docker/nginx/nginx.conf /etc/nginx/nginx.conf \
  && mv -vf /docker/nginx/entrypoint.sh /nginx-extrypoint.sh \
  && mv -vf /docker/scheduler/entrypoint.sh /scheduler-entrypoint.sh \
  && rm -Rfv /src && mv -v /docker/src /src \
  && rm -Rfv /docker \
  && mkdir -pv /data \
  && find /src -type f -name '*.sh' -exec chmod +x {} \; \
  && chmod +x /*.sh \
  && apk --update add bash curl wget grep sed apache2-utils unrar findutils \
  && rm -rf /var/cache/apk/*

WORKDIR /src
VOLUME ["/data"]
ENTRYPOINT ["/src/nod32-mirror.sh"]

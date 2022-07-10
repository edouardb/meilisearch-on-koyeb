FROM alpine:latest

RUN apk add --update --quiet --no-cache supervisor rclone
RUN echo '*/5 * * * * /meilisearch-on-koyeb/meilisearch-sync.sh >/proc/1/fd/1 2>&1' > /etc/crontabs/root
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisord.conf

WORKDIR /meilisearch-on-koyeb
COPY --from=getmeili/meilisearch:latest /bin/meilisearch ./meilisearch
COPY --from=koyeb/koyeb-cli:latest /koyeb ./koyeb
COPY docker-entrypoint.sh ./docker-entrypoint.sh
COPY meilisearch-sync.sh ./meilisearch-sync.sh
RUN mkdir ./snapshots
RUN touch $HOME/.koyeb.yaml

ENV MEILI_HTTP_ADDR=0.0.0.0:7700
EXPOSE 7700/tcp

ENTRYPOINT ["/meilisearch-on-koyeb/docker-entrypoint.sh"]

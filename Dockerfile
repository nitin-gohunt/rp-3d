FROM nginx

EXPOSE 80
EXPOSE 81
EXPOSE 443
EXPOSE 6443
EXPOSE 7443
EXPOSE 8080
EXPOSE 8081
EXPOSE 8443
EXPOSE 10443

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/
RUN rm /etc/nginx/conf.d/default.conf

RUN mkdir -p /data/nginx/cache

COPY ./scripts/docker_entrypoint.sh /tmp/entrypoint.sh
RUN chmod +x /tmp/entrypoint.sh

ENTRYPOINT ["/tmp/entrypoint.sh"]
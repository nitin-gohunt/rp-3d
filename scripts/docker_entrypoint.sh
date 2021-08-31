#!/bin/bash

if [ $ENVIRONMENT == "production" ]; then
  NGINX_ADDITIONAL_CONFIG='access_log off;'
else
  NGINX_ADDITIONAL_CONFIG="access_log /var/log/nginx/access.log;
                           access_log /var/log/nginx/cache.log cache_st;
                           access_log /var/log/nginx/proxy.log upstream_logging;"
fi
nginx -g $NGINX_ADDITIONAL_CONFIG
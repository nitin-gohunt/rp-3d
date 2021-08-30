#!/bin/bash

sed -i "s/{{ENVIRONMENT}}/${ENVIRONMENT}/g" /usr/share/nginx/html/index.html

nginx -g 'daemon off;'
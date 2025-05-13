#!/bin/sh

# Recreate config file
envsubst < /usr/share/nginx/html/env-config.js.template > /usr/share/nginx/html/env-config.js

# Run nginx
exec "$@"

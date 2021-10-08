#!/usr/bin/env bash
set -e

env=${APP_ENV:-production}
role=${CONTAINER_ROLE:-api}

if [ "$env" != "local"  ]; then
    echo "Caching configuration..."
    (
        cd /var/www/html \
        && /usr/local/bin/php artisan config:cache \
        && /usr/local/bin/php artisan route:cache \
        && /usr/local/bin/php artisan view:cache \
        && echo ''
    )
fi

if [ "${role}" = "api" ]; then
    /usr/local/sbin/php-fpm --nodaemonize

elif [ "${role}" = "worker" ]; then
    echo "Running the queue..."
    /usr/local/bin/php /var/www/html/artisan queue:work \
        --verbose \
        --tries=3 \
        --timeout=600

elif [ "${role}" = "scheduler" ]; then
    echo "Running the scheduler..."
    /usr/local/bin/php /var/www/html/artisan schedule:run

else
    echo "Unknown container role '${role}'"
    exit 1

fi

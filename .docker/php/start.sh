#!/bin/bash
set -e

# Always run config:cache
#/usr/local/bin/php /var/www/artisan config:cache

role=${CONTAINER_ROLE:-api}

if [ "${role}" = "api" ]; then
    php-fpm

elif [ "${role}" = "worker" ]; then
    echo "Running the queue..."
    /usr/local/bin/php /var/www/artisan queue:work \
        --verbose \
        --tries=3 \
        --timeout=600

elif [ "${role}" = "scheduler" ]; then
    echo "Running the scheduler..."
    /usr/local/bin/php /var/www/artisan schedule:run

else
    echo "Unknown container role '${role}'"
    exit 1

fi

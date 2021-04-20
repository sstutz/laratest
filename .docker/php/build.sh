#!/usr/bin/env bash

dirs=(
    bootstrap/cache
    storage/app
    storage/framework
    storage/framework/cache
    storage/framework/sessions
    storage/framework/views
    storage/framework/proxies
    storage/logs
)

for dir in "${dirs[@]}"; do
    if [ ! -e "$dir" ]; then
        mkdir -vp "$dir"
    fi

    chown -R :www-data "$dir"
    chmod -R 775 "$dir"
done

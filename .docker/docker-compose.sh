#!/usr/bin/env bash

pushd "${0%/*}" 1>/dev/null

# Default environment is production
export APP_ENV=${APP_ENV:-prod}
export VERSION=$(git rev-parse --short HEAD)
export APP_NAME="hello_world"
export APP_IMAGE="gcr.io/laravel/$APP_NAME:$VERSION"

# MySQL defaults
export DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-secret}
export DB_DATABASE=${DB_DATABASE:-portal}
export DB_USER=${DB_USER:-portal}
export DB_PASSWORD=${DB_PASSWORD:-secret}

# Make sure docker will not create volumes unless they don't exist
ensure_volume() {
    if ! docker volume inspect "$1" > /dev/null 2>&1; then
        docker volume create --name="$1" > /dev/null
        echo "$1 successfully created"
    fi
}

ensure_volume "portal_database"

if [ $# -gt 0 ]; then
    docker-compose "$@"
else
    docker-compose ps
fi

popd 1>/dev/null

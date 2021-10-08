all:
    BUILD +backend
    BUILD +frontend
    BUILD +app
    BUILD +unit-test
    BUILD +it-test

download-composer:
    FROM composer:2
    SAVE ARTIFACT /usr/bin/composer composer

base-image:
    FROM php:8.1.0RC3-fpm-alpine3.14
    ENV PHP_EXT_DIR /usr/local/lib/php/extensions/no-debug-non-zts-20210902
    ENV COMPOSER_CACHE_DIR /composer-cache
    RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/main bash \
        mpdecimal vim curl libpng libjpeg-turbo freetype libzip libxml2 icu shadow libpq
    RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
    COPY +download-composer/composer /usr/local/bin/composer
    COPY .docker/php/build.sh .
    RUN bash ./build.sh && rm ./build.sh

extension-build:
    FROM +base-image
    RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/main \
        $PHPIZE_DEPS coreutils mpdecimal libpng-dev libjpeg-turbo-dev  \
        freetype-dev libzip-dev libxml2-dev icu-dev mpdecimal-dev postgresql-dev
    RUN pecl install decimal-1.4.0 xdebug-3.1.0 ast-1.0.14 pcov-1.0.9 \
        && docker-php-ext-configure gd --with-freetype --with-jpeg \
        && docker-php-ext-install pdo_mysql pgsql pdo_pgsql zip soap intl gd
    SAVE ARTIFACT $PHP_EXT_DIR $PHP_EXT_DIR

update-depedencies:
    FROM +extension-build
    COPY composer.json composer.lock ./
    RUN --mount=type=cache,target=/composer-cache composer update \
        --no-interaction \
        --no-ansi \
        --prefer-dist \
        --no-scripts \
        --no-autoloader
    SAVE ARTIFACT composer.lock AS LOCAL composer.lock

backend:
    FROM +extension-build
    COPY composer.json composer.lock ./
    RUN --mount=type=cache,target=/composer-cache composer install \
        --no-dev \
        --no-interaction \
        --no-ansi \
        --prefer-dist \
        --no-scripts \
        --no-autoloader \
        --no-progress
    SAVE ARTIFACT vendor /dist/vendor

frontend:
    FROM node:alpine3.14
    WORKDIR /var/www/html
    COPY package*.json ./
    RUN npm ci \
        --no-optional \
        --no-dev
    COPY . ./
    RUN npm run prod
    SAVE ARTIFACT public/css/app.css /dist/app.css AS LOCAL ./public/css/app.css
    SAVE ARTIFACT public/js/app.js /dist/app.js AS LOCAL ./public/js/app.js

inter-image:
    FROM +base-image
    WORKDIR /var/www/html
    COPY .docker/php/conf.d/ $PHP_INI_DIR/conf.d/
    COPY +extension-build/$PHP_EXT_DIR $PHP_EXT_DIR

prod-image:
    FROM +inter-image
    COPY +backend/dist/vendor vendor

app:
    FROM +prod-image
    COPY +frontend/dist/app.css public/js/app.css
    COPY +frontend/dist/app.js public/js/app.css
    COPY . /var/www/html
    COPY .docker/php/start.sh /usr/local/bin/start
    RUN composer dump-autoload --optimize \
        && chmod u+x /usr/local/bin/start
    CMD ["/usr/local/bin/start"]
    SAVE IMAGE example:latest

test-image:
    FROM +inter-image
    RUN apk add --no-cache docker docker-compose postgresql-client
    COPY composer.json composer.lock .
    RUN --mount=type=cache,target=/composer-cache composer install \
        --ignore-platform-reqs \
        --no-interaction \
        --no-ansi \
        --no-scripts \
        --no-autoloader \
        --no-progress
    COPY . /var/www/html
    RUN composer dump-autoload --optimize
    SAVE IMAGE tmp:latest

unit-test:
    FROM +test-image
    RUN php artisan test --testsuite=Unit

it-test:
    FROM +test-image
    WITH DOCKER \
        --compose .docker/docker-compose.yml \
        --service ingress \
        --service db
        RUN while ! pg_isready --host=127.0.0.1 --port=5432 --quiet; do sleep 1; done; \
         php artisan test --testsuite=Feature
    END

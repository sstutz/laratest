FROM php:8.1.0RC3-fpm-alpine3.14 AS base
ARG ENVIRONMENT=production

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/main bash \
    mpdecimal vim curl libpng libjpeg-turbo freetype libzip libxml2 icu shadow
RUN mv "$PHP_INI_DIR/php.ini-${ENVIRONMENT}" "$PHP_INI_DIR/php.ini"

# keep in mind for private packages
# RUN mkdir ~/.ssh \
#     && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config

FROM base AS phpbuild
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/main \
    $PHPIZE_DEPS coreutils mpdecimal libpng-dev libjpeg-turbo-dev  \
    freetype-dev libzip-dev libxml2-dev icu-dev mpdecimal-dev postgresql-dev

RUN pecl install decimal-1.4.0 xdebug-3.0.4 ast-1.0.14 pcov-1.0.9 \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql pdo_pqsql pgsql zip soap intl gd

FROM composer:2 as backend
COPY composer.json composer.lock ./
RUN composer install \
    --ignore-platform-reqs \
    --no-dev \
    --no-interaction \
    --no-ansi \
    --prefer-dist \
    --no-scripts \
    --no-autoloader \
    && rm -rf /root/.composer

FROM node:alpine3.14 AS frontend
WORKDIR /var/www/html
COPY package*.json ./
RUN npm ci \
    --no-optional \
    --no-dev

COPY . ./
RUN npm run production

FROM base AS release
WORKDIR /var/www/html
COPY .docker/php/conf.d/ $PHP_INI_DIR/conf.d/
COPY .docker/php/start.sh /usr/local/bin/start
COPY .docker/php/build.sh .

COPY --from=phpbuild \
    /usr/local/lib/php/extensions/no-debug-non-zts-20210902 \
    /usr/local/lib/php/extensions/no-debug-non-zts-20210902

COPY --from=backend \
    /usr/bin/composer \
    /usr/bin/composer

COPY --from=backend \
    /app/vendor \
    /var/www/html/vendor

COPY --from=frontend \
    /var/www/html/public/js /var/www/html/public/css \
    /var/www/html/public/

RUN bash ./build.sh && rm ./build.sh
COPY . /var/www/html

RUN composer dump-autoload --optimize \
    && chmod u+x /usr/local/bin/start \
    # && php artisan doctrine:generate:proxies -q \
    && echo ''

CMD ["/usr/local/bin/start"]

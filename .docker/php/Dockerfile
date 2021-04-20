FROM php:8.0.2-fpm-alpine3.13 AS base

RUN apk add --no-cache bash vim curl libpng libjpeg-turbo freetype libzip libxml2 icu wkhtmltopdf shadow \
     && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/main mpdecimal
# keep in mind for private packages
# RUN mkdir ~/.ssh && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config
ARG ENVIRONMENT=production
RUN mv "$PHP_INI_DIR/php.ini-${ENVIRONMENT}" "$PHP_INI_DIR/php.ini"

FROM base AS phpbuild
RUN apk add --no-cache $PHPIZE_DEPS coreutils libpng-dev libjpeg-turbo-dev freetype-dev libzip-dev libxml2-dev icu-dev \
     && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/main mpdecimal-dev
RUN pecl install decimal-1.4.0 xdebug-3.0.3 ast-1.0.10 pcov-1.0.6
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql zip soap intl gd

FROM base as deps
RUN apk add --no-cache coreutils
RUN echo "$(curl -sS https://composer.github.io/installer.sig) -" > setup.php.sig \
    && curl -sS https://getcomposer.org/installer \
        | tee setup.php \
        | sha384sum -c setup.php.sig \
    && php setup.php --install-dir=/usr/bin --filename=composer \
    && rm setup.php setup.php.sig;

COPY composer.json composer.lock /var/www/html/
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-ansi \
    --prefer-dist \
    --no-scripts \
    --no-autoloader \
    && rm -rf /root/.composer

FROM node:alpine3.13 AS frontend
WORKDIR /var/www/html
COPY package*.json ./
RUN yarn install \
    --frozen-lockfile \
    --ignore-optional \
    --non-interactive
COPY . ./
RUN yarn production

FROM base AS release
COPY .docker/php/conf.d/ $PHP_INI_DIR/conf.d/
COPY .docker/php/start.sh /usr/local/bin/start
COPY .docker/php/build.sh .

COPY --from=phpbuild \
    /usr/local/lib/php/extensions/no-debug-non-zts-20200930 \
    /usr/local/lib/php/extensions/no-debug-non-zts-20200930

COPY --from=deps \
    /usr/bin/composer \
    /usr/bin/composer

COPY --from=deps \
    /var/www/html/vendor \
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

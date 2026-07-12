# syntax = docker/dockerfile:1

ARG NODE_VERSION=20
ARG PHP_VERSION=8.2

# ============================================
# Node build stage — Viteアセットのビルド専用
# 成果物(public/build)だけを本番イメージへ渡し、Node本体は残さない
# ============================================
FROM node:${NODE_VERSION}-slim AS node_build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# manifest.json の存在を検証する（ビルド失敗を静かに通過させず、ここで必ず落とす）
RUN npm run build && test -f public/build/manifest.json

# ============================================
# PHP base stage — 本番ランタイム
# ============================================
FROM ubuntu:22.04 AS base
LABEL fly_launch_runtime="laravel"
ARG PHP_VERSION
ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    COMPOSER_MAX_PARALLEL_HTTP=24 \
    PHP_PM_MAX_CHILDREN=10 \
    PHP_PM_START_SERVERS=3 \
    PHP_MIN_SPARE_SERVERS=2 \
    PHP_MAX_SPARE_SERVERS=4 \
    PHP_DATE_TIMEZONE=UTC \
    PHP_DISPLAY_ERRORS=Off \
    PHP_ERROR_REPORTING=22527 \
    PHP_MEMORY_LIMIT=256M \
    PHP_MAX_EXECUTION_TIME=90 \
    PHP_POST_MAX_SIZE=100M \
    PHP_UPLOAD_MAX_FILE_SIZE=100M \
    PHP_ALLOW_URL_FOPEN=Off
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY .fly/php/ondrej_ubuntu_php.gpg /etc/apt/trusted.gpg.d/ondrej_ubuntu_php.gpg
ADD .fly/php/packages/${PHP_VERSION}.txt /tmp/php-packages.txt
RUN apt-get update \
    && apt-get install -y --no-install-recommends gnupg2 ca-certificates git-core curl zip unzip \
    rsync vim-tiny htop sqlite3 nginx supervisor cron \
    && ln -sf /usr/bin/vim.tiny /etc/alternatives/vim \
    && ln -sf /etc/alternatives/vim /usr/bin/vim \
    && echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ondrej-ubuntu-php-focal.list \
    && apt-get update \
    && apt-get -y --no-install-recommends install $(cat /tmp/php-packages.txt) \
    && ln -sf /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm \
    && mkdir -p /var/www/html/public && echo "index" > /var/www/html/public/index.php \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*
COPY .fly/nginx/ /etc/nginx/
COPY .fly/fpm/ /etc/php/${PHP_VERSION}/fpm/
COPY .fly/supervisor/ /etc/supervisor/
COPY .fly/entrypoint.sh /entrypoint
COPY .fly/start-nginx.sh /usr/local/bin/start-nginx
RUN chmod 754 /usr/local/bin/start-nginx

COPY . /var/www/html
# Nodeステージでビルドしたアセットを取り込む
COPY --from=node_build /app/public/build /var/www/html/public/build
WORKDIR /var/www/html

RUN composer install --optimize-autoloader --no-dev

# optimize:clear は置かない（.env/ローカルキャッシュは.dockerignoreで除外済みのクリーンイメージ。
# 実行するとcache:clearがDB接続を要求してビルドが落ちる）
RUN mkdir -p storage/logs storage/framework/cache/data storage/framework/sessions storage/framework/views bootstrap/cache

# chown は単独RUNにする（前段の失敗でスキップされると www-data が書き込めず全リクエスト500になる）
RUN chown -R www-data:www-data /var/www/html

RUN echo "MAILTO=\"\"\n* * * * * www-data /usr/bin/php /var/www/html/artisan schedule:run" > /etc/cron.d/laravel; \
    if [ -d .fly ]; then cp .fly/entrypoint.sh /entrypoint; chmod +x /entrypoint; fi;

EXPOSE 8080
ENTRYPOINT ["/entrypoint"]
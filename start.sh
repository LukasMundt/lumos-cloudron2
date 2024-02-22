#!/bin/bash

set -eu

mkdir -p /run/lumos /run/lumos/sessions

readonly ARTISAN="sudo -E -u www-data php /app/code/artisan"

if [[ ! -f /app/data/.cr ]]; then
    echo "=> First run"
    mkdir -p /app/data/storage
    cp -R /app/code/storage.template/* /app/data/storage
    cp /app/code/.env.prod-cloudron /app/data/env

    chown -R www-data:www-data /run/lumos /app/data

    echo "=> Generating app key"
    $ARTISAN key:generate --force --no-interaction

    echo "=> Run migrations and seed database"
    # $ARTISAN lumos:install
    $ARTISAN migrate --seed --force

    # echo "=> Create the access tokens required for the API"
    # $ARTISAN passport:keys --force
    # $ARTISAN passport:client --personal --no-interaction

    touch /app/data/.cr
else
    echo "=> Existing installation. Running migration script"
    chown -R www-data:www-data /run/lumos /app/data
    # $ARTISAN lumos:update --force
fi

echo "==> Creating credentials.txt"
sed -e "s,\bMYSQL_HOST\b,${CLOUDRON_MYSQL_HOST}," \
    -e "s,\bMYSQL_PORT\b,${CLOUDRON_MYSQL_PORT}," \
    -e "s,\bMYSQL_USERNAME\b,${CLOUDRON_MYSQL_USERNAME}," \
    -e "s,\bMYSQL_PASSWORD\b,${CLOUDRON_MYSQL_PASSWORD}," \
    -e "s,\bMYSQL_DATABASE\b,${CLOUDRON_MYSQL_DATABASE}," \
    -e "s,\bMYSQL_URL\b,${CLOUDRON_MYSQL_URL}," \
    -e "s,\bMAIL_SMTP_SERVER\b,${CLOUDRON_MAIL_SMTP_SERVER}," \
    -e "s,\bMAIL_SMTP_PORT\b,${CLOUDRON_MAIL_SMTP_PORT}," \
    -e "s,\bMAIL_SMTPS_PORT\b,${CLOUDRON_MAIL_SMTPS_PORT}," \
    -e "s,\bMAIL_SMTP_USERNAME\b,${CLOUDRON_MAIL_SMTP_USERNAME}," \
    -e "s,\bMAIL_SMTP_PASSWORD\b,${CLOUDRON_MAIL_SMTP_PASSWORD}," \
    -e "s,\bMAIL_FROM\b,${CLOUDRON_MAIL_FROM}," \
    -e "s,\bMAIL_DOMAIN\b,${CLOUDRON_MAIL_DOMAIN}," \
    -e "s,\bREDIS_HOST\b,${CLOUDRON_REDIS_HOST:-NA}," \
    -e "s,\bREDIS_PORT\b,${CLOUDRON_REDIS_PORT:-NA}," \
    -e "s,\bREDIS_PASSWORD\b,${CLOUDRON_REDIS_PASSWORD:-NA}," \
    -e "s,\bREDIS_URL\b,${CLOUDRON_REDIS_URL:-NA}," \
    /app/code/credentials.template > /app/data/credentials.txt

chown -R www-data:www-data /app/data /run/lumos /tmp

APACHE_CONFDIR="" source /etc/apache2/envvars
rm -f "${APACHE_PID_FILE}"
exec /usr/sbin/apache2 -DFOREGROUND

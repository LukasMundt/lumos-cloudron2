FROM cloudron/base:4.2.0@sha256:46da2fffb36353ef714f97ae8e962bd2c212ca091108d768ba473078319a47f4

RUN mkdir -p /app/code
WORKDIR /app/code

ARG VERSION=0.2.5

RUN wget https://github.com/LukasMundt/lumosBaseApplication/archive/${VERSION}.tar.gz -O -| tar -xz -C /app/code --strip-components=1 && \
    chown -R www-data:www-data /app/code

RUN wget https://getcomposer.org/download/2.6.5/composer.phar -O /usr/bin/composer && chmod +x /usr/bin/composer

RUN chmod -R g+w bootstrap/cache
RUN sudo -u www-data composer install --no-interaction --no-suggest --no-dev && \
    sudo -u www-data composer clear-cache

RUN npm install && npm run build && chown -R www-data:www-data /app/code

# configure apache
RUN rm /etc/apache2/sites-enabled/*
RUN sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf
COPY apache/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

RUN a2disconf other-vhosts-access-log
COPY apache/app.conf /etc/apache2/sites-enabled/app.conf
RUN echo "Listen 80" > /etc/apache2/ports.conf

# configure mod_php
RUN a2enmod php8.1
RUN crudini --set /etc/php/8.1/apache2/php.ini PHP upload_max_filesize 256M && \
    crudini --set /etc/php/8.1/apache2/php.ini PHP upload_max_size 256M && \
    crudini --set /etc/php/8.1/apache2/php.ini PHP post_max_size 256M && \
    crudini --set /etc/php/8.1/apache2/php.ini PHP memory_limit 256M && \
    crudini --set /etc/php/8.1/apache2/php.ini PHP max_execution_time 200 && \
    crudini --set /etc/php/8.1/apache2/php.ini Session session.save_path /run/app/sessions && \
    crudini --set /etc/php/8.1/apache2/php.ini Session session.gc_probability 1 && \
    crudini --set /etc/php/8.1/apache2/php.ini Session session.gc_divisor 100

COPY index.php start.sh /app/code/
RUN chown -R www-data.www-data /app/code

RUN chmod +x start.sh
CMD [ "/app/code/start.sh" ]

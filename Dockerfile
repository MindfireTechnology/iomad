FROM php:7.4-apache-buster

WORKDIR /app
ADD . .

RUN chown -R www-data /app
RUN mkdir /moodledata
RUN chown www-data /moodledata
RUN chmod 775 /moodledata
RUN chmod 775 /app

ENV APACHE_DOCUMENT_ROOT /app

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# MS SQL Server Driver
ENV ACCEPT_EULA=Y

RUN apt-get update \
	&& apt-get install -y gnupg zlib1g-dev libxml2-dev libzip-dev libpng-dev \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/9/prod.list \
        > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get install -y --no-install-recommends \
        locales \
        apt-transport-https \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && apt-get update \
    && apt-get -y --no-install-recommends install \
        unixodbc-dev \
        msodbcsql17

RUN docker-php-ext-install pdo pdo_mysql zip intl gd xmlrpc soap \
    && pecl install sqlsrv pdo_sqlsrv xdebug \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv xdebug zip intl gd xmlrpc soap

# RUN /usr/src/php/configure  --with-apxs2=/usr/sbin/apxs --enable-mbstring --with-mysql=/usr --with-pear --enable-sockets \
#              --with-gd --with-jpeg-dir=/usr --with-ttf --with-freetype-dir=/usr --with-zlib-dir=/usr \
#              --with-iconv --with-curl --with-openssl --with-mysqli --enable-soap --with-xmlrpc --enable-zip

# TODO: Enable Cron - https://docs.moodle.org/32/en/Cron_with_Unix_or_Linux
RUN apt-get install -y cron
RUN systemctl enable cron
RUN */1 * * * * /usr/bin/php  /path/to/moodle/admin/cli/cron.php >/dev/null

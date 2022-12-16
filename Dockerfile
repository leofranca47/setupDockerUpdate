FROM php:8.1-apache

# Arguments defined in docker-compose.yml
ARG user
ARG uid

RUN apt update -y &&\
    apt install nano -y &&\
    apt-get install libldb-dev libldap2-dev  -y gdb build-essential

RUN docker-php-ext-install opcache
RUN apt-get update \
    && apt-get install -y git zlib1g-dev libpng-dev \
    &&  apt-get install libcurl4-gnutls-dev libxml2-dev -y\
    && apt-get install libzip-dev -y\
    && docker-php-ext-install pdo pdo_mysql zip ldap gd curl soap mysqli

RUN apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_16.x | bash -

#Instalando ferramentas para verificar o commit
RUN apt-get install -y nodejs
RUN npm install -g @commitlint/cli @commitlint/config-conventional
RUN npm install -g commitizen

RUN apt -y install iputils-ping

# Install xdebug
RUN yes | pecl install xdebug \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.mode=develop,coverage,debug,profile" >> /usr/local/etc/php/conf.d/xdebug.ini  \
    && echo "xdebug.discover_client_host=0" >> /usr/local/etc/php/conf.d/xdebug.ini  \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini  \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/xdebug.ini  \
#    && echo "xdebug.client_host=127.0.0.1" >> /usr/local/etc/php/conf.d/xdebug.ini
  && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/xdebug.ini

#Instala xdebug
# RUN pecl install xdebug && docker-php-ext-enable xdebug

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"


COPY config/. /etc/apache2/
COPY src/php.ini /usr/local/etc/php

# CUSTOMIZER TERMINAL
# COPY config/.bashrc /root/.bashrc
RUN apt-get -y update && apt-get -y install zsh
RUN PATH="$PATH:/usr/bin/zsh"
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"


# Install MS ODBC Driver for SQL Server
# RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
#     && curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list \
#     && apt-get update \
#     && apt-get -y --no-install-recommends install msodbcsql17 unixodbc-dev \
#     && pecl install sqlsrv -y\
#     && pecl install pdo_sqlsrv -y\
#     && echo "extension=pdo_sqlsrv.so" >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-pdo_sqlsrv.ini \
#     && echo "extension=sqlsrv.so" >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-sqlsrv.ini \
#     && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

COPY ssl/. /etc/apache2/ssl/
RUN mkdir -p /var/run/apache2/

RUN a2enmod ssl

RUN a2ensite default-ssl &&\
    a2ensite 000-default

RUN a2enmod rewrite

RUN service apache2 restart

RUN chsh -s $(which zsh)
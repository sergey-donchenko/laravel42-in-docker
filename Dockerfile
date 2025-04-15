FROM php:7.0-apache

# Installing required packages
RUN sed -i '/stretch-updates/d' /etc/apt/sources.list && \
    sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until && \
    apt-get update && \
    apt-get install -y \
        unzip \
        zip \
        git \
        mariadb-client \
        zlib1g-dev \
        libpng-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libxml2-dev \
        libmcrypt-dev \
        build-essential && \
        docker-php-ext-install pdo_mysql mcrypt || true

# Timezone settings
ENV TZ=Europe/Kyiv
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y unzip

# Copy apache config
COPY .docker/apache/10-php.conf /etc/apache2/conf-enabled/10-php.conf
COPY .docker/apache/10-server.conf /etc/apache2/conf-enabled/10-server.conf
COPY .docker/apache/000-default.conf /etc/apache2/sites-enabled/000-default.conf

# Copy launching script to container
COPY .docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
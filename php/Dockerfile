FROM php:8.2-apache

EXPOSE 8080

RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf \
    && sed -i 's/:80>/:8080>/' /etc/apache2/sites-available/000-default.conf

RUN a2enmod rewrite headers expires ssl

COPY . /var/www/html/

RUN chown -R www-data:www-data /var/www/html

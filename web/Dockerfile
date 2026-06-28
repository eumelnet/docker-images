FROM httpd:2.4-alpine

COPY . /usr/local/apache2/htdocs/

RUN sed -i 's/^Listen 80$/Listen 8080/' /usr/local/apache2/conf/httpd.conf \
    && echo "ServerName localhost" >> /usr/local/apache2/conf/httpd.conf \
    && chown -R daemon:daemon /usr/local/apache2

USER daemon

EXPOSE 8080

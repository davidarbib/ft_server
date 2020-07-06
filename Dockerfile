# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: darbib <darbib@student.42.fr>              +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2020/01/22 10:51:12 by darbib            #+#    #+#              #
#    Updated: 2020/02/04 13:25:48 by darbib           ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:buster-20191224-slim 

#---Setting repos---
RUN apt update --yes \ 
	&& apt upgrade --yes

RUN apt install --yes wget gnupg2 ca-certificates apt-transport-https \
	&& wget -q https://packages.sury.org/php/apt.gpg -O- \
	| apt-key add - \
	&& echo "deb https://packages.sury.org/php/ jessie main" \
	| tee /etc/apt/sources.list.d/php.list

RUN apt update

#---install---
RUN apt install --yes nginx \
	php7.4 php7.4-fpm php7.4-mysql \
	mariadb-server \
	vim

#---port exposition---
EXPOSE 80/tcp
EXPOSE 443/tcp

#---site creation---
RUN mkdir -p /var/www/html/ft_server.com \
	&& mkdir -p /var/www/html/ft_server.com/test_autoindex \
	&& touch /var/www/html/ft_server.com/test_autoindex/test.txt

#---configure phpMyAdmin---
COPY srcs/phpMyAdmin-5.0.1-all-languages.tar.gz /tmp/phpMyAdmin-5.0.1-all-languages.tar.gz
RUN tar -xf /tmp/phpMyAdmin-5.0.1-all-languages.tar.gz -C /tmp \
	&& mv /tmp/phpMyAdmin-5.0.1-all-languages /tmp/phpmyadmin \
	&& cp -a /tmp/phpmyadmin /var/www/html/ft_server.com

#---configure SSL---
RUN cd /var \
	&& mkdir certs \ 
	&& cd certs \
	&& openssl req -new -newkey rsa:2048 -nodes -out ft_server_com.csr -keyout ft_server_com.key -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=ft_server.com" \
	&& openssl x509 -req -days 365 -in ft_server_com.csr -signkey ft_server_com.key -out ft_server_com.crt

#---configure Wordpress---
COPY srcs/wordpress-5.3.2.tar.gz /tmp/wordpress-5.3.2.tar.gz
RUN tar -xf /tmp/wordpress-5.3.2.tar.gz -C /tmp \
	&& cp -a /tmp/wordpress /var/www/html/ft_server.com
COPY srcs/wp-config.php /var/www/html/ft_server.com/wordpress/wp-config.php
RUN chown -R www-data:www-data /var/www/html/ft_server.com

#---configure Nginx---
RUN rm -f /etc/nginx/sites-enabled/default \
	&& ln -s /etc/nginx/sites-available/ft_server.com /etc/nginx/sites-enabled/

COPY srcs/nginx.conf /etc/nginx/sites-available/ft_server.com

#---personal page---
COPY srcs/index.html /var/www/html/ft_server.com

#---all services start and db setup ---
COPY srcs/wp.sql /tmp/wp.sql
CMD service nginx start \
	&& service php7.4-fpm start \
	&& service mysql start \
	&& mysql -u root < /tmp/wp.sql \
	&& sh

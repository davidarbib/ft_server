CREATE USER 'www-data'@localhost IDENTIFIED BY 'www-data';
CREATE DATABASE wp;
GRANT ALL PRIVILEGES on wp.* to 'www-data'@localhost;
FLUSH PRIVILEGES;

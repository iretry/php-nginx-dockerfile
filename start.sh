#!/bin/bash


echo  "export PATH=/usr/local/php/bin:/usr/local/php/sbin:/usr/local/nginx/sbin/:$PATH" >> /etc/profile
source /etc/profile
#/usr/local/php/sbin/php-fpm
#/usr/local/nginx/sbin/nginx  -g 'daemon off;'
supervisord -c /etc/supervisord.conf
echo "start"
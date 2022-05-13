FROM centos:7

ENV NGINX_VERSION 1.13.9
ENV PHP_VERSION 7.4.24

RUN mkdir -p /home/phpext 

COPY oniguruma-6.9.4.tar.gz /home
COPY redis-5.3.7.tgz /home/phpext 
COPY memcached-3.2.0.tgz /home/phpext 

RUN set -x && \
    curl  http://mirrors.aliyun.com/repo/Centos-7.repo -o /etc/yum.repos.d/Centos-Base.repo && \
    yum makecache && yum -y update && \
    yum install -y epel-release && yum install -y supervisor && \
    yum install -y wget sqlite-devel\
    yum install -y gcc \
    gcc-c++ \
    autoconf \
    automake \
    libtool \
    make \
    cmake && \
#Install PHP library
## libmcrypt-devel DIY
## rpm -ivh https://centos.pkgs.org/7/epel-aarch64/libmcrypt-devel-2.5.8-13.el7.aarch64.rpm.html && \
    yum remove -y libzip && \
    yum install -y  zlib-devel && \
    mkdir -p /home/libzip && \
    curl -Lk https://libzip.org/download/libzip-1.2.0.tar.gz | gunzip | tar x -C /home/libzip && \
    cd /home/libzip/libzip-1.2.0 && ./configure && make && make install && export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig/" && \
    cd /home && tar zxf oniguruma-6.9.4.tar.gz && \
    cd /home/oniguruma-6.9.4 && \
    ./autogen.sh && \
    ./configure --prefix=/usr --libdir=/lib64 && \
    make && make install && \
    yum install -y zlib \
    libmemcached-devel \
    readline-devel \
    libicu-devel \
    libxslt-devel \
    openssl \
    openssl-devel \
    bzip2  \
    bzip2-devel \
    pcre-devel \
    libzip-devel \
    libxml2 \
    libxml2-devel \
    libcurl \
    libcurl-devel \
    libpng-devel \
    libjpeg-devel \
    freetype-devel \
    libmcrypt-devel \
    openssh-server \
    python-setuptools && \
#Add user
    mkdir -p /data/{phpextini,phpextfile} && mkdir -p /var/www/html && \
    useradd -r -s /sbin/nologin -d /var/www/html -m -k no www && \
#Download nginx & php
    mkdir -p /etc/nginx/conf.d && \
    mkdir -p /data/log && \
    mkdir -p /home/nginx-php && cd $_ && \
    curl -Lk http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php && \
    curl -Lk http://php.net/distributions/php-$PHP_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php && \
#Make install nginx
    cd /home/nginx-php/nginx-$NGINX_VERSION && \
    ./configure --prefix=/usr/local/nginx \
    --user=www --group=www \
    --error-log-path=/var/log/nginx_error.log \
    --http-log-path=/var/log/nginx_access.log \
    --pid-path=/var/run/nginx.pid \
    --with-pcre \
    --with-http_ssl_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --with-http_gzip_static_module && \
    make && make install && \
#Make install php
    cd /home/nginx-php/php-$PHP_VERSION && \
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/data/phpextini \
    --with-fpm-user=www \
    --with-fpm-group=www \
    --with-mysqli \
    --with-pdo-mysql \
    --with-openssl \
    --with-iconv \
    --with-zlib \
    --with-gettext \
    --with-curl \
    --with-png \
    --with-jpeg \
    --with-freetype \
    --with-xmlrpc \
    --with-mhash \
    --enable-fpm \
    --enable-xml \
    --enable-shmop \
    --enable-sysvsem \
    --enable-inline-optimization \
    --enable-mbregex \
    --enable-mbstring \
    --enable-ftp \
    --enable-gd \
    --enable-mysqlnd \
    --enable-pcntl \
    --enable-sockets \
    --enable-zip \
    --enable-soap \
    --enable-session \
    --enable-opcache \
    --enable-bcmath \
    --enable-exif \
    --enable-fileinfo \
    --disable-rpath \
    --enable-ipv6 \
    --disable-debug \
    --enable-intl \
    --with-zip \
    --with-readline \
    --with-pear \
    --with-xsl \
    --enable-sysvmsg \
    --enable-sysvshm \
    #--enable-gd-jis-conv \
    --without-pear && \
    make && make install && \
#Install php-fpm
    cd /home/nginx-php/php-$PHP_VERSION && \
    cp php.ini-production /usr/local/php/etc/php.ini && \
    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf && \
    cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf && \
#Install php ext
    # 下载太慢
    #wget https://pecl.php.net/get/redis-5.3.7.tgz -O /home/phpext/redis-5.3.7.tgz && \
    #wget https://pecl.php.net/get/memcached-3.2.0.tgz -O /home/phpext/memcached-3.2.0.tgz && \
    cd /home/phpext && tar zxf  redis-5.3.7.tgz && cd redis-5.3.7 && /usr/local/php/bin/phpize && ./configure &&   make && make install \
    cd /home/phpext && tar zxf  memcached-3.2.0.tgz && cd memcached-3.2.0 && /usr/local/php/bin/phpize && ./configure &&   make && make install \


#Install Composer
    /usr/local/php/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    /usr/local/php/bin/php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    /usr/local/php/bin/php -r "unlink('composer-setup.php');" && \
#Install supervisor
#    easy_install supervisor && \
    mkdir -p /var/{log/supervisor,run/{sshd,supervisord}} && \
#Clean OS
    rm -rf /tmp/* /var/cache/{yum,ldconfig} /etc/my.cnf{,.d} && \
    mkdir -p --mode=0755 /var/cache/{yum,ldconfig} && \
    find /var/log -type f -delete && \
    rm -rf /home/nginx-php && rm -rf /home/libzip && rm -rf  /home/phpext &&\
#Change Mod from webdir
    chown -R www:www /var/www/html


#Add supervisord conf
COPY supervisord.conf /etc/

#Create web folder
# WEB Folder: /var/www/html
# SSL Folder: /usr/local/nginx/conf/ssl
# Vhost Folder: /usr/local/nginx/conf/vhost
# php extfile ini Folder: /usr/local/php/etc/conf.d
# php extfile Folder: /data/phpextfile
VOLUME ["/var/www/html", "/usr/local/nginx/conf/ssl", "/etc/nginx/conf.d", "/data/phpextini", "/data/phpextfile"]

COPY index.php /var/www/html

#Update nginx config
COPY nginx.conf /usr/local/nginx/conf/

#Start
COPY start.sh /
RUN chmod +x /start.sh

#Set port
EXPOSE 80 443

#Start it
ENTRYPOINT ["/start.sh"]

#Start web server
#CMD ["/bin/bash", "/start.sh"]

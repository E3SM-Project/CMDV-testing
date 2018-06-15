FROM ubuntu:16.04

MAINTAINER Andreas Wilke <wilke@mcs.anl.gov>

RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y -qq \
  apache2 \
  emacs \
  git \
  htop \
  less \
  libapache2-mod-php \
#  mysql-server \
  php \
  php-curl \
  php-gd \
  php-mcrypt \
  php-mysql \
  php-xsl \
  unzip \
  nano
  
  

###
# Check out CDash from github,
# perform necessary setup.
###

WORKDIR /var/www/html
RUN git clone https://github.com/Kitware/CDash.git CDash
RUN cd CDash && git checkout prebuilt && mkdir -p /var/www/html/CDash/rss
#RUN chmod -R 777 /var/www/html/CDash && mv /var/www/html/CDash/* /var/www/html/ && rm /var/www/html/index.html

COPY httpd-foreground /usr/local/bin/
RUN chmod a+x /usr/local/bin/httpd-foreground

EXPOSE 80
CMD ["httpd-foreground"]
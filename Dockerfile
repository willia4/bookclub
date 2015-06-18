FROM ubuntu:15.04
MAINTAINER james@jameswilliams.me

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7 && \
	apt-get -y install apt-transport-https ca-certificates

RUN echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger vivid main' > /etc/apt/sources.list.d/passenger.list && \
 	chown root: /etc/apt/sources.list.d/passenger.list && \
 	chmod 600 /etc/apt/sources.list.d/passenger.list && \
 	apt-get update && \
 	apt-get -y install wget curl \ 
 	build-essential zlib1g-dev libssl-dev libreadline-gplv2-dev libxml2-dev \ 
 	libsqlite3-dev libffi6 libffi-dev \
 	nginx-extras passenger

ADD http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.5.tar.gz /tmp/ruby.tar.gz
WORKDIR /tmp
RUN tar -xf ruby.tar.gz

WORKDIR /tmp/ruby-2.1.5
RUN ./configure && make && make install

WORKDIR /tmp
RUN rm -rf ruby

ADD src /www
WORKDIR /www
RUN rm -f secrets.yaml

WORKDIR /www/tmp
RUN rm always_restart.txt && touch restart.txt

RUN gem install bundler && bundle install;

COPY docker_files/nginx.conf /etc/nginx/nginx.conf
COPY provision/nginx.environment.conf /etc/nginx/environment.conf

COPY docker_files/init_container.sh /init_container.sh
RUN chmod +x /init_container.sh

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

RUN locale-gen en_US.UTF-8

CMD ["/init_container.sh"]

EXPOSE 80
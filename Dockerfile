#IMAGE-NAME: willia4/bookclub
#IMAGE-VERSION: 1.0.3
FROM willia4/nginx_passenger_ruby:1.8.0_5.0.21-1_2.1.5
MAINTAINER james@jameswilliams.me
RUN echo "build 1.0.2"
ADD src /www
WORKDIR /www
RUN rm -f secrets.yaml

WORKDIR /www/tmp
RUN rm always_restart.txt && touch restart.txt

RUN bundle install;

COPY provision/nginx.environment.conf /etc/nginx/conf.d/bookclub_environment.conf

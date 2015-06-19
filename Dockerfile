FROM willia4/nginx_passenger_ruby
MAINTAINER james@jameswilliams.me

ADD src /www
WORKDIR /www
RUN rm -f secrets.yaml

WORKDIR /www/tmp
RUN rm always_restart.txt && touch restart.txt

RUN bundle install;

COPY provision/nginx.environment.conf /etc/nginx/conf.d/bookclub_environment.conf
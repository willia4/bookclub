#!/usr/bin/env bash

# create some www directories
mkdir -p /vagrant/www/bookclub/public
ln -s /vagrant/www /www

############ Phusion Passenger
# Add Phusion's apt repository to the system
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
apt-get -y install apt-transport-https ca-certificates

echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list
chown root: /etc/apt/sources.list.d/passenger.list
chmod 600 /etc/apt/sources.list.d/passenger.list
apt-get -y update

# Install passenger and the special nginx passenger server (nginx-extras lives in Phusion's repository)
apt-get -y install nginx-extras passenger

# uncomment the passenger lines from nginx.conf; replace passenger_ruby with rvm's 2.1.3
sed -i '/passenger_root/ s/# //' /etc/nginx/nginx.conf
sed -i '/passenger_ruby/c\\tpassenger_ruby /usr/local/rvm/gems/ruby-2.1.3/wrappers/ruby;' /etc/nginx/nginx.conf

# set up nginx server files
rm /etc/nginx/sites-enabled/default
cp /vagrant/provision/site.nginx_server /etc/nginx/sites-available/bookclub.investigationcomplete.com
ln -s /etc/nginx/sites-available/bookclub.investigationcomplete.com /etc/nginx/sites-enabled/bookclub.investigationcomplete.com

#restart nginx after all is said and done 
service nginx restart

rm -rf /vagrant/www/bookclub/public

exit 0
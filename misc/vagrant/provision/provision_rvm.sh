#!/usr/bin/env bash

#rvm will check gpg keys. Make sure we have the correct gpg key.
sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

\curl -sSL https://get.rvm.io | sudo bash -s stable

usermod -a -G rvm vagrant

# change the locale settings that rvm wants ruby to run under
echo '' >> /usr/local/rvm/gems/ruby-2.1.3/environment
echo 'export LC_ALL="en_US.UTF-8"' >> /usr/local/rvm/gems/ruby-2.1.3/environment
echo 'export LC_CTYPE="en_US.UTF-8"' >> /usr/local/rvm/gems/ruby-2.1.3/environment
echo 'export LANG=en_US.UTF-8' >> /usr/local/rvm/gems/ruby-2.1.3/environment

exit 0
#!/usr/bin/env bash

cd /home/vagrant 
git clone git://github.com/sstephenson/rbenv.git /home/vagrant/.rbenv

echo 'export PATH="/home/vagrant/.rbenv/bin:$PATH"' >> /home/vagrant/.bashrc
echo 'eval "$(rbenv init -)"' >> /home/vagrant/.bashrc
git clone git://github.com/sstephenson/ruby-build.git /home/vagrant/.rbenv/plugins/ruby-build

PS1='$ ' # This hackery is because on debian bashrc exits if PS1 isn't defined
. /home/vagrant/.bashrc 
echo $PATH

# install ruby
rbenv install 2.1.1
rbenv shell 2.1.1

#install rails
gem update
gem install bundler
gem install rails

#install sinatra and thin (could be in a different script but whatever)
gem install sinatra
gem install thin

sudo -u vagrant rbenv global 2.1.1
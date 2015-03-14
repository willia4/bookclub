#!/usr/bin/env bash

add-apt-repository -y ppa:git-core/ppa

apt-get -y update
apt-get -y install vim curl git build-essential

exit 0
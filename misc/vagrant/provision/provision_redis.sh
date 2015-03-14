#!/usr/bin/env bash

apt-get -y install redis-server

#save a copy of the config file, just in case
cp /etc/redis/redis.conf /etc/redis/redis.default

#comment the lines beginning with "save" so redis won't write anything to disk
sed -i '/^save /s/^/#/g' /etc/redis/redis.conf 

#set max memory to something reasonable and uncomment the directive
sed -i '/# maxmemory <bytes>/ c\maxmemory 50MB' /etc/redis/redis.conf 

#set a more reasonable memory eviction policy
sed -i '/# maxmemory-policy/ c\maxmemory-policy allkeys-lru' /etc/redis/redis.conf
#!/bin/bash

fallocate -l 2000MB /swapfile
[ $? -ne 0 ] && exit 1
chmod 600 /swapfile
[ $? -ne 0 ] && exit 2
mkswap /swapfile
[ $? -ne 0 ] && exit 3
swapon /swapfile
[ $? -ne 0 ] && exit 4
echo '/swapfile   none    swap    sw    0   0' >> /etc/fstab
[ $? -ne 0 ] && exit 5

exit 0
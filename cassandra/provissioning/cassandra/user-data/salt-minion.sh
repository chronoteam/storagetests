#!/usr/bin/env bash
#!/usr/bin/env bash

sudo apt update
sudo apt-get update -y
curl -L https://bootstrap.saltstack.com -o install_salt.sh

## salt master discovery
echo "${master_private_ip}    salt" >> /etc/hosts

## install minion
sudo sh install_salt.sh -P -i "${name}_${index}"
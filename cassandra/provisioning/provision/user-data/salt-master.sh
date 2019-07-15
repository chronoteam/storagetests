#!/usr/bin/env bash

# update, change hostname and make discovery with hosts file
sudo apt update
sudo apt-get update -y
sudo hostnamectl set-hostname provision
sudo echo $(hostname -i)    salt >> /etc/hosts
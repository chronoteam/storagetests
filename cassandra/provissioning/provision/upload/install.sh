#!/usr/bin/env bash

DESIRED=$(cat /tmp/count-resources)
TOTAL=0
while [[ ${TOTAL} -lt ${DESIRED} ]]
do
    ACCEPTED=`sudo salt-key --list accepted | wc -l`
    ACCEPTED=$((ACCEPTED - 1))
    UNACCEPTED=`sudo salt-key --list unaccepted | wc -l`
    UNACCEPTED=$((UNACCEPTED - 1))
    DENIED=`sudo salt-key --list denied | wc -l`
    DENIED=$((DENIED - 1))

    TOTAL=$((ACCEPTED + UNACCEPTED + DENIED))
    echo " --------------------------------------- "
    echo "Accepted minions: " ${ACCEPTED}
    echo "Unaccepted minions: " ${UNACCEPTED}
    echo "Denied minions: " ${DENIED}
    echo "Total desired minions: " ${DESIRED}
    echo ""
    echo " === Waiting for " $((DESIRED - TOTAL)) " minion(s) to be visible for master === "
    wait 1
done

echo "All minions are visible to master --- go ahead"

# replace master config
sudo rm -r /etc/salt/master
sudo cp /tmp/upload/etc/salt/master /etc/salt/master

# add states
sudo rm -rf /srv/salt
sudo cp -r /tmp/upload/srv/* /srv
# cassandra configuration
sudo mkdir -p /srv/salt/cassandra/files
sudo cp -r /tmp/upload/config/cassandra.yaml /srv/salt/cassandra/files/
# cassandra schema
sudo cp -r /tmp/upload/config/cassandra-schema.cql /srv/salt/cassandra/files/

# restart salt master
sudo systemctl stop salt-master
sudo systemctl start salt-master

# accept minions
sudo salt-key -A -y
sudo salt-key

# send mine
sudo salt '*' mine.send network.ipaddrs
sudo salt '*' mine.send grains.items
sudo salt '*' mine.update

echo -e "\e[1;31;42mSuccessful (re)init configuration \e[0m"

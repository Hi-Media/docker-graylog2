#!/bin/sh
chown mongodb:mongodb /var/lib/mongodb
sudo -u mongodb -H /usr/bin/mongod --config /etc/mongod.conf --httpinterface --rest &

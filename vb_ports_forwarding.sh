#!/bin/bash

# vm must be powered off
PORTS=(8080 9000 9200 27017 28017)

for i in "${PORTS[@]}"
do
    VBoxManage modifyvm "boot2docker-vm" --natpf1 "tcp-port$i,tcp,,$i,,$i";
    VBoxManage modifyvm "boot2docker-vm" --natpf1 "udp-port$i,udp,,$i,,$i";
done

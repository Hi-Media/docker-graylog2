#!/bin/bash

# vm must be powered off
PORTS=(8080 9000 9200 27017 28017)

for i in "${PORTS[@]}"
do
    VBoxManage modifyvm "boot2docker-vm" --natpf1 delete "tcp-port$i";
    VBoxManage modifyvm "boot2docker-vm" --natpf1 delete "udp-port$i";
done

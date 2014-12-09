#!/bin/bash

PORTS=(9200,8080,27017,28017,9000)

for i in "${filecontent[@]}"
do
  VBoxManage modifyvm "boot2docker-vm" --natpf1 delete "tcp-port$i"; 
  VBoxManage modifyvm "boot2docker-vm" --natpf1 delete "udp-port$i"; 
done

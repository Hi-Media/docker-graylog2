#!/bin/bash

PORTS=(9200,8080,27017,28017,9000)

for i in "${filecontent[@]}"
do
  VBoxManage modifyvm "boot2docker-vm" --natpf1 "tcp-port$i,tcp,,$i,,$i";
  VBoxManage modifyvm "boot2docker-vm" --natpf1 "udp-port$i,udp,,$i,,$i";
done

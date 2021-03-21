#!/bin/sh

# CHOOSE: DOCKER or CRI

# Docker
# sudo kubeadm init --apiserver-advertise-address=192.168.100.100 --pod-network-cidr=10.244.0.0/16 --cri

# CRI
sudo kubeadm init --apiserver-advertise-address=192.168.100.100 --pod-network-cidr=10.244.0.0/16 --cri-socket=/var/run/crio/crio.sock

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown vagrant:vagrant $HOME/.kube/config


# Flannel
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Add Worker Node to Cluster
sudo ssh -i /vagrant/insecure_key -o BatchMode=yes -o StrictHostKeyChecking=no root@worker-01 sudo $(sudo kubeadm token create --print-join-command) --cri-socket=/var/run/crio/crio.sock

sudo kubectl get nodes
echo


#!/bin/bash

KUBEVERSION="1.20.5-00"
#KUBEVERSION="1.19.9-00"

sudo swapoff -a
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /tmp/kubernetes.list
sudo mv /tmp/kubernetes.list /etc/apt/sources.list.d
sudo apt update
# sudo apt upgrade -y
sudo apt install -y kubeadm=${KUBEVERSION} --allow-unauthenticated
sudo apt install -y kubectl=${KUBEVERSION} --allow-unauthenticated --allow-downgrades

sudo apt install -y docker.io

sudo modprobe overlay
sudo modprobe br_netfilter

#
# Container Runtime CRIO DISABLED BY DEFAULT
#
sudo rm -f /etc/sysctl.d/99-kubernetes-cri.conf
sudo cp /vagrant/99-kubernetes-cri.conf /etc/sysctl.d/99-kubernetes-cri.conf
sudo sysctl --system

export OS=xUbuntu_20.04
export VERSION=$(echo ${KUBEVERSION} | cut -d '.' -f1,2)

echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | sudo tee -a  /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" | sudo tee -a /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key add -
sudo apt update
sudo apt install -y cri-o cri-o-runc

sudo rm -f /etc/crio/crio.conf
sudo cp /vagrant/crio.conf /etc/crio/crio.conf

sudo systemctl daemon-reload

# CRIO
sudo systemctl enable crio
sudo systemctl start crio
sudo systemctl status crio

# Docker
sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

rm -f /etc/default/kubelet
cp /vagrant/default_kubelet /etc/default/kubelet

sudo apt install -y kubelet=${KUBEVERSION} --allow-unauthenticated --allow-downgrades
#sudo apt install -y kubernetes-cni --allow-unauthenticated

# Keys
mkdir -p --mode=0700 $HOME/.ssh
touch $HOME/.ssh/authorized_keys
chmod 0600 $HOME/.ssh/authorized_keys
cat /vagrant/insecure_key.pub >> $HOME/.ssh/authorized_keys

#!/bin/bash

sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a

bash -c 'cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF'
sudo sysctl --system

apt-get update && apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

mkdir -p /etc/docker
bash -c 'cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF'

apt-get update && apt-get install -y \
  containerd.io=1.2.13-2 \
  docker-ce=5:18.09.9~3-0~ubuntu-$(lsb_release -cs) \
  docker-ce-cli=5:18.09.9~3-0~ubuntu-$(lsb_release -cs)

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker ; systemctl enable docker

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

bash -c 'cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF'

apt-get update
apt-get install -y kubelet=1.18.9-00 kubeadm=1.18.9-00 kubectl=1.18.9-00
apt-mark hold kubelet kubeadm kubectl

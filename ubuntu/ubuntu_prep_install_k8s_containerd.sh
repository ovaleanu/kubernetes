#!/bin/bash

sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a
apt-get update

bash -c 'cat <<EOF > /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF'

modprobe overlay
modprobe br_netfilter

bash -c 'cat <<EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF'

sysctl --system
apt-get update && apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

apt-get update && apt-get install -y containerd.io
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

bash -c 'cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF'

apt-get update
apt-get install -y kubelet=1.18.9-00 kubeadm=1.18.9-00 kubectl=1.18.9-00
sudo apt-mark hold kubelet kubeadm kubectl

echo "runtime-endpoint: unix:///run/containerd/containerd.sock" > /etc/crictl.yaml
systemctl daemon-reload

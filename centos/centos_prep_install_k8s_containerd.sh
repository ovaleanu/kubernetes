#!/bin/bash

yum update -y

bash -c 'cat <<EOF > /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF'

modprobe overlay
modprobe br_netfilter

yum install -y epel-release yum-utils device-mapper-persistent-data lvm2 curl
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum update -y && yum install -y containerd.io
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd && systemctl enable containerd

bash -c 'cat <<EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF'

sysctl --system

bash -c 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF'

sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
systemctl stop firewalld; systemctl disable firewalld

yum update -y && yum install -y kubelet-1.18.9 kubeadm-1.18.9 kubectl-1.18.9 --disableexcludes=kubernetes
systemctl enable --now kubelet
echo "runtime-endpoint: unix:///run/containerd/containerd.sock" > /etc/crictl.yaml
systemctl daemon-reload

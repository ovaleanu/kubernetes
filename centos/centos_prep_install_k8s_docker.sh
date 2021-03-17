#!/bin/bash

yum -y update
yum install -y epel-release yum-utils device-mapper-persistent-data lvm2 curl wget
sed -i '/swap/ s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
systemctl stop firewalld; systemctl disable firewalld

bash -c 'cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF'

sysctl --system

yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

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

yum -y update && yum install -y containerd.io-1.2.13 docker-ce-19.03.11 docker-ce-cli-19.03.11

mkdir /etc/docker

bash -c 'cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF'

mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl enable --now docker

yum install -y kubelet-1.19.7 kubeadm-1.19.7 kubectl-1.19.7 --disableexcludes=kubernetes
systemctl enable --now kubelet

kubeadm config images pull

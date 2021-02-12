#!/bin/bash

yum -y update
yum -y install epel-release curl wget

sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
systemctl stop firewalld; systemctl disable firewalld

modprobe overlay
modprobe br_netfilter
echo "br_netfilter" >> /etc/modules-load.d/br_netfilter.conf

bash -c 'cat <<EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF'

sysctl --system

OS="${OS:-CentOS_7}"
VERSION="${VERSION:-1.20}"

curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo

yum install -y cri-o
systemctl daemon-reload
systemctl enable --now crio

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

yum update -y && yum install -y kubelet-1.19.7 kubeadm-1.19.7 kubectl-1.19.7 --disableexcludes=kubernetes
mkdir /var/lib/kubelet

bash -c 'cat <<EOF > /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF'

cat /dev/null > /etc/sysconfig/kubelet

bash -c 'cat <<EOF > /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS=--container-runtime=remote --cgroup-driver=systemd --container-runtime-endpoint="unix:///var/run/crio/crio.sock"
EOF'
systemctl enable --now kubelet

kubeadm config images pull

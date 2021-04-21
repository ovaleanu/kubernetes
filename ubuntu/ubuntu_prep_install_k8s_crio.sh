#!/bin/bash

apt update
sed -i '/swap/ s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a

bash -c 'cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF'

modprobe overlay
modprobe br_netfilter

bash -c 'cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF'

sudo sysctl --system

OS="${OS:-xUbuntu_20.04}"
VERSION="${VERSION:-1.20}"

bash -c 'cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF'

bash -c 'cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF'

curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers-cri-o.gpg add -

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
bash -c 'cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF'


apt update
apt install -y cri-o cri-o-runc
systemctl daemon-reload
systemctl enable --now crio

apt install -y apt-transport-https
apt install -y kubelet=1.19.7-00 kubeadm=1.19.7-00 kubectl=1.19.7-00
apt-mark hold kubelet kubeadm kubectl
mkdir -p /var/lib/kubelet
bash -c 'cat <<EOF > /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF'

cat /dev/null > /etc/default/kubelet
bash -c 'cat <<EOF > /etc/default/kubelet
KUBELET_EXTRA_ARGS=--container-runtime=remote --cgroup-driver=systemd --container-runtime-endpoint="unix:///var/run/crio/crio.sock"
EOF'
systemctl enable --now kubelet

kubeadm config images pull

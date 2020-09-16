## Upgrade a Kubernetes cluster using kubeadm

The scope of this doc is to upgrade a HA Kubernetes cluster from version 1.17.9 to latest 1.18 patch

```
$ kubectl get nodes -o wide
NAME      STATUS   ROLES    AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
master1   Ready    master   47d   v1.17.9   192.168.213.131   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
master2   Ready    master   47d   v1.17.9   192.168.213.132   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
master3   Ready    master   47d   v1.17.9   192.168.213.133   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
node1     Ready    <none>   47d   v1.17.9   192.168.213.134   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
node2     Ready    <none>   47d   v1.17.9   192.168.213.135   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
```

### Determine which version planning to upgrade

Choose the 1.18 version from the list. I will upgrade to 1.18.8.
```
$ sudo apt-get update
$ sudo apt-cache madison kubeadm
```

### Upgrade the masters

On the first master
```
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.18.8-00
```
Check the version
```
kubeadm version
```
Drain the master node
```
$ kubectl drain master1 --ignore-daemonsets
```
Check if the cluster can be upgraded and fetch the versions you want upgrade to
```
$ sudo kubeadm upgrade plan
```
You get an output ending like this
```
Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT             AVAILABLE
Kubelet     1 x v1.17.3   v1.18.0

Upgrade to the latest version in the v1.17 series:

COMPONENT            CURRENT   AVAILABLE
API Server           v1.17.9   v1.18.8
Controller Manager   v1.17.9   v1.18.8
Scheduler            v1.17.9   v1.18.8
Kube Proxy           v1.17.9   v1.18.8
CoreDNS              1.6.5     1.6.7
Etcd                 3.4.3     3.4.3-0

You can now apply the upgrade by executing the following command:

    kubeadm upgrade apply v1.18.8
```

Upgrade the first master node
```
sudo kubeadm upgrade apply v1.18.8
```

Manually upgrade your CNI provider plugin. This is Contrail in my case.

Uncordon the master node
```
kubectl uncordon master1
```

Upgrade the other two master nodes

On the master 2
```
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.18.8-00
$ kubectl drain master2 --ignore-daemonsets
$ sudo kubeadm upgrade plan
$ sudo kubeadm upgrade node
```

On the master 3
```
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.18.8-00
$ kubectl drain master2 --ignore-daemonsets
$ sudo kubeadm upgrade plan
$ sudo kubeadm upgrade node
```

Upgrade `kubectl` and `kubelet` on all master nodes
```
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=1.18.8-00 kubectl=1.18.8-00
$ sudo systemctl daemon-reload
$ sudo systemctl restart kubelet
```

### Upgrade the workers

```
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.18.8-00
```
Drain the master node
```
$ kubectl drain node1 --ignore-daemonsets
```

Upgrade kubeadm
```
sudo kubeadm upgrade node
```
Upgrade `kubectl` and `kubelet`
```
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=1.18.8-00 kubectl=1.18.8-00
$ sudo systemctl daemon-reload
$ sudo systemctl restart kubelet
```

Uncordon the node
```
kubectl uncordon node1
```

### Verify the status of the cluster

```
$ kubectl get nodes -o wide
NAME      STATUS   ROLES    AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
master1   Ready    master   47d   v1.18.8   192.168.213.131   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
master2   Ready    master   47d   v1.18.8   192.168.213.132   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
master3   Ready    master   47d   v1.18.8   192.168.213.133   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
node1     Ready    <none>   47d   v1.18.8   192.168.213.134   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
node2     Ready    <none>   47d   v1.18.8   192.168.213.135   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
```

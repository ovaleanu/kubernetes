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

Choose the 1.18 version from the list. I will upgrade to latest 1.18.9.
```
$ sudo apt-get update
$ sudo apt-cache madison kubeadm
```

### Upgrade the masters

On the first master
```
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.18.9-00
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
Kubelet     5 x v1.17.9         v1.18.9

Upgrade to the latest version in the v1.17 series:

COMPONENT            CURRENT   AVAILABLE
API Server           v1.17.9   v1.18.9
Controller Manager   v1.17.9   v1.18.9
Scheduler            v1.17.9   v1.18.9
Kube Proxy           v1.17.9   v1.18.9
CoreDNS              1.6.5     1.6.7
Etcd                 3.4.3     3.4.3-0

You can now apply the upgrade by executing the following command:

    kubeadm upgrade apply v1.18.9
```

Upgrade the first master node
```
$ sudo kubeadm upgrade apply v1.18.9
```
Manually upgrade your CNI provider plugin. This is Contrail in my case.

Upgrade `kubectl` and `kubelet`
```
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=1.18.9-00 kubectl=1.18.9-00
$ sudo systemctl daemon-reload
$ sudo systemctl restart kubelet
```
Uncordon the master node
```
kubectl uncordon master1
```

Upgrade the other two master nodes

On the master 2
```
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.18.9-00
$ kubectl drain master2 --ignore-daemonsets
$ sudo kubeadm upgrade node
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=1.18.9-00 kubectl=1.18.9-00
$ sudo systemctl daemon-reload
$ sudo systemctl restart kubelet
$ kubectl uncordon master2
```

On the master 3
```
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.18.9-00
$ kubectl drain master3 --ignore-daemonsets
$ sudo kubeadm upgrade node
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=1.18.9-00 kubectl=1.18.9-00
$ sudo systemctl daemon-reload
$ sudo systemctl restart kubelet
$ kubectl uncordon master3
```

### Upgrade the workers

```
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.18.9-00
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
$ sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=1.18.9-00 kubectl=1.18.9-00
$ sudo systemctl daemon-reload
$ sudo systemctl restart kubelet
```

Uncordon the node
```
kubectl uncordon node1
```

The same for all the nodes

### Verify the status of the cluster

```
$ kubectl get nodes -o wide
NAME      STATUS   ROLES    AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
master1   Ready    master   47d   v1.18.9   192.168.213.131   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
master2   Ready    master   47d   v1.18.9   192.168.213.132   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
master3   Ready    master   47d   v1.18.9   192.168.213.133   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
node1     Ready    <none>   47d   v1.18.9   192.168.213.134   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
node2     Ready    <none>   47d   v1.18.9   192.168.213.135   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
```

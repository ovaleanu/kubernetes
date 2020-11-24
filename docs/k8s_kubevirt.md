## KubeVirt on a Kubernetes cluster with Contrail

KubeVirt is an open-source project that offers a VM-based virtualisation option on top of any Kubernetes cluster.

KubeVirt can be installed using the KubeVirt operator, which manages the lifecycle of all the KubeVirt core components. More details on KubeVirt [page](https://kubevirt.io/).

For my demo I will use a mainstream Kubernetes cluster with Contrail

```
$ kubectl get nodes -o wide
NAME          STATUS   ROLES    AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
k8s-master1   Ready    master   63d   v1.18.9   172.16.125.115   <none>        Ubuntu 18.04.5 LTS   4.15.0-118-generic   docker://18.9.9
k8s-master2   Ready    master   63d   v1.18.9   172.16.125.116   <none>        Ubuntu 18.04.5 LTS   4.15.0-118-generic   docker://18.9.9
k8s-master3   Ready    master   63d   v1.18.9   172.16.125.117   <none>        Ubuntu 18.04.5 LTS   4.15.0-118-generic   docker://18.9.9
k8s-node1     Ready    <none>   63d   v1.18.9   172.16.125.118   <none>        Ubuntu 18.04.5 LTS   4.15.0-112-generic   docker://18.9.9
k8s-node2     Ready    <none>   63d   v1.18.9   172.16.125.119   <none>        Ubuntu 18.04.5 LTS   4.15.0-112-generic   docker://18.9.9

kubectl get pods -n kube-system
NAME                                          READY   STATUS    RESTARTS   AGE
config-zookeeper-4klts                        1/1     Running   0          63d
config-zookeeper-cs2fk                        1/1     Running   0          63d
config-zookeeper-wgrtb                        1/1     Running   0          63d
contrail-agent-ch8kv                          3/3     Running   3          63d
contrail-agent-kh9cf                          3/3     Running   1          63d
contrail-agent-kqtmz                          3/3     Running   0          63d
contrail-agent-m6nrz                          3/3     Running   1          63d
contrail-agent-qgzxt                          3/3     Running   0          63d
contrail-analytics-6666s                      4/4     Running   1          63d
contrail-analytics-jrl5x                      4/4     Running   4          63d
contrail-analytics-x756g                      4/4     Running   4          63d
contrail-configdb-2h7kd                       3/3     Running   4          63d
contrail-configdb-d57tb                       3/3     Running   4          63d
contrail-configdb-zpmsq                       3/3     Running   4          63d
contrail-controller-config-c2226              6/6     Running   9          63d
contrail-controller-config-pbbmz              6/6     Running   5          63d
contrail-controller-config-zqkm6              6/6     Running   4          63d
contrail-controller-control-2kz4c             5/5     Running   2          63d
contrail-controller-control-k522d             5/5     Running   0          63d
contrail-controller-control-nr54m             5/5     Running   2          63d
contrail-controller-webui-5vxl7               2/2     Running   0          63d
contrail-controller-webui-mzpdv               2/2     Running   1          63d
contrail-controller-webui-p8rc2               2/2     Running   1          63d
contrail-kube-manager-88c4f                   1/1     Running   0          63d
contrail-kube-manager-fsz2z                   1/1     Running   0          63d
contrail-kube-manager-qc27b                   1/1     Running   0          63d
.....
```

Check the latest KubeVirt version on [https://kubevirt.io/blogs/releases.html](https://kubevirt.io/blogs/releases.html).

```
$ export KUBEVIRT_VERSION="v0.35.0"
```

Install the KubeVirt operator

```
$ kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
$ kubectl get pods -n kubevirt
NAME                               READY   STATUS    RESTARTS   AGE
virt-operator-78fbcdfdf4-ghxhg     1/1     Running   2          5m
virt-operator-78fbcdfdf4-pgsfw     1/1     Running   0          3m
```

After KubeVirt operator is deployed you will deploy KubeVirt Custom Resource Definitions (CRD):

```
$ kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml
$ kubectl get pods -n kubevirt
NAME                               READY   STATUS    RESTARTS   AGE
virt-api-64999f7bf5-k48g6          1/1     Running   0          26m
virt-api-64999f7bf5-ql5fm          1/1     Running   0          26m
virt-controller-8696ccdf44-w9nd8   1/1     Running   2          25m
virt-controller-8696ccdf44-znvdk   1/1     Running   0          25m
virt-handler-c866z                 1/1     Running   0          25m
virt-handler-ns5xg                 1/1     Running   0          25m
virt-handler-sr6sj                 1/1     Running   0          25m
virt-handler-v5gz7                 1/1     Running   0          25m
virt-handler-w274q                 1/1     Running   0          25m
virt-operator-78fbcdfdf4-ghxhg     1/1     Running   2          31m
virt-operator-78fbcdfdf4-pgsfw     1/1     Running   0          29m
```

If you are running KubeVirt in a nested enviroment, create kubevirt-config ConfigMap to support [software emulation](https://github.com/kubevirt/kubevirt/blob/master/docs/software-emulation.md#software-emulation).

```
$ kubectl create cm kubevirt-config -n kubevirt
```

Add to kubevirt-config ConfigMap
```
data:
  debug.useEmulation: "true"
```
```
$ kubectl edit cm kubevirt-config -n kubevirt

apiVersion: v1
kind: ConfigMap
metadata:
  name: kubevirt-config
  namespace: kubevirt
data:
  debug.useEmulation: "true"
```
Then you need to restart `virt-handler` pods

```
$ kubectl -n kubevirt delete pod -l k8s-app=virt-handler
```

### Creating Virtual Machines on KubeVirt

Create namespace for the demo. I will call it `kubevirt-demo`

```
$ kubectl create ns kubevirt-demo
```

Using Virtual Machine Instance (VMI) custom resources you can create VMs fully integrated in Kubernetes.

Create a Virtual Machine with Centos 7 using the following manifest:

```
cat <<EOF > kubevirt-centos.yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-centos7
  name: vmi-centos7
  namespace: kubevirt-demo
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
      - disk:
          bus: virtio
        name: cloudinitdisk
      interfaces:
      - name: default
        bridge: {}
    resources:
      requests:
        memory: 1024M
  networks:
  - name: default
    pod: {}
  volumes:
  - containerDisk:
      image: ovaleanu/centos:latest
    name: containerdisk
  - cloudInitNoCloud:
      userData: |-
        #cloud-config
        password: centos
        ssh_pwauth: True
        chpasswd: { expire: False }
    name: cloudinitdisk
EOF

$ kubectl apply -f kubevirt-centos.yaml
virtualmachineinstance.kubevirt.io/vmi-centos7 created
```

Check if the pod and VirtualMachineInstance was created

```
kubectl get pods -n kubevirt-demo
NAME                              READY   STATUS    RESTARTS   AGE
virt-launcher-vmi-centos7-xfw2p   2/2     Running   0          100s

kubectl get vmi -n kubevirt-demo
NAME          AGE     PHASE     IP                 NODENAME
vmi-centos7   5m48s   Running   10.47.255.218/12   k8s-node1
```

Create a service for Centos VM to connect with ssh through NodePort using node ip

```
cat <<EOF > kubevirt-centos-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: vmi-centos-ssh-svc
  namespace: kubevirt-demo
spec:
  ports:
  - name: centos-ssh-svc
    nodePort: 30000
    port: 27017
    protocol: TCP
    targetPort: 22
  selector:
    special: vmi-centos7
  type: NodePort
EOF

$ kubectl apply -f kubevirt-centos-svc.yaml

$ kubectl get svc -n kubevirt-demo
NAME                 TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
vmi-centos-ssh-svc   NodePort   10.97.172.252   <none>        27017:30000/TCP   13s
```

Connect to Centos VM with ssh via service NodePort using worker node IP address

```
ssh centos@172.16.125.118 -p 30000
The authenticity of host '[172.16.125.118]:30000 ([172.16.125.118]:30000)' can't be established.
ECDSA key fingerprint is SHA256:1ELZpIiqyBaUEN4EUkskTvGzB+2GyJmkvT7d+FiXfL8.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[172.16.125.118]:30000' (ECDSA) to the list of known hosts.
centos@172.16.125.118's password:
[centos@vmi-centos7 ~]$ uname -sr
Linux 3.10.0-957.12.2.el7.x86_64
[centos@vmi-centos7 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 02:bb:7b:93:16:2e brd ff:ff:ff:ff:ff:ff
    inet 10.47.255.218/12 brd 10.47.255.255 scope global dynamic eth0
       valid_lft 86313353sec preferred_lft 86313353sec
    inet6 fe80::bb:7bff:fe93:162e/64 scope link
       valid_lft forever preferred_lft forever
[centos@vmi-centos7 ~]$ ping www.google.com
PING www.google.com (216.58.194.164) 56(84) bytes of data.
64 bytes from sfo07s13-in-f164.1e100.net (216.58.194.164): icmp_seq=1 ttl=113 time=5.06 ms
64 bytes from sfo07s13-in-f164.1e100.net (216.58.194.164): icmp_seq=2 ttl=113 time=4.30 ms
^C
--- www.google.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 4.304/4.686/5.069/0.388 ms
```

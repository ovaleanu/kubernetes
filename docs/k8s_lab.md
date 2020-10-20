## Contrail Kubernetes lab guide

Download the lab folder.

```
$ git clone clone https://github.com/ovaleanujnpr/k8-lab
$ cd k8s-lab
```

### Install Kubernetes Dashboard an access it through NodePort

The yaml file has been modified to access [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) using NodePort. The reference yaml file is [here](https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml).

```
$ cd dashboard
$ kubectl apply -f kubernetes-dashboard.yaml
namespace/kubernetes-dashboard created
serviceaccount/kubernetes-dashboard created
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created
serviceaccount/admin-user created
clusterrolebinding.rbac.authorization.k8s.io/admin-user created

$ kubectl get pods -n kubernetes-dashboard
NAME                                         READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-6b4884c9d5-2bnsn   1/1     Running   0          18s
kubernetes-dashboard-7b544877d5-vkpbs        1/1     Running   0          18s

$ kubectl get svc -n kubernetes-dashboard
NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)         AGE
dashboard-metrics-scraper   ClusterIP   10.109.228.44   <none>        8000/TCP        28s
kubernetes-dashboard        NodePort    10.99.77.250    <none>        443:30373/TCP   28s
```

Get the bearer token to authenticate

```
$ kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
Name:         admin-user-token-xcr2h
Namespace:    kubernetes-dashboard
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: admin-user
              kubernetes.io/service-account.uid: df4a8b91-af6b-4ea7-9e76-cd94b381acc3

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1025 bytes
namespace:  20 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6InBGUmN4eEczUVpGYlp2TnU3T05Cc1FtNnBIZTEyX0RVWGVYcGh0a2lxd3cifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLXhjcjJoIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJkZjRhOGI5MS1hZjZiLTRlYTctOWU3Ni1jZDk0YjM4MWFjYzMiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tdXNlciJ9.g0jyVWol-sxyVK4qVsskQVLTdfawLDeOoZQ7XmV0UHg5ZhGEzXtj9iQojyVTx-Txw39RVEXXSl8daM97iJEzELudvImy-IYflgmT-mJ4bWp-5wlIadWkISVgM2w5n0O9VDPwSyFDgQCCteqFkXROJgQ-4h0eupPumhSzLrGXeLfVF8qsxWz56BoL1SLEK07fkJB0WYjDjhN_lwUIQabvItwcrDJ5IPQlysJowmPSFEHoIPsx2pSebLF0Bg84OC9NvsSwcSZOQU4_qc3zhDKQdBfUA4lj4auSWH4f1A3FG1LWJ99ipYDe1umES67fQXwaDlEme7PAIa6XXXXXXXXXXXX
```

Access Kubernetes Dasboard using a worker node ip and the port above, https://<node_ip>:30373. (Your port will be different)

![](https://github.com/ovaleanujnpr/kubernetes/blob/master/images/k8s-image1.png)

Copy the token, paste it in UI and Login

![](https://github.com/ovaleanujnpr/kubernetes/blob/master/images/k8s-image2.png)

### Load Balancers - Replication and Services

You will create an ubuntu pod and three ReplicationControllers.

![](https://github.com/ovaleanujnpr/kubernetes/blob/master/images/k8s-image3.png)

```
$ cd exercise1
$ cat ubuntu.yaml
$ kubectl create -f ubuntu.yaml
$ cat rc-frontend.yaml
$ kubectl create -f rc-frontend.yaml
$ kubectl get pods -o wide
NAME                READY   STATUS    RESTARTS   AGE   IP              NODE             NOMINATED NODE   READINESS GATES
frontend-8pr7f      1/1     Running   0          23m   10.47.255.243   ru16-k8s-node1   <none>           <none>
frontend-l6tdw      1/1     Running   0          23m   10.47.255.241   ru16-k8s-node3   <none>           <none>
frontend-vrlz9      1/1     Running   0          23m   10.47.255.242   ru16-k8s-node2   <none>           <none>
ubuntuapp           1/1     Running   0          24m   10.47.255.244   ru16-k8s-node2   <none>           <none>
```

Check connectivity between the pods. So far there is no load balancing, there is simple any-to-any connectivity.

```
$ kubectl exec ubuntuapp -- ping 10.47.255.243
PING 10.47.255.243 (10.47.255.243) 56(84) bytes of data.
64 bytes from 10.47.255.243: icmp_seq=1 ttl=63 time=1.36 ms
64 bytes from 10.47.255.243: icmp_seq=2 ttl=63 time=0.467 ms

$ kubectl exec ubuntuapp -- ping 10.47.255.241
PING 10.47.255.241 (10.47.255.241) 56(84) bytes of data.
64 bytes from 10.47.255.241: icmp_seq=1 ttl=63 time=1.15 ms
64 bytes from 10.47.255.241: icmp_seq=2 ttl=63 time=0.690 ms
```

Install curl in `ubuntuapp` pod. You will need it later.

```
$ kubectl exec -it ubuntuapp -- bash
root@ubuntuapp:/# apt-get update
root@ubuntuapp:/# apt install curl
```

Now create a load balancing construct, by exposing the frontend service

![](https://github.com/ovaleanujnpr/kubernetes/blob/master/images/k8s-image4.png)

```
$ kubectl expose rc/frontend

$ kubectl get svc
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
frontend      ClusterIP   10.98.129.6     <none>        80/TCP    5m2s
kubernetes    ClusterIP   10.96.0.1       <none>        443/TCP   15h
```

By repeatedly checking the output of the following command, you will see a changing IP address that proves load balancing.

```
$ kubectl exec ubuntuapp -- curl frontend
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   353  100   353    0     0  28114      0 --:--:-- --:--:-- --:--:-- 29416

<html>
<style>
  h1   {color:green}
  h2   {color:red}
</style>
  <div align="center">
  <head>
    <title>Contrail Pod</title>
  </head>
  <body>
    <h1>Hello</h1><br><h2>This page is served by a <b>Contrail</b> pod</h2><br><h3>IP address = 10.47.255.241<br>Hostname = frontend-l6tdw</h3>
    <img src="/static/giphy.gif">
  </body>
  </div>
</html>

$ kubectl exec ubuntuapp -- curl frontend
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
<html>
<style>
  h1   {color:green}
  h2   {color:red}
</style>
  <div align="center">
  <head>
    <title>Contrail Pod</title>
  </head>
  <body>
    <h1>Hello</h1><br><h2>This page is served by a <b>Contrail</b> pod</h2><br><h3>IP address = 10.47.255.242<br>Hostname = frontend-vrlz9</h3>
    <img src="/static/giphy.gif">
  </body>
  </div>
</html>
100   353  100   353    0     0  25268      0 --:--:-- --:--:-- --:--:-- 27153
```

### URL Based Load Balancers

One evolution of previous construct is per-URL load balancing

![](https://github.com/ovaleanujnpr/kubernetes/blob/master/images/k8s-image5.png)

```
$ cd ../exercise2
$ cat rc-frontend-dev.yaml
$ cat rc-frontend-qa.yam
$ kubectl create -f rc-frontend-dev.yaml
$ kubectl create -f rc-frontend-qa.yaml
$ kubectl get pods -o wide
NAME                READY   STATUS    RESTARTS   AGE   IP              NODE             NOMINATED NODE   READINESS GATES
frontend-8pr7f      1/1     Running   0          47m   10.47.255.243   ru16-k8s-node1   <none>           <none>
frontend-l6tdw      1/1     Running   0          47m   10.47.255.241   ru16-k8s-node3   <none>           <none>
frontend-vrlz9      1/1     Running   0          47m   10.47.255.242   ru16-k8s-node2   <none>           <none>
ubuntuapp           1/1     Running   0          48m   10.47.255.244   ru16-k8s-node2   <none>           <none>
web-app-dev-8thq8   1/1     Running   0          37m   10.47.255.240   ru16-k8s-node2   <none>           <none>
web-app-dev-jqc68   1/1     Running   0          37m   10.47.255.238   ru16-k8s-node1   <none>           <none>
web-app-dev-lkkrl   1/1     Running   0          37m   10.47.255.239   ru16-k8s-node3   <none>           <none>
web-app-qa-kt6qx    1/1     Running   0          37m   10.47.255.236   ru16-k8s-node2   <none>           <none>
web-app-qa-pw9b9    1/1     Running   0          37m   10.47.255.237   ru16-k8s-node3   <none>           <none>
web-app-qa-wf55s    1/1     Running   0          37m   10.47.255.235   ru16-k8s-node1   <none>           <none>

$ cat svc-frontend-dev.yaml
$ cat svc-frontend-qa.yaml
$ kubectl create -f svc-frontend-dev.yaml
$ kubectl create -f svc-frontend-qa.yaml
$ kubectl get svc
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
frontend      ClusterIP   10.98.129.6     <none>        80/TCP    42m
kubernetes    ClusterIP   10.96.0.1       <none>        443/TCP   15h
web-app-dev   ClusterIP   10.104.62.209   <none>        80/TCP    38m
web-app-qa    ClusterIP   10.108.195.59   <none>        80/TCP    38m
```

Now check basic load balancing within each service and look for the ip addresses.

```
$ kubectl exec ubuntuapp -- curl web-app-dev
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
<html>
<style>
  h1   {color:green}
  h2   {color:blue}
</style>
  <div align="center">
  <head>
    <title>DEV Pod</title>
  </head>
  <body>
    <h1>Hello</h1><br><h2>This page is served by a nginx pod in <b>DEV</b> namespace</h2><br><h3>IP address = 10.47.255.240<br>Hostname = web-app-dev-8thq8</h3>
  </body>
  </div>
</html>
100   332  100   332    0     0  27179      0 --:--:-- --:--:-- --:--:-- 27666

$ kubectl exec ubuntuapp -- curl web-app-qa
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
<html>
<style>
  h1   {color:green}
  h2   {color:blue}
</style>
  <div align="center">
  <head>
    <title>QA Pod</title>
  </head>
  <body>
    <h1>Hello</h1><br><h2>This page is served by a nginx pod in <b>QA</b> namespace</h2><br><h3>IP address = 10.47.255.235<br>Hostname = web-app-qa-wf55s</h3>
  </body>
  </div>
</html>
100   329  100   329    0     0  22802      0 --:--:-- --:--:-- --:--:-- 23500
```

Now create the URL based load balancer

```
$ cat ingress-frontend.yaml
$ kubectl create -f ingress-frontend.yaml
$ kubectl get ingress
NAME             CLASS    HOSTS   ADDRESS         PORTS   AGE
name-based-ing   <none>   *       10.47.255.234   80      40m
```

Check the IP address of the ingress construct, and verify per-URL load balancing

```
$ kubectl exec ubuntuapp -- curl 10.47.255.234/dev
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
<html>
<style>
  h1   {color:green}
  h2   {color:blue}
</style>
  <div align="center">
  <head>
    <title>DEV Pod</title>
  </head>
  <body>
    <h1>Hello</h1><br><h2>This page is served by a nginx pod in <b>DEV</b> namespace</h2><br><h3>IP address = 10.47.255.238<br>Hostname = web-app-dev-jqc68</h3>
  </body>
  </div>
</html>
100   332  100   332    0     0  28786      0 --:--:-- --:--:-- --:--:-- 30181

$ kubectl exec ubuntuapp -- curl 10.47.255.234/qa
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
<html>
<style>
  h1   {color:green}
  h2   {color:blue}
</style>
  <div align="center">
  <head>
    <title>QA Pod</title>
  </head>
  <body>
    <h1>Hello</h1><br><h2>This page is served by a nginx pod in <b>QA</b> namespace</h2><br><h3>IP address = 10.47.255.235<br>Hostname = web-app-qa-wf55s</h3>
  </body>
  </div>
</html>
100   329  100   329    0     0  31910      0 --:--:-- --:--:-- --:--:-- 32900
```

### NodePort services

Another way to load balance a service is using a NodePort service. When a service is exposed using NodePort the service is reachable on via the [HOSTIP:PORT_NUMBER].
The Kubernetes Dasboard we accessed it using NodePort services.

```
$ cd ../exercise3
$ cat rc-frontend.yaml
$ kubectl create -f rc-frontend.yaml
$ $ kubectl get pods -o wide | grep np
NAME                READY   STATUS    RESTARTS   AGE   IP              NODE             NOMINATED NODE   READINESS GATES
np-example-7z69r    1/1     Running   0          12s   10.47.255.233   ru16-k8s-node2   <none>           <none>
np-example-b45js    1/1     Running   0          12s   10.47.255.231   ru16-k8s-node1   <none>           <none>
np-example-sf8s6    1/1     Running   0          12s   10.47.255.232   ru16-k8s-node3   <none>           <none>

$ kubectl expose rc/np-example --name=np-svc --type=NodePort
$ kubectl get svc -o wide
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE   SELECTOR
frontend      ClusterIP   10.98.129.6     <none>        80/TCP         50m   app=frontend
kubernetes    ClusterIP   10.96.0.1       <none>        443/TCP        15h   <none>
np-svc        NodePort    10.96.197.199   <none>        80:32189/TCP   15s   app=frontend
web-app-dev   ClusterIP   10.104.62.209   <none>        80/TCP         46m   app=web-app-dev
web-app-qa    ClusterIP   10.108.195.59   <none>        80/TCP         46m   app=web-app-qa

$ curl 172.16.133.154:32189

<html>
<style>
  h1   {color:green}
  h2   {color:red}
</style>
  <div align="center">
  <head>
    <title>Contrail Pod</title>
  </head>
  <body>
    <h1>Hello</h1><br><h2>This page is served by a <b>Contrail</b> pod</h2><br><h3>IP address = 10.47.255.241<br>Hostname = frontend-l6tdw</h3>
    <img src="/static/giphy.gif">
  </body>
  </div>
</html>
```

### Isolation (Namespace and Custom)

**Isolated Namespace** has its own default pod-network and service-network, including two new VRFs are also created for each isolated namspace. The same flat-subnets '10.32.0.0/12' and '10.96.0.0/12' are shared by the pod and service networks in the isolated namespaces. However, since the networks are with a different VRF, by default it is isolated with other NS. Pods launched in isolated NS can only talk to service and pods on the same namespace. Additional configurations, e.g. policy, is required to enable the pod to reach the network outside of the current namespace.

![](https://github.com/ovaleanujnpr/kubernetes/blob/master/images/k8s-image6.png)


You will create two isolated namespaces `dev`, `qa` and spawn some pods in each namespace. The annotation means namspace is isolated. The namespaces will have SNAT enabled.
```
annotations: {
      "opencontrail.org/isolation": "true",
```

```
$ cd ../exercise4
$ cat ns-dev-isolated.yaml
apiVersion: v1
kind: Namespace
metadata:
 name: "dev-isolated"
 annotations: {
      "opencontrail.org/isolation": "true",
      "opencontrail.org/ip_fabric_snat": "true"
}

$ $ cat ns-qa-isolated.yaml
apiVersion: v1
kind: Namespace
metadata:
 name: "qa-isolated"
 annotations: {
      "opencontrail.org/isolation": "true",
      "opencontrail.org/ip_fabric_snat": "true"
}

$ kubectl create -f ns-dev-isolated.yaml
$ kubectl create -f ns-qa-isolated.yaml

$ kubectl get ns | grep isolated
dev-isolated           Active   16m
qa-isolated            Active   15m

$ kubectl create -f rc-frontend-dev.yaml -n dev-isolated
$ kubectl create -f rc-frontend-qa.yaml -n qa-isolated
$ kubectl create -f svc-frontend-dev.yaml -n dev-isolated
$ kubectl create -f svc-frontend-qa.yaml -n qa-isolated

$ kubectl get all -n dev-isolated
NAME                    READY   STATUS    RESTARTS   AGE
pod/web-app-dev-66h4n   1/1     Running   0          49s
pod/web-app-dev-hb58f   1/1     Running   0          49s
pod/web-app-dev-kwj5j   1/1     Running   0          49s

NAME                                DESIRED   CURRENT   READY   AGE
replicationcontroller/web-app-dev   3         3         3       49s

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/web-app-dev   ClusterIP   10.105.134.59   <none>        80/TCP    36s

$ kubectl get all -n qa-isolated
NAME                   READY   STATUS    RESTARTS   AGE
pod/web-app-qa-2b89l   1/1     Running   0          48s
pod/web-app-qa-c6g48   1/1     Running   0          48s
pod/web-app-qa-klmnr   1/1     Running   0          48s

NAME                               DESIRED   CURRENT   READY   AGE
replicationcontroller/web-app-qa   3         3         3       48s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/web-app-qa   ClusterIP   10.109.233.177   <none>        80/TCP    36s
```

Check if you can ping using ubuntuapp pod any frontend from `qa` and `dev` namespaces

```
$ kubectl exec ubuntuapp -- curl web-app-dev.dev-isolated
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:05 --:--:--     0^C

$ kubectl exec ubuntuapp -- curl web-app-qa.qa-isolated
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:01 --:--:--     0^C
```

Communication fails. In isolation mode, PODs cannot reach PODs from different namespaces.

**Custom Mode ** allows users to interconnect their workloads with other Infrastructure services tools like OpenStack, vCenter, BMS or Public Clouds.

You will create a new virtual network called blue-net with one subnet such as 10.10.10.0/24.

```
$ cd../exercise5
$ cat blue-net.yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
 name: blue-net
 annotations: {
   "opencontrail.org/cidr" : "10.10.10.0/24",
   "opencontrail.org/ip_fabric_snat": "true"
   }
spec:
 config: '{
   "cniVersion": "0.3.1",
   "type": "contrail-k8s-cni"
}'

$ kubectl create -f blue-net.yaml
```

Now you will create a pod in this virtual network

```
$ cat blue-pod.yaml
apiVersion: v1
kind: Pod
metadata:
 name: blue-pod
 annotations: {
    "opencontrail.org/network" : '{"domain":"default-domain", "project": "k8s-default", "name":"k8s-blue-net-pod-network"}'
  }
spec:
 containers:
   - name: ubuntuapp
     image: ubuntu-upstart

$ kubectl create -f blue-pod.yaml
$ kubectl get pods -o wide| grep blue
blue-pod            1/1     Running   0          12s    10.10.10.252    ru16-k8s-node3   <none>           <none>

$ kubectl exec -it blue-pod -- bash
root@blue-pod:/# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: ip_vti0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
42: eth0@if43: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:71:c1:6f:a4:12 brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.252/24 scope global eth0
       valid_lft forever preferred_lft forever
```

The pod is running isolated in his custom network

### Pod multi interfaces

Contrail has natively the ability to create pods with multi interfaces. This exercise will demonstrate multi-interface pod in Kubernetes with Contrail 2008.
Create two virtual networks `red-net` and `green-net` in Contrail

```
$ cd ../exercise6

$ cat red-green-net.yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
 name: red-net
 annotations: {
   "opencontrail.org/cidr" : "20.20.20.0/24",
   "opencontrail.org/ip_fabric_snat": "true"
   }
spec:
 config: '{
   "cniVersion": "0.3.1",
   "type": "contrail-k8s-cni"
}'

---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
 name: green-net
 annotations: {
   "opencontrail.org/cidr" : "30.30.30.0/24",
   "opencontrail.org/ip_fabric_snat": "true"
  }
spec:
 config: '{
   "cniVersion": "0.3.1",
   "type": "contrail-k8s-cni"
}'

$ kubectl create -f red-green-net.yaml
```

Now create a pod with network interfaces in both custom networks `red-net` and `green-net`

```
$ cat ubuntu-multi-nic.yaml
apiVersion: v1
kind: Pod
metadata:
 name: multi-intf-pod
 annotations:
   k8s.v1.cni.cncf.io/networks: '[
     { "name": "red-net" },
     { "name": "green-net" }
   ]'
spec:
 containers:
   - name: ubuntuapp
     image: ubuntu-upstart

$ kubectl create -f ubuntu-multi-nic.yaml
$ $ kubectl get pods | grep multi
multi-intf-pod      1/1     Running   0          5m10s
```

Connect to the pod to check network interfacea. As you can see the pod has a network interface in each virtual network defined and an interface in default podNetwork.

```
$ kubectl describe pod/multi-intf-pod
Name:         multi-intf-pod
Namespace:    default
Priority:     0
Node:         ru16-k8s-node2/172.16.133.155
Start Time:   Tue, 20 Oct 2020 09:00:05 -0400
Labels:       <none>
Annotations:  k8s.v1.cni.cncf.io/network-status:
                [
                    {
                        "ips": "20.20.20.252",
                        "mac": "02:2c:6f:b2:38:12",
                        "name": "red-net"
                    },
                    {
                        "ips": "30.30.30.252",
                        "mac": "02:2c:88:4b:18:12",
                        "name": "green-net"
                    },
                    {
                        "ips": "10.47.255.224",
                        "mac": "02:2c:59:66:f4:12",
                        "name": "cluster-wide-default"
                    }
                ]
              k8s.v1.cni.cncf.io/networks: [ { "name": "red-net" }, { "name": "green-net" } ]
Status:       Running
IP:           10.47.255.224


$ kubectl exec -it multi-intf-pod -- bash
root@multi-intf-pod:/# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: ip_vti0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
48: eth0@if49: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:2c:59:66:f4:12 brd ff:ff:ff:ff:ff:ff
    inet 10.47.255.224/12 scope global eth0
       valid_lft forever preferred_lft forever
50: eth1@if51: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:2c:6f:b2:38:12 brd ff:ff:ff:ff:ff:ff
    inet 20.20.20.252/24 scope global eth1
       valid_lft forever preferred_lft forever
52: eth2@if53: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:2c:88:4b:18:12 brd ff:ff:ff:ff:ff:ff
    inet 30.30.30.252/24 scope global eth2
       valid_lft forever preferred_lft forever
```

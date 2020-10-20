## Contrail Kubernetes lab guide

Download the lab folder.

```
$ git clone ....
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
apiVersion: v1
kind: Pod
metadata:
  name: ubuntuapp
  labels:
    app: ubuntuapp
spec:
  containers:
    - name: ubuntuapp
      image: ubuntu-upstart
      command: ["/bin/bash","-c","while true; do sleep 10;done"]

$ kubectl create -f ubuntu.yaml

$ cat rc-frontend.yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: frontend
spec:
  replicas: 3
  selector:
    app: frontend
  template:
    metadata:
      name: frontend
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: savvythru/contrail-frontend-app
        ports:
        - containerPort: 80

$ kubectl create -f rc-frontend.yaml

$ NAME                READY   STATUS    RESTARTS   AGE   IP              NODE             NOMINATED NODE   READINESS GATES
frontend-8pr7f      1/1     Running   0          23m   10.47.255.243   ru16-k8s-node1   <none>           <none>
frontend-l6tdw      1/1     Running   0          23m   10.47.255.241   ru16-k8s-node3   <none>           <none>
frontend-vrlz9      1/1     Running   0          23m   10.47.255.242   ru16-k8s-node2   <none>           <none>
ubuntuapp           1/1     Running   0          24m   10.47.255.244   ru16-k8s-node2   <none>           <none>
```

Check connectivity betwwen the pods. So far there is no load balancing, there is simple any-to-any connectivity.

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

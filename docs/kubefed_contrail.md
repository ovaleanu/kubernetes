## Multi-cloud Kubernetes clusters running Contrail with KubeFed

KubeFed is the newest and current solution for federation from Kubernetes.

For my test I will use 2 Kubernetes clusters running Contrail.
What I want to demo?
1. Deploy KubeFed on a host cluster
2. Join the K8s clusters
3. Deploy a simple app via the host cluster and federate it on the other cluster
4. Establish end-to-end connectivity to the deployed app.

Both clusters are running Kubernetes v.18.8. Please refer to installation procedures for mainstream [Kubernetes with Contrail](https://github.com/ovaleanujnpr/Kubernetes/wiki/Installing-Kubernetes-with-Contrail).

One of the clusters will be the _Host Cluster_. This is the cluster which is used to expose the KubeFed API and run the KubeFed Control Plane.
The other cluster will be _Member Custer_. This is the cluster which is registered with the KubeFed API and that KubeFed controllers have authentication credentials for. The _Host Cluster_ can also be a _Member Cluster_.

### Deploy KubeFed on a Host Cluster

First I need to combine all the kubeconfigs and contexts. I am using kubectx to switch between the clusters.

Get cluster contexts
```
$ kubectl config get-contexts
CURRENT   NAME            CLUSTER                                           AUTHINFO                                          NAMESPACE
*         contrail-1      contrail-1                                        kubernetes-admin
          contrail-2      contrail-2                                        cluster-admin
```

```
$ kubectx
contrail-1
contrail-2
```

```
$ kubectx contrail-1
Switched to context "contrail-1".

$ kubectl get nodes -o wide
NAME      STATUS   ROLES    AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
master1   Ready    master   46d   v1.18.8   192.168.213.131   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
master2   Ready    master   46d   v1.18.8   192.168.213.132   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
master3   Ready    master   46d   v1.18.8   192.168.213.133   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
node1     Ready    <none>   46d   v1.18.8   192.168.213.134   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9
node2     Ready    <none>   46d   v1.18.8   192.168.213.135   <none>        Ubuntu 18.04.4 LTS   4.15.0-112-generic   docker://18.9.9

$ kubectl get pods -n kube-system
NAME                                READY   STATUS    RESTARTS   AGE
config-zookeeper-lplxh              1/1     Running   1          46d
config-zookeeper-nlk9c              1/1     Running   1          46d
config-zookeeper-pnwnk              1/1     Running   1          46d
contrail-agent-b6fd4                3/3     Running   3          46d
contrail-agent-dlzbq                3/3     Running   7          46d
contrail-agent-fq7rc                3/3     Running   3          46d
contrail-agent-gx9fz                3/3     Running   6          46d
contrail-agent-lchd6                3/3     Running   3          46d
contrail-analytics-alarm-tphpx      4/4     Running   26         46d
contrail-analytics-alarm-zv9lx      4/4     Running   12         46d
contrail-analytics-g6cjm            4/4     Running   8          46d
contrail-analytics-h7kgw            4/4     Running   7          46d
contrail-analytics-snmp-ffkj5       4/4     Running   15         46d
contrail-analytics-snmp-lqsmp       4/4     Running   14         46d
contrail-analytics-snmp-mwmk4       4/4     Running   16         46d
contrail-configdb-h7hbb             3/3     Running   6          46d
contrail-configdb-zftk8             3/3     Running   6          46d
contrail-controller-config-c8jqv    6/6     Running   14         46d
contrail-controller-config-gxh2z    6/6     Running   16         46d
contrail-controller-config-zw7mp    6/6     Running   12         46d
contrail-controller-control-dlrbn   5/5     Running   7          46d
contrail-controller-control-f2nks   5/5     Running   7          46d
contrail-controller-control-qbl5f   5/5     Running   7          46d
contrail-controller-webui-f7zt7     2/2     Running   4          46d
contrail-controller-webui-gc228     2/2     Running   4          46d
contrail-kube-manager-6gvct         1/1     Running   2          46d
contrail-kube-manager-lk4nh         1/1     Running   1          46d
contrail-kube-manager-mt6xc         1/1     Running   2          46d
coredns-684f7f6cb4-29hrm            1/1     Running   0          5d1h
coredns-684f7f6cb4-bm2kg            1/1     Running   0          5d1h
etcd-master1                        1/1     Running   0          5d3h
etcd-master2                        1/1     Running   0          5d3h
etcd-master3                        1/1     Running   0          5d3h
kube-apiserver-master1              1/1     Running   0          5d3h
kube-apiserver-master2              1/1     Running   0          5d3h
kube-apiserver-master3              1/1     Running   0          5d3h
kube-controller-manager-master1     1/1     Running   4          5d3h
kube-controller-manager-master2     1/1     Running   3          5d3h
kube-controller-manager-master3     1/1     Running   4          5d3h
kube-proxy-7xw85                    1/1     Running   0          5d3h
kube-proxy-ffhz7                    1/1     Running   0          5d3h
kube-proxy-k572k                    1/1     Running   0          5d3h
kube-proxy-kp95k                    1/1     Running   0          5d3h
kube-proxy-wpbx6                    1/1     Running   0          5d3h
kube-scheduler-master1              1/1     Running   3          5d3h
kube-scheduler-master2              1/1     Running   3          5d3h
kube-scheduler-master3              1/1     Running   3          5d3h
rabbitmq-46fpp                      1/1     Running   1          46d
rabbitmq-lx67l                      1/1     Running   1          46d
rabbitmq-sv244                      1/1     Running   1          46d
redis-2kqt2                         1/1     Running   1          46d
redis-krg6w                         1/1     Running   1          46d
redis-lrw6t                         1/1     Running   1          46d
```
```
$ kubectx contrail-2
Switched to context "contrail-2".

$ kubectl get nodes -o wide
NAME       STATUS   ROLES    AGE    VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
master1a   Ready    master   3d2h   v1.18.8   192.168.213.136   <none>        Ubuntu 18.04.5 LTS   4.15.0-117-generic   docker://18.9.9
node1a     Ready    <none>   3d2h   v1.18.8   192.168.213.137   <none>        Ubuntu 18.04.5 LTS   4.15.0-117-generic   docker://18.9.9
node2a     Ready    <none>   3d2h   v1.18.8   192.168.213.138   <none>        Ubuntu 18.04.5 LTS   4.15.0-117-generic   docker://18.9.9

$ kubectl get pods -n kube-system
NAME                                READY   STATUS    RESTARTS   AGE
config-zookeeper-qqljr              1/1     Running   0          2d23h
contrail-agent-7q6nn                3/3     Running   0          2d23h
contrail-agent-8jqdw                3/3     Running   0          2d23h
contrail-agent-xsswr                3/3     Running   0          2d23h
contrail-analytics-4n9wk            4/4     Running   0          2d23h
contrail-analytics-alarm-clqsf      4/4     Running   0          2d23h
contrail-analytics-snmp-7wwks       4/4     Running   0          2d23h
contrail-analyticsdb-2mcbp          4/4     Running   0          2d23h
contrail-configdb-n69dw             3/3     Running   0          2d23h
contrail-controller-config-h8nzn    6/6     Running   0          2d23h
contrail-controller-control-czjw8   5/5     Running   0          2d23h
contrail-controller-webui-wbw2g     2/2     Running   0          2d23h
contrail-kube-manager-q2vpr         1/1     Running   0          2d23h
coredns-66bff467f8-6vvmc            1/1     Running   0          3d2h
coredns-66bff467f8-7bbrc            1/1     Running   0          3d2h
etcd-master1a                       1/1     Running   0          3d2h
kube-apiserver-master1a             1/1     Running   0          3d2h
kube-controller-manager-master1a    1/1     Running   2          3d2h
kube-proxy-2h58p                    1/1     Running   0          3d2h
kube-proxy-n6fwg                    1/1     Running   0          3d2h
kube-proxy-tk79s                    1/1     Running   0          3d2h
kube-scheduler-master1a             1/1     Running   2          3d2h
rabbitmq-9phqz                      1/1     Running   0          2d23h
redis-fjl9f                         1/1     Running   0          2d23h
````

`contrail-1` it will be the _Host Cluster_.

Installation of KubeFed is pretty straight forward. I followed the installation procedure from [KubeFed github](https://github.com/kubernetes-sigs/kubefed/blob/master/docs/installation.md).

I neeed to install Helm. Check the [installation guide](https://helm.sh/docs/intro/install/).
```
$ curl https://helm.baltorepo.com/organization/signing.asc | sudo apt-key add -
$ sudo apt-get install apt-transport-https --yes
$ echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
$ sudo apt-get update
$ sudo apt-get install helm
```
Clone local static provisioner repo
```
$ helm repo add kubefed-charts https://raw.githubusercontent.com/kubernetes-sigs/kubefed/master/charts

$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "kubefed-charts" chart repository
Update Complete. ⎈ Happy Helming!⎈

$ helm search repo kubefed
NAME                        	CHART VERSION	APP VERSION	DESCRIPTION
kubefed-charts/kubefed      	0.4.0        	           	KubeFed helm chart
kubefed-charts/federation-v2	0.0.10       	           	Kubernetes Federation V2 helm chart
```

Now, I will deploy the help chart
```
$ helm --namespace kube-federation-system upgrade -i kubefed kubefed-charts/kubefed --version=0.4.0 --create-namespace
Release "kubefed" does not exist. Installing it now.
NAME: kubefed
LAST DEPLOYED: Mon Sep 14 15:04:17 2020
NAMESPACE: kube-federation-system
STATUS: deployed
REVISION: 1
TEST SUITE: None

$ helm ls -A
NAME   	NAMESPACE             	REVISION	UPDATED                                	STATUS  	CHART            	APP VERSION
kubefed	kube-federation-system	1       	2020-09-14 15:04:17.020792233 -0400 EDT	deployed	kubefed-0.4.0
sc1    	storageclass          	1       	2020-07-30 08:04:21.658546624 -0400 EDT	deployed	provisioner-3.0.0	2.3.4
```

Check the pods to see if the controllers and webhooks are up
```
$ kubectl get po -n kube-federation-system
NAME                                         READY   STATUS    RESTARTS   AGE
kubefed-admission-webhook-969b7496f-8c7q6    1/1     Running   0          3d4h
kubefed-controller-manager-fdb945d8c-kptrd   1/1     Running   0          3d4h
kubefed-controller-manager-fdb945d8c-ktws6   1/1     Running   0          3d4h
```

### Adding clusters

After KubeFed control plane is install on the _Host Cluster_, it is time to add the other cluster.
For this I need the `kubefedctl` cli tool.

```
$ wget https://github.com/kubernetes-sigs/kubefed/releases/download/v0.4.0/kubefedctl-0.4.0-linux-amd64.tgz
$ tar xvzf kubefedctl-0.4.0-linux-amd64.tgz
$ chmod +x kubefedctl
$ sudo mv kubefedctl /usr/local/bin/kubefedctl
$ $ kubefedctl version
kubefedctl version: version.Info{Version:"v0.3.1-113-g6eeeac232", GitCommit:"6eeeac232dcd7556054d2c2042069684f11a08cc", GitTreeState:"clean", BuildDate:"2020-08-17T16:13:02Z", GoVersion:"go1.14.7", Compiler:"gc", Platform:"linux/amd64"}
```

Now I can register the clusters with the kubefed control plane

```
$ kubefedctl join contrail-1 --cluster-context contrail-1 --host-cluster-context contrail-1 --v=2
I0914 17:06:59.044505   14137 join.go:160] Args and flags: name contrail-1, host: contrail-1, host-system-namespace: kube-federation-system, kubeconfig: , cluster-context: contrail-1, secret-name: , dry-run: false
I0914 17:06:59.078548   14137 join.go:242] Performing preflight checks.
I0914 17:06:59.081639   14137 join.go:248] Creating kube-federation-system namespace in joining cluster
I0914 17:06:59.084378   14137 join.go:389] Already existing kube-federation-system namespace
I0914 17:06:59.084410   14137 join.go:256] Created kube-federation-system namespace in joining cluster
I0914 17:06:59.084422   14137 join.go:412] Creating service account in joining cluster: contrail-1
I0914 17:06:59.091305   14137 join.go:422] Created service account: contrail-1-contrail-1 in joining cluster: contrail-1
I0914 17:06:59.091319   14137 join.go:450] Creating cluster role and binding for service account: contrail-1-contrail-1 in joining cluster: contrail-1
I0914 17:06:59.105421   14137 join.go:459] Created cluster role and binding for service account: contrail-1-contrail-1 in joining cluster: contrail-1
I0914 17:06:59.105444   14137 join.go:820] Creating cluster credentials secret in host cluster
I0914 17:06:59.109983   14137 join.go:848] Using secret named: contrail-1-contrail-1-token-qc6kg
I0914 17:06:59.114784   14137 join.go:893] Created secret in host cluster named: contrail-1-n6cn7
I0914 17:06:59.130077   14137 join.go:284] Created federated cluster resource

$ kubefedctl join contrail-2 --cluster-context contrail-2 --host-cluster-context contrail-1 --v=2
I0911 15:08:20.606119    8600 join.go:160] Args and flags: name contrail-2, host: contrail-1, host-system-namespace: kube-federation-system, kubeconfig: , cluster-context: contrail-2, secret-name: , dry-run: false
I0911 15:08:20.639781    8600 join.go:242] Performing preflight checks.
I0911 15:08:20.649723    8600 join.go:248] Creating kube-federation-system namespace in joining cluster
I0911 15:08:20.654783    8600 join.go:256] Created kube-federation-system namespace in joining cluster
I0911 15:08:20.654801    8600 join.go:412] Creating service account in joining cluster: contrail-2
I0911 15:08:20.661230    8600 join.go:422] Created service account: contrail-2-contrail-1 in joining cluster: contrail-2
I0911 15:08:20.661245    8600 join.go:450] Creating cluster role and binding for service account: contrail-2-contrail-1 in joining cluster: contrail-2
I0911 15:08:20.679216    8600 join.go:459] Created cluster role and binding for service account: contrail-2-contrail-1 in joining cluster: contrail-2
I0911 15:08:20.679236    8600 join.go:820] Creating cluster credentials secret in host cluster
I0911 15:08:20.682399    8600 join.go:848] Using secret named: contrail-2-contrail-1-token-t5rj7
I0911 15:08:20.696698    8600 join.go:893] Created secret in host cluster named: contrail-2-dzddb
I0911 15:08:20.718870    8600 join.go:284] Created federated cluster resource
```

Check if both clusters have joined
```
$ kubectl get kubefedclusters -n kube-federation-system
NAME            AGE     READY
contrail-1      16m     True
contrail-2      26m     True
```

### Deploy a federated app

I have the KubeFed Control Plane up and running with both clusters registered. Now, I am  going to deploy a federated application. This application is a nginx web server serving a welcome page.

I will label the nodes that are part of the federation

```
$ kubectl label kubefedclusters -n kube-federation-system contrail-1 federation-enabled=true
kubefedcluster.core.kubefed.io/contrail-1 labeled
$ kubectl label kubefedclusters -n kube-federation-system contrail-2 federation-enabled=true
kubefedcluster.core.kubefed.io/contrail-2 labeled
$ kubectl get kubefedclusters   -n kube-federation-system --show-labels
NAME         AGE   READY   LABELS
contrail-1   34m   True    federation-enabled=true
contrail-2   44m   True    federation-enabled=true
```

I will create a federate namespace in Host Cluster and then propagate it to Member Cluster

```
$ kubectl create ns kubefed-test

$ cat kubefed-ns.yaml
apiVersion: types.kubefed.io/v1beta1
kind: FederatedNamespace
metadata:
  name: kubefed-test
  namespace: kubefed-test
spec:
  placement:
    clusterSelector:
      matchLabels:
        federation-enabled: "true"

$ kubectl apply -f kubefed-ns.yaml
federatednamespace.types.kubefed.io/kubefed-test created

$ kubectl --context=contrail-1 get ns | grep kubefed-test
kubefed-test               Active   15m

$ kubectl --context=contrail-2 get ns | grep kubefed-test
kubefed-test             Active   9m22s
```

Before creating the application objects, I need to enable the types I want to federate, like:

`namespaces`
`services`
`deployments.apps`

```
$ for type in namespaces services deployments.apps; do kubefedctl enable $type --kubefed-namespace kubefed-test; done
customresourcedefinition.apiextensions.k8s.io/federatednamespaces.types.kubefed.io updated
federatedtypeconfig.core.kubefed.io/namespaces updated in namespace kubefed-test
customresourcedefinition.apiextensions.k8s.io/federatedservices.types.kubefed.io updated
federatedtypeconfig.core.kubefed.io/services updated in namespace kubefed-test
customresourcedefinition.apiextensions.k8s.io/federateddeployments.types.kubefed.io updated
federatedtypeconfig.core.kubefed.io/deployments.apps updated in namespace kubefed-test
```

I will take a simple nginx deployment like this [one](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#creating-a-deployment)

```
$ cat nginx-deployment-simple.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: kubefed-test
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```
I will use `kubefedctl` to federate this deployment. It will generate a new yaml file

```
$ kubefedctl federate -f nginx-deployment-simple.yaml > nginx-deployment-fed.yaml
$ cat nginx-deployemnt-fed.yaml
---
apiVersion: types.kubefed.io/v1beta1
kind: FederatedDeployment
metadata:
  name: nginx-deployment
  namespace: kubefed-test
spec:
  placement:
    clusterSelector:
      matchLabels: {}
  template:
    metadata:
      labels:
        app: nginx
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - image: nginx:1.14.2
            name: nginx
            ports:
            - containerPort: 80
```

Apply the new federated yaml file

```
kubectl create -f nginx-deployemnt-fed.yaml
```

Three replicas of nginx are running on both clusters

```
$ for c in `kubectl config get-contexts --no-headers=true -o name|grep -v k8s-cluster-kubefed `; do echo "Getting pods  in context $c"; kubectl get pods -n  kubefed-test  --context=$c; done
Getting pods  in context contrail-1
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-6b474476c4-vvr6k   1/1     Running   0          3m45s
nginx-deployment-6b474476c4-w7dgx   1/1     Running   0          3m45s
nginx-deployment-6b474476c4-xqz4g   1/1     Running   0          3m45s
Getting pods  in context contrail-2
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-6b474476c4-5crhd   1/1     Running   0          3m45s
nginx-deployment-6b474476c4-fnvb4   1/1     Running   0          3m45s
nginx-deployment-6b474476c4-qn2x2   1/1     Running   0          3m45s
```

I will use the _overrides_ element in FederatedDeployment to scale up replicas for contrail-2 cluster.

```
kubectl get federateddeployment -n kubefed-test
NAME               AGE
nginx-deployment   176m
lab@master1:~$ kubectl edit federateddeployment/nginx-deployment -n kubefed-test
federateddeployment.types.kubefed.io/nginx-deployment edited
```
Add the `overrides` part like below

```
spec:
  placement:
    clusterSelector:
      matchLabels: {}
  template:
    metadata:
      labels:
        app: nginx
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - image: nginx:1.14.2
            name: nginx
            ports:
            - containerPort: 80
  overrides:
    - clusterName: contrail-2
      clusterOverrides:
      - path: "/spec/replicas"
        value: 5
```

Check the pods again. On contrail-2 cluster I have 5 replicas of nginx.

```
$ for c in `kubectl config get-contexts --no-headers=true -o name|grep -v k8s-cluster-kubefed `; do echo "Getting pods  in context $c"; kubectl get pods -n  kubefed-test  --context=$c; done
Getting pods  in context contrail-1
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-6b474476c4-vvr6k   1/1     Running   0          3h1m
nginx-deployment-6b474476c4-w7dgx   1/1     Running   0          3h1m
nginx-deployment-6b474476c4-xqz4g   1/1     Running   0          3h1m
Getting pods  in context contrail-2
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-6b474476c4-5crhd   1/1     Running   0          3h1m
nginx-deployment-6b474476c4-9d7j5   1/1     Running   0          28s
nginx-deployment-6b474476c4-fdg6w   1/1     Running   0          28s
nginx-deployment-6b474476c4-fnvb4   1/1     Running   0          3h1m
nginx-deployment-6b474476c4-qn2x2   1/1     Running   0          3h1m
```

The FederatedDeployment in detail:

```
lab@master1:~$ kubectl describe federateddeployments -n kubefed-test
Name:         nginx-deployment
Namespace:    kubefed-test
Labels:       <none>
Annotations:  <none>
API Version:  types.kubefed.io/v1beta1
Kind:         FederatedDeployment
Metadata:
  Creation Timestamp:  2020-09-15T07:46:23Z
  Finalizers:
    kubefed.io/sync-controller
  Generation:  2
  Managed Fields:
    API Version:  types.kubefed.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:finalizers:
          .:
          v:"kubefed.io/sync-controller":
      f:status:
        .:
        f:clusters:
        f:conditions:
        f:observedGeneration:
    Manager:      controller-manager
    Operation:    Update
    Time:         2020-09-15T10:47:50Z
    API Version:  types.kubefed.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:spec:
        .:
        f:overrides:
        f:placement:
          .:
          f:clusterSelector:
            .:
            f:matchLabels:
        f:template:
          .:
          f:metadata:
            .:
            f:labels:
              .:
              f:app:
          f:spec:
            .:
            f:replicas:
            f:selector:
              .:
              f:matchLabels:
                .:
                f:app:
            f:template:
              .:
              f:metadata:
                .:
                f:labels:
                  .:
                  f:app:
              f:spec:
                .:
                f:containers:
    Manager:         kubectl
    Operation:       Update
    Time:            2020-09-15T10:47:50Z
  Resource Version:  2866408
  Self Link:         /apis/types.kubefed.io/v1beta1/namespaces/kubefed-test/federateddeployments/nginx-deployment
  UID:               859d1373-bc0c-4494-8d6a-3f1cebafef21
Spec:
  Overrides:
    Cluster Name:  contrail-2
    Cluster Overrides:
      Path:   /spec/replicas
      Value:  5
  Placement:
    Cluster Selector:
      Match Labels:
  Template:
    Metadata:
      Labels:
        App:  nginx
    Spec:
      Replicas:  3
      Selector:
        Match Labels:
          App:  nginx
      Template:
        Metadata:
          Labels:
            App:  nginx
        Spec:
          Containers:
            Image:  nginx:1.14.2
            Name:   nginx
            Ports:
              Container Port:  80
Status:
  Clusters:
    Name:  contrail-2
    Name:  contrail-1
  Conditions:
    Last Transition Time:  2020-09-15T07:46:23Z
    Last Update Time:      2020-09-15T10:47:50Z
    Status:                True
    Type:                  Propagation
  Observed Generation:     2
Events:
  Type    Reason           Age   From                            Message
  ----    ------           ----  ----                            -------
  Normal  UpdateInCluster  3m7s  federateddeployment-controller  Updating Deployment "kubefed-test/nginx-deployment" in cluster "contrail-1"
  Normal  UpdateInCluster  3m7s  federateddeployment-controller  Updating Deployment "kubefed-test/nginx-deployment" in cluster "contrail-2"
```

Now I will create a service and then federate it. Starting from a simple service yaml file, I am going to generate the FederatedService similar with FederatedDeployment.

```
$ cat nginx-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: kubefed-test
spec:
  template:
    spec:
      selector:
        app: nginx
      type: NodePort
      ports:
        - name: http
          port: 80


```

```
kubefedctl federate -f nginx-svc.yaml > nginx-svc-fed.yaml
```

```
$ cat nginx-svc-fed.yaml
---
apiVersion: types.kubefed.io/v1beta1
kind: FederatedService
metadata:
  name: nginx-service
  namespace: kubefed-test
spec:
  placement:
    clusterSelector:
      matchLabels: {}
  template:
    spec:
       selector:
         app: nginx
       type: NodePort
       ports:
         - name: http
           port: 80
```
Apply the yaml file

```
$ kubectl create -f nginx-svc-fed.yaml
federatedservice.types.kubefed.io/nginx-service created
```

Check if the FederatedService was created on the clusters
```
$ for c in `kubectl config get-contexts --no-headers=true -o name|grep -v k8s-cluster-kubefed `; do echo "Getting pods  in context $c"; kubectl get svc -n  kubefed-test  --context=$c; done
Getting pods  in context contrail-1
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-service   NodePort   10.107.183.88   <none>        80:31650/TCP   21s
Getting pods  in context contrail-2
NAME            TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
nginx-service   NodePort   10.109.126.125   <none>        80:32737/TCP   22s
```

```
$ kubectl describe federatedservice -n kubefed-test
Name:         nginx-service
Namespace:    kubefed-test
Labels:       <none>
Annotations:  <none>
API Version:  types.kubefed.io/v1beta1
Kind:         FederatedService
Metadata:
  Creation Timestamp:  2020-09-15T11:34:04Z
  Finalizers:
    kubefed.io/sync-controller
  Generation:  1
  Managed Fields:
    API Version:  types.kubefed.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:spec:
        .:
        f:placement:
          .:
          f:clusterSelector:
            .:
            f:matchLabels:
        f:template:
          .:
          f:spec:
            .:
            f:ports:
            f:selector:
              .:
              f:app:
            f:type:
    Manager:      kubectl
    Operation:    Update
    Time:         2020-09-15T11:34:04Z
    API Version:  types.kubefed.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:finalizers:
          .:
          v:"kubefed.io/sync-controller":
      f:status:
        .:
        f:clusters:
        f:conditions:
        f:observedGeneration:
    Manager:         controller-manager
    Operation:       Update
    Time:            2020-09-15T11:34:05Z
  Resource Version:  2875296
  Self Link:         /apis/types.kubefed.io/v1beta1/namespaces/kubefed-test/federatedservices/nginx-service
  UID:               bdd744ff-5af7-473f-afe1-0d1b91816ab6
Spec:
  Placement:
    Cluster Selector:
      Match Labels:
  Template:
    Spec:
      Ports:
        Name:  http
        Port:  80
      Selector:
        App:  nginx
      Type:   NodePort
Status:
  Clusters:
    Name:  contrail-1
    Name:  contrail-2
  Conditions:
    Last Transition Time:  2020-09-15T11:34:05Z
    Last Update Time:      2020-09-15T11:34:05Z
    Status:                True
    Type:                  Propagation
  Observed Generation:     1
Events:
  Type    Reason           Age    From                         Message
  ----    ------           ----   ----                         -------
  Normal  CreateInCluster  6m10s  federatedservice-controller  Creating Service "kubefed-test/nginx-service" in cluster "contrail-2"
  Normal  CreateInCluster  6m10s  federatedservice-controller  Creating Service "kubefed-test/nginx-service" in cluster "contrail-1"
```

I have successfully federated a namespace along with a simple deployment, between two Kubernetes clusters running with Contrail.

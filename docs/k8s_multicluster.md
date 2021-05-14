 ## Multi-cluster Kubernetes support via a single Contrail controller

There are cases when customers need to manage the network for different clusters by a single sdn controller. Contrail has the capability to do that. In this document I will show how two K8s cluster are managed by a single Contrail SDN.

First, we need two running K8s clusters. Acvtually there isn't a limit for the number of clusters. Theoretically you can add as many as you want. For installing them you can use any of the deployment tools available, [`kubeadm` or `Kubespray`](https://kubernetes.io/docs/setup/production-environment/tools/). In this [wiki](https://github.com/ovaleanu/Kubernetes/wiki/Installing-Kubernetes-with-Contrail) I am using `kubeadm` to deploy the clusters.

Create a secret for downloading Contrail docker images on both clusters

```
$ kubectl create secret docker-registry contrail-registry --docker-server=hub.juniper.net/contrail --docker-username=JNPR-FieldUserXXX --docker-password=XXXXXXXXXXX --docker-email=user@company.com -n kube-system
```

Choose a cluster to be the master among the other clusters. On this cluster install Contrail using single yaml file using this [example](https://github.com/ovaleanu/kubernetes/blob/master/single_yaml/contrail_single_multicluster.yaml).

On the slave clusters, only contrail kubemanager and the contrail vrouter agents will be installed. Contrail kubemanager and contrail vrouter agent will connect to Contrail Controller running on the master cluster.
This is an [example](https://github.com/ovaleanu/kubernetes/blob/master/single_yaml/contrail_single_slavecluster.yaml) of yaml file to be applied on the slave clusters.


 On the master cluster you will have full Contrail Controller installed:

 ```
$ kubectl get pods -n kube-system
NAME                                READY   STATUS    RESTARTS   AGE
config-zookeeper-m55lq              1/1     Running   0          3h41m
contrail-agent-vj872                3/3     Running   0          3h41m
contrail-analytics-2pk9c            4/4     Running   0          3h41m
contrail-analytics-alarm-7qb4h      4/4     Running   0          3h41m
contrail-analyticsdb-gwwf7          4/4     Running   0          3h41m
contrail-configdb-m8nfn             3/3     Running   0          3h41m
contrail-controller-config-glkzc    6/6     Running   0          3h41m
contrail-controller-control-hwnjm   5/5     Running   0          3h41m
contrail-controller-webui-mt7t8     2/2     Running   0          3h41m
contrail-kube-manager-wcg24         1/1     Running   0          3h41m
coredns-5644d7b6d9-gf5f9            1/1     Running   0          4h16m
coredns-5644d7b6d9-rkd7m            1/1     Running   0          4h16m
etcd-m1                             1/1     Running   0          4h14m
kube-apiserver-m1                   1/1     Running   0          4h14m
kube-controller-manager-m1          1/1     Running   0          4h14m
kube-proxy-tlbl7                    1/1     Running   0          4h15m
kube-proxy-vp9n2                    1/1     Running   0          4h16m
kube-scheduler-m1                   1/1     Running   0          4h15m
rabbitmq-d9t4d                      1/1     Running   0          3h41m
redis-dn4mn                         1/1     Running   0          3h41m
```

And on the slave cluster only Contrail kubemanager and vrouters

```
$ kubectl get pods -n kube-system
NAMESPACE     NAME                          READY   STATUS    RESTARTS   AGE
kube-system   contrail-agent-k6xz5          3/3     Running   0          44m
kube-system   contrail-kube-manager-wzrzl   1/1     Running   0          44m
kube-system   coredns-5644d7b6d9-4b462      1/1     Running   0          51m
kube-system   coredns-5644d7b6d9-btj8z      1/1     Running   0          51m
kube-system   etcd-m2                       1/1     Running   0          50m
kube-system   kube-apiserver-m2             1/1     Running   0          50m
kube-system   kube-controller-manager-m2    1/1     Running   0          50m
kube-system   kube-proxy-5zcj2              1/1     Running   0          51m
kube-system   kube-proxy-p7pz5              1/1     Running   0          50m
kube-system   kube-scheduler-m2             1/1     Running   0          50m
```

In Contrail UI you can see both clusters

![](https://github.com/ovaleanu/kubernetes/blob/master/images/k8s-image9.png)

## Setup a Local Persistent Volume for a Kubernetes cluster

Workloads can request a persistent volume using PersistentVolumeClaim interface as remote storage backends.
There are a various storage volumes supported in Kubernetes. See here the [list](https://kubernetes.io/docs/concepts/storage/volumes/).

Here I will setup a local storage volume. A local volume represents a mounted local storage device such as a disk, partition or directory.

Local volumes can only be used as a statically created PersistentVolume. Dynamic provisioning is not supported yet.

First, a StorageClass should be created that sets volumeBindingMode: WaitForFirstConsumer to enable volume topology-aware scheduling. This mode instructs Kubernetes to wait to bind a PVC until a Pod using it is scheduled.

```
$ cat sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```
Then, the [external static provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner#user-guide) can be configured and run to create PVs for all the local disks on your nodes.

To configure the local static provisioner, first we need to create `/mnt/disks` directory and mount several volumes into its subdirectories on all your workers:

```
$ mkdir /mnt/disks
$ for vol in vol1 vol2 vol3; do
    mkdir /mnt/disks/$vol
    mount -t tmpfs $vol /mnt/disks/$vol
done

$ ls -l /mnt/disks/
total 0
drwxrwxrwt 2 root root 40 Jul 23 09:09 vol1
drwxrwxrwt 2 root root 40 Jul 23 09:09 vol2
drwxrwxrwt 2 root root 40 Jul 23 09:09 vol3
```

Local static provisioner uses some helm charts to create Provisioner's ServiceAccount, Roles, DaemonSet, and ConfigMap.
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
$ git clone --depth=1 https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner.git
$ cd sig-storage-local-static-provisioner
$ cp helm/provisioner/values.yaml .
```

Edit values.yaml for your enviroment. Here it is an [example](https://github.com/ovaleanujnpr/kubernetes/blob/master/storage/values.yaml) of what I used. This can create also the StorageClass.

Install local-static-provisioner using `helm install`

```
helm install -f ./values.yaml storageclass1 --namespace storageclass ./helm/provisioner
```

This creates a StorageClass, the local provisioner pods in storageclass namespace who will discover the `\mnt\disks` directories previously created

```
$ helm ls -n storageclass
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
storageclass1   storageclass    1               2020-07-23 09:15:17.397626789 -0400 EDT deployed        provisioner-3.0.0       2.3.4

$ kubectl get sc
NAME                 PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
standard (default)   kubernetes.io/no-provisioner   Delete          WaitForFirstConsumer   false                  37m

$ kubectl get po -n storageclass
NAME                              READY   STATUS    RESTARTS   AGE
storageclass1-provisioner-dpll9   1/1     Running   0          38m
storageclass1-provisioner-kl9zn   1/1     Running   0          38m

root@r9-ru26:~/sig-storage-local-static-provisioner# kubectl get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                STORAGECLASS   REASON   AGE
local-pv-16a99427   62Gi       RWO            Delete           Available                                        standard                38m
local-pv-1aca0a25   62Gi       RWO            Delete           Available                                        standard                38m
local-pv-c098a420   62Gi       RWO            Delete           Available                                        standard                38m
```

Test with this StatefulSet example

```
$ cat <<EOF > storage-ubuntu.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ubuntu-storage
spec:
  serviceName: "local-storage-service"
  replicas: 3
  selector:
    matchLabels:
      app: ubuntu-storage
  template:
    metadata:
      labels:
        app: ubuntu-storage
    spec:
      containers:
      - name: ubuntu-storage
        image: ubuntu
        command: ["/bin/sh","-c","sleep 100000"]
        volumeMounts:
        - name: local-vol
          mountPath: /usr/test-pod
  volumeClaimTemplates:
  - metadata:
      name: local-vol
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "standard"
      resources:
        requests:
          storage: 5Gi
EOF
kubectl create -f storage-ubuntu.yaml
```

Once the StatefulSet is up and running, the PVCs are all bound:

```
$ kubectl get po
NAME               READY   STATUS    RESTARTS   AGE
ubuntu-storage-0   1/1     Running   0          41m
ubuntu-storage-1   1/1     Running   0          41m
ubuntu-storage-2   1/1     Running   0          40m

$ kubectl get pvc
NAME                         STATUS   VOLUME              CAPACITY   ACCESS MODES   STORAGECLASS   AGE
local-vol-ubuntu-storage-0   Bound    local-pv-e00b14f6   62Gi       RWO            standard       42m
local-vol-ubuntu-storage-1   Bound    local-pv-6ebebd2    62Gi       RWO            standard       42m
local-vol-ubuntu-storage-2   Bound    local-pv-dac58761   62Gi       RWO            standard       42m
```

When the disk is no longer needed, the PVC can be deleted. The external static provisioner will clean up the disk and make the PV available for use again

```
$  kubectl patch sts ubuntu-storage -p '{"spec":{"replicas":1}}'
statefulset.apps/ubuntu-storage patched

$ kubectl get po
NAME               READY   STATUS    RESTARTS   AGE
ubuntu-storage-0   1/1     Running   0          48m
```
```
$ kubectl delete pvc/local-vol-ubuntu-storage-1
persistentvolumeclaim "local-vol-ubuntu-storage-1" deleted

$ kubectl delete pvc/local-vol-ubuntu-storage-2
persistentvolumeclaim "local-vol-ubuntu-storage-2" deleted

root@r9-ru26:~/sig-storage-local-static-provisioner# kubectl get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                STORAGECLASS   REASON   AGE
local-pv-16a99427   62Gi       RWO            Delete           Available                                        standard                52m
local-pv-1aca0a25   62Gi       RWO            Delete           Available                                        standard                52m
local-pv-6ebebd2    62Gi       RWO            Delete           Available                                        standard                31s
local-pv-c098a420   62Gi       RWO            Delete           Available                                        standard                52m
local-pv-dac58761   62Gi       RWO            Delete           Available                                        standard                3m7s
local-pv-e00b14f6   62Gi       RWO            Delete           Bound       default/local-vol-ubuntu-storage-0   standard                52m
```

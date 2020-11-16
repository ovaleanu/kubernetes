## Deploying K8s clusters in multi-cloud environments using [Cluster API](https://github.com/kubernetes-sigs/cluster-api)

Create a K8s Kind cluster on your station. This will act as a bootstraper for creating the clusters.

```
❯ mkdir ~/kind;cd ~/kind

❯ cat <<EOF > config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 6443
  podSubnet: "192.168.0.0/16"
  disableDefaultCNI: true
nodes:
- role: control-plane
  image: kindest/node:v1.18.8@sha256:f4bcc97a0ad6e7abaf3f643d890add7efe6ee4ab90baeb374b4f41a4c95567eb
- role: worker
  image: kindest/node:v1.18.8@sha256:f4bcc97a0ad6e7abaf3f643d890add7efe6ee4ab90baeb374b4f41a4c95567eb
- role: worker
  image: kindest/node:v1.18.8@sha256:f4bcc97a0ad6e7abaf3f643d890add7efe6ee4ab90baeb374b4f41a4c95567eb
EOF

❯ kind create cluster --config config.yaml --name clusterapi
❯ kubectl apply -f https://docs.projectcalico.org/v3.16/manifests/calico.yaml
❯ kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true
❯ kubectl get po --all-namespaces
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
kube-system          calico-kube-controllers-676c4cbdf-mdj2r      1/1     Running   0          115s
kube-system          calico-node-7mmlk                            1/1     Running   0          91s
kube-system          calico-node-cwcnt                            1/1     Running   0          91s
kube-system          calico-node-th47r                            1/1     Running   0          91s
kube-system          coredns-66bff467f8-8r4qw                     1/1     Running   0          4m15s
kube-system          coredns-66bff467f8-rwf9k                     1/1     Running   0          4m15s
kube-system          etcd-kind-control-plane                      1/1     Running   0          4m30s
kube-system          kube-apiserver-kind-control-plane            1/1     Running   0          4m30s
kube-system          kube-controller-manager-kind-control-plane   1/1     Running   0          4m30s
kube-system          kube-proxy-bpcsk                             1/1     Running   0          4m5s
kube-system          kube-proxy-mrvmr                             1/1     Running   0          3m59s
kube-system          kube-proxy-x49gw                             1/1     Running   0          4m16s
kube-system          kube-scheduler-kind-control-plane            1/1     Running   0          4m30s
local-path-storage   local-path-provisioner-5b4b545c55-klplx      1/1     Running   0          4m15s
```

Install `clusterctl` CLI tool for handling the lifecycle of a Cluster API management cluster

```
❯ curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.10/clusterctl-darwin-amd64 -o clusterctl
❯ chmod +x ./clusterctlsudo
❯ mv ./clusterctl /usr/local/bin/clusterctl
❯ clusterctl version
```

Initialize the management cluster using `clusterctl init`. The command accepts as input a list of providers to install; when executed for the first time, `clusterctl init` automatically adds to the list the `cluster-api` core provider, and if unspecified, it also adds the `kubeadm` bootstrap and `kubeadm` control-plane providers.

### Initialization for AWS provider

```
❯ export AWS_REGION=eu-west-2
❯ export AWS_ACCESS_KEY_ID=<your-key>
❯ export AWS_SECRET_ACCESS_KEY=<your-key>
```

Download the latest binary of `clusterawsadm` from the [AWS provider releases](https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases) and make sure to place it in your path.

```
❯ clusterawsadm bootstrap iam create-cloudformation-stack
Attempting to create AWS CloudFormation stack cluster-api-provider-aws-sigs-k8s-io
Following resources are in the stack:

Resource                  |Type                                                                                |Status
AWS::IAM::InstanceProfile |control-plane.cluster-api-provider-aws.sigs.k8s.io                                  |CREATE_COMPLETE
AWS::IAM::InstanceProfile |controllers.cluster-api-provider-aws.sigs.k8s.io                                    |CREATE_COMPLETE
AWS::IAM::InstanceProfile |nodes.cluster-api-provider-aws.sigs.k8s.io                                          |CREATE_COMPLETE
AWS::IAM::ManagedPolicy   |arn:aws:iam::927874460243:policy/control-plane.cluster-api-provider-aws.sigs.k8s.io |CREATE_COMPLETE
AWS::IAM::ManagedPolicy   |arn:aws:iam::927874460243:policy/nodes.cluster-api-provider-aws.sigs.k8s.io         |CREATE_COMPLETE
AWS::IAM::ManagedPolicy   |arn:aws:iam::927874460243:policy/controllers.cluster-api-provider-aws.sigs.k8s.io   |CREATE_COMPLETE
AWS::IAM::Role            |control-plane.cluster-api-provider-aws.sigs.k8s.io                                  |CREATE_COMPLETE
AWS::IAM::Role            |controllers.cluster-api-provider-aws.sigs.k8s.io                                    |CREATE_COMPLETE
AWS::IAM::Role            |nodes.cluster-api-provider-aws.sigs.k8s.io                                          |CREATE_COMPLETE

❯ export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile)

❯ clusterctl init --infrastructure aws
Fetching providers
Installing cert-manager Version="v0.16.1"
Waiting for cert-manager to be available...
Installing Provider="cluster-api" Version="v0.3.10" TargetNamespace="capi-system"
Installing Provider="bootstrap-kubeadm" Version="v0.3.10" TargetNamespace="capi-kubeadm-bootstrap-system"
Installing Provider="control-plane-kubeadm" Version="v0.3.10" TargetNamespace="capi-kubeadm-control-plane-system"
Installing Provider="infrastructure-aws" Version="v0.6.2" TargetNamespace="capa-system"

Your management cluster has been initialized successfully!

You can now create your first workload cluster by running the following:

  clusterctl config cluster [name] --kubernetes-version [version] | kubectl apply -f -
```

This will install Cluster API bootstraper and kubeadm control-plane in `capi-system` namespaces. The controller manager for AWS will be installed in `capa-system` namespace.

```
❯ kubectl get po --all-namespaces
NAMESPACE                           NAME                                                             READY   STATUS    RESTARTS   AGE
capa-system                         capa-controller-manager-8644556945-r8z6g                         2/2     Running   0          54s
capi-kubeadm-bootstrap-system       capi-kubeadm-bootstrap-controller-manager-86f4bcdf9f-xmkz2       2/2     Running   0          72s
capi-kubeadm-control-plane-system   capi-kubeadm-control-plane-controller-manager-756df75c96-c2d7k   2/2     Running   0          64s
capi-system                         capi-controller-manager-6d97bcb988-ggk7x                         2/2     Running   0          78s
capi-webhook-system                 capa-controller-manager-546fbc65-9v2c5                           2/2     Running   0          59s
capi-webhook-system                 capi-controller-manager-695dd68b7f-c8hmg                         2/2     Running   0          79s
capi-webhook-system                 capi-kubeadm-bootstrap-controller-manager-8496dcdbdb-4gtcj       2/2     Running   0          77s
capi-webhook-system                 capi-kubeadm-control-plane-controller-manager-77f644cd55-ddsc9   2/2     Running   0          69s
cert-manager                        cert-manager-578cd6d964-bwztt                                    1/1     Running   0          104s
cert-manager                        cert-manager-cainjector-5ffff9dd7c-p6l47                         1/1     Running   0          104s
cert-manager                        cert-manager-webhook-556b9d7dfd-ggl52                            1/1     Running   0          103s
....
```

Import your ssh public key in AWS

```
❯ aws ec2 import-key-pair --key-name default --public-key-material fileb://~/.ssh/id_rsa.pub
❯ export AWS_SSH_KEY_NAME=default
```

Define the instance type for control plane and worker nodes and generate the cluster yaml file

```
❯ export AWS_CONTROL_PLANE_MACHINE_TYPE=t3.large
❯ export AWS_NODE_MACHINE_TYPE=t3.large
❯ clusterctl config cluster capi-aws-2 --kubernetes-version v1.18.9 --control-plane-machine-count=3 --worker-machine-count=3 --infrastructure aws > capi-aws-2.yaml
```

Apply the clutser yaml file for creating the cluster in AWS

```
❯ kubectl apply -f capi-aws-2.yaml
cluster.cluster.x-k8s.io/capi-aws-2 created
awscluster.infrastructure.cluster.x-k8s.io/capi-aws-2 created
kubeadmcontrolplane.controlplane.cluster.x-k8s.io/capi-aws-2-control-plane created
awsmachinetemplate.infrastructure.cluster.x-k8s.io/capi-aws-2-control-plane created
machinedeployment.cluster.x-k8s.io/capi-aws-2-md-0 created
awsmachinetemplate.infrastructure.cluster.x-k8s.io/capi-aws-2-md-0 created
kubeadmconfigtemplate.bootstrap.cluster.x-k8s.io/capi-aws-2-md-0 created

❯ kubectl get cluster
NAME         PHASE
capi-aws-2   Provisioned

❯ kubectl get kubeadmcontrolplane --all-namespaces
NAMESPACE   NAME                       INITIALIZED   API SERVER AVAILABLE   VERSION   REPLICAS   READY   UPDATED   UNAVAILABLE
default     capi-aws-2-control-plane   true                                 v1.18.9   3                  3         3

❯ kubectl get machines
NAME                              PROVIDERID                              PHASE     VERSION
capi-aws-2-control-plane-dt4sm    aws:///eu-west-2c/i-0dbe03668241abc84   Running   v1.18.9
capi-aws-2-control-plane-qwwmg    aws:///eu-west-2a/i-098a29e5183dac849   Running   v1.18.9
capi-aws-2-control-plane-z85qb    aws:///eu-west-2b/i-0bbb62d740e799811   Running   v1.18.9
capi-aws-2-md-0-7df56dcb4-5md2x   aws:///eu-west-2a/i-0fda116b6f3feec87   Running   v1.18.9
capi-aws-2-md-0-7df56dcb4-5tw7v   aws:///eu-west-2a/i-0a1bfb5c30b8e2918   Running   v1.18.9
capi-aws-2-md-0-7df56dcb4-npmjc   aws:///eu-west-2a/i-07098e5d696887de2   Running   v1.18.9
```

Retrive the cluster kubeconfig file

```
❯ clusterctl get kubeconfig capi-aws-2 > capi-aws-2.kubeconfig
```

```
❯ kubectl get nodes -o wide --kubeconfig=./capi-aws-2.kubeconfig
NAME                                         STATUS     ROLES    AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION   CONTAINER-RUNTIME
ip-10-0-107-201.eu-west-2.compute.internal   NotReady   master   3m21s   v1.18.9   10.0.107.201   <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-aws   containerd://1.4.1
ip-10-0-110-106.eu-west-2.compute.internal   NotReady   <none>   4m27s   v1.18.9   10.0.110.106   <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-aws   containerd://1.4.1
ip-10-0-128-98.eu-west-2.compute.internal    NotReady   master   4m37s   v1.18.9   10.0.128.98    <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-aws   containerd://1.4.1
ip-10-0-216-88.eu-west-2.compute.internal    NotReady   master   6m25s   v1.18.9   10.0.216.88    <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-aws   containerd://1.4.1
ip-10-0-68-195.eu-west-2.compute.internal    NotReady   <none>   4m39s   v1.18.9   10.0.68.195    <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-aws   containerd://1.4.1
ip-10-0-87-53.eu-west-2.compute.internal     NotReady   <none>   4m39s   v1.18.9   10.0.87.53     <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-aws   containerd://1.4.1
```

Install the CNI

```
❯ kubectl apply -f https://docs.projectcalico.org/v3.16/manifests/calico.yaml --kubeconfig=./capi-aws-2.kubeconfig
```

### Initialization for Azure provider

The same K8s Kind cluster used as a bootstraper for AWS we can use it to initialize also for Azure Public Cloud.

```
❯ az account list -o table
Name                                       CloudName    SubscriptionId                        State    IsDefault
-----------------------------------------  -----------  ------------------------------------  -------  -----------
Azure MultiCloud Development Subscription  AzureCloud   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  Enabled  True

❯ export AZURE_SUBSCRIPTION_ID="<you_subscription_id"
```

Cluster API  will use a service principal to do the installation. Because this service principale will create the cluster, I will specify also a RBAC role for this service principal.

```
❯ az ad sp create-for-rbac --role Contributor --name clusterapi
{
  "appId": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  "displayName": "clusterapi",
  "name": "http://clusterapi",
  "password": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  "tenant": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

❯ az role assignment create --role "User Access Administrator" --assignee "<your_appId>" --output none
❯ az role assignment create --role Contributor --assignee "<your_appId>" --output none
```

```
❯ export AZURE_TENANT_ID="<your_tenant"
❯ export AZURE_CLIENT_ID="<your_appId>"
❯ export AZURE_CLIENT_SECRET="wBBPDZNtFfY7o94_myxcJS70lD_Ur-spJ_"
❯ export AZURE_ENVIRONMENT="AzurePublicCloud"
❯ export AZURE_SUBSCRIPTION_ID_B64="$(echo -n "$AZURE_SUBSCRIPTION_ID" | base64 | tr -d '\n')"
❯ export AZURE_TENANT_ID_B64="$(echo -n "$AZURE_TENANT_ID" | base64 | tr -d '\n')"
❯ export AZURE_CLIENT_ID_B64="$(echo -n "$AZURE_CLIENT_ID" | base64 | tr -d '\n')"
❯ export AZURE_CLIENT_SECRET_B64="$(echo -n "$AZURE_CLIENT_SECRET" | base64 | tr -d '\n')"
```

Initialize the Azure

```
❯ clusterctl init --infrastructure azure
Fetching providers
Skipping installing cert-manager as it is already installed
Installing Provider="infrastructure-azure" Version="v0.4.9" TargetNamespace="capz-system”
```

Because the cluster was previously intiated for AWS, now only the controller manager for Azure was added in `capz-system` namespace

Set Azure datacenter location, VMs types and generate azure cluster yaml file

```
❯ export AZURE_LOCATION=“uksouth"
❯ export AZURE_CONTROL_PLANE_MACHINE_TYPE="Standard_D2s_v3"
❯ export AZURE_NODE_MACHINE_TYPE="Standard_D2s_v3"

❯ clusterctl config cluster capi-azure-uk --kubernetes-version v1.18.9 --control-plane-machine-count=3 --worker-machine-count=3 --infrastructure azure > capi-azure-uk.yaml
```

```
❯ kubectl get cluster
NAME            PHASE
capi-aws-2      Provisioned
capi-azure-uk   Provisioned

❯ kubectl get machines
NAME                                 PROVIDERID                                                                                                                                                                PHASE     VERSION
capi-aws-2-control-plane-dt4sm       aws:///eu-west-2c/i-0dbe03668241abc84                                                                                                                                     Running   v1.18.9
capi-aws-2-control-plane-qwwmg       aws:///eu-west-2a/i-098a29e5183dac849                                                                                                                                     Running   v1.18.9
capi-aws-2-control-plane-z85qb       aws:///eu-west-2b/i-0bbb62d740e799811                                                                                                                                     Running   v1.18.9
capi-aws-2-md-0-7df56dcb4-5md2x      aws:///eu-west-2a/i-0fda116b6f3feec87                                                                                                                                     Running   v1.18.9
capi-aws-2-md-0-7df56dcb4-5tw7v      aws:///eu-west-2a/i-0a1bfb5c30b8e2918                                                                                                                                     Running   v1.18.9
capi-aws-2-md-0-7df56dcb4-npmjc      aws:///eu-west-2a/i-07098e5d696887de2                                                                                                                                     Running   v1.18.9
capi-azure-uk-control-plane-8dnxb    azure:////subscriptions/f39bcbf9-3a71-414d-a17f-794d0fffe65c/resourceGroups/capi-azure-uk/providers/Microsoft.Compute/virtualMachines/capi-azure-uk-control-plane-66hc4   Running   v1.18.9
capi-azure-uk-control-plane-cskct    azure:////subscriptions/f39bcbf9-3a71-414d-a17f-794d0fffe65c/resourceGroups/capi-azure-uk/providers/Microsoft.Compute/virtualMachines/capi-azure-uk-control-plane-pbq97   Running   v1.18.9
capi-azure-uk-control-plane-mn6xx    azure:////subscriptions/f39bcbf9-3a71-414d-a17f-794d0fffe65c/resourceGroups/capi-azure-uk/providers/Microsoft.Compute/virtualMachines/capi-azure-uk-control-plane-c8tkt   Running   v1.18.9
capi-azure-uk-md-0-8dfb68948-45cwv   azure:////subscriptions/f39bcbf9-3a71-414d-a17f-794d0fffe65c/resourceGroups/capi-azure-uk/providers/Microsoft.Compute/virtualMachines/capi-azure-uk-md-0-mhdrm            Running   v1.18.9
capi-azure-uk-md-0-8dfb68948-ftl4x   azure:////subscriptions/f39bcbf9-3a71-414d-a17f-794d0fffe65c/resourceGroups/capi-azure-uk/providers/Microsoft.Compute/virtualMachines/capi-azure-uk-md-0-zzx8g            Running   v1.18.9
capi-azure-uk-md-0-8dfb68948-lj8qm   azure:////subscriptions/f39bcbf9-3a71-414d-a17f-794d0fffe65c/resourceGroups/capi-azure-uk/providers/Microsoft.Compute/virtualMachines/capi-azure-uk-md-0-4sxdm            Running   v1.18.9
```

Retrieve the azure kubeconfig file

```
❯ clusterctl get kubeconfig capi-azure-uk > capi-azure-uk.kubeconfig
```

```
❯ kubectl get nodes -o wide --kubeconfig=./capi-azure-uk.kubeconfig
NAME                                STATUS     ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
capi-azure-uk-control-plane-66hc4   NotReady   master   21m   v1.18.9   10.0.0.4      <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-azure   containerd://1.3.4
capi-azure-uk-control-plane-c8tkt   NotReady   master   16m   v1.18.9   10.0.0.6      <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-azure   containerd://1.3.4
capi-azure-uk-control-plane-pbq97   NotReady   master   19m   v1.18.9   10.0.0.5      <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-azure   containerd://1.3.4
capi-azure-uk-md-0-4sxdm            NotReady   <none>   19m   v1.18.9   10.1.0.6      <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-azure   containerd://1.3.4
capi-azure-uk-md-0-mhdrm            NotReady   <none>   19m   v1.18.9   10.1.0.5      <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-azure   containerd://1.3.4
capi-azure-uk-md-0-zzx8g            NotReady   <none>   19m   v1.18.9   10.1.0.4      <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-azure   containerd://1.3.4
```

Install the CNI

```
❯ kubectl apply -f https://docs.projectcalico.org/v3.16/manifests/calico.yaml --kubeconfig=./capi-azure-uk.kubeconfig
```

### Deploy KubeFed on the newly created clusters and federate a deployment

Merge the kubeconfig finalizers

```
❯ KUBECONFIG=$HOME/.kube/capi-aws-2.kubeconfig:$HOME/.kube/capi-azure-uk.kubeconfig kubectl config view --merge --flatten > $HOME/.kube/config

❯ kubectx
capi-aws
capi-azure
```

```
❯ kubectx capi-aws
❯ kubectl get nodes
NAME                                         STATUS   ROLES    AGE   VERSION
ip-10-0-107-201.eu-west-2.compute.internal   Ready    master   38h   v1.18.9
ip-10-0-110-106.eu-west-2.compute.internal   Ready    <none>   38h   v1.18.9
ip-10-0-128-98.eu-west-2.compute.internal    Ready    master   38h   v1.18.9
ip-10-0-216-88.eu-west-2.compute.internal    Ready    master   38h   v1.18.9
ip-10-0-68-195.eu-west-2.compute.internal    Ready    <none>   38h   v1.18.9
ip-10-0-87-53.eu-west-2.compute.internal     Ready    <none>   38h   v1.18.9

❯ kubectx capi-azure
❯ kubectl get nodes
NAME                                STATUS   ROLES    AGE   VERSION
capi-azure-uk-control-plane-66hc4   Ready    master   86m   v1.18.9
capi-azure-uk-control-plane-c8tkt   Ready    master   81m   v1.18.9
capi-azure-uk-control-plane-pbq97   Ready    master   84m   v1.18.9
capi-azure-uk-md-0-4sxdm            Ready    <none>   84m   v1.18.9
capi-azure-uk-md-0-mhdrm            Ready    <none>   84m   v1.18.9
capi-azure-uk-md-0-zzx8g            Ready    <none>   84m   v1.18.9
```

From this point I am following the steps documented [here](https://github.com/ovaleanujnpr/kubernetes/blob/master/docs/kubefed_contrail.md).

```
❯ kubectl get kubefedclusters -n kube-federation-system
NAME         AGE   READY
capi-aws     32s   True
capi-azure   10s   True


❯ for c in `kubectl config get-contexts --no-headers=true -o name|grep -v k8s-cluster-kubefed `; do echo "Getting pods  in context $c"; kubectl get pods -n  kubefed-test  --context=$c; done
Getting pods  in context capi-aws
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-6b474476c4-2654h   1/1     Running   0          14s
nginx-deployment-6b474476c4-gwm75   1/1     Running   0          14s
nginx-deployment-6b474476c4-pnc58   1/1     Running   0          14s
Getting pods  in context capi-azure
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-6b474476c4-fb48s   1/1     Running   0          15s
nginx-deployment-6b474476c4-kdljz   1/1     Running   0          15s
nginx-deployment-6b474476c4-zs26d   1/1     Running   0          15s

for c in `kubectl config get-contexts --no-headers=true -o name|grep -v k8s-cluster-kubefed `; do echo "Getting pods  in context $c"; kubectl get svc -n  kubefed-test  --context=$c; done
Getting pods  in context capi-aws
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-service   NodePort   10.111.90.179   <none>        80:30905/TCP   26s
Getting pods  in context capi-azure
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-service   NodePort   10.100.35.173   <none>        80:31129/TCP   27s
```

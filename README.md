## Kiwis

Kluster installation wrapped in shell-scripts.

This project is aimed at speeding up deployment of cluster environment.

#### Quick Start
Kubernetes installation wrapped in a shell script:

on Ubuntu 20.04
```
$ sudo scripts/install_k8s_ubuntu.sh
```

on CentOS 7.6
```
$ su -c scripts/install_k8s_centos_7.6.sh
```

on CentOS 8.x

```
$ su -c scripts/install_k8s_centos_8.5.sh
```

Slurm installation:

on CentOS 7.9
```
$ su -c scripts/install_slurm_centos.sh
```
Currently supported features in the scripts:

- Installing docker, kubelet service.
- Configurations needed for kubernetes, like 
 removing swap and configuring port ranges.
- Installing cni network plugins like `flannel`
- Setup nvidia plugin and nginx-ingress with helm.

#### Additional service add-on

Customed services can also be added to your cluster with `.yaml`
files. We placed some of the most commonly used yamls in [services](Kubernetes/services)
folder. 

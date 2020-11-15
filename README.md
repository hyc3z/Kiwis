## Kiwis

**K**ubernetes **i**nstallation **w**rapped **i**n **s**hell-scripts.

This project is aimed at speeding up deployment of kubernetes.

#### Quick Start
Kubernetes installation wrapped in a shell script:

on Ubuntu 20.04
```
$ sudo scripts/install_k8s_ubuntu.sh
```

on CentOS 7.9
```
$ su -c scripts/install_k8s_ubuntu.sh
```
Currently supported features in the scripts:

- Installing docker, kubelet service.
- Configurations needed for kubernetes, like 
 removing swap and configuring port ranges.
- Installing cni network plugins like `flannel`
- Setup nvidia plugin and nginx-ingress with helm.

#### Additional service add-on

Customed services can also be added to your cluster with `.yaml`
files. We placed some of the most commonly used yamls in [services](./services)
folder. 

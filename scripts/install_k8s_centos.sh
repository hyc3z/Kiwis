#!/bin/bash

version="v1.0.6"
revise_date="Nov.3, 2020"
author="Hyc3z"
dir=$(pwd)
workflow() {
  disclaimer
  install_docker_and_kubelet
  remove_swap
  turnoff_selinux
  enable_ipforwarding
  install_option
  return 0
}

display_menu() {
    echo -e "\e[1m----------"
    echo -e "\e[1mKubernetes Installation Support ${version} For CentOS 7.6 , by \e[38;5;4m${author} \e[39m"
    echo -e "\e[1m ${revise_date}"
    echo -e "\e[1m---------- \e[0m"
    echo "--- menu ---"
    echo "0. Auto install kubernetes (0)"
    echo "1. Disclaimer (1)"
    echo "2. Install docker and kubelet (2)"
    echo "3. Remove swap (3) "
    echo "4. Turn off selinux (4) "
    echo "5. Enable ipforwarding (5)"
    echo "6. Install master (6)"
    echo "7. Install follower (7)"
    echo "8. Install flannel (8)"
    echo "9. Add TTLAfterFinished (9)"
    echo "a. Install helm (a)"
    echo "b. Setup nvidia environment (b)"
    echo "c. Change port range (c)"
    echo "d. Setup nginx environment (d)"
#    echo "Detected md arrays, auto mount? (Y or N)"
#    read auto_mount
#    echo "Detected md arrays, auto add to /etc/fstab? (Y or N)"
#    read auto_fstab
    read choice
    return "$choice"
}

disclaimer() {
  echo -e "\e[1m----------"
  echo -e "\e[1m---------- \e[0m"
  echo -e "\e[1mKubernetes Installation Support ${version} For CentOS 7.6 , by \e[38;5;4m${author} \e[39m"
  echo -e "\e[1m${revise_date} "
  echo -e "\e[1m---------- \e[0m"
  echo "Proceed? (Y/N)"
  read x
  case $x in
  y|Y)return 0;;
  *)exit 1;;
  esac
}

remove_swap() {
  swapoff -a
  # annotate swap line in fstab so that swap will remain off after reboot.
  while read line
  do
  tmp=$( echo $line | grep swap )
  if [[ $tmp ]]; then
    if [[ ! $tmp =~ ^#.*  ]]; then
      newline="#${tmp}"
      pre_sed=$(echo $line | sed 's/\//\\\//g')
      post_sed=$(echo $newline | sed 's/\//\\\//g')
      sed -i "s/${pre_sed}/${post_sed}/g" /etc/fstab
#      echo $newline
    fi
  fi
  done < /etc/fstab
  sed -i "s/\/swapfile/#\/swapfile/g" /etc/fstab
  return 0
}

install_docker_and_kubelet() {
  cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
  yum makecache
  setenforce 0
  yum install -y kubelet kubeadm kubectl
#  Use systemd driver instead of cgroupfs driver.
  yum install -y yum-utils device-mapper-persistent-data lvm2 ipvsadm
  yum-config-manager --add-repo -y https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
  yum makecache fast
  yum -y install docker-ce
  systemctl enable kubelet
# systemd driver support in k8s is currently really poor.Consider using cgroupfs for stablility.
  cat <<EOF > /etc/docker/daemon.json
{
  "registry-mirror": [
    "https://registry.docker-cn.com"
  ],
  "default-runtime": "nvidia",
  "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
  },
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
  systemctl daemon-reload && systemctl restart docker && systemctl enable docker
  return 0
}

turnoff_selinux() {
  setenforce 0
  sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
  return 0
}

enable_ipforwarding() {
  # issue https://github.com/kubernetes/kubernetes/issues/95163 add iptables flush
  iptables --flush
  cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
EOF
  sysctl --system
  return 0
}

install_option() {
  echo "Install as master (y) or worker (n)"
  read x
  case $x in
  y|Y)install_master;;
  *)install_follower;;
  esac
  return 0
}

clean_install() {
  systemctl stop firewalld
  systemctl disable firewalld
  iptables --flush
  ipvsadm --clear
  rm -f $HOME/.kube/config
#  kubeadm_args=$(cat /var/lib/kubelet/kubeadm-flags.env | grep --cgroup-driver)
#  if [[ $kubeadm_args ]]; then
#    sed -i "s/--cgroup-driver=cgroupfs/--cgroup-driver=systemd/g" /var/lib/kubelet/kubeadm-flags.env
#  else
#    kubeadm_args=$(cat /var/lib/kubelet/kubeadm-flags.env | grep KUBELET_KUBEADM_ARGS)
#    desired_args="${kubeadm_args} --cgroup-driver=systemd"
#    pre_sed=$(echo $kubeadm_args | sed 's/\//\\\//g')
#    post_sed=$(echo $desired_args | sed 's/\//\\\//g')
#    sed -i "s/${pre_sed}/${post_sed}/g" /var/lib/kubelet/kubeadm-flags.env
#  fi
}

install_master() {
  clean_install
  config_path="/tmp/kubeadm_init.yaml"
  kubeadm config print init-defaults > ${config_path}
  cat <<EOF >> ${config_path}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
EOF
  advertise_addr=$(cat ${config_path} | grep advertiseAddress)
  desired_advertise_addr="advertiseAddress: 0.0.0.0"
  sed -i "s/${advertise_addr}/  ${desired_advertise_addr}/g" ${config_path}
  repository_url=$(cat ${config_path} | grep imageRepository)
  desired_repository_url="imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers"
  pre_sed=$(echo $repository_url | sed 's/\//\\\//g')
  post_sed=$(echo $desired_repository_url | sed 's/\//\\\//g')
  sed -i "s/${pre_sed}/${post_sed}/g" ${config_path}
  pod_subnet="  podSubnet: 10.244.0.0/16"
  svc_subnet=$(cat ${config_path} | grep serviceSubnet)
  processed_pod_subnet=$(echo $pod_subnet | sed 's/\//\\\//g')
  processed_svc_subnet=$(echo $svc_subnet | sed 's/\//\\\//g')
  sed -i "s/${processed_svc_subnet}/${processed_svc_subnet}\n  ${processed_pod_subnet}/g" ${config_path}
  export KUBE_PROXY_MODE=ipvs
  modprobe -- ip_vs
  modprobe -- ip_vs_rr
  modprobe -- ip_vs_wrr
  modprobe -- ip_vs_sh
  main=$(uname -r | awk -F . '{print $1}')
  minor=$(uname -r | awk -F . '{print $2}')
#  Notes: use nf_conntrack instead of nf_conntrack_ipv4 for Linux kernel 4.19 and later
# https://github.com/kubernetes/kubernetes/blob/master/pkg/proxy/ipvs/README.md
  if [ "$main" -gt 4 ] || { [ "$main" -ge 4 ] && [ "$minor" -ge 19 ]; }
    then
      modprobe -- nf_conntrack
    else
      modprobe -- nf_conntrack_ipv4
  fi
  # modprobe -- nf_conntrack_ipv4
  kubeadm init --config ${config_path}
  export_command="export KUBECONFIG=/etc/kubernetes/admin.conf"
  tmp=$( cat /etc/profile | grep KUBECONFIG)
  if [[ $tmp ]]; then
    # shellcheck disable=SC2076
    if [[ ! $tmp =~ ^export\ KUBECONFIG.*  ]]; then
      pre_sed=$(echo $line | sed 's/\//\\\//g')
      post_sed=$(echo $export_command | sed 's/\//\\\//g')
      sed -i "s/${pre_sed}/${post_sed}/g" /etc/profile
      echo $line
    fi
  else
    echo $export_command >> /etc/profile
  fi
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  $export_command

# Flannel daemonset is only installed on master.
  install_flannel_networking
# Add extra feature gates.
  add_featuregate TTLAfterFinished
# change service port range
  change_service_port_range
# helm is a package manager for kubernetes.
  install_helm
# install nvidia k8s-device-plugin and other components.
  setup_nvidia_environment
# install nginx-ingress https://github.com/nginxinc/kubernetes-ingress.
  setup_nginx_ingress
  return 0
}

setup_nginx_ingress() {
  helm repo add nginx-stable https://helm.nginx.com/stable
  helm repo update
  helm install my-release nginx-stable/nginx-ingress
  return 0
}

setup_nvidia_environment()  {
  DISTRIBUTION=$(. /etc/os-release;echo $ID$VERSION_ID)
  rm -f /etc/yum.repos.d/nvidia-docker.repo
  yum makecache
  curl -s -L https://nvidia.github.io/nvidia-docker/$DISTRIBUTION/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo
  sudo yum-config-manager --enable libnvidia-container-experimental
  sudo yum-config-manager --enable nvidia-container-runtime-experimental
  sudo yum install -y nvidia-container-toolkit
  nvdp_version=$(helm search repo nvdp --devel | grep nvidia-device-plugin | awk '{print $2}')
  if [[ $nvdp_version ]];then
    helm install --version=${nvdp_version} --generate-name --set securityContext.privileged=true --set deviceListStrategy=volume-mounts nvdp/nvidia-device-plugin
  else
    echo "failed to install nvdp."
    return 1
  fi
  return 0
}

install_helm() {
  curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
  if [ $? -ne 0 ]; then
    echo "ERROR: ... get content failed.Retrying... "
  #    This is an unsafe approach, may write multiple host records into /etc/hosts. Consider replacing this method in the future.
    github_records=$( cat /etc/hosts | grep raw.githubusercontent.com | awk '{print $1}')
    github_host_ip="199.232.28.133"
    if [[ $github_records ]]; then
      for record in $github_records
      do
        sed -i "s/${record}/${github_host_ip}/g" /etc/hosts
      done
    else  sudo chown $(id -u):$(id -g) $HOME/.kube/config
      echo "${github_host_ip} raw.githubusercontent.com" >> /etc/hosts
    fi
    curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    if [ $? -ne 0 ]; then
      echo "ERROR: ... get content failed.Check networking? "
      exit 1
    fi
  fi
  chmod 700 /tmp/get_helm.sh
  /tmp/get_helm.sh
  return 0
}

install_follower() {
  clean_install
  kubeadm config print join-defaults > /tmp/kubeadm_join.yaml
  #cat <<EOF >> /tmp/kubeadm_join.yaml
#---
#apiVersion: kubeproxy.config.k8s.io/v1alpha1
#kind: KubeProxyConfiguration
#mode: "ipvs"
#EOF
  echo "Input the join command displayed on master node:"
  read -r join_command
  join_command="${join_command} "
#--config /tmp/kubeadm_join.yaml"
  $join_command
  export_command="export KUBECONFIG=/etc/kubernetes/kubelet.conf"
  tmp=$( cat /etc/profile | grep KUBECONFIG)
  if [[ $tmp ]]; then
    # shellcheck disable=SC2076
    if [[ ! $tmp =~ ^export\ KUBECONFIG.*  ]]; then
      pre_sed=$(echo $line | sed 's/\//\\\//g')
      post_sed=$(echo $export_command | sed 's/\//\\\//g')
      sed -i "s/${pre_sed}/${post_sed}/g" /etc/profile
      echo $line
    fi
  else
    echo $export_command >> /etc/profile
  fi
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/kubelet.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  $export_command
  return 0
}

install_flannel_networking() {
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  if [ $? -ne 0 ]; then
    echo "ERROR: ... get content failed.Retrying... "
#    This is an unsafe approach, may write multiple host records into /etc/hosts. Consider replacing this method in the future.
    github_records=$( cat /etc/hosts | grep raw.githubusercontent.com | awk '{print $1}')
    github_host_ip="199.232.28.133"
    if [[ $github_records ]]; then
      for record in $github_records
      do
        sed -i "s/${record}/${github_host_ip}/g" /etc/hosts
      done
    else
      echo "${github_host_ip} raw.githubusercontent.com" >> /etc/hosts
    fi
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
      if [ $? -ne 0 ]; then
          echo "ERROR: ... get content failed.Check networking? "
          exit 1
      fi
    else
    echo "Flannel applied."
  fi
  return 0
}

add_featuregate() {
  filenames="kube-apiserver.yaml  kube-controller-manager.yaml"
  for filename in $filenames
  # determine if featuregate exists
  do
    feature_gate_exists=$(cat /etc/kubernetes/manifests/$filename | grep feature-gates)
    if [[ $feature_gate_exists ]]; then
      ttl_exists=$(echo "$feature_gate_exists" | grep TTLAfterFinished)
      if [[ $ttl_exists ]]; then
        new_feature_gate=$(echo "$feature_gate_exists" | sed "s/$1=false/$1=true/g")
        if [[ $new_feature_gate == "$feature_gate_exists" ]]; then
          echo "feature gate $1 in ${filename} unchanged."
        else
          sed -i "s/${feature_gate_exists}/${new_feature_gate}/g" /etc/kubernetes/manifests/$filename
          echo "feature gate $1 in ${filename} enabled."
        fi
        else
          new_feature_gate=$(echo "$feature_gate_exists" | sed "s/feature-gates=/feature-gates=$1=true,/g")
      fi
      else
        # place new line under this line, can be modified
        feature_exists=$(cat /etc/kubernetes/manifests/$filename | grep etcd-servers)
        if [[ $feature_exists ]]; then
          new_feature_gate="${feature_exists}\n    - --feature-gates=$1=true"
          pre_sed=$(echo "$feature_exists" | sed 's/\//\\\//g')
          post_sed=$(echo "$new_feature_gate" | sed 's/\//\\\//g')
          sed -i "s/${pre_sed}/${post_sed}/g" /etc/kubernetes/manifests/$filename
          echo "placed new feature gate $1 in ${filename}."
        else
          feature_exists=$(cat /etc/kubernetes/manifests/$filename | grep leader-elect)
          if [[ $feature_exists ]]; then
            new_feature_gate="${feature_exists}\n    - --feature-gates=$1=true"
            pre_sed=$(echo "$feature_exists" | sed 's/\//\\\//g')
            post_sed=$(echo "$new_feature_gate" | sed 's/\//\\\//g')
            sed -i "s/${pre_sed}/${post_sed}/g" /etc/kubernetes/manifests/$filename
            echo "placed new feature gate $1 in ${filename}."
          fi
        fi
    fi
  done
}

change_service_port_range() {
  filename="kube-apiserver.yaml"
  new_feature_gate="- --service-node-port-range=2-65535"
  port_range_exists=$(cat /etc/kubernetes/manifests/$filename | grep service-node-port-range)
    if [[ $port_range_exists ]]; then
        pre_sed=$(echo $port_range_exists | sed 's/\//\\\//g')
        post_sed=$(echo "$new_feature_gate" | sed 's/\//\\\//g')
        sed -i "s/${pre_sed}/${post_sed}/g" /etc/kubernetes/manifests/$filename
        echo "Replaced service-node-port-range in ${filename}."
      else
        feature_exists=$(cat /etc/kubernetes/manifests/$filename | grep etcd-servers)
        if [[ $feature_exists ]]; then
          pre_feature_gate="${feature_exists}\n    ${new_feature_gate}"
          pre_sed=$(echo "$feature_exists" | sed 's/\//\\\//g')
          post_sed=$(echo "$pre_feature_gate" | sed 's/\//\\\//g')
          sed -i "s/${pre_sed}/${post_sed}/g" /etc/kubernetes/manifests/$filename
          echo "placed new service-node-port-range in ${filename}."
        fi
    fi
}


loop=1
until [ $loop -eq 0 ]; do
  display_menu
  case $choice in
    0) workflow;;
    1) disclaimer ;;
    2) install_docker_and_kubelet ;;
    3) remove_swap ;;
    4) turnoff_selinux ;;
    5) enable_ipforwarding ;;
    6) install_master ;;
    7) install_follower ;;
    8) install_flannel_networking ;;
    9) add_featuregate TTLAfterFinished ;;
    a) install_helm ;;
    b) setup_nvidia_environment ;;
    c) change_service_port_range ;;
    d) setup_nginx_ingress ;;
    *)   (( loop=0 )) ;;
  esac
done
echo "Finished."
exit 0


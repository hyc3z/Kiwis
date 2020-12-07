#!/bin/bash

version="v0.0.1"
revise_date="Dec.7, 2020"
author="Hyc3z"
dir=$(pwd)
workflow() {
  disclaimer
  install_mpi
  turnoff_selinux
  pass_ssh_keys
  pass_host_records
  create_slurm_user
  install_ohpc_repo
  install_dependency
  install_slurm
  return 0
}

display_menu() {
    echo -e "\e[1m----------"
    echo -e "\e[1mSlurm Management Support ${version} For CentOS 7.9 , by \e[38;5;4m${author} \e[39m"
    echo -e "\e[1m${revise_date} "
    echo -e "\e[1m---------- \e[0m"
    echo "--- menu ---"
    echo "0. Auto install slurm (0)"
    echo "1. Disclaimer (1)"
    echo "2. Install mpi (2)"
    echo "3. Turn off selinux (3) "
    echo "4. Pass keys (4)"
    echo "5. Pass host records (5)"
    echo "6. Create Slurm User (6)"
    echo "7. Install Ohpc Repo (7)"
    echo "8. Install Dependency (8)"
    echo "9. Install Slurm (9)"
    read choice
    return "$choice"
}

disclaimer() {
  echo -e "\e[1m----------"
  echo -e "\e[1m---------- \e[0m"
  echo -e "\e[1mSlurm Management Support ${version} For CentOS 7.6 , by \e[38;5;4m${author} \e[39m"
  echo -e "\e[1m${revise_date} "
  echo -e "\e[1m---------- \e[0m"
  echo "Proceed? (Y/N)"
  read x
  case $x in
  y|Y)return 0;;
  *)exit 1;;
  esac
}

install_mpi() {
  yum install mpich-3.2.x86_64
  yum install mpich-3.2-autoload.x86_64
  yum install mpich-3.2-devel.x86_64
  yum install mpich-3.2-doc.noarch
  export_command="export PATH=/usr/lib64/mpich-3.2/bin:\$PATH" >> ~/.bashrc
  tmp=$( cat /etc/profile | grep mpich)
  if [[ $tmp ]]; then
    # shellcheck disable=SC2076
    if [[ ! $tmp =~ ^export\ KUBECONFIG.*  ]]; then
      pre_sed=$(echo $tmp | sed 's/\//\\\//g')
      post_sed=$(echo $export_command | sed 's/\//\\\//g')
      sed -i "s/${pre_sed}/${post_sed}/g" /etc/profile
    fi
  else
    echo $export_command >> /etc/profile
  fi
}

turnoff_selinux() {
  setenforce 0
  sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
  systemctl stop firewalld
  systemctl disable firewalld
  return 0
}

pass_ssh_keys() {
  yum install -y sshpass
  ssh-keygen -t rsa -f ~/.ssh/id_rsa -N "" -q
  while read line
  do
    host_ip=$( echo $line | awk \{'print $1'\} )
    host_name=$( echo $line | awk \{'print $2'\} )
    pass_phrase=$( echo $line | awk \{'print $3'\} )
  #  pass ssh keys
    sshpass -p $pass_phrase ssh-copy-id -i ~/.ssh/id_rsa.pub  root@$host_ip -o StrictHostKeyChecking=no  &>/dev/null
    if [ $? -eq 0 ];then
      echo $host_name done.
    else
      echo $host_name failed.
    fi

  done < ./host_config.txt
}

pass_host_records() {
  while read line
  do
    host_ip=$( echo $line | awk \{'print $1'\} )
    host_name=$( echo $line | awk \{'print $2'\} )
    pass_phrase=$( echo $line | awk \{'print $3'\} )
  #  remote execute
    ssh $host_ip "mv /etc/hosts /etc/hosts.bak" < /dev/null
    while read line2
    do
      host_ip_config=$( echo $line2 | awk \{'print $1'\} )
      host_name_config=$( echo $line2 | awk \{'print $2'\} )
      echo $host_ip_config $host_name_config
      ssh $host_ip "echo $host_ip_config $host_name_config >> /etc/hosts" < /dev/null
    done < ./host_config.txt
    if [ $? -eq 0 ];then
      echo $host_name done.
    else
      echo $host_name failed.
    fi
  done < ./host_config.txt
}

create_slurm_user() {
  export SLURMUSER=412
  groupadd -g $SLURMUSER slurm
  useradd -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm -s /bin/bash
  has_slurmuser=$(cat /etc/profile | grep SLURMUSER)
  if [ -z $has_slurmuser ]; then
    echo "export SLURMUSER=412" >> /etc/profile
  fi
}

install_ohpc_repo() {
#  Need to be updated
  yum install -y http://build.openhpc.community/OpenHPC:/1.3/CentOS_7/x86_64/ohpc-release-1.3-1.el7.x86_64.rpm
}

install_dependency() {
  yum install openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel man2html libibmad libibumad -y
}

# Slurm clients also need to install server,
# as it contains script for stopping jobs.
install_slurm() {
  while read line
  do
    host_ip=$( echo $line | awk \{'print $1'\} )
    host_name=$( echo $line | awk \{'print $2'\} )
    pass_phrase=$( echo $line | awk \{'print $3'\} )
  #  remote execute
    ssh $host_ip "yum -y install ohpc-slurm-server ohpc-slurm-client" < /dev/null
    ssh $host_ip "mkdir -p /etc/slurm" < /dev/null
    scp ./slurm.conf $host_ip:/etc/slurm/slurm.conf
    ssh $host_ip "systemctl start munge && systemctl start slurmctld && systemctl start slurmd && systemctl enable munge && systemctl enable slurmctld && systemctl enable slurmd" < /dev/null
    if [ $? -eq 0 ];then
      echo $host_name done.
    else
      echo $host_name failed.
    fi
  done < ./host_config.txt
}

loop=1
until [ $loop -eq 0 ]; do
  display_menu
  case $choice in
    0) workflow;;
    1) disclaimer ;;
    2) install_mpi ;;
    3) turnoff_selinux ;;
    4) pass_ssh_keys ;;
    5) pass_host_records ;;
    6) create_slurm_user ;;
    7) install_ohpc_repo ;;
    8) install_dependency ;;
    9) install_slurm ;;
    *)   (( loop=0 )) ;;
  esac
done
echo "Finished."
exit 0
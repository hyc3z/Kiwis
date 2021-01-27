#!/bin/bash

version="v0.0.2"
revise_date="Jan.26, 2021"
author="Hyc3z"
dir=$(pwd)
leadership=1
SLURM_BUILD_VER=20.11.3
# reference: https://wiki.fysik.dtu.dk/niflheim/Slurm_installation
# TODO: Start services, test file passing.
workflow() {
  disclaimer
  selection
  clean_install
  create_global_user_account
  munge_authentication_service
  if [[ $leadership ]];then
    build_rpms
    pass_ssh_keys
    pass_host_records
    pass_rpms
    pass_munge_keys
  fi
  install_rpms
  configures
  return 0
}
disclaimer() {
  echo -e "\e[1m----------"
  echo -e "\e[1m---------- \e[0m"
  echo -e "\e[1mSlurm Compile Support ${version} For CentOS 7.6 , by \e[38;5;4m${author} \e[39m"
  echo -e "\e[1m${revise_date} "
  echo -e "\e[1m---------- \e[0m"
  echo "Proceed? (Y/N)"
  read x
  case $x in
  y|Y)return 0;;
  *)exit 1;;
  esac
}

clean_install() {
  installed=$(yum list installed | grep ohpc | awk {'print $1'})
  yum remove -y ${installed}
  installed=$(yum list installed | grep slurm | awk {'print $1'})
  yum remove -y ${installed}
  rm -f slurm-${SLURM_BUILD_VER}.tar*
}

selection() {
  echo -e "\e[1m---------- \e[0m"
  echo -e "\e[1mChoose whether or not current machine will serve as distributer which compiles rpm packages and replicate them to receivers.This saves time for installation afterwards, as receivers do not have to compile the same rpm packages again.Usually (Y|y) when first running the script on the first machine, then N when running the script afterwards on others."
  echo -e "\e[1m${revise_date} "
  echo -e "\e[1m---------- \e[0m"
  echo "Compile and distribute rpm packages to receivers? (Y/N)"
  read x
  case $x in
  y|Y) leadership=1;;
  *) leadership=0;;
  esac
}

create_global_user_account() {
  MUNGEUSER=1001
  groupadd -g $MUNGEUSER munge
  useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGEUSER -g munge  -s /sbin/nologin munge
  SlurmUSER=1002
  groupadd -g $SlurmUSER slurm
  useradd  -m -c "Slurm workload manager" -d /var/lib/slurm -u $SlurmUSER -g slurm  -s /bin/bash slurm
}

munge_authentication_service() {
  yum install -y epel-release
  yum install -y munge munge-libs munge-devel ssh-pass
  # remove existing key before creating
  rm -f /etc/munge/munge.key
  /usr/sbin/create-munge-key -r

  chown -R munge: /etc/munge/ /var/log/munge/
  chmod 0700 /etc/munge/ /var/log/munge/
  systemctl enable munge
  systemctl start munge
}

pass_munge_keys() {
  while read line
  do
    host_ip=$( echo $line | awk \{'print $1'\} )
    host_name=$( echo $line |  \{'print $2'\} )
    pass_phrase=$( echo $line | awk \{'print $3'\} )
  #  pass munge keys
    ssh $host_ip "mkdir -p /etc/munge/" < /dev/null
    sshpass -p $pass_phrase scp /etc/munge/munge.key root@$host_ip:/etc/munge &>/dev/null
    if [ $? -eq 0 ];then
      echo $host_name done.
    else
      echo $host_name failed.
    fi
  done < ./host_config.txt
}
pass_ssh_keys() {
  yum install -y sshpass
  rm -f /root/.ssh/id_rsa
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

pass_rpms() {
  while read line
  do
    host_ip=$( echo $line | awk \{'print $1'\} )
    host_name=$( echo $line | awk \{'print $2'\} )
    pass_phrase=$( echo $line | awk \{'print $3'\} )
  #  remote execute
    ssh $host_ip "mkdir -p /root/rpmbuild/RPMS/x86_64" < /dev/null
    sshpass -p $pass_phrase scp -r /root/rpmbuild/RPMS/x86_64 root@$host_ip:/root/rpmbuild/RPMS/x86_64 &>/dev/null
    if [ $? -eq 0 ];then
      echo $host_name done.
    else
      echo $host_name failed.
    fi
  done < ./host_config.txt
}

build_rpms() {
  #  prerequisites
    yum install -y python3 rpm-build gcc openssl openssl-devel libssh2-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel gtk2-devel libssh2-devel libibmad libibumad perl-Switch perl-ExtUtils-MakeMaker
  #  EPEL
    yum install -y man2html
  # build slurmrestd
    yum install -y http-parser-devel json-c-devel
  # Enable accounting
    yum install -y mariadb-server mariadb-devel
  # Enable Ansible
    yum install -y mysql-python
  # build jwt
    # yum install -y jansson jansson-devel
    # git clone --depth 1 --single-branch -b v1.12.0 https://github.com/benmcollins/libjwt.git libjwt
    # cd libjwt
    # autoreconf --force --install
    # ./configure --prefix=/usr/local
    # make -j
    # sudo make install
    # cd ..
  # install jwt
    yum install -y http://springdale.princeton.edu/data/springdale/7/x86_64/os/Computational/libjwt-1.12.0-0.sdl7.x86_64.rpm
    yum install -y http://springdale.princeton.edu/data/springdale/7/x86_64/os/Computational/libjwt-devel-1.12.0-0.sdl7.x86_64.rpm
    # build rpm
    # Note that hdf5 depency is not solved, build may fail.
    wget https://download.schedmd.com/slurm/slurm-${SLURM_BUILD_VER}.tar.bz2
    rpmbuild -ta slurm-${SLURM_BUILD_VER}.tar.bz2 --with mysql --with slurmrestd --with jwt
    rm -f slurm-${SLURM_BUILD_VER}.tar.*
}

install_rpms() {
  yum install -y /root/rpmbuild/RPMS/x86_64/slurm*.rpm
  # if [[ $leadership ]]; then
  #   systemctl enable slurmctld
  #   systemctl enable slurmrestd
  # else
  #   systemctl enable slurmd
  # fi
}

configures() {
  echo "You'll have to manually configure mariadb, reference: https://wiki.fysik.dtu.dk/niflheim/Slurm_database."
  echo "Finished configuration? (Y/N)"
  read x
  case $x in
  y|Y)return 0;;
  *)exit 1;;
  esac
  chmod 0600 /etc/slurm/slurmdbd.conf
  chown slurm /etc/slurm/slurmdbd.conf
  systemctl enable slurmdbd
  systemctl start slurmdbd
  
}
workflow
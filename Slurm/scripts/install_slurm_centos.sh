#!/bin/bash

version="v1.0.0"
revise_date="Dec.5, 2020"
author="Hyc3z"
dir=$(pwd)
workflow() {
  disclaimer
  install_mpi
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
  echo "export PATH=/usr/lib64/mpich-3.2/bin:\$PATH" >> ~/.bashrc
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
}




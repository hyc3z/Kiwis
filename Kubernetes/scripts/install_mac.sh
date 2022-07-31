#!/bin/bash

version="v1.0.0"
revise_date="July.31, 2022"
author="Hyc3z"
dir=$(pwd)
workflow() {
  disclaimer
  install_docker
  install_k8s_images
  return 0
}

disclaimer() {
  echo -e "\e[1m----------"
  echo -e "\e[1m---------- \e[0m"
  echo -e "\e[1mKubernetes Installation Support ${version} For Ubuntu 20.04 , by \e[38;5;4m${author} \e[39m"
  echo -e "\e[1m${revise_date}"
  echo -e "\e[1m---------- \e[0m"
  echo "Proceed? (Y/N)"
  read x
  case $x in
  y|Y)return 0;;
  *)exit 1;;
  esac
}

install_docker() {
    echo -e "https://docs.docker.com/desktop/install/mac-install/ to download docker desktop"
    echo "Proceed? (Y/N)"
    read x
    case $x in
    y|Y)return 0;;
    *)exit 1;;
    esac
}

install_k8s_images() {
    git clone git@github.com:AliyunContainerService/k8s-for-docker-desktop
    cd k8s-for-docker-desktop
    ./load_images.sh
    echo -e "Go to docker desktop and start kubernetes."
    echo "Proceed? (Y/N)"
    read x
    case $x in
    y|Y)return 0;;
    *)exit 1;;
    esac
}

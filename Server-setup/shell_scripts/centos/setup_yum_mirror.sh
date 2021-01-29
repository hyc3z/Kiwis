#!/bin/bash

cp -a /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
sed -i "s/#baseurl/baseurl/g" /etc/yum.repos.d/CentOS-Base.repo
sed -i "s/mirrorlist=http/#mirrorlist=http/g" /etc/yum.repos.d/CentOS-Base.repo
sed -i "s@http://mirror.centos.org@https://mirrors.huaweicloud.com@g" /etc/yum.repos.d/CentOS-Base.repo
yum clean all
yum makecache
if [ $? -ne 0 ]; then
    echo "ERROR: ... yum makecache failed.Check networking. "
    return 1
else
  echo "yum cache syncing completed."
fi
echo "Would you like to install upgrades? (Y or N)"
read x
if [[ $x == "y" ]]; then
   yum -y upgrade
  if [ $? -ne 0 ]; then
      echo "ERROR: ... yum upgrade failed.Check networking. "
      return 1
  else
    echo "yum upgrade completed. "
  fi
fi

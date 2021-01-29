#!/bin/bash
yum makecache
#echo "Would you like to install basic utils? (Y or N)"
#read x
#if [[ $x == "y" ]]; then
yum install -y git net-tools gcc gcc-c++  redhat-lsb  curl epel-release screen python-pip
if [ $? -ne 0 ]; then
  echo "ERROR: ... yum install failed.Check networking. "
  return 1
else
echo "Basic util installations completed."
fi
#fi
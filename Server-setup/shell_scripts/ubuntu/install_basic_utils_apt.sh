#!/bin/bash
apt update
#echo "Would you like to install basic utils? (Y or N)"
#read x
#if [[ $x == "y" ]]; then
apt install -y git net-tools gcc g++ openjdk-8-jre-headless lsb-core vim curl sysstat screen python3-pip
if [ $? -ne 0 ]; then
  echo "ERROR: ... apt upgrade failed.Check networking. "
  return 1
else
echo "Basic util installations completed."
fi
#fi
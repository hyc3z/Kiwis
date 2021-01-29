#!/bin/bash

sudo cp -a /etc/apt/sources.list /etc/apt/sources.list.bak
sudo sed -i "s@http://.*archive.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list
sudo sed -i "s@http://.*security.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list
sudo apt update
if [ $? -ne 0 ]; then
    echo "ERROR: ... apt update failed.Check networking. "
    return 1
else
  echo "apt syncing completed."
fi
echo "Would you like to install upgrades? (Y or N)"
read x
if [[ $x == "y" ]]; then
   apt dist-upgrade
  if [ $? -ne 0 ]; then
      echo "ERROR: ... apt upgrade failed.Check networking. "
      return 1
  else
    echo "apt upgrade completed. "
  fi
fi

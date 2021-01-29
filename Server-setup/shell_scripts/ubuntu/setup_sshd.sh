#!/bin/bash

sudo apt update
if [ $? -ne 0 ]; then
    echo "ERROR: ... apt update failed.Check networking. "
    return 1
else
  echo "apt syncing completed."
fi
sudo apt install -y openssh-server
if [ $? -ne 0 ]; then
    echo "ERROR: ... apt update failed.Check networking. "
    return 1
else
  echo "apt syncing completed."
fi
sudo systemctl start sshd
if [ $? -ne 0 ]; then
    echo "ERROR: sshd failed to start. "
    return 1
else
  echo "Sshd succesfully started."
fi
check_results=$(cat /etc/ssh/sshd_config | grep "PermitRootLogin yes")
if [[ $check_results ]]; then
  if [[ $check_results == 'PermitRootLogin yes' ]]; then
    echo "Login as root already permitted. "
  elif [[ $check_results == '#PermitRootLogin yes' ]]; then
    sed -i 's/^#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
    echo "Login as root activated."
  fi
else
  echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
  echo "Rule 'login as root' added."
fi
sudo systemctl restart sshd
if [ $? -ne 0 ]; then
    echo "ERROR: sshd failed to start. "
    return 1
else
  echo "Sshd succesfully started. Completed."
fi
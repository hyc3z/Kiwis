#!/bin/bash

if [ ! -d "${HOME}/.pip" ]; then
  mkdir ${HOME}/.pip
fi
if [ -f "${HOME}/.pip/pip.conf" ]; then
  rm -f "${HOME}/.pip/pip.conf"
fi
cat <<EOF > ~/.pip/pip.conf
[global]
index-url = https://mirrors.huaweicloud.com/repository/pypi/simple
trusted-host = mirrors.huaweicloud.com
timeout = 120
EOF
if [ $? -ne 0 ]; then
    echo "ERROR: ... upgrade failed."
    return 1
else
  echo "pypi mirror syncing completed. "
fi

#!/bin/bash

dir=$1
#echo "${dir}"
# 初始化yum镜像源
sh -c "${dir}/setup_yum_mirror.sh"
# 初始化pypi镜像源
sh -c "${dir}/setup_py3_mirror.sh"
# 安装一些开发基本工具
sh -c "${dir}/install_basic_utils_yum.sh"
# 安装sshd服务
sh -c "${dir}/setup_sshd.sh"
# 管理磁盘阵列，挂载/删除/读取/等操作,支持raid 0 1 4 5 6 10, raidz raidz2 zpool-mirror zpool(raid 0)等
sh -c "${dir}/raid_management.sh"


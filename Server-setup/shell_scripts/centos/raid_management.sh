#!/bin/bash
check_installed() {
  installed=$(rpm -qa | grep $1)
  if [[ -z $installed ]]; then
    if [[ $1 == zfs ]]; then
      yum install -y http://download.zfsonlinux.org/epel/zfs-release.el7_6.noarch.rpm
    fi
    if [ $? -ne 0 ]; then
        echo -e "\e[38;5;1mERROR \e[0m: ... apt update failed.Check networking. "
        return 1
    else
      echo "apt syncing completed. Installing $1..."
    fi
    yum install -y $1
    if [ $? -ne 0 ]; then
        echo -e "\e[38;5;1mERROR \e[0m: ... $1 installation failed.Check networking. "
        return 1
    else
      echo "$1 installation completed. "
    fi
  fi
}
display_menu() {
    echo -e "\e[1m----------"
    echo -e "\e[1mRaid Management Support v1.3 For CentOS 7.6, by \e[38;5;4mHu Yichong \e[39m"
    echo -e "\e[1mOct.5, 2020"
    echo -e "\e[1m---------- \e[0m"
    echo "--- menu ---"
    echo "1. Auto detect and mount mdadm raid arrays (1)"
    echo "2. Delete existing Mdadm Raid arrays (2)"
    echo "3. Create Mdadm Raid arrays (3) "
    echo "4. Create zpool (zfs raid z) (4) "
    echo "5. Export zpool for system reinstall or disk removal (5)."
    echo "6. Import zpool arrays (6)"
#    echo "Detected md arrays, auto mount? (Y or N)"
#    read auto_mount
#    echo "Detected md arrays, auto add to /etc/fstab? (Y or N)"
#    read auto_fstab
    read choice
    return "$choice"
}

auto_detect_mount() {
  if [ $mdadm_checked -eq 0 ]; then
    check_installed mdadm
    (( mdadm_checked=1 ))
  fi
#   backup fstab.
  cp /etc/fstab /etc/fstab.bak
#  refresh mdadm cache
  mdadm --assemble --scan
  mds=$(ls /dev/md)
  for md in $mds
    do
      raid_level=$( mdadm -D /dev/md"${md}" | grep "Raid Level" | awk '{print $4}')
      filesystem=$(df -hT | grep /dev/md"${md}" | awk '{print $2}')
#      Mounting phase
       mkdir /mnt/"md${md}_${raid_level}"
       mount /dev/md"${md}" /mnt/"md${md}_${raid_level}"
      if [ $? -ne 0 ]; then
          echo -e "\e[38;5;1mERROR \e[0m: ... mounting failed."
          return 1
        else
          echo "Successfully mounted /dev/md{$md} to /mnt/md${md}_${raid_level}. "
        fi
##     Manually mount, Deprecated code, for reference.
#    else
#      echo "Would you like to mount /dev/md{$md} (Y or N)"
#      read x
#      if [[ $x == "y" ]]; then
#        echo "Where to mount /dev/md${md}?"
#        read x
#         mount /dev/md"${md}" "$x"
#        if [ $? -ne 0 ]; then
#          echo -e "\e[38;5;1mERROR \e[0m: ... mounting failed."
#        else
#          echo "Successfully mounted /dev/md${md} to $x. "
#        fi
#     fi
#     Add to fstab
        check_dup=$(cat /etc/fstab | grep "/dev/md${md}")
        prep_str="/dev/md${md} /mnt/md${md}_${raid_level} ${filesystem} defaults 0 0"
        chk_dup_sed=$(echo $check_dup | sed 's/\//\\\//g')
	      prp_str_sed=$(echo $prep_str | sed 's/\//\\\//g')
	      fstab_status="added"
        if [[ $check_dup ]]; then
          sed -i "s/${chk_dup_sed}/${prp_str_sed}/g" /etc/fstab
          fstab_status="replaced"
        else
          echo "${prep_str}" >> /etc/fstab
        fi
        if [ $? -ne 0 ]; then
            echo -e "\e[38;5;1mERROR \e[0m: ...  failed to write to /etc/fstab."
            return 1
          else
            if [[ $fstab_status == "added" ]]; then
              echo "Successfully ${fstab_status} new /dev/md${md} record to /etc/fstab. "
            elif [[ $fstab_status == "replaced" ]]; then
              echo "Successfully ${fstab_status} existing /dev/md${md} record in /etc/fstab. "
            else
              echo "Successfully finished operation '${fstab_status}' for /dev/md${md} in /etc/fstab."
            fi
        fi
      done
      return 0
}

delete_arrays() {
  echo -e "\e[38;5;1mWARNING!!! Would you like to delete All existing raid arrays? This option maybe dangerous, only desired for new disks. (Y or N)\e[0m"
  read x
  if [[ ! $x == "y" ]]; then
    return 1
  fi
  if [ $mdadm_checked -eq 0 ]; then
    check_installed mdadm
    (( mdadm_checked=1 ))
  fi
  mdadm --assemble --scan
  mds=$(ls /dev/md)
  for md in $mds
    do
      raid_level=$(mdadm -D /dev/md"${md}" | grep "Raid Level" | awk '{print $4}')
#      get all disks of that array.
      umount /dev/md"${md}"
      if [ $? -ne 0 ]; then
          echo -e "\e[38;5;1mERROR: \e[0m: ... Failed to unmount array /dev/md${md}."
      else
          echo "Unmounted array /dev/md${md}."
      fi
      disks=$(mdadm -D /dev/md"${md}" | awk '{print $7}'| grep /dev)
#      Seemingly unnecessary moves.
#      for disk in $disks
#      do
#        mdadm /dev/md"${md}" --fail "${disk}" --remove "${disk}"
#        if [ $? -ne 0 ]; then
#          echo -e "\e[38;5;1mWARNING: \e[0m: ... Removing disk ${disk} failed."
#        fi
#      done
      mdadm --stop /dev/md"${md}"
      if [ $? -ne 0 ]; then
          echo -e "\e[38;5;1mERROR: \e[0m: ... Failed to stop array /dev/md${md}."
      fi
      mdadm --remove /dev/md"${md}"
      if [ $? -ne 0 ]; then
          echo -e "\e[38;5;1mERROR: \e[0m: ... Failed to remove array /dev/md${md}."
      fi
      for disk in $disks
      do
      mdadm --misc --zero-superblock "${disk}"
      if [ $? -ne 0 ]; then
          echo -e "\e[38;5;1mERROR: \e[0m: ... Failed to remove superblock from ${disk}."
      fi
      done
      # remove array definition from /etc/mdadm.conf
      arr_row=$(cat /etc/mdadm/mdadm.conf | grep /dev/md/"${md}")
      arr_row_sed=$(echo "$arr_row" | sed 's/\//\\\//g')
      sed -i "s/${arr_row_sed}//g" /etc/mdadm/mdadm.conf
      echo "Raid array /dev/md${md} successfully removed from system. "
    done
    echo "All jobs finished. consider running \"Auto detect and mount raid arrays\" again. "
    return 0
}

create_arrays() {
  if [ $mdadm_checked -eq 0 ]; then
    check_installed mdadm
    (( mdadm_checked=1 ))
  fi
  mdadm --assemble --scan
  mds=$(ls /dev/md)
  duplicated=1
  provisional_id=0
  while [ $duplicated -eq 1 ]; do
    (( duplicated=0 ))
    for md in $mds
    do
      if [[ $md == $provisional_id ]]; then
        (( duplicated=1 ))
      fi
    done
    if [[ $duplicated == 1 ]]; then
      (( provisional_id++ ))
    fi
  done
  #TODO: validate input
  echo "Input raid level: (0,1,4,5,6,10)"
  read raid_level_npt
  echo "Input active raid devices count: (Input number)"
  read raid_dvc_count
  echo "Input spare disk count: (Input number)"
  read spare_dvc_count
  echo "Input spare disks:"
  provisional_command="mdadm --create /dev/md${provisional_id} --level=${raid_level_npt} --raid-devices=${raid_dvc_count} -x ${spare_dvc_count} "
  echo "Input member disks devices:"
  i=0
  while [ $i -lt $(( raid_dvc_count+spare_dvc_count )) ]
  do
    read x
    provisional_command="${provisional_command} ${x}"
    (( i++ ))
  done
  $provisional_command
  echo "All jobs finished. consider running \"Auto detect and mount raid arrays\" again. "
  return 0
}

create_arrays_zfs() {
  if [ $zfs_checked -eq 0 ]; then
    check_installed zfs
    (( zfs_checked=1 ))
  fi
  echo "Input raid level: (0,1,5,6). raid 10 is supported in zfs, but not yet implemented in this script. If you want raid 10 please refer to official documentation of zpool."
  read raid_level_npt
  echo "Input active raid devices count: (Input number)"
  read raid_dvc_count
  raid_level_name=""
  case $raid_level_npt in
  1)raid_level_name="mirror"
    ;;
  5)raid_level_name="raidz1"
    ;;
  6)raid_level_name="raidz2"
    ;;
  *) echo -e "\e[38;5;1mWARNING: \e[0m: ... Failed to recognize raid level, default to raid 0. proceed? (Y/N)"
    read x
    case $x in
    y|Y)
    ;;
    *) return 1
    ;;
    esac
  esac
  provisional_command="zpool create zfs_raid_pool ${raid_level_name} "
  i=0
  while [ $i -lt "$raid_dvc_count" ]
  do
    read x
    provisional_command="${provisional_command} ${x}"
    (( i++ ))
  done
  echo "Wait for zpool creation..."
  $provisional_command
  echo "All jobs finished. consider running \"Auto detect and mount raid arrays\" again. "
  return 0
}

export_zpool() {
  if [ $zfs_checked -eq 0 ]; then
    check_installed zfs
    (( zfs_checked=1 ))
  fi
  pools=$(zpool list | awk '{print $1}' | sed -n '2,$p')
  if [[ $pools ]]; then
    for pool in $pools
    do
      zpool export "${pool}"
      if [ $? -ne 0 ]; then
          echo -e "\e[38;5;1mERROR: \e[0m: ... Failed to export ${pool}."
      fi
    done
  fi
  echo "Success."
  return 0
}

import_zpool() {
  if [ $zfs_checked -eq 0 ]; then
    check_installed zfs
    (( zfs_checked=1 ))
  fi
  modprobe zfs
  pools=$(zpool import | grep pool: | awk '{print $2}')
  if [[ $pools ]]; then
    for pool in $pools
    do
      zpool import "${pool}"
      if [ $? -ne 0 ]; then
          echo -e "\e[38;5;1mERROR: \e[0m: ... Failed to import ${pool}."
      fi
    done
  fi
#  upgrade is needed if ZFS versions are different.
  zpool upgrade
  echo "Success."
  return 0
}

mdadm_checked=0
zfs_checked=0
loop=1
until [ $loop -eq 0 ]; do
  display_menu
  case $choice in
    1) auto_detect_mount ;;
    2) delete_arrays ;;
    3) create_arrays ;;
    4) create_arrays_zfs ;;
    5) export_zpool ;;
    6) import_zpool ;;
    *)   (( loop=0 )) ;;
  esac
done
echo "Finished."
exit 0



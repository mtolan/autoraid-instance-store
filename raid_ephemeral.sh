#!/bin/bash
#
# this script will attempt to detect any ephemeral drives on an EC2 node and create a RAID-0 stripe
# mounted at /mnt. It should be run early on the first boot of the system.
#
# Beware, This script is NOT fully idempotent.
#

if [ "$1" != "start" ]; then
  echo 'Not doing anything'
  exit 0
fi

METADATA_URL_BASE="http://169.254.169.254/latest"
LOGFILE="/var/log/raid_ephemeral.log"

haveProg() {
    [ -x "$(which $1)" ]
}

# Configure Raid - take into account xvdb or sdb
root_drive=`df -h | grep -v grep | awk 'NR==2{print $1}'`

if [ "$root_drive" == "/dev/xvda1" ]; then
  echo "Detected 'xvd' drive naming scheme (root: $root_drive)" >> $LOGFILE
  DRIVE_SCHEME='xvd'
else
  echo "Detected 'sd' drive naming scheme (root: $root_drive)" >> $LOGFILE
  DRIVE_SCHEME='sd'
fi

# figure out how many ephemerals we have by querying the metadata API, and then:
#  - convert the drive name returned from the API to the hosts DRIVE_SCHEME, if necessary
#  - verify a matching device is available in /dev/
drives=""
ephemeral_count=0
ephemerals=$(curl --connect-timeout 10 --silent $METADATA_URL_BASE/meta-data/block-device-mapping/ | grep ephemeral)
for e in $ephemerals; do
  echo "Probing $e .." >> $LOGFILE
  device_name=$(curl --silent $METADATA_URL_BASE/meta-data/block-device-mapping/$e/)
  # might have to convert 'sdb' -> 'xvdb'
  device_name=$(echo $device_name | sed "s/sd/$DRIVE_SCHEME/")
  device_path="/dev/$device_name"

  # test that the device actually exists since you can request more ephemeral drives than are available
  # for an instance type and the meta-data API will happily tell you it exists when it really does not.
  if [ -b $device_path ]; then
    echo "Detected ephemeral disk: $device_path" >> $LOGFILE
    drives="$drives $device_path"
    ephemeral_count=$((ephemeral_count + 1 ))
  else
    echo "Ephemeral disk $e, $device_path is not present. skipping" >> $LOGFILE
  fi
done

if [ "$ephemeral_count" = 0 ]; then
  echo "No ephemeral disk detected. exiting" >> $LOGFILE
  exit 0
fi

if haveProg apt-get ; then 
  apt-get install mdadm --no-install-recommends
  apt-get install curl
elif haveProg yum ; then 
  yum -y -d0 install mdadm curl
else
    echo 'No package manager found!' >> $LOGFILE
    exit 2
fi

# ephemeral0 is typically mounted for us already. umount it here
umount /mnt
for drive in $drives; do
  umount $drive
done

# overwrite first few blocks in case there is a filesystem, otherwise mdadm will prompt for input
for drive in $drives; do
  dd if=/dev/zero of=$drive bs=4096 count=1024
done

partprobe
mdadm --create --verbose /dev/md0 --level=0 -c256 --raid-devices=$ephemeral_count $drives
echo DEVICE $drives | tee /etc/mdadm.conf
mdadm --detail --scan | tee -a /etc/mdadm.conf $LOGFILE
blockdev --setra 65536 /dev/md0
mkfs -t ext3 /dev/md0
mount -t ext3 -o rw,noatime /dev/md0 /mnt

# Remove xvdb/sdb from fstab
chmod 777 /etc/fstab
sed -i "/${DRIVE_SCHEME}b/d" /etc/fstab

# Make raid appear on reboot
echo "/dev/md0 /mnt ext3 rw,noatime,nobootwait 0 0" | tee -a /etc/fstab $LOGFILE

cat /etc/mdadm.conf >> /etc/mdadm/mdadm.conf
update-initramfs -u


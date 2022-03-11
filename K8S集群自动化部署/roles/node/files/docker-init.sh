#!/bin/bash
/usr/sbin/ip link show docker0 > /dev/null
if [ $? -ne 0 ];then
  /usr/sbin/brctl addbr docker0
  /usr/sbin/ip link set dev docker0 up
  /usr/sbin/ip addr add 100.85.29.1/24 dev docker0
fi
# End

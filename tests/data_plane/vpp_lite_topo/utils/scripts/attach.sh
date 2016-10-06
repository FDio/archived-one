#!/usr/bin/env bash

# Help script for attaching running vpp
#
# Currently his sctipt waits for second vpp pid

pid=""

cd ${VPP_LITE_DIR}

while [ "$pid" == "" ] ; do
  pid=$(pidof vpp | awk '{print $2}')
done

echo "attached to $pid"
gdb attach $pid -ex cont

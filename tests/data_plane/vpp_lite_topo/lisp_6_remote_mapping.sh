#!/usr/bin/env bash

function ping_lisp6 {
  sudo ip netns exec vppns1 ping6 -c 10 6:0:2::2
  if [ $? -ne 0 ] ; then
      echo "Can not ping other machine"
      exit -1
  fi
}

sudo ip netns exec vppns1 \
  bash -c "
    ip link set dev lo up
    ip addr add 6:0:1::2/64 dev veth_vpp1
    ip route add 6:0:2::0/64 via 6:0:1::1
"

sudo ip netns exec vppns2 \
  bash -c "
    ip link set dev lo up
    ip addr add 6:0:2::2/64 dev veth_vpp2
    ip route add 6:0:1::0/64 via 6:0:2::1
"

ping_lisp6

expect << EOF
spawn telnet localhost 5003
expect -re ".*>"
send "set int ip address del host-intervpp2 6:0:3::2/64\r"
expect -re ".*>"
send "set int ip address host-intervpp2 6:0:3::20/64\r"
expect -re ".*>"
EOF

expect << EOF
spawn telnet localhost 5002
expect -re ".*>"
send "lisp remote-mapping del vni 0 deid 6:0:2::0/64 seid 6:0:1::0/64 rloc 6:0:3::2\r"
expect -re ".*>"
send "lisp remote-mapping add vni 0 deid 6:0:2::0/64 seid 6:0:1::0/64 rloc 6:0:3::20\r"
expect -re ".*>"
EOF

ping_lisp6

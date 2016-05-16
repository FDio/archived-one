#!/usr/bin/env bash

function ping_lisp6 {
  sudo ip netns exec vppns1 ping6 -c 15 6:0:2::2
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

post_curl "add-mapping" ${ODL_ADD_CONFIG1_6o4}
post_curl "add-mapping" ${ODL_ADD_CONFIG2_6o4}

ping_lisp6

expect << EOF
spawn telnet localhost 5003
expect -re ".*>"
send "set int ip address del host-intervpp2 6.0.3.2/24\r"
expect -re ".*>"
send "set int ip address host-intervpp2 6.0.3.20/24\r"
expect -re ".*>"
EOF

post_curl "update-mapping" ${ODL_REPLACE_CONFIG2_6o4}

ping_lisp6

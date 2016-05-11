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

curl -X POST http://${ODL_IP}:${ODL_PORT}/restconf/operations/odl-mappingservice:add-mapping \
     -H "Content-Type: application/json" --data-binary "@${ODL_CONFIG_DIR}${ODL_ADD_CONFIG1_6}" \
     -u ${ODL_USER}:${ODL_PASSWD}
curl -X POST http://${ODL_IP}:${ODL_PORT}/restconf/operations/odl-mappingservice:add-mapping \
     -H "Content-Type: application/json" --data-binary "@${ODL_CONFIG_DIR}${ODL_ADD_CONFIG2_6}" \
     -u ${ODL_USER}:${ODL_PASSWD}

ping_lisp6

expect << EOF
spawn telnet localhost 5003
expect -re ".*>"
send "set int ip address del host-intervpp2 6:0:3::2/64\r"
expect -re ".*>"
send "set int ip address host-intervpp2 6:0:3::20/64\r"
expect -re ".*>"
EOF

curl -X POST http://${ODL_IP}:${ODL_PORT}/restconf/operations/odl-mappingservice:update-mapping \
     -H "Content-Type: application/json" --data-binary "@${ODL_CONFIG_DIR}${ODL_REPLACE_CONFIG2_6}" \
     -u ${ODL_USER}:${ODL_PASSWD}

ping_lisp6

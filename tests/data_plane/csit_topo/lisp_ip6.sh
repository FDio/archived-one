#!/usr/bin/env bash

function ping_lisp6 {
  local RESULTS
  RESULTS=$(ssh_tg "ping6 -c 10 6:0:2::2")
  if [ $? -ne 0 ] ; then
      echo "Can not ping other machine"
      ssh_vpp1 "sudo rm -r ${TMP_DIR}"
      ssh_vpp2 "sudo rm -r ${TMP_DIR}"
      exit -1
  fi
}

curl -X POST http://${ODL_IP}:${ODL_PORT}/restconf/operations/odl-mappingservice:add-mapping \
     -H "Content-Type: application/json" --data-binary "@${ODL_CONFIG_DIR}${ODL_ADD_CONFIG1_6}" \
     -u ${ODL_USER}:${ODL_PASSWD}
curl -X POST http://${ODL_IP}:${ODL_PORT}/restconf/operations/odl-mappingservice:add-mapping \
     -H "Content-Type: application/json" --data-binary "@${ODL_CONFIG_DIR}${ODL_ADD_CONFIG2_6}" \
     -u ${ODL_USER}:${ODL_PASSWD}

rsync -avz ${VPP_CONFIG_DIR}${VPP_CONFIG1_6} ${USER}@${VPP1_IP}:${TMP_DIR}/vpp1_6.conf
rsync -avz ${VPP_CONFIG_DIR}${VPP_CONFIG2_6} ${USER}@${VPP2_IP}:${TMP_DIR}/vpp2_6.conf

ssh_vpp1 "sudo vpp_api_test < ${TMP_DIR}/vpp1_6.conf"
ssh_vpp2 "sudo vpp_api_test < ${TMP_DIR}/vpp2_6.conf"

ssh_tg "sudo ip addr add 6:0:1::2/64 dev ${TG_INT1}"
ssh_tg "sudo ip link set ${TG_INT1} up"
ssh_tg "sudo ip route add 6:0:2::0/64 via 6:0:1::1 || exit 0"
ssh_tg "sudo ip netns exec net2 ip addr add 6:0:2::2/64 dev ${TG_INT2}"
ssh_tg "sudo ip netns exec net2 ip link set lo up"
ssh_tg "sudo ip netns exec net2 ip link set ${TG_INT2} up"
ssh_tg "sudo ip netns exec net2 ip route add 6:0:1::/64 via 6:0:2::1"

ping_lisp6

rsync -avz ${VPP_CONFIG_DIR}${VPP_RECONF2_6}  ${USER}@${VPP2_IP}:${TMP_DIR}/vpp2_reconf_6.conf

ssh_vpp2 "sudo vpp_api_test < ${TMP_DIR}/vpp2_reconf_6.conf"

curl -X POST http://${ODL_IP}:${ODL_PORT}/restconf/operations/odl-mappingservice:update-mapping \
     -H "Content-Type: application/json" --data-binary "@${ODL_CONFIG_DIR}${ODL_REPLACE_CONFIG2_6}" \
     -u ${ODL_USER}:${ODL_PASSWD}

ping_lisp6

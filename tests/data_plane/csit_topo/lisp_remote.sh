#!/usr/bin/env bash

function ping_lisp {
  local RESULTS
  RESULTS=$(ssh_tg "ping -c 10 6.0.2.2")
  if [ $? -ne 0 ] ; then
      echo "Can not ping other machine"
      ssh_vpp1 "sudo rm -r ${TMP_DIR}"
      ssh_vpp2 "sudo rm -r ${TMP_DIR}"
      exit -1
  fi
}

rsync -avz ${VPP_CONFIG_DIR}${VPP_CONFIG1} ${USER}@${VPP1_IP}:${TMP_DIR}/vpp1.conf
rsync -avz ${VPP_CONFIG_DIR}${VPP_CONFIG2} ${USER}@${VPP2_IP}:${TMP_DIR}/vpp2.conf

ssh_vpp1 "sudo vpp_api_test < ${TMP_DIR}/vpp1.conf"
ssh_vpp2 "sudo vpp_api_test < ${TMP_DIR}/vpp2.conf"

ssh_tg "sudo ip addr add 6.0.1.2/24 dev ${TG_INT1}"
ssh_tg "sudo ip link set ${TG_INT1} up"
ssh_tg "sudo ip route add 6.0.2.0/24 via 6.0.1.1"
ssh_tg "sudo ip netns exec net2 ip addr add 6.0.2.2/24 dev ${TG_INT2}"
ssh_tg "sudo ip netns exec net2 ip link set lo up"
ssh_tg "sudo ip netns exec net2 ip link set ${TG_INT2} up"
ssh_tg "sudo ip netns exec net2 ip route add 6.0.1.0/24 via 6.0.2.1"

ping_lisp

rsync -avz ${VPP_CONFIG_DIR}${VPP_RECONF1}  ${USER}@${VPP1_IP}:${TMP_DIR}/vpp1_reconf.conf
rsync -avz ${VPP_CONFIG_DIR}${VPP_RECONF2}  ${USER}@${VPP2_IP}:${TMP_DIR}/vpp2_reconf.conf

ssh_vpp1 "sudo vpp_api_test < ${TMP_DIR}/vpp1_reconf.conf"
ssh_vpp2 "sudo vpp_api_test < ${TMP_DIR}/vpp2_reconf.conf"

ping_lisp

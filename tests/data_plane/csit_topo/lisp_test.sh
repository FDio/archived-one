#!/usr/bin/env bash
#
#
#         +------+                   +-----+
#         |      | VPP1_INT  TG_INT1 |     |
#         | VPP1 +-------------------+ TG  |
#         |      |                   |     |
#         |      |                   |     |
#         +--+---+                   +--+--+
#            | VPP1_INT                 | TG_INT2
#   ODL_INT  |                          |
# ODL -------|                          |
#            | VPP2_INT                 |
#         +--+---+                      |
#         |      | VPP2_INT             |
#         | VPP2 +----------------------+
#         |      |
#         |      |
#         +------+

set -x

USER="csit"
ODL_USER="admin"
ODL_PASSWD="admin"
VPP1_IP="192.168.255.101"
VPP2_IP="192.168.255.102"
TG_IP="192.168.255.100"
ODL_IP="192.168.255.10"
ODL_PORT="8181"
TMP_DIR="/tmp/vpp_${RANDOM}_lisp_test"
TG_INT1="eth2"
TG_INT2="eth3"
ODL_M_USER="user"
ODL_INT="eth2"
VPP_CONFIG_DIR="../configs/vpp_csit_config/"
VPP_CONFIG1="vpp1.conf"
VPP_CONFIG1_6="vpp1_6.conf"
VPP_CONFIG2="vpp2.conf"
VPP_CONFIG2_6="vpp2_6.conf"
VPP_RECONF2="vpp2_reconf.conf"
VPP_RECONF2_6="vpp2_reconf_6.conf"
ODL_CONFIG_DIR="../configs/odl/"
ODL_ADD_CONFIG1="add_ipv4_odl1.txt"
ODL_ADD_CONFIG1_6="add_ipv6_odl1.txt"
ODL_ADD_CONFIG2="add_ipv4_odl2.txt"
ODL_ADD_CONFIG2_6="add_ipv6_odl2.txt"
ODL_REPLACE_CONFIG2="replace_ipv4_odl2.txt"
ODL_REPLACE_CONFIG2_6="replace_ipv6_odl2.txt"

function ssh_vpp1 {
    ssh ${USER}@${VPP1_IP} ${@} || exit
}

function ssh_vpp2 {
    ssh ${USER}@${VPP2_IP} ${@} || exit
}

function ssh_tg {
    ssh ${USER}@${TG_IP} ${@} || exit
}

function ssh_odl {
    ssh ${ODL_M_USER}@${ODL_IP} ${@} || exit
}

curl -X DELETE http://${ODL_IP}:${ODL_PORT}/restconf/config/odl-mappingservice:mapping-database/ -u ${ODL_USER}:${ODL_PASSWD}

ssh_tg "sudo ip netns del net2 &> /dev/null || exit 0"
ssh_tg "sudo ip addr flush dev ${TG_INT1} &> /dev/null || exit 0"
ssh_tg "sudo ip route del 6.0.2.0/24 via 6.0.1.1 || exit 0"
ssh_tg "sudo ip route del 6:0:2::0/64 via 6:0:1::1 || exit 0"

ssh_odl "sudo ip addr flush dev ${ODL_INT} &> /dev/null || exit 0"
ssh_odl "sudo ip addr add 6.0.3.100/24 dev ${ODL_INT}"
ssh_odl "sudo ip addr add 6:0:3::100/64 dev ${ODL_INT}"

ssh_odl "sudo ethtool --offload  ${ODL_INT}  rx off tx off"

ssh_vpp1 "sudo stop vpp;  exit 0"
ssh_vpp2 "sudo stop vpp;  exit 0"

ssh_vpp1 "sudo start vpp;  exit 0"
ssh_vpp2 "sudo start vpp;  exit 0"

ssh_vpp1 "mkdir ${TMP_DIR}"
ssh_vpp2 "mkdir ${TMP_DIR}"

ssh_tg "sudo ip netns add net2"
ssh_tg "sudo ip link set dev ${TG_INT2} netns net2"

if [ "$#" == 0 ] || [ "$1" == "ip4" ] ; then
  source lisp_ip4.sh
fi

if [ "$1" == "ip6" ] ; then
  source lisp_ip6.sh
fi

if [ "$1" == "all" ] ; then
  source lisp_ip4.sh
  source lisp_ip6.sh

  ping_lisp
  ping_lisp6
fi

#clean tmp file
ssh_vpp1 "sudo rm -r ${TMP_DIR}"
ssh_vpp2 "sudo rm -r ${TMP_DIR}"

echo "Success"
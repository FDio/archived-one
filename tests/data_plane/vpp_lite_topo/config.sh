ODL_USER="admin"
ODL_PASSWD="admin"
ODL_IP="127.0.0.1"
ODL_PORT="8181"

# path to vpp executable
VPP_LITE_BIN=/vpp/build-root/install-vpp_lite_debug-native/vpp/bin/vpp

if [ ! -f "${VPP_LITE_BIN}" ] ; then
  echo "Error: VPP binary not found. You can set VPP_LITE_BIN in config.sh"
  echo "Current value:"
  echo "VPP_LITE_BIN=${VPP_LITE_BIN}"
  exit 1
fi

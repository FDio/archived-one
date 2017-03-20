# Script for checking whether a mapping exists in the vpp's map-cache
#
# Params:
#   vat_exec - VAT executable
#   vpp_prefix - shared vpp memory prefix
#   mapping - mapping to verify

import sys
import subprocess
import json

def has_mapping(json, mapping):
  if len (json) == 0:
    return False

  for obj in json:
    if obj['eid'] == mapping:
      return True;

  return False

def verify_mapping(vat_exec, prefix, mapping, vat_path):
  vat_file = vat_path + '/' + 'dump_remote_mappings.tpl'
  out = subprocess.Popen([vat_exec, "chroot", "prefix", prefix, "json", "script",
      "in", vat_file], stdout=subprocess.PIPE).communicate()[0]

  o = json.loads(out)
  return has_mapping(o, mapping)

if __name__ == "__main__":
  if len(sys.argv) < 4:
    raise Exception('expected 4 parameters: VAT executable, shared prefix '
        + ' name, mapping expected, path to vat templates!')

  if verify_mapping(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]):
    sys.exit(0)
  else:
    sys.exit(1)

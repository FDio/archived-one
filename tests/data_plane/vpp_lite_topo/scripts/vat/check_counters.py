# Script for checking LISP counters

help_string = """
 Params:
   vat_exec - VAT executable
   vpp_prefix - shared vpp memory prefix
   vat_path - VAT template file
   vni
   seid
   deid
   loc_rloc
   rmt_rloc
   pkt_count
   bytes
"""

import sys
import subprocess
import json

def get_stat_entry(json, vni, seid, deid, loc_rloc, rmt_rloc):
  if len (json) == 0:
    return None

  for obj in json:
    if obj['vni'] == int(vni) and\
            obj['seid'] == seid and\
            obj['deid'] == deid and\
            obj['lloc'] == loc_rloc and\
            obj['rloc'] == rmt_rloc:
      return obj

  return None


def check_counters(vat_exec, vat_path, vpp_prefix, vni, seid, deid, loc_rloc,
        rmt_rloc, pkt_count, total_bytes):
  vat_file = vat_path + '/' + 'dump_stats.tpl'
  out = subprocess.Popen([vat_exec, "chroot", "prefix", vpp_prefix, "json", "script",
      "in", vat_file], stdout=subprocess.PIPE).communicate()[0]

  o = json.loads(out)
  stat_entry = get_stat_entry(o, vni, seid, deid, loc_rloc, rmt_rloc)

  if stat_entry is None:
    return False

  if stat_entry['pkt_count'] != int(pkt_count):
    return False
  if stat_entry['bytes'] != int(total_bytes):
    return False
  return True


if __name__ == "__main__":
  if len(sys.argv) < 10:
    raise Exception('expected 10 parameters: ' + help_string)

  if check_counters(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4],
          sys.argv[5],
          sys.argv[6],
          sys.argv[7],
          sys.argv[8],
          sys.argv[9],
          sys.argv[10]):
    sys.exit(0)
  else:
    sys.exit(1)

#/usr/bin/env python

# Simple map resolver
#
# This script creates an UDP socket and starts listening on it.
# When a map-request is received nonce is extracted from the request and
# used in map-reply.
#
# Notes:
# * works only with ipv4 in both under/over-lays.
# * exact address matching is done while looking for a mapping
#
# Usage:
#   ./dummy_mr <bind-ip> <port>
#

import sys
import socket

# mapping between EIDs and RLOCs
mappings = {
  b'\x06\x00\x02\x02' : (b'\x06\x00\x03\x02', ),
  b'\x06\x00\x01\x02' : (b'\x06\x00\x03\x01', )
}

# LISP map-reply message
reply_data = (b'\x20\x00\x00\x01'   # type, PES, reserved, record count
             + '\x00\x00\x00\x00'   # nonce
             + '\x00\x00\x00\x00'   # nonce
             + '\x00\x00\x05\xa0'   # record TTL
             + '\x01\x18\x10\x00'   # loc-count, EID-len, ACT
             + '\x00\x00\x00\x01'   # rsvd, map-version, EID-AFI=ipv4
             + '\x06\x00\x02\x00'   # EID prefix
             + '\x01\x01\xff\x00'   # prio, weight, mprio, mweight
             + '\x00\x05\x00\x01'   # unused, LpR, Loc-AFI
             + '\x06\x00\x03\x02')  # locator

request_nonce_offset = 36
reply_nonce_offset = 4

request_eid_offset = 60
reply_eid_offset = 24

reply_rloc_offset = 36


def build_reply(nonce, deid):
  if deid not in mappings:
    raise Exception('No mapping found for eid {}!'.format(repr(deid)))
  m = mappings[deid]

  # prepare reply data
  reply = bytearray(reply_data)

  # update rloc field in reply message
  rloc = bytearray(m[0])

  for i in range(0, 4):
    reply[reply_rloc_offset + i] = rloc[i]

  # update eid prefix field
  for i in range(0, 4):
    reply[reply_eid_offset + i] = deid[i]

  # update nonce
  for i in range(0, 8):
    reply[reply_nonce_offset + i] = nonce[i]

  return reply


def run(host, port):
  sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  server_address = (host, int(port))
  sock.bind(server_address)

  while True:
    data, address = sock.recvfrom(4096)

    # extract nonce from request
    nonce = data[request_nonce_offset:request_nonce_offset+8]

    # extract deid
    deid = data[request_eid_offset:request_eid_offset+4]

    rp = build_reply(nonce, deid)
    sock.sendto(rp, address)


if __name__ == "__main__":
  if len(sys.argv) < 2:
    raise Exception('IP and port expected')

  run(sys.argv[1], sys.argv[2])

# Usage:
#
#   $ python dummy_map_server <bind-ip> <port>
#

import sys
import socket
import hmac
import hashlib

map_notify = (b"\x40\x00\x00\x01"
    + "\x00\x00\x00\x00"
    + "\x00\x00\x00\x00"
    + "\x00\x01\x00\x14"  # key ID, Auth data length = 20
    + "\x00\x00\x00\x00"
    + "\x00\x00\x00\x00"
    + "\x00\x00\x00\x00"
    + "\x00\x00\x00\x00"
    + "\x00\x00\x00\x00" # auth data
    + "\x00\x01"
    + "\x51\x80\x01\x18\x00\x00\x00\x00\x00\x01\x06\x00\x01\x00\x01\x01"
    + "\x00\x00\x00\x04\x00\x01\x06\x00\x03\x01")

notify_nonce_offset = 4
notify_auth_data_len = 20
register_nonce_offset = 4
auth_data_offset = 16
secret_key = 'password'


def build_notify(nonce):
  rp = bytearray(map_notify)

  for i in range(0, 8):
    rp[notify_nonce_offset + i] = nonce[i]

  # compute hash
  digest = hmac.new(secret_key, rp, hashlib.sha1).digest()

  for i in range(0, notify_auth_data_len):
    rp[auth_data_offset + i] = digest[i]

  return rp


def run(host, port):
  sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  server_address = (host, int(port))
  sock.bind(server_address)

  while True:
    data, address = sock.recvfrom(4096)

    # extract nonce from message
    nonce = data[register_nonce_offset:register_nonce_offset+8]

    rp = build_notify(nonce)
    sock.sendto(rp, address)
    print 'Replied to ', ''.join(x.encode('hex') for x in nonce)


if __name__ == "__main__":
  if len(sys.argv) < 2:
    raise Exception('IP and port expected')

  run(sys.argv[1], sys.argv[2])

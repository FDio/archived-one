#/usr/bin/env python

import sys
import socket


def do_flood(host, num):
  try:
    socket.inet_aton(host)
    is_ip4 = True
  except socket.error:
    try:
      socket.inet_pton(socket.AF_INET6, host)
      is_ip4 = False
    except socket.error:
        raise Exception('Invlid ip4/6 address!')

  family = socket.AF_INET if is_ip4 else socket.AF_INET6

  for port in range(num):
    sock = socket.socket(family, socket.SOCK_DGRAM)
    sock.sendto('test', (host, port + 1))


if __name__ == '__main__':
  if len(sys.argv) < 2:
    raise Exception('IP and packet count expected!')
  do_flood(sys.argv[1], int(sys.argv[2]))

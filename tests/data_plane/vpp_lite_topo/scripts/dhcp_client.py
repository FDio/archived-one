import sys
from scapy.all import *

def p(s):
    print 'DHCP client: {}'.format(s)

def main(argv):
  src_mac = argv[1]
  dhcp_src = argv[2]

  # needed for scapy not to match replies since DHCP uses broadcast addresses
  # which wouldn't work
  conf.checkIPaddr = False

  while True:
    discover = Ether(dst='ff:ff:ff:ff:ff:ff', src=src_mac)/ \
      IP(src='0.0.0.0', dst='255.255.255.255')/ \
      UDP(dport=67,sport=68)/ \
      BOOTP(op=1, chaddr=src_mac)/ \
      DHCP(options=[('message-type', 'discover'), ('end')])

    ans,unans = srp(discover, timeout=3)
    for snd,rcv in ans:
      if rcv[IP].src == dhcp_src:
        exit(0)
      else:
        p('Unexpected DHCP packet source address! ({})'.format(rcv[IP].src))
        exit(1)

if __name__ == "__main__":
  main(sys.argv)

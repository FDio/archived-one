from scapy.all import *
from scapy.layers import *

server_ip="6.0.2.2"
client_ip="6.0.1.2"
server_mac="00:0B:CD:AE:9F:C6"
client_mac="aa:a2:a5:ea:54:20"
subnet_mask="255.255.255.0"
gateway="6.0.1.1"

# suboption 1 Agent circuit ID; len:4; val:0x00000001
# suboption 5 Link selection; len:4; val:6.0.1.1
option82 = '\x01\x04\x00\x00\x00\x01\x05\x04\x06\00\x01\x01'

def detect_dhcp(pkt):
  # check if we get DHCP discover and send offer message
  if pkt[DHCP] and pkt[DHCP].options[0][1] == 1:
    sendp(Ether(src=server_mac,dst="ff:ff:ff:ff:ff:ff")/
          IP(src=server_ip,dst="6.0.1.1")/
          UDP(sport=67,dport=68)/
          BOOTP(op=2, yiaddr=client_ip, siaddr=server_ip, giaddr=gateway,
                chaddr=client_mac, xid=pkt[BOOTP].xid)/
          DHCP(options=[('message_type', 'offer')])/
          DHCP(options=[('subnet_mask',subnet_mask)])/
          DHCP(options=[('server_id',server_ip)])/
          DHCP(options=[('relay_agent_Information', option82), ('end')]))

#sniff DHCP requests
def start():
    sniff(filter="udp and (port 67 or 68)", prn=detect_dhcp, store=0)

start()

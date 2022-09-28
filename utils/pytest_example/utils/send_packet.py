#
# Do not directly call this script in your test cases. Use function send_packets() in utils.py
#
import argparse
from scapy.utils import rdpcap
from scapy.sendrecv import sendpfast

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='Send network packets (need root privileges)')
    parser.add_argument('--itf', help='ethernet interface', type=str)
    parser.add_argument('--pcap', help='path to the PCAP file', type=str)
    parser.add_argument('--loop', help='number of times to process the packet list', default=1)
    parser.add_argument('--mbps', help='Mbits per second', default=100000)
    args = parser.parse_args()

    pkts = rdpcap(args.pcap)
    sendpfast(pkts, mbps=int(args.mbps), loop=int(args.loop), file_cache=True, iface=args.itf)

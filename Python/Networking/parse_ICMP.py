import dpkt
import socket
import datetime

#pcap_file = input("Input the filepath to the .pcap file: ")

def mac_addr(address):
    return ':'.join('%02x' % b for b in address)

def inet_to_str(inet):
    return socket.inet_ntoa(inet)

with open('icmpWhy.pcapng', 'rb') as f:
    pcap = dpkt.pcap.Reader(f)
    for timestamp, buf in pcap:
        eth = dpkt.ethernet.Ethernet(buf)
        if not isinstance(eth.data, dpkt.ip.IP):
            continue
        ip = eth.data
        if isinstance(ip.data, dpkt.icmp.ICMP):
            icmp = ip.data
            print('Timestamp:', datetime.datetime.utcfromtimestamp(timestamp))
            print('Ethernet Frame:', mac_addr(eth.src), mac_addr(eth.dst), eth.type)
            print('IP:', inet_to_str(ip.src), '->', inet_to_str(ip.dst))
            print('ICMP: type:', icmp.type, 'code:', icmp.code, 'checksum:', icmp.sum)
            print()

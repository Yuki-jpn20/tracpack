from __future__ import print_function
from bcc import BPF
from sys import argv
import time
import ipaddress
import socket

#args
def usage():
    print("USAGE: %s IF_NAME" % argv[0])
    print("")
    print("examples:")
    print("    sudo python3 %s eth0  # bind socket to eth0" % argv[0])

if len(argv) != 2:
  usage()
  exit()

#arguments
interface = argv[1]

print ("binding socket to '%s'" % interface)

bpf = BPF(src_file = "store_metrics.c",debug = 0)
func = bpf.load_func("store_metrics", BPF.SOCKET_FILTER)

BPF.attach_raw_socket(func, interface)
socket_fd = func.sock

sock = socket.fromfd(socket_fd, socket.PF_PACKET, socket.SOCK_RAW, socket.IPPROTO_IP)
sock.setblocking(True)

metrics = bpf.get_table("metrics")
print("START")

while 1:
  try:
    metrics.clear()
    time.sleep(1)
    for k, v in metrics.items():
        print("saddr: {}, daddr: {}, spanid: 0x{:x}{:x}, msg: {}, timestamp: {}".format(str(ipaddress.ip_address(k.src_addr).reverse_pointer), str(ipaddress.ip_address(k.dst_addr).reverse_pointer), k.span_id_1, k.span_id_2, k.msg, k.timestamp))

  except KeyboardInterrupt:
    break

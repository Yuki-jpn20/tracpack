#!/usr/bin/python3

from bcc import BPF
from pyroute2 import IPRoute
import sys
import time
from sys import argv

#args
def usage():
    print("USAGE: %s IF_NAME" % argv[0])
    print("")
    print("examples:")
    print("    sudo python3 %s eth0  # bind socket to eth0" % argv[0])

if len(argv) != 2:
  usage()
  exit()

ipr = IPRoute()
interface = sys.argv[1]
print ("binding socket to '%s'" % interface)

INGRESS="ffff:ffff2"
EGRESS="ffff:ffff3"

print("START")

try:
    b = BPF(src_file = "update_len.c", debug=0)
    fn = b.load_func("update_len", BPF.SCHED_CLS)
    idx = ipr.link_lookup(ifname=interface)[0]

    ipr.tc("add", "clsact", idx)
    ipr.tc("add-filter", "bpf", idx, ":1", fd=fn.fd, name=fn.name, parent=INGRESS, classid=1,direct_action=True)

    while True:
      try:
        time.sleep(1)
      except KeyboardInterrupt:
        break
finally:
  if "idx" in locals(): 
    ipr.tc("del", "clsact", idx)

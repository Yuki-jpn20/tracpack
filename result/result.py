#!/usr/bin/env python3

import csv
import numpy as np
import matplotlib.pyplot as plt
import os
import sys

args = sys.argv
if len(args) == 2:
    os.chdir(args[1])
else:
    print("./result.py DIR")
    exit()

c1,c2,c3 = "blue","green","red"
l1,l2,l3 = "simple","zipkin","ebpf"
output_file = "output.png"

def export_data(csv_file):
    res_time = []

    with open(csv_file) as f:
        reader = csv.reader(f)
        for row in reader:
            res_time.append(int(row[0]))
    # print(len(res_time))
    del res_time[660:]
    return res_time

def histogram(res_time):
    tmp = res_time
    tmp.sort()
    n = int(len(tmp) * 0.01)
    del tmp[-n:]

    data_num = max(tmp) - min(tmp)
    return tmp,data_num

def all_histgram(res_time):
    tmp = res_time
    tmp.sort()
    n = int(len(tmp) * 0.01)
    del tmp[-n:]

    data_num = max(tmp) - min(tmp)
    y,binEdges = np.histogram(tmp,bins=data_num)
    bincenters = 0.5*(binEdges[1:]+binEdges[:-1])

    return bincenters,y

def stack(res_time):
    tmp = res_time
    tmp.sort()
    n = int(len(tmp) * 0.01)
    del tmp[-n:]
    stack_y = []
    sum = 0
    data_num = max(tmp) - min(tmp)
    y,binEdges = np.histogram(tmp,bins=data_num)
    for i in y:
        sum += i
        stack_y.append(sum)
    bincenters = 0.5*(binEdges[1:]+binEdges[:-1])

    return bincenters,stack_y

def stat(res_time):
    for p in range(0, 101, 10):
        print(p, "パーセンタイル: ", np.percentile(res_time, p))
        if p == 90:
            print("99 パーセンタイル: ", np.percentile(res_time, 99))

simple_res_time = export_data("simple-response-time")
zipkin_res_time = export_data("zipkin-response-time")
bpf_res_time = export_data("bpf-response-time")

# 統計
# stat(simple_res_time)
# stat(zipkin_res_time)
# stat(bpf_res_time)

# 時系列グラフ
x1 = range(1,len(simple_res_time)+1)
x2 = range(1,len(zipkin_res_time)+1)
x3 = range(1,len(bpf_res_time)+1)
plt.plot(x1,simple_res_time,'-',color=c1, label=l1)
plt.plot(x2,zipkin_res_time,'-',color=c2, label=l2)
plt.plot(x3,bpf_res_time,'-',color=c3, label=l3)
plt.legend(loc=0)
plt.savefig("all_time.png")
plt.clf()

# 累積グラフ
x1,y1 = stack(simple_res_time)
x2,y2 = stack(zipkin_res_time)
x3,y3 = stack(bpf_res_time)
print(len(y1), len(y2), len(y3))

plt.plot(x1,y1,'-',color=c1, label=l1)
plt.plot(x2,y2,'-',color=c2, label=l2)
plt.plot(x3,y3,'-',color=c3, label=l3)
plt.xlabel('response time (ms)')
plt.ylabel('request number')
plt.legend(loc=0)
plt.savefig("all_stack.pdf")
plt.savefig("all_stack.png")
plt.clf()

# 各場合のヒストグラム(99パーセンタイル)
x,y = histogram(simple_res_time)
plt.hist(x,bins=y)
plt.savefig("simple-hist.png")
plt.clf()

x,y = histogram(zipkin_res_time)
plt.hist(x,bins=y)
plt.savefig("zipkin-hist.png")
plt.clf()

x,y = histogram(bpf_res_time)
plt.hist(x,bins=y)
plt.xlabel('response time (ms)')
plt.ylabel('request number')
plt.savefig("bpf-hist.png")
plt.clf()

# 各場合のヒストグラムを重ねた場合
bincenters,y = all_histgram(simple_res_time)
plt.plot(bincenters,y,'-',color=c1, label=l1)

bincenters,y = all_histgram(zipkin_res_time)
plt.plot(bincenters,y,'-',color=c2, label=l2)

bincenters,y = all_histgram(bpf_res_time)
plt.plot(bincenters,y,'-',color=c3, label=l3)
plt.legend(loc=0)
plt.savefig("all-hist.png")
plt.clf()

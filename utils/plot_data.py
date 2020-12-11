#!/usr/bin/python

import numpy as np
import sys
import matplotlib.pyplot as plt

with open(sys.argv[1]) as f:
    data = f.read()

data = data.split('\n')
data = data[:-2] # remove 2 last elements

x = [row.split(' ')[0] for row in data]
y1 = [row.split(' ')[1] for row in data]
y2 = [row.split(' ')[2] for row in data]

fig = plt.figure()

ax1 = fig.add_subplot(111)

ax1.set_title("Packet arrival time diff (ms)")    
ax1.set_xlabel('Packet id')
ax1.set_ylabel('Diff (ms)')

ax1.plot(x,y1, c='r', label="Sent pkt diff time")
ax1.plot(x,y2, c='g', label="Received pkt diff time")

leg = ax1.legend()

plt.show()

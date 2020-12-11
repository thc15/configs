#!/bin/bash -x

MPPA_IP=$1
HOST_EN="enp8s0f4d1"
min=123
max=125
MPPA_LOG="/tmp/pkt_mppa.pcap"
HOST_LOG="/tmp/pkt_host.pcap"

rm -f $HOST_LOG
ssh -t -t -f root@$MPPA_IP "killall tcpdump ; rm -f ${MPPA_LOG} ; tcpdump -i enmppa0 -w ${MPPA_LOG}" > /dev/null
PID_SSH=$(pgrep -f 'ssh.*-f')

sudo -b tcpdump -i $HOST_EN -w $HOST_LOG
PID_TCPDUMP=$!

for i in $(seq $min  $max)
do
  iperf3 -c ${MPPA_IP} -P 1 -l $i -u -R -b 100m -i 2 -t 2 -w 32k
  if [ $? -ne 0 ]
  then
	  exit "[$(( $i - $min ))] Failed @size $i"
  fi
done

pkill -9 $PID_SSH $PID_TCPDUMP

scp root@$MPPA_IP:${MPPA_LOG} $HOME/tmp/
cp ${HOST_LOG} ${HOME}/${HOST_LOG}
echo "SUCCESS"

#python $HOME/softs/pcap-diff/pcap_diff.py -i ${HOME}/${HOST_LOG} -i ${HOME}/${MPPA_LOG} -o $HOME/tmp/diff.pcap -f s

exit 0

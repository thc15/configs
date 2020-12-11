#!/bin/bash -x


usage() {
 echo "Usage: $0 [-i input pcap] [-j output pcap] [-o resulting diff file]" 1>&2; exit 1;
}

DIFF="/tmp/diff.pcap"
MERGE="/tmp/merge.pcap"
COMPARE=0

while getopts ":i:j:c" option; do
    case "${option}" in
        i)
            IN_PCAP=${OPTARG}
            ;;
        j)
            OUT_PCAP=${OPTARG}
            ;;
        c)
            COMPARE=1
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))
if [ -z "${IN_PCAP}" ] || [ -z "${OUT_PCAP}" ] || [ -z "${DIFF}" ]; then
    usage
fi

scp tcostis@coolisaurus02:${IN_PCAP} tcostis@coolisaurus02:${OUT_PCAP} /tmp

IF=`basename ${IN_PCAP}`
OF=`basename ${OUT_PCAP}`

python ~/softs/pcap-diff/pcap_diff.py -i /tmp/${IF} -i /tmp/${OF} -o ${DIFF} -f s

if [ ! -z $COMPARE ]; then
  mergecap -w ${MERGE} /tmp/${IF} /tmp/${OF}

  wireshark ${DIFF} &
  wireshark ${MERGE} &
fi



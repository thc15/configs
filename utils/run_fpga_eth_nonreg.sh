#!/bin/bash

LOG=`mktemp`
echo "LOG FILE -> $LOG"

#ROOT_DIR=`dirname $(readlink -f $0)`
#ROOT_DIR="$ROOT_DIR/.."
ROOT_DIR="/work1/tcostis/work/tools_coolidge/ethernet/"
ETH_TESTS_DIR="$ROOT_DIR/tests/ethernet_bare/internal_loop/"
ETH_UNITTESTS_DIR="$ROOT_DIR/libmppaeth/output/bin/"

BUILD=$1
if hostname | grep -q "coolisaurus" ; then
echo "coolisaurus"
    BUILD=0
fi

#/work2/hardware/cao/synopsys/confpro/L-2016.09-SP2/bin/confprosh ~/utils/reset_haps.sh;  k1-jtag-runner --exec-file=Cluster0:tests/ethernet_bare/internal_loop/stats/output/bin/check_stats --progress --jtag-verbose --dtb=/work1/tcostis/work/rdtools/kEnv/k1tools/usr/local/k1rdtools/lib/firmware/kalray/dtb/k1c/0x2_haps/0x1_haps_low_speed_soc.dtb --no-bootloader

pushd  $ETH_UNITTESTS_DIR
for d in $ETH_UNITTESTS_DIR/* ; do
 testname=`basename $d`
 echo
 echo
 echo "RUNNING $testname"
  ${K1_TOOLCHAIN_DIR}/bin/k1-jtag-runner --no-pll --no-bootloader --no-ddr --no-pcie --no-pcie-load --exec-file=Cluster0:$testname --progress --dtb=${K1_TOOLCHAIN_DIR}/lib/firmware/kalray/dtb/k1c/iss/default.dtb | tee -a $LOG
  if [ $?==0 ]; then echo "$testname SUCCESS" ;
  else echo "$testname FAILED"; fi
done
popd  $ETH_UNITTESTS_DIR

for d in $ETH_TESTS_DIR/* ; do
 testname=`basename $d`
 # if [ "$testname" == "hash" ]; then continue; fi
 # if [ "$testname" == "lut" ]; then continue; fi
 # if [ "$testname" == "PFC" ]; then continue; fi
 pushd $d
 echo
 echo
 if [ "$BUILD" -eq "1" ]; then
     make clean all 2>&1 | tee -a $LOG
 fi
 for t in `find $d/output/bin -maxdepth 1 -perm -111 -type f`; do
         if echo $t | egrep -qi "stats64"; then continue; fi
         if echo $t | egrep -qi "pfc"; then continue; fi
         echo "RUNNING $t"
         #make run_hw 2>&1 | tee -a $LOG
         ${K1_TOOLCHAIN_DIR}/bin/k1-jtag-runner --no-pll --no-bootloader --no-ddr --no-pcie --no-pcie-load --exec-file=Cluster0:$t --progress --dtb=${K1_TOOLCHAIN_DIR}/lib/firmware/kalray/dtb/k1c/iss/default.dtb | tee -a $LOG
         if [ $?==0 ]; then echo "$testname SUCCESS" ;
         else echo "$testname FAILED"; fi
         echo
 done
 popd $d
done

echo "DONE -> $LOG"

egrep -i 'k1-jtag-runner|failed|passed|success' $LOG > /tmp/eth_nonreg.log

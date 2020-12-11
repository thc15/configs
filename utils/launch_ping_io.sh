#!/bin/bash -x

/work2/hardware/cao/synopsys/confpro/L-2016.09-SP2/bin/confprosh ~/utils/reset_haps.sh;  k1-jtag-runner --exec-file=Cluster0:tests/ethernet_bare/ping/output/bin/ping_io_only --progress --jtag-verbose --dtb=/work1/tcostis/work/rdtools/kEnv/k1tools/usr/local/k1rdtools/lib/firmware/kalray/dtb/k1c/0x2_haps/0x1_haps_low_speed_soc.dtb --no-bootloader -- -i 192.168.1.6 -m 02:02:02:02:02:02 -l 2

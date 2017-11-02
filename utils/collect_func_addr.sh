#!/bin/bash

tmp=$(mktemp)
func="$1"
exe="/local_home/thomas/work/sandbox/trunk/defacto/src/framework/librtledit/obj/test/debug64/rtledit_debug64.exe"
cmdfile="$HOME/tmp/cmd.gdb"

echo "Dump gdb file -> $tmp"

#readelf -s /local_home/thomas/work/sandbox/trunk/defacto/src/framework/librtledit/obj/test/debug64/rtledit_debug64.exe | gawk '
nm -gC $exe > $tmp

echo  "set logging on gdb.log" > $cmdfile
echo  "delete" >> $cmdfile
echo  "set args move_inst bug5648" >> $cmdfile

cat $tmp | grep $func | gawk '
{
  if($2 == "T") { 
    print "# code for " $3;
    print "b *0x" $1; 
    print "commands"; 
    print "silent"; 
    print "bt"; 
    print "c"; 
    print "end"; 
    print ""; 
  }
}' >> $cmdfile
#     print "print this->GetName ()";
echo "run" >> $cmdfile
echo "set logging off" >>  $cmdfile
echo "quit" >>  $cmdfile

gdb --command=$cmdfile $exe 


#{ 
#  if($4 == "FUNC" && $2 != 0) { 
#    print "# code for " $NF; 
#    print "b *0x" $2; 
#    print "commands"; 
#    print "silent"; 
#    print "bt 1"; 
#    print "c"; 
#    print "end"; 
#    print ""; 
#  } 
#}' > $tmp; 
##gdb --command=$tmp ./a.out; 
#rm -f $tmp

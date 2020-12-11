cd /proc
for pid in [0-9]*
do
    echo "PID = $pid with $(ls /proc/$pid/fd/ | wc -l) file descriptors"
done | sort -rn -k5 | head | while read -r _ _ pid _ fdcount _;
do
 command=$(ps -o cmd -p "$pid" -hc);   printf "pid = %5d with %4d fds: %s\n" "$pid" "$fdcount" "$command";
done

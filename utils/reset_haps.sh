set result [cfg_open haps80 emu:8]
puts "Wait Reset $result"
set result [cfg_reset_pulse cfg0 FB1_A]
puts "Reset $result"

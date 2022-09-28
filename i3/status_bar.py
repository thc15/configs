from i3pystatus import Status

#status = Status()
status=Status(logfile='/work1/tcostis/i3pystatus.log')

# Tue 30 Jul 11:59:46 PM KW31
status.register("clock", format="%a %-d %b %T W%V",)

# Note: requires libpulseaudio from PyPI
#status.register("alsa",
  #  format='{volume}%{volume_bar}',
 #   vertical_bar_width=1,
#)
status.register("pulseaudio",
        format="♪{volume}",
)
# Shows disk usage of /
status.register("disk", path="/", format="{avail}G",)
status.register("load")
status.register("mem",
    color="#999999",
    warn_color="#E5E500",
    alert_color="#FF1919",
    format="{avail_mem}/{total_mem}GB",
    divisor=1073741824,)

status.register("network",
    interface="enp0s31f6",
    #divisor=1024,
    #hints = {"markup": "pango"},
    #format_up = "<span color=\"#00FF00\">{essid}</span> {bytes_recv:6.1f}KiB {bytes_sent:5.1f}KiB",
    graph_width=4,
    #graph_style="braille-peak",
    #format_up="{v4} {network_graph_sent} {network_graph_recv}",
    format_up="\u2193{bytes_recv}KB/s \u2191{bytes_sent}KB/s",
    format_down="",
    )

status.run()

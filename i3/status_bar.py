from i3pystatus import Status

status = Status()

# Tue 30 Jul 11:59:46 PM KW31
status.register("clock", format="%a %-d %b %X W%V",)

# Note: requires libpulseaudio from PyPI
status.register(
    "pulseaudio",
    format='{volume}%{volume_bar}',
    vertical_bar_width=1,
)


status.register("battery",
        format="{status}{percentage:.2f}% {remaining:%E%hh:%Mm}",
        alert=True,
        alert_percentage=5,
        status={ "DIS": "↓", "CHR": "↑", "FULL": "=", },)

# Shows disk usage of /
status.register("disk", path="/", format="{avail}G",)
status.register("load")
status.register("mem",
    color="#999999",
    warn_color="#E5E500",
    alert_color="#FF1919",
    format="{avail_mem}/{total_mem}GB",
    divisor=1073741824,)

#status.register("temp", format="{temp:.0f}°C",)

status.register("network",
    interface="enx00e04c6814ae",
    #divisor=1024,
    #hints = {"markup": "pango"},
    #format_up = "<span color=\"#00FF00\">{essid}</span> {bytes_recv:6.1f}KiB {bytes_sent:5.1f}KiB",
    graph_width=4,
    #graph_style="braille-peak",
    #format_up="{v4} {network_graph_sent} {network_graph_recv}",
    #format (default: {interface} {bytes_sent}kB/s ↘{bytes_recv}kB/s) – format string
    format_up="\u2193{bytes_recv}KB/s \u2191{bytes_sent}KB/s",
    format_down="",
    )

# Note: requires both netifaces and basiciw (for essid and quality)  -> pip3 install basiciw
status.register("network",
    interface="wlo1",
    format_up="{essid} {quality:03.0f}%",
    format_down="",
    )

status.run()

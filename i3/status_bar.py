from i3pystatus import Status

status = Status()

# Note: requires libpulseaudio from PyPI
status.register(
    "pulseaudio",
    format='{volume}%{volume_bar}',
    vertical_bar_width=1,
)

# Tue 30 Jul 11:59:46 PM KW31
status.register("clock", format="%a %-d %b %X W%V",)

status.register("battery",
        format="{status}/{consumption:.2f}W {percentage:.2f}% {remaining:%E%hh:%Mm}",
        alert=True,
        alert_percentage=5,
        status={ "DIS": "↓", "CHR": "↑", "FULL": "=", },)

status.register("load")
status.register("temp", format="{temp:.0f}°C",)

status.register("network", interface="enx00e04c6814ae", format_up="{v4cidr}",)
# Note: requires both netifaces and basiciw (for essid and quality)  -> pip3 install basiciw
status.register("network", interface="wlo1", format_up="{essid} {quality:03.0f}%",)
# Shows disk usage of /
status.register("disk", path="/", format="[{avail}G]",)

status.run()

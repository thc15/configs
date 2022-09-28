import re


class CommandParser:

    def __init__(self, cmd_output):
        self.cmd_out = cmd_output

    def _search(self, regex, text):
        search = re.search(regex, text)
        return search.group(1) if search else None

    def _str_to_bool(self, txt):
        txt = txt.strip().lower()
        assert txt in ['yes', 'no']
        return True if txt == 'yes' else False


class EthtoolParser(CommandParser):
    """ Parser for cmd: ethtool <iface>
    """

    REGEX_SUPPORTED_SPEED = r'\tSupported link modes:\s([a-zA-Z0-9/_ \t\n]+)\t'
    REGEX_AUTONEG_SUPPORTED = r'\tSupports auto-negotiation:\s(Yes|No)\n\t'
    REGEX_FEC_SUPPORTED = r'\tSupported FEC modes:\s([a-zA-Z \t]+)\n\t'
    REGEX_FEC_ADVERTISED = r'\tAdvertised FEC modes:\s([a-zA-Z \t]+)\n\t'
    REGEX_AUTONEG_STATUS = r'\tAuto-negotiation:\s(on|off)'

    def supported_speeds(self):
        """ the output of 'ethtool <itf>' must be provided in the constructor
        """
        link_modes = self._search(self.REGEX_SUPPORTED_SPEED, self.cmd_out)
        if link_modes:
            speeds = re.findall(r"([0-9]+)b", link_modes)
            return set([int(x) for x in speeds])
        return set()

    def autoneg_supported(self):
        autoneg_bool = self._search(self.REGEX_AUTONEG_SUPPORTED, self.cmd_out)
        if autoneg_bool:
            return self._str_to_bool(autoneg_bool)
        return False

    def autoneg_status(self):
        autoneg_bool = self._search(self.REGEX_AUTONEG_STATUS, self.cmd_out)
        if autoneg_bool:
            return autoneg_bool
        return 'off'

    def supported_fec(self):
        out = self._search(self.REGEX_FEC_SUPPORTED, self.cmd_out)
        return self._parse_fec_encodings(out)

    def advertised_fec(self):
        out = self._search(self.REGEX_FEC_ADVERTISED, self.cmd_out)
        return self._parse_fec_encodings(out)

    def _parse_fec_encodings(self, out):
        if out == "Not reported":
            return set()
        elif out is not None:
            fec_supported = re.findall(r"([a-z]+)", out.lower())
            if 'none' in fec_supported:
                fec_supported.remove('none')
                fec_supported.append('off')
            return set(fec_supported)
        return set()



class ShowFecParser(CommandParser):
    """ Parser for cmd: ethtool --show-fec <iface>
    """
    
    REGEX_ACTIVE_FEC = r'Active FEC encoding:\s([A-Za-z]+)'

    def active_fec(self):
        active_fec = self._search(self.REGEX_ACTIVE_FEC, self.cmd_out)
        return active_fec.lower()


class EthtoolTransceiverParser(CommandParser):
    """ Parser for cmd: ethtool -m <iface>
    """
    
    REGEX_IDENTIFIER       = r'Identifier\s+: 0x([a-f0-9]{2})\s'
    REGEX_VENDOR_SN        = r'Vendor SN\s+: ([A-Za-z0-9]+)(?:-[AB12])?\n'
    REGEX_VENDOR_PN        = r'Vendor PN\s+: (\S+)\n'
    REGEX_VENDOR_REV       = r'Vendor rev\s+: (\S+)\n'
    REGEX_TRANSMITTER_TECH = r'Transmitter technology\s+:\s+0x([a-f0-9]{2})\s'
    REGEX_VENDOR_NAME      = r'Vendor name\s+: ([\S ]+)\n'

    def identifier(self):
        return self._search(self.REGEX_IDENTIFIER, self.cmd_out)

    def vendor_sn(self):
        return self._search(self.REGEX_VENDOR_SN, self.cmd_out)

    def vendor_pn(self):
        return self._search(self.REGEX_VENDOR_PN, self.cmd_out)

    def vendor_rev(self):
        return self._search(self.REGEX_VENDOR_REV, self.cmd_out)

    def transmitter_tech(self):
        return self._search(self.REGEX_TRANSMITTER_TECH, self.cmd_out)

    def vendor_name(self):
        return self._search(self.REGEX_VENDOR_NAME, self.cmd_out)


class MicrotikMonitorParser(CommandParser):
    """ Parser for cmd: /interface ethernet monitor <port>
    """
    
    REGEX_CABLE_SN = r'sfp-vendor-serial:\s([A-Za-z0-9]+)(?:-[AB])?\r\n'

    def vendor_sn(self):
        if not 'sfp-module-present: yes' in self.cmd_out:
            return None
        return self._search(self.REGEX_CABLE_SN, self.cmd_out)


class MicrotikSystemParser(CommandParser):
    """ Parser for cmd: /system package print
    """
    
    REGEX_VERSION = r'\s([0-9]+.[0-9]+.[0-9]+)\s'

    def version_of(self, element):
        if element not in self.cmd_out:
            return None
        line = [x for x in self.cmd_out.split('\r\n') if element in x][0]
        return self._search(self.REGEX_VERSION, line)


class MellanoxShowItfParser(CommandParser):
    """ Parser for cmd: show interface ethernet <port>
    """
    
    REGEX_CABLE_SN = r'serial number\s+:\s+([A-Za-z0-9]+)(?:-[AB12])?'
    REGEX_PORT_NB  = r'1/([0-9]{1,2})[\s\S]+serial number'

    def vendor_sn(self):
        return self._search(self.REGEX_CABLE_SN, self.cmd_out)

    def port(self):
        return self._search(self.REGEX_PORT_NB, self.cmd_out)


class MellanoxVersionParser(CommandParser):
    """ Parser for cmd: show inventory
    """
    
    REGEX_HW_VER = r'CHASSIS\s+([\w-]+)\s'

    def hw_version(self):
        ver = self._search(self.REGEX_HW_VER, self.cmd_out)
        return ver.strip() if ver else 'unknown'


class CiscoShowItfParser(CommandParser):
    """ Parser for cmd: show interface ethernet <port>
    """
    
    REGEX_CABLE_SN = r'serial number is ([A-Za-z0-9]+)(?:-[AB12])?'
    REGEX_PORT_NB  = r'1/([0-9]{1,2})[\s\S]+serial number'

    def vendor_sn(self):
        return self._search(self.REGEX_CABLE_SN, self.cmd_out)

    def port(self):
        return self._search(self.REGEX_PORT_NB, self.cmd_out)


class CiscoVersionParser(CommandParser):
    """ Parser for cmd: show version
    """
    
    REGEX_HW_VER = r' ([A-Z0-9-]+) Chassis '

    def hw_version(self):
        ver = self._search(self.REGEX_HW_VER, self.cmd_out)
        return ver.strip() if ver else 'unknown'        


class KvxBoardDiagParser(CommandParser):
    """ Parser for cmd: kvx-board-diag
    """
    
    REGEX_K200_CONFIG     = r'\|\s+configuration\s+\|\s+CONF\s+\|\s+([a-z-]+)\s+\|'
    REGEX_K200_SN         = r'-\s*serial:\s([A-Za-z0-9-]+)\n'
    REGEX_K200_BOARD_TYPE = r'-\sName:\s([a-z0-9]+)\n'
    REGEX_K200_BOARD_REV  = r'-\srevision:\s([a-z0-9]+)\n'

    def k200_config(self):
        return self._search(self.REGEX_K200_CONFIG, self.cmd_out)

    def k200_sn(self):
        return self._search(self.REGEX_K200_SN, self.cmd_out)

    def k200_board_type(self):
        return self._search(self.REGEX_K200_BOARD_TYPE, self.cmd_out)

    def k200_board_rev(self):
        return self._search(self.REGEX_K200_BOARD_REV, self.cmd_out)

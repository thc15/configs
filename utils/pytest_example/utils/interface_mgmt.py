import logging
import netifaces
import re
from utils.parsers import EthtoolParser, EthtoolTransceiverParser, ShowFecParser

from utils.utils import run_cmd, MppaSysfs


logger = logging.getLogger("Interface Mgmt")


class NotSupported(Exception):

    def __init__(self, iface, msg):
        super().__init__(f"{iface}: {msg}")


class InterfaceMgmt:
    """Abstract interface class. Contains basic settings such as autoneg, ifdown and ifup."""
    
    interface_type = '1G'

    # cache for ethtool commands
    ethtool_output = {}
    
    def __init__(self, iface):
        super().__init__(iface)
        self.iface = iface
        self.ip_subnet = None # of the form 192.168.1.1/24
        # callback for executing shell commands
        self.run_cmd_callback = run_cmd
        # to run commands as non-root user
        self.unprivileged_user = 'sudo'
    
    def __str__(self):
        return self.iface
    
    def _run_cmd(self, cmd, **kwargs):
        return self.run_cmd_callback(cmd=cmd.strip(), **kwargs)
    
    def _ethtool(self, cmd, sudo=True, parser=None, refresh=False, **kwargs):
        if '{iface}' in cmd:
            cmd = cmd.format(iface=self.iface)
        else:
            cmd = f"{cmd} {self.iface}"
        cmd = cmd.format(**kwargs)
        cmd = f"ethtool {cmd}"
        cmd2 = f"{self.unprivileged_user} {cmd}" if sudo else cmd
        if refresh or cmd not in InterfaceMgmt.ethtool_output:
            ret, out, _ = self._run_cmd(cmd2)
            if ret != 0:
                return None
            InterfaceMgmt.ethtool_output[cmd] = out
        ret = InterfaceMgmt.ethtool_output[cmd]
        return parser(ret) if parser else ret
    
    def is_1G_interface(self):
        return self.interface_type == '1G'
    
    def set_autoneg(self, autoneg, speed=None, fec=None):
        # check that autoneg is supported
        if autoneg == 'on' and not self.autoneg_supported():
            raise NotSupported(self.iface, "autoneg is not supported")
        # check that speed is supported
        if autoneg == 'off':
            assert speed is not None, "Speed must be set when autoneg is off"
            if not self.speed_supported(speed):
                raise NotSupported(self.iface, f"speed {speed} is not supported")
        # if autoneg already on, no need to turn it on
        if autoneg == self.autoneg_status() == 'on':
            logger.info('Auto-negotiation is already on, no need to turn it on')
            return True
        # all checks done, we can set the autoneg
        cmd = f"{self.unprivileged_user} ethtool -s {self.iface} autoneg {autoneg}" + (f" speed {speed}" if autoneg == 'off' else "")
        ret, _, _ = self._run_cmd(cmd)
        return ret == 0
    
    def down(self):
        ret, _, _ = self._run_cmd(f"{self.unprivileged_user} ifconfig {self.iface} down")
        return ret == 0
    
    def up(self):
        ret, _, _ = self._run_cmd(f"{self.unprivileged_user} ifconfig {self.iface} up")
        return ret == 0
    
    def autoneg_supported(self):
        ethtool = self._ethtool(cmd="", parser=EthtoolParser)
        return ethtool.autoneg_supported()
    
    def autoneg_status(self):
        ethtool = self._ethtool(cmd="", parser=EthtoolParser, refresh=True)
        return ethtool.autoneg_status()
    
    def speed_supported(self, speed):
        ethtool = self._ethtool(cmd="", parser=EthtoolParser)
        supported = ethtool.supported_speeds()
        return speed in supported
    
    def fec_supported(self, encoding):
        if encoding == 'auto' and self.autoneg_supported():
            return True
        ethtool = self._ethtool(cmd="", parser=EthtoolParser)
        supported = set.union(ethtool.supported_fec(), ethtool.advertised_fec())
        return encoding in supported
    
    @property
    def ip_address(self):
        if self.ip_subnet:
            return self.ip_subnet.split('/')[0]
        return None
    
    @property
    def ip_with_subnet(self):
        if self.ip_subnet:
            return self.ip_subnet
        return None

    def get_ip_address(self):
        """ Returns the IP address bounded to an interface

        Args:
            itf (str): interface
        """
        data = None
        try:
            data = netifaces.ifaddresses(self.iface)
        except ValueError:
            _, out, _ = self._run_cmd(f"ip -f inet addr show {self.iface} | grep 'inet'")
            assert 'inet ' in out, "Could not find ethernet interface %s" % self.iface
            return out.strip().split(' ')[1].split('/')[0]
        
        if netifaces.AF_INET not in data:
            raise Exception("No IP is bounded to %s" % self.iface)
        
        return data[netifaces.AF_INET][0]['addr']
    
    def set_ip_address(self, addr):
        # ip configuration
        self._run_cmd(f"{self.unprivileged_user} ip addr flush dev {self.iface}", expect_ret=0)
        self._run_cmd(f"{self.unprivileged_user} ip route flush {addr}", expect_ret=0)
        
        for _ in range(3):
            # T17201 workaround: retry to configure ip up to 3 times if not successful
            self._run_cmd(f"{self.unprivileged_user} ip addr add {addr} dev {self.iface}", expect_ret=0)
            # check that ip configuration was successful
            ip_set = self.get_ip_address()
            ip_ok = ip_set == addr.split('/')[0]
            if ip_ok:
                break
        assert ip_ok, f"IP configuration on interface {self.iface} failed 3 times"
        self.ip_subnet = addr
    
    @property
    def mac_address(self):
        """ Returns the MAC address of an interface

        Args:
            itf (str): interface
        """
        data = None
        try:
            data = netifaces.ifaddresses(self.iface)
        except ValueError:
            assert False, "Could not find ethernet interface %s" % self.iface
        
        return data[netifaces.AF_LINK][0]['addr']


class GigabitInterfaceMgmt(InterfaceMgmt):
    """Abstract class for interfaces 10G 25G 40G 50G 100G with SFP or QSFP cages.
       This class contains FEC settings in addition to InterfaceMgmt."""
    
    interface_type = '100G'

    def set_autoneg(self, autoneg, speed=None, fec=None):
        if not super().set_autoneg(autoneg, speed):
            return False
        if autoneg == 'off' and fec is not None:
            self.set_fec(fec)
            active_fec = self.get_fec()
            if active_fec != fec:
                logger.warning(f"The active FEC encoding {active_fec} is different than the one set {fec}")
            return active_fec == fec
        return True

    def set_fec(self, fec_encoding):
        # check that FEC is supported
        if not self.fec_supported(fec_encoding):
            raise NotSupported(self.iface, f"FEC {fec_encoding} is not supported")
        ret, _, _ = self._run_cmd(f"{self.unprivileged_user} ethtool --set-fec {self.iface} encoding {fec_encoding}")
        return ret == 0
    
    def get_fec(self):
        # some NIC do not support --show-fec, thus no expectation on return code
        parser = self._ethtool("--show-fec {iface}", parser=ShowFecParser, refresh=True)
        if parser is None:
            raise NotSupported(self.iface, "ethtool --show-fec is not supported")
        else:
            return parser.active_fec()
    
    def get_cable_sn(self):
        parser = self._ethtool("-m {iface}", parser=EthtoolTransceiverParser)
        if parser:
            return parser.vendor_sn()
        return None # no cable is connected
    
    def get_cable_pn(self):
        parser = self._ethtool("-m {iface}", parser=EthtoolTransceiverParser)
        if parser:
            return parser.vendor_pn()
        return None # no cable is connected
    
    def get_cable_rev(self):
        parser = self._ethtool("-m {iface}", parser=EthtoolTransceiverParser)
        if parser:
            return parser.vendor_rev()
        return None # no cable is connected
    
    def get_cable_type(self):
        parser = self._ethtool("-m {iface}", parser=EthtoolTransceiverParser)
        if parser:
            return int(parser.transmitter_tech(), 16)
        return None # no cable is connected
    
    def get_cable_vendor(self):
        parser = self._ethtool("-m {iface}", parser=EthtoolTransceiverParser)
        if parser:
            return parser.vendor_name()
        return None # no cable is connected
    
    @classmethod
    def all_interfaces():
        raise NotImplementedError()
    
    @classmethod
    def get_itf_cable_map(cls, **kwargs):
        itf_cab_map = []
        for itf in cls.all_interfaces(**kwargs):
            cable_sn = itf.get_cable_sn()
            if cable_sn:
                itf_cab_map.append((itf, cable_sn))
        return itf_cab_map


class InterfaceBinding:
    """Abstract class with attribute that serves as link to the interface binded host/mppa"""
    
    def __init__(self, iface):
        super().__init__()
        self.iface = iface
        self.binded_to_itf = None
        self.switch_port_binding = None
    
    def bind_to_interface(self, itf_obj, double_bind=True):
        if self.binded_to_itf:
            raise Exception(f"Interface {self.iface} is already binded to {self.binded_to_itf}")
        self.binded_to_itf = itf_obj
        if double_bind:
            itf_obj.bind_to_interface(self, double_bind=False)
    
    def bind_to_switch_port(self, switch_port):
        if self.switch_port_binding:
            raise Exception(f"Interface {self.iface}: switch_port is already set to {self.switch_port_binding}")
        self.switch_port_binding = switch_port
    
    def get_itf_binding_str(self):
        return f"{self.iface}={self.binded_iface}"
    
    def get_switch_port_binding_str(self):
        return f"{self.iface}={self.switch_port_binding}"
    
    def get_binded_interface(self):
        return self.binded_to_itf
    
    def get_binded_switch_port(self):
        return self.switch_port_binding
    
    @property
    def binded_iface(self):
        return self.binded_to_itf.iface


class HostInterface(GigabitInterfaceMgmt, InterfaceBinding):
    
    def __init__(self, iface):
        assert iface in netifaces.interfaces(), f"interface {iface} does not exist"
        super().__init__(iface)
    
    @classmethod
    def all_interfaces(cls):
        return [cls(iface=x) for x in netifaces.interfaces()]
    
    def set_autoneg(self, autoneg, speed=None, fec=None):
        ret_autoneg = super().set_autoneg(autoneg, speed, fec)
        # we need to reset FEC mode on ConnectX-5 when autoneg is on
        if ret_autoneg and autoneg == 'on':
            self.set_fec('auto')
        return ret_autoneg


class MPPAInterface(GigabitInterfaceMgmt, InterfaceBinding):
    ENMPPA0 = "enmppa0"
    ENMPPA4 = "enmppa4"

    def __init__(self, iface, remote=None):
        assert iface in [self.ENMPPA0, self.ENMPPA4], f"Wrong interface, must be {self.ENMPPA0} or {self.ENMPPA4}"
        super().__init__(iface)
        self.sysfs = None
        if remote:
            self.set_remote(remote)
        self.unprivileged_user = '' # we are root on MPPA
        self._mac_address = None
    
    def set_remote(self, remote):
        self.run_cmd_callback = remote.run_cmd
        self.sysfs = MppaSysfs(remote, f"{{net}}/{self.iface}")
    
    def set_autoneg(self, autoneg, speed=None, fec=None):
        # we don't want to set autoneg on eth0 (not supported by driver)
        if not self.is_1G_interface():
            return super().set_autoneg(autoneg, speed, fec)
    
    @classmethod
    def all_interfaces(cls, **kwargs):
        return [cls(iface=cls.ENMPPA0, **kwargs), cls(iface=cls.ENMPPA4, **kwargs)]
    
    @property
    def mac_address(self):
        if self._mac_address is None:
            self._mac_address = self.sysfs.address
        return self._mac_address


class HostInterface_1G(InterfaceMgmt, InterfaceBinding):
    """Class for managing 1G interface on host"""
    pass


class MPPAInterface_1G(InterfaceMgmt, InterfaceBinding):
    """Class for managing 1G interface on MPPA"""
    
    def __init__(self, remote=None):
        super().__init__(iface='eth0')
        self.unprivileged_user = '' # we are root on MPPA
    
    def set_remote(self, remote):
        # search 1G interface name
        _, out, _ = remote.run_cmd('ip link | grep ": <" | grep "eth"')
        self.iface = "eth" + re.search(r": eth([0-9]?): ", out).group(1)
        logger.info(f"Changed eth0 interface name to {self.iface}")
        self.run_cmd_callback = remote.run_cmd
    
    def set_autoneg(self, autoneg, speed=None, fec=None):
        # not supported on mppa, we do nothing except activating the interface
        self.up()

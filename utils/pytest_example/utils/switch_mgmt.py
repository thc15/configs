
import logging
import re
import time

from utils.parsers import MicrotikMonitorParser, MicrotikSystemParser, MellanoxShowItfParser, \
                          CiscoShowItfParser, MellanoxVersionParser, CiscoVersionParser
from utils.ssh import SSHClient, SSHClientTTY


class SwitchPortMgmt:
    _cmd_autoneg = {}
    _fec_enc = {}

    def __init__(self, port, switch):
        self.port = port
        self.selected = False
        self.run_cmd = switch.run_cmd
        self.logger = switch.logger
        self.switch_version = switch.switch_version

    def __enter__(self):
        self.select_cmd()
        self.disable()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        if exc_type is not None:
            self.logger.error(f"An exception occured while configuring port {self.port}")
            self.logger.error(f"type: {exc_type}   value: {exc_value}")
            self.logger.error(traceback)
        self.enable()
        self.exit_cmd()
        self.logger.info("Waiting 10 secs for changes to take effect...")
        time.sleep(10)
        self.get_config() # show config in logs

    def enable(self):
        not_selected = not self.selected
        if not_selected:
            self.select_cmd()
        self.run_cmd(f"no shutdown")
        if not_selected:
            self.exit_cmd()

    def disable(self):
        not_selected = not self.selected
        if not_selected:
            self.select_cmd()
        self.run_cmd(f"shutdown")
        if not_selected:
            self.exit_cmd()

    def select_cmd(self):
        self.run_cmd(f'interface ethernet {self.port}')
        self.selected = True

    def exit_cmd(self):
        self.run_cmd('exit')
        self.selected = False

    def get_config(self):
        raise NotImplemented()

    def set_autoneg(self, autoneg='on', speed=None):
        self.run_cmd(self._autoneg_cmd[self.switch_version][autoneg].format(speed=speed))

    def set_fec(self, fec='auto'):
        assert fec in self._fec_enc, f'FEC encoding {fec} not supported by switch'
        self.run_cmd(self._fec_enc[fec])

    def link_is_up(self):
        raise NotImplemented()


class SwitchMgmt:
    _port_cls = SwitchPortMgmt
    _switch_vendor = ''
    _prompt_regex = ''

    def __init__(self, mgmt_ip, mgmt_login, mgmt_password, mgmt_port=22, switch_version=None):
        self.mgmt_ip = mgmt_ip
        self.mgmt_port = mgmt_port
        self.mgmt_login = mgmt_login
        self.mgmt_password = mgmt_password
        self.switch_version = switch_version
        self.logger = logging.getLogger(f"switch {mgmt_ip}")

    def connect(self):
        self.ssh_client = SSHClientTTY(self.mgmt_ip, username=self.mgmt_login,
                                       password=self.mgmt_password, port=self.mgmt_port)
        self.logger.info(f"Opening SSH connection to {self.mgmt_ip}:{self.mgmt_port}")
        self.ssh_client.set_prompt_regex(self._prompt_regex)
        return self.ssh_client.connect()

    def disconnect(self):
        self.logger.info(f"Disconnection {self.mgmt_ip}:{self.mgmt_port}")
        self.ssh_client.close()

    def run_cmd(self, cmd, **kwargs):
        self.logger.info(f"CMD: {cmd}")
        out = self.ssh_client.run_cmd(cmd, **kwargs)
        self.logger.info(f"CMD output:")
        if out != '':
            for line in out.split('\n'):
                self.logger.info(line)
        return out

    def get_all_transceivers(self):
        raise NotImplemented()

    def configure_link(self, port, autoneg='on', speed=None, fec='auto'):
        if fec is None:
            fec = 'auto'
        set_an, set_fec = True, True
        cur_an, cur_speed, cur_fec = self.current_autoneg_fec(port)
        if autoneg == cur_an == 'on' or (autoneg, speed) == (cur_an, cur_speed):
            self.logger.info(f"No need to configure autoneg and speed on port {port}. Skipping it")
            set_an = False
        if fec == cur_fec:
            self.logger.info(f"No need to configure fec on port {port}. Skipping it")
            set_fec = False

        if set_an or set_fec:
            with self._port_cls(port, self) as port:
                if set_an:
                    port.set_autoneg(autoneg, speed)
                if set_fec:
                    port.set_fec(fec)

    def get_switch_vendor_version(self):
        return self._switch_vendor, self.switch_version

    def hw_version(self):
        raise NotImplemented()

    def get_port(self, port):
        return self._port_cls(port, self)

    def monitor_port(self, port):
        return self.get_port(port).get_config()

    def current_autoneg_fec(self, port):
        raise NotImplemented()


class MellanoxSwitchPortMgmt(SwitchPortMgmt):
    _autoneg_cmd = {
        '3.6': { 'on': 'no speed',   'off': 'speed {speed} no-autoneg' },
        '3.9': { 'on': 'speed auto', 'off': 'speed {speed}'            }
    }
    _fec_enc = {
        'auto': 'no fec-override',
        'rs': 'fec-override rs-fec',
        'off': 'fec-override no-fec',
        'baser': 'fec-override fc-fec'
    }

    def get_config(self):
        out = self.run_cmd(f'show interface ethernet {self.port}')
        config = {}
        for k,v in re.findall(r'([\w\s-]+):(.+)\n', out):
            config[k.strip()] = v.strip()
        return config

    def link_is_up(self):
        conf = self.get_config()
        return conf['Operational state'] == 'Up'


class MellanoxSwitchMgmt(SwitchMgmt):
    _port_cls = MellanoxSwitchPortMgmt
    _switch_vendor = 'mellanox'
    _prompt_regex = r'[\w-]+\s\[standalone: master\]\s(?:\(.+\)\s)?(?:>|#)\s$'

    def connect(self):
        if super().connect():
            self.ssh_client.run_cmd('enable')
            self.ssh_client.run_cmd('configure terminal')
            return True
        return False

    def get_all_transceivers(self):
        out= self.run_cmd("show interface ethernet transceiver")
        cable_port = {}
        for x in out.split('Port ')[1:]:
            if 'Cable is not present.' in x:
                continue
            parser = MellanoxShowItfParser(x)
            port, cable_sn = parser.port(), parser.vendor_sn()
            cable_port[cable_sn] = f"1/{port}"
        return cable_port

    def current_autoneg_fec(self, port):
        conf = self.monitor_port(port)
        an = 'on' if conf['Auto-negotiation'] == 'Enabled' else 'off'
        speed = conf['Actual speed']
        if speed == 'Unknown':
            speed = None
        else:
            speed = speed.replace('Gbps', '000')
            speed = speed.replace('G', '000')
            speed = int(speed.replace(' ', ''))
        fec_dec = {'auto': 'auto', 'rs-fec': 'rs', 'fc-fec': 'baser', 'no-fec': 'off'}
        return an, speed, fec_dec[conf['Fec']]

    def hw_version(self):
        out = self.run_cmd('show inventory')
        return MellanoxVersionParser(out).hw_version()


class CiscoSwitchPortMgmt(SwitchPortMgmt):
    _autoneg_cmd = {
        '9.3': { 'on': 'speed auto ; negotiate auto', 'off': 'speed {speed} ; no negotiate auto' }
    }
    _fec_enc = {
        'auto': 'fec auto',
        'rs': 'fec rs-fec',
        'off': 'fec off',
        'baser': 'fec fc-fec'
    }

    def get_config(self):
       return self.run_cmd(f'show interface ethernet {self.port}')

    def link_is_up(self):
        conf = self.get_config()
        status = re.search(r"Ethernet[0-9]/(?:[0-9]+)\sis\s(up|down)", conf)
        return  status.group(1) == 'up' if status else False


class CiscoSwitchMgmt(SwitchMgmt):
    _port_cls = CiscoSwitchPortMgmt
    _switch_vendor = 'cisco'
    _prompt_regex = r'[\w-]+(?:\([\w-]+\))?#\s'

    def connect(self):
        if super().connect():
            self.ssh_client.run_cmd('configure terminal')
            return True
        return False

    def get_all_transceivers(self):
        out = self.run_cmd('show interface transceiver')
        cable_port = {}
        for x in out.split('Ethernet')[1:]:
            if 'transceiver is not present' in x:
                continue
            parser = CiscoShowItfParser(x)
            port, cable_sn = parser.port(), parser.vendor_sn()
            cable_port[cable_sn] = f"1/{port}"
        return cable_port

    def current_autoneg_fec(self, port):
        out = self.monitor_port(port)
        an = re.search(r'Auto-Negotiation is turned (on|off)', out).group(1)
        speed = None
        if an == 'off':
            speed = re.search(r'-duplex, ([0-9]+) Gb/s,', out).group(1)
            speed = int(speed) * 1000
        fec_dec = {'auto': 'auto', 'rs-fec': 'rs', 'fc-fec': 'baser', 'no-fec': 'off', 'off': 'off'}
        fec = re.search(r'FEC mode is ([\w-]+)', out).group(1).lower()
        return an, speed, fec_dec[fec]

    def hw_version(self):
        out = self.run_cmd('show version')
        return CiscoVersionParser(out).hw_version()


class MicrotikSwitchPortMgmt(SwitchPortMgmt):
    _fec_enc = {
        'auto': 'auto',
        'rs': 'fec91',
        'off': 'off',
        'baser': 'fec74'
    }

    def get_config(self):
        _, out, _ = self.run_cmd(f'/interface ethernet monitor {self.port} once without-paging', expect_ret=0)
        config = {}
        for k,v in re.findall(r'([\w\s-]+):(.+)\n', out):
            config[k.strip()] = v.strip()
        return config

    def select_cmd(self):
        pass

    def enable(self):
        cmd = f'/interface ethernet enable {self.port}'
        self.run_cmd(cmd, expect_ret=0)

    def disable(self):
        cmd = f'/interface ethernet disable {self.port}'
        self.run_cmd(cmd, expect_ret=0)

    def set_autoneg(self, autoneg='on', speed=None):
        autoneg_cmd = 'yes' if autoneg == 'on' else 'no'
        if autoneg == 'on':
            speed_cmd = ""
        else:
            speed_cmd = "speed=" + f"{int(speed / 1000)}Gbps" if speed >= 1000 else f"{speed}Mbps"

        cmd = f'/interface ethernet set auto-negotiation={autoneg_cmd} {speed_cmd} {self.port}'
        self.run_cmd(cmd, expect_ret=0)

    def set_fec(self, encoding='auto'):
        self.run_cmd(f'/interface ethernet set fec-mode={self._fec_enc[encoding]} {self.port}')

    def link_is_up(self):
        conf = self.get_config()
        return conf['status'] == 'link-ok'


class MicrotikSwitchMgmt(SwitchMgmt):
    """ Management class for switch 10G MicroTik CRS306-1G"""

    _port_cls = MicrotikSwitchPortMgmt
    _switch_vendor = 'microtik'

    def connect(self):
        self.ssh_client = SSHClient(self.mgmt_ip, username=self.mgmt_login, password=
                                    self.mgmt_password, port=self.mgmt_port)
        self.logger.info(f"Opening SSH connection to {self.mgmt_ip}:{self.mgmt_port}")
        return self.ssh_client.connect()

    def run_cmd(self, cmd, **kwargs):
        return self.ssh_client.run_cmd(cmd, **kwargs)

    def current_autoneg_fec(self, port):
        conf = self.monitor_port(port)
        an = 'on' if conf['auto-negotiation'] == 'enabled' else 'off'
        if 'rate' in conf:
            speed = conf['rate'].replace('Gbps', '000')
            speed = int(speed)
        else:
            speed = None
        # fec setting unvailable
        return an, speed, None

    def get_all_transceivers(self):
        cmd = '/interface ethernet; :foreach i in=([find default-name~"sfp"]) do={monitor [get $i default-name] once without-paging}'
        _, out, _ = self.run_cmd(cmd, expect_ret=0)
        cable_port = {}
        for x in out.split('name: sfp-sfpplus')[1:]:
            sn = MicrotikMonitorParser(x).vendor_sn()
            if sn:
                cable_port[sn] = f"sfp-sfpplus{x[0]}"
        return cable_port

    def hw_version(self):
        cmd = "/system package print without-paging"
        _, out, _ = self.run_cmd(cmd, expect_ret=0)
        ver = MicrotikSystemParser(out).version_of('routeros-arm')
        return ver if ver else "unknown"


def switch_mgmt(switch_vendor, switch_conf):
    vendor, version = switch_vendor.split('-')
    for cl in [MellanoxSwitchMgmt, CiscoSwitchMgmt, MicrotikSwitchMgmt]:
        if cl._switch_vendor == vendor:
            switch = cl(mgmt_ip=switch_conf.get('hostname'), mgmt_login=switch_conf.get('login'),
                        mgmt_password=switch_conf.get('password'), mgmt_port=switch_conf.get('port'),
                        switch_version=version)
            assert switch.connect(), f"Connection to switch {switch_vendor} failed"
            return switch
    assert False, "switch vendor not found"

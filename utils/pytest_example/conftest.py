import copy
import logging
import pytest
import subprocess
import time
import threading
import os
import re
import pathlib
import yaml
import sqlalchemy
import csv
from datetime import datetime
from sqlalchemy.orm.session import sessionmaker
from sqlalchemy_utils.functions.database import create_database, database_exists
from collections import OrderedDict

import utils.utils as ut
from utils.ssh import SSHClient
from utils.minicom import Minicom
from utils.jtag import JTAGLink
from utils.switch_mgmt import switch_mgmt
from utils.acceptance_db import K200, AcceptanceConfig, AcceptanceRun, AcceptanceTest, Base, EthernetCable, LinkPartner, TestCaseResult, TestScenarioParam
from utils.eom import EOM
from utils.interface_mgmt import HostInterface, HostInterface_1G, MPPAInterface, MPPAInterface_1G


DIR = pathlib.Path(__file__).parent.absolute()

# all-tests.csv file (pytest-csv plugin)
PYTEST_CSV_COLUMNS  = "id,parameters_as_columns,doc,status,duration_formatted,message"
PYTEST_CSV_DELIMITER = ','

JTAG_COMMAND        = "kvx-jtag-runner --exec-file Cluster0:{vmlinux} --progress"

LINUX_WELCOME_MSG   = "Welcome to Buildroot"
TIMEOUT_LINUX_LOAD_BOOT  = 600 # seconds

MPPA_SSH_HOSTNAME = "mppalinux.local"
MPPA_SSH_LOGIN    = "root"
MPPA_SSH_PASSWORD = "kalray"

STR_TIME_FORMAT = "%Y-%m-%d_%H-%M-%S"

# autoneg: on/off, fec: off/baser/rs, config_first: host/mppa
DEFAULT_TP_CONFIG_FIRST = 'host'
DEFAULT_TEST_PARAMETERS = [
    {'autoneg': 'on',  'speed': {'host': 100000, 'mppa': 100000}, 'fec': 'auto', 'config_first': 'host'},
    {'autoneg': 'on',  'speed': {'host': 100000, 'mppa': 100000}, 'fec': 'auto', 'config_first': 'mppa'},
    {'autoneg': 'off', 'speed': {'host': 10000, 'mppa': 10000}, 'fec': 'off', 'config_first': 'host'},
#    {'autoneg': 'off', 'speed': {'host': 10000, 'mppa': 10000}, 'fec': 'baser', 'config_first': 'host'},
#    {'autoneg': 'off', 'speed': {'host': 40000, 'mppa': 40000}, 'fec': 'baser', 'config_first': 'host'},
    {'autoneg': 'off', 'speed': {'host': 100000, 'mppa': 100000}, 'fec': 'rs', 'config_first': 'host'},
]

HOST_MPPA_IP_BINDINGS = {
    'enmppa0': {
        'host': '192.168.253.10/24',
        'mppa': '192.168.253.1/24'
    },
    'enmppa4': {
        'host': '192.168.244.10/24',
        'mppa': '192.168.244.1/24'
    },
    'eth0': {
        'host': '192.168.250.10/24',
        'mppa': '192.168.250.1/24'
    }
}

DEFAULT_CONF = {
    "version": 0.1,
    "vmlinux": None,
    "serial": None,
    "dtb": None,
    "serial-baudrate": 115200,
    "jtag-stm": None,
    "acceptance-db": None,
    "report-path": None,
    "iterations": 1,
    "switch": None,
    "release": None,
    "switch-mgmt": [],
    "test-parameters": DEFAULT_TEST_PARAMETERS,
    "ip-bindings": HOST_MPPA_IP_BINDINGS,
    "swith-port-bindings": [],
    "rtm-eom": False,
    "remote-host": None,
    "debug-mode": False,
    "no-ssh": False,
    "loopback": False,
    "kvx-net-traces": False,
    "no-interaction": False,
    "email": False,
    "cable-sn-map": {}
}

# parameters that can be overwritten by command-line arguments
ARGUMENT_OVERWRITE = ['vmlinux', 'serial', 'serial-baudrate' ,'iterations', 'release', 'acceptance-db', 'report-path', 'jtag-stm',
                      'switch', 'rtm-eom', 'remote-host', 'debug-mode', 'no-ssh', 'loopback', 'kvx-net-traces', 'no-interaction',
                      'email', 'dtb']

conftest_logger = logging.getLogger("conftest")


@pytest.hookimpl(tryfirst=True)
def pytest_keyboard_interrupt(excinfo):
    conftest_logger.warning('Keyboard interrupt received !')
    if hasattr(pytest, 'jtag') and not pytest.conf['debug-mode']:
        pytest.jtag.interrupt()
    if hasattr(pytest, 'minicom'):
        pytest.minicom.interrupt()
    pytest.keyboard_interrupt = True


def pytest_addoption(parser):
    parser.addoption("--serial", action='store', type=str, help="Path to MPPA TTY")
    parser.addoption("--serial-baudrate", action='store', type=int, help="baudrate to apply on TTY")
    parser.addoption('--vmlinux', action='store', required=False, type=str, help='Path to vmlinux')
    parser.addoption('--dtb', action='store', required=False, type=str, help='Path to the device tree')
    parser.addoption('--iterations', action='store', type=int, help='Number of repetition of each test')
    parser.addoption('--report-path', action='store', type=str, help='Path where to store test results and logs')
    parser.addoption('--config', action='store', type=str, default='config.yml', help='Path to the configuration file config.yml')
    parser.addoption('--enmppa0', action='store', type=str, metavar='host_to_enmppa0',
                     help='If set, test enmppa0. Argument must specify the devname of the interface from host to enmppa0')
    parser.addoption('--enmppa4', action='store', type=str, metavar='host_to_enmppa4',
                     help='If set, test enmppa4. Argument must specify the devname of the interface from host to enmppa4')
    parser.addoption('--eth0', action='store', type=str, metavar='host_to_eth0',
                     help='If set, test the 1G interface. Argument must specify the devname of the interface from host to eth0')
    parser.addoption('--enmppa0-port', action='store', type=str, help='Port number of the switch connected to enmppa0. E.g: 1/12')
    parser.addoption('--enmppa4-port', action='store', type=str, help='Port number of the switch connected to enmppa4. E.g: 1/12')
    parser.addoption('--host-port', action='store', type=str, help='Port number of the switch connected to the host interface.')
    parser.addoption('--skip-itf-search', action='store_true', help='Skip the initial search of cable and interface bindings.')
    parser.addoption('--acceptance-db', action='store', type=str, help='Path to the Sqlite database')
    parser.addoption('--jtag-stm', dest='jtag_stm', action='store', help='Set JTAG connection')
    parser.addoption('--kvx-net-traces', dest='kvx_net_traces', action='store_true', help='Enable kvx net traces')
    parser.addoption('--email', action='store_true', help='Generate email containing results (continuous integration)')
    parser.addoption('--switch', action='store', type=str, choices=['mellanox-3.6', 'mellanox-3.9', 'cisco-9.3', 'microtik-1'],
                     help='Test using a switch as link partner, supported vendors are mellanox and cisco')
    parser.addoption('--release', action='store', type=str, help='Linux release. e.g. 4.6')
    parser.addoption('--rtm-eom', action='store_true', help='Always generate the eye diagram no matter whether the test case passes or fails.')
    parser.addoption('--remote-host', action='store', help="SSH credentials in the form <user>@<host>:<password> if the host is remote")
    parser.addoption('--debug-mode', action='store_true', help="Start in Debug mode. Linux is assumed to be already running on MPPA.")
    parser.addoption('--no-interaction', action='store_true', help="Skip all tests that need user interaction.")
    parser.addoption('--loopback', action='store_true', help='Start in lookback mode.')
    parser.addoption('--no-ssh', action='store_true', help='Send commands through serial console instead of SSH')

def keep_sudo_credit():
    while(True):
        try:
            subprocess.check_output(["sudo", "-n", "true"])
        except:
            subprocess.run(["sudo", "-v"])
        time.sleep(60)


def pytest_sessionstart(session):
    pytest.switch = None
    if pytest.conf['switch']:
        # switch instance
        switch_conf = [x for x in pytest.conf['switch-mgmt'] if x['vendor'] == pytest.conf['switch']]
        switch_conf = switch_conf[0] if len(switch_conf) == 1 else {}
        pytest.switch = switch_mgmt(pytest.conf['switch'], switch_conf)

    # check host ssh argument
    if pytest.conf['remote-host'] and not isinstance(pytest.conf['remote-host'], dict):
        r = re.compile(r'([a-zA-Z0-9_]+)@([a-zA-Z0-9_\-\.]+):(.+)').match(pytest.conf['remote-host'])
        assert bool(r), "remote host: wrong format"
        u, h, p = r.groups()
        pytest.conf['remote-host'] = {'user': u, 'host': h, 'password': p}

    sudo_thread = threading.Thread(target=keep_sudo_credit)
    sudo_thread.daemon = True
    sudo_thread.start()

    if not session.config.option.skip_itf_search and not pytest.interfaces:
        lp_type = 'switch' if pytest.switch else 'nic'
        find_itf_binding(lp_type)


@pytest.hookimpl(tryfirst=True)
def pytest_configure(config):
    # open configuration file
    pytest.conf = DEFAULT_CONF
    if os.path.isfile(config.option.config):
        yml_conf = {}
        with open(config.option.config, 'r') as f:
            yml_conf = yaml.load(f, yaml.Loader)
        conftest_logger.info(f"Configuration file was loaded successfully: {config.option.config}")
        pytest.conf.update(yml_conf)

    # override default conf and yaml conf with arguments if provided
    for arg in ARGUMENT_OVERWRITE:
        val = getattr(config.option, arg.replace('-', '_'))
        if val:
            pytest.conf[arg] = val

    # other global variables
    pytest.interfaces = [] # list of host interfaces
    pytest.start_time = datetime.now()
    pytest.keyboard_interrupt = False

    # HTML report path
    if pytest.conf['report-path'] is None:
        pytest.conf['report-path'] = os.path.join(f"{DIR}/reports", pytest.start_time.strftime(STR_TIME_FORMAT))
    else:
        pytest.conf['report-path'] = os.path.join(pytest.conf['report-path'], pytest.start_time.strftime(STR_TIME_FORMAT))
    if not os.path.isdir(pytest.conf['report-path']):
        os.makedirs(pytest.conf['report-path'])
    conftest_logger.info(f"Report path is set to {pytest.conf['report-path']}")

    if pytest.conf['loopback']:
        itf0 = MPPAInterface(iface='enmppa0')
        itf4 = MPPAInterface(iface='enmppa4')
        itf0.bind_to_interface(itf4)
        pytest.interfaces.extend([itf0, itf4])
    else:
        # make sure all switch arguments are present
        if pytest.conf['switch']:
            switch_args = ['enmppa0', 'enmppa4', 'enmppa0_port', 'enmppa4_port', 'host_port']
            check_switch_args = lambda i: [getattr(config.option, x) is not None for x in switch_args if i not in x]
            if any(check_switch_args('this_is_not_in_any_arg')):
                assert all(check_switch_args('0')) or all(check_switch_args('4')), \
                        "An argument is missing: --enmppa{0,4}, --enmppa{0,4}-port and --host-port"

                # check that switch login, password etc. are defined in the yml config file
                assert pytest.conf['switch-mgmt'], "Missing switch-mgmt in config file"
                sw = [x for x in pytest.conf['switch-mgmt'] if x['vendor'] == pytest.conf['switch']]
                assert len(sw) == 1, f"Missing switch {pytest.conf['switch']} in config file"

        # look for --enmppa0 and --enmppa4 and make corresponding bindings
        # idem for switch ports
        for opt in ['enmppa0', 'enmppa4']:
            val = getattr(config.option, opt)
            if val:
                host_itf = HostInterface(iface=val)
                if config.option.host_port:
                    host_itf.bind_to_switch_port(config.option.host_port)
                mppa_itf = MPPAInterface(iface=opt)
                port = getattr(config.option, f'{opt}_port')
                if port:
                    mppa_itf.bind_to_switch_port(port)
                host_itf.bind_to_interface(mppa_itf)
                pytest.interfaces.append(mppa_itf)

        # look for --eth0 argument
        if config.option.eth0:
            host_itf = HostInterface_1G(iface=config.option.eth0)
            mppa_itf = MPPAInterface_1G()
            mppa_itf.bind_to_interface(host_itf)
            pytest.interfaces.append(mppa_itf)

    # report, log file and csv plugins
    config.option.report.append(os.path.join(pytest.conf['report-path'], "report.html"))
    config.option.template.append("html1/index.html")
    config.option.log_file = os.path.join(pytest.conf['report-path'], "all-tests.log")
    config.option.csv_path = os.path.join(pytest.conf['report-path'], "all-tests.csv")
    config.option.csv_columns = PYTEST_CSV_COLUMNS.split(',')
    config.option.csv_delimiter = PYTEST_CSV_DELIMITER


@pytest.fixture(autouse=True, scope='session')
def add_metadata(request):
    try:
        config, sn, board, rev = K200.kvx_board_diag()
        request.config._metadata["k200 type"] = f"{board}_{rev}"
        request.config._metadata["k200 SN"] = sn
        request.config._metadata["k200 config"] = config
    except K200.NoKvxEnvironnement:
        # no kvx environment, we cannot get board infos
        pass
    request.config._metadata["Interface bindings"] = " ".join([x.get_itf_binding_str() for x in pytest.interfaces])
    request.config._metadata["Switch port bindings"] = " ".join([x.get_switch_port_binding_str() for x in pytest.interfaces])
    pytest.html_report_metadata = request.config._metadata


def pytest_make_parametrize_id(config, val, argname):
    """ pytest hook: generate string with parameters.
        E.g: param1=hello-param2=world
    """
    if isinstance(val, dict):
        params = []
        for k,v in val.items():
            if isinstance(v, dict):
                params.extend([f"{k}_{k2}:{str(v2)}" for k2,v2 in v.items()])
            else:
                params.append(f"{k}:{str(v)}")
        return '-'.join(params)
    else:
        return '{}:{}'.format(argname, str(val))


def pytest_runtest_setup(item):
    # skip the test cases that don't have the loopback marker if we are in loopback mode
    if pytest.conf['loopback']:
        if not ('loopback' in item.keywords or 'loopback_only' in item.keywords):
            pytest.skip("add loopback marker if you want to run this test in loopback mode")
    else:
        if 'loopback_only' in item.keywords:
            pytest.skip("loopback mode only")


def new_jtag_instance():
    jtag_cmd = JTAG_COMMAND.format(vmlinux=pytest.conf['vmlinux'])
    if pytest.conf['jtag-stm']:
        jtag_cmd += f" --jtag-connection={pytest.conf['jtag-stm']}"
    if pytest.conf['dtb']:
        jtag_cmd += f" --dtb={pytest.conf['dtb']}"
    return JTAGLink(jtag_cmd)


def new_ssh_instance():
    for _ in range(int(TIMEOUT_LINUX_LOAD_BOOT / 2)):
        ret, _, _ = ut.run_cmd(f"ping -c1 -W2 {MPPA_SSH_HOSTNAME}", disable_logging=True)
        if ret == 0:
            break

    assert ret == 0, "Could not start Linux on MPPA. Please check --vmlinux argument"
    ssh = SSHClient(hostname=MPPA_SSH_HOSTNAME, username=MPPA_SSH_LOGIN, password=MPPA_SSH_PASSWORD)
    if not ssh.connect():
        pytest.fail(msg=f'Unable to make connection to {MPPA_SSH_HOSTNAME}')

    return ssh


def find_itf_binding(lp_type):
    """ find the interface binding between host and mppa
    """
    jtag = None
    ssh = None
    cable_itf_map = {'host': {}, 'mppa': {}}

    try:
        jtag = new_jtag_instance()
        if not pytest.conf['debug-mode']:
            jtag.start()
            time.sleep(20)

        ssh = new_ssh_instance()

        # mapping mppa itf -> cable SN
        cable_itf_map['mppa'] = MPPAInterface.get_itf_cable_map(remote=ssh)
    finally:
        if ssh is not None:
            ssh.close()
        if jtag is not None and not pytest.conf['debug-mode']:
            jtag.interrupt()

    # mapping host itf -> cable SN
    cable_itf_map['host'] = HostInterface.get_itf_cable_map()

    # mapping cable SN -> switch port
    if lp_type == 'switch':
        cable_port = pytest.switch.get_all_transceivers()

    # cable SN mapping from config file + inverted map
    conf_cable_sn = pytest.conf['cable-sn-map']
    if conf_cable_sn:
        conf_cable_sn.update(dict((v, k) for k, v in conf_cable_sn.items()))

    # check for loopback mode
    if len(cable_itf_map['mppa']) == 2 and cable_itf_map['mppa'][0][1] == cable_itf_map['mppa'][1][1]:
        cable_itf_map['mppa'][0][0].bind_to_interface(cable_itf_map['mppa'][1][0])
        pytest.interfaces.extend([cable_itf_map['mppa'][x][0] for x in range(2)])
        pytest.conf['loopback'] = True
        conftest_logger.warning(f"Loopback detected on MPPA | Cable SN: {cable_itf_map['mppa'][0][1]}")
        return

    # compare cable SN of mppa and host
    for mppa_itf, mppa_cable_sn in cable_itf_map['mppa'].copy():
        to_find = set([mppa_cable_sn])
        if mppa_cable_sn in conf_cable_sn:
            to_find.add(conf_cable_sn[mppa_cable_sn])
        if lp_type == 'nic':
            host_itf = [x for x,y in cable_itf_map['host'] if y in to_find]
            if len(host_itf) == 1:
                mppa_itf.bind_to_interface(host_itf[0])
                pytest.interfaces.append(mppa_itf)
                conftest_logger.warning(f"{mppa_itf} --> NIC itf {host_itf[0]} | cable SN: {mppa_cable_sn}")
                # useful to autodetect later cable with two != SN
                cable_itf_map['mppa'] = [x for x in cable_itf_map['mppa'] if x[0] is not mppa_itf]
                cable_itf_map['host'] = [x for x in cable_itf_map['host'] if x[0] is not host_itf[0]]
        elif lp_type == 'switch':
            port = [y for x,y in cable_port.items() if x in to_find]
            if len(port) == 1:
                mppa_itf.bind_to_switch_port(port[0])
                pytest.interfaces.append(mppa_itf)
                conftest_logger.warning(f"{mppa_itf} --> switch port {port[0]} | cable SN: {mppa_cable_sn}")

    if lp_type == 'switch':
        # find the interface on host that is connected to the switch
        found = False
        for host_itf, host_cable_sn in cable_itf_map['host']:
            to_find = set([host_cable_sn])
            if host_cable_sn in conf_cable_sn:
                to_find.add(conf_cable_sn[host_cable_sn])
            port = [y for x,y in cable_port.items() if x in to_find]
            if len(port) == 1:
                for mppa_itf in pytest.interfaces:
                    # binding the same instance of HostInterface to multiple MPPAInterfaces can cause problems, that's why we copy the object
                    host_itf_cp = copy.copy(host_itf)
                    host_itf_cp.bind_to_switch_port(port[0])
                    mppa_itf.bind_to_interface(host_itf_cp)
                conftest_logger.warning(f"NIC itf {host_itf} --> switch port {port[0]} | cable SN: {host_cable_sn}")
                found = True
                break
        assert found, "No cable was found between host and switch. Use --enmppa{0,4}-port if there is actually a cable"

    if lp_type == 'nic' and len(cable_itf_map['host']) == len(cable_itf_map['mppa']) == 1:
        # if there is only 1 cable left plugged on host and SNs do not match, we can safely suppose it's the same cable
        cable_itf_map['mppa'][0][0].bind_to_interface(cable_itf_map['host'][0][0])
        pytest.interfaces.append(cable_itf_map['mppa'][0][0])
        conftest_logger.warning(f"{cable_itf_map['mppa'][0][1]} --> NIC itf {cable_itf_map['host'][0][1]} | Serial numbers do not match but we can guess it is the same cable")


def pytest_generate_tests(metafunc):
    if pytest.conf['iterations'] > 1:
        metafunc.parametrize("iter", range(1, pytest.conf['iterations'] + 1), indirect=True)
    if pytest.conf['test-parameters']:
        metafunc.parametrize("conf", pytest.conf['test-parameters'], indirect=True)
    if pytest.interfaces:
        metafunc.parametrize("itf", pytest.interfaces, indirect=True)


def pytest_sessionfinish(session, exitstatus):
    if hasattr(pytest, 'jtag') and not pytest.jtag.interrupt_jtag and not pytest.conf['debug-mode']:
        pytest.jtag.interrupt()
    if hasattr(pytest, 'minicom') and not pytest.minicom.interrupt_com:
        pytest.minicom.interrupt()


@pytest.fixture(scope='session')
def acceptance_db():
    db_path = pytest.conf['acceptance-db']
    session = None

    if db_path:
        db = sqlalchemy.create_engine(f"sqlite:///{db_path}", echo=False, isolation_level='AUTOCOMMIT')
        if not database_exists(db.url):
            create_database(db.url)
            Base.metadata.create_all(db)
        assert os.access(db_path, os.W_OK), "Database is read-only, please check write permissions"
        Session = sessionmaker()
        Session.configure(bind=db)
        session = Session()

    yield session

    if session is not None:
        session.commit()
        session.close()


@pytest.fixture(scope='session')
def device():
    """ fixture: returns the serial path of device
    """
    # search for serial path if not provided
    if pytest.conf['serial'] is None:
        serial_paths = [x for x in os.listdir('/dev/kalray/') if '-MPPA-itf00' in x]
        assert len(serial_paths) != 0, "No device was found in /dev/kalray/"
        assert len(serial_paths) == 1, "More than 1 device was found in /dev/kalray/, please select one using --serial"
        pytest.conf['serial'] = f"/dev/kalray/{serial_paths[0]}"
        conftest_logger.info(f"The MPPA board serial path was automatically found: {pytest.conf['serial']}")
    yield pytest.conf['serial']


@pytest.fixture(scope='session', autouse=True)
def iter(request):
    """fixture: returns current iteration
    """
    return request.param if hasattr(request, 'param') else 1


# we must keep autouse=True because fixture is parametrize in pytest_generate_tests
@pytest.fixture(scope='module', autouse=True)
def conf(request, iter, minicom):
    """fixture: returns 'test-parameters' conf in the form of dict
    """
    conf = request.param if hasattr(request, 'param') else None

    # check vmlinux file exists
    assert os.path.isfile(pytest.conf['vmlinux']), "No vmlinux to load, please define --vmlinux"

    pytest.jtag = new_jtag_instance()
    if not pytest.conf['debug-mode']:
        pytest.jtag.start()
        pytest.jtag.wait_for_linux_boot(minicom, LINUX_WELCOME_MSG, TIMEOUT_LINUX_LOAD_BOOT)

    yield conf

    if not pytest.conf['debug-mode']:
        pytest.jtag.interrupt()


@pytest.fixture(scope="session", autouse=True)
def minicom(device):
    """ fixture: returns a minicom instance
    """
    minicom = Minicom(device, baudrate=pytest.conf['serial-baudrate'])
    pytest.minicom = minicom
    minicom.start()
    yield minicom
    minicom.interrupt()


def configure_host_itf(host_itf, conf):
    """host network devices must be configureed before MPPA Linux is started.
       We want to check the status of autoneg on/off at startup, not afterward."""
    if not pytest.conf['loopback'] and 'autoneg' in conf:
        if pytest.switch:
            autoneg, speed = 'on', None
        else:
            autoneg, speed = conf['autoneg'], conf['speed']['host'] if 'speed' in conf else None

        host_itf.up()
        host_itf.set_autoneg(autoneg, speed, conf.get('fec'))
        ip_itf = 'eth0' if host_itf.is_1G_interface() else host_itf.binded_iface
        host_itf.set_ip_address(pytest.conf['ip-bindings'][ip_itf]['host'])

        if pytest.switch:
            port = host_itf.get_binded_switch_port()
            pytest.switch.configure_link(port=port, autoneg=autoneg, speed=speed, fec=conf.get('fec'))
            assert pytest.switch.get_port(port).link_is_up(), "Link up failure between host and switch"
            conftest_logger.info(f"Link is up between {host_itf.iface} and switch port {port}")


# we must keep autouse=True because fixture is parametrize in pytest_generate_tests
@pytest.fixture(scope='class', autouse=True)
def itf(request, conf, remote):
    """fixture: configure autoneg, speed and fec on MPPA interfaces. At least 'autoneg' must be
       set in pytest.conf['test-parameters'], otherwise the interface will not be configured.
    """
    if not pytest.interfaces or conf is None:
        return None

    mppa_itf = request.param
    mppa_itf.set_remote(remote)

    if 'autoneg' in conf:
        # in which order we configure the link partners: mppa or host first
        lp_order = [conf['config_first'] if 'config_first' in conf else DEFAULT_TP_CONFIG_FIRST]
        lp_order.append('host' if lp_order[0] == 'mppa' else 'mppa')

        for order in lp_order:
            mppa_speed = conf['speed']['mppa'] if 'speed' in conf else None
            if order == 'mppa': # configure mppa interface
                assert mppa_itf.set_autoneg(autoneg=conf['autoneg'], speed=mppa_speed, fec=conf.get('fec')), \
                    f"Failed to configure ethernet itf on MPPA - autoneg={conf['autoneg']}  speed={mppa_speed}  fec={conf.get('fec')}"

                if pytest.switch:
                    pytest.switch.configure_link(port=mppa_itf.get_binded_switch_port(), autoneg=conf['autoneg'],
                                                 speed=mppa_speed, fec=conf.get('fec'))

                ip_itf = 'eth0' if mppa_itf.is_1G_interface() else mppa_itf.iface
                mppa_itf.set_ip_address(pytest.conf['ip-bindings'][ip_itf]['mppa'])

            elif order == 'host': # configure host interface
                if not pytest.conf['loopback']:
                    configure_host_itf(mppa_itf.get_binded_interface(), conf)
                else:
                    binded_itf = mppa_itf.get_binded_interface()
                    binded_itf.set_remote(remote)
                    binded_itf.set_autoneg(autoneg=conf['autoneg'], speed=mppa_speed, fec=conf.get('fec'))

    return mppa_itf


@pytest.fixture(scope="session")
def run_cmd():
    cred = pytest.conf['remote-host']

    if cred:
        ssh = SSHClient(hostname=cred['host'], username=cred['user'], password=cred['password'])
        if not ssh.connect():
            pytest.fail(msg=f"Unable to make connection to {cred['host']}")
        yield ssh.run_cmd
        ssh.close()
    else:
        yield ut.run_cmd


@pytest.fixture(scope="class")
def remote(request, conf, minicom):
    """ returns an ssh client instance
    """
    if pytest.conf['no-ssh']:
        ssh = minicom
        ssh.login_console(MPPA_SSH_LOGIN, MPPA_SSH_PASSWORD)
    else:
        ssh = SSHClient(hostname=MPPA_SSH_HOSTNAME, username=MPPA_SSH_LOGIN, password=MPPA_SSH_PASSWORD, timeout=120)
        if not ssh.connect():
            pytest.fail(msg=f'Unable to make connection to {MPPA_SSH_HOSTNAME}')
        ssh.isalive()

    if request.config.getoption('--kvx-net-traces'):
        # enables kvx net traces
        ret1, _, err = ssh.run_cmd("mount -t debugfs nodev /sys/kernel/debug")
        assert ret1 == 0 or 'Device or resource busy' in err
        ssh.run_cmd('echo "file drivers/net/ethernet/kalray/kvx-net.c +p" > /sys/kernel/debug/dynamic_debug/control', expect_ret=0)

    yield ssh

    if not pytest.conf['no-ssh']:
        conftest_logger.info("Clossing SSH connection")
        ssh.close()


@pytest.mark.hookwrapper
def pytest_runtest_makereport(item, call):
    pytest_html = item.config.pluginmanager.getplugin('html')
    outcome = yield
    report = outcome.get_result()
    extra = getattr(report, 'extra', [])
    if report.when == 'call':
        xfail = hasattr(report, 'wasxfail')
        if pytest.conf['rtm-eom'] or (report.skipped and xfail) or (report.failed and not xfail):
            # add image of eom to html report in case of failure
            if 'rtm_eom' in item.fixturenames:
                eom = item.funcargs['rtm_eom']
                img_b64 = eom.draw_eom().decode('ascii')
                img = pytest_html.extras.image(img_b64, mime_type='image/png', extension='png',
                                               name='Retimer Eye Diagram')
                img['format'] = 'image' # needed by the 'modern' template
                extra.append(img)
        report.extra = extra

        # separation between tests in logs and print verdict
        conftest_logger.info(f"VERDICT: {report.outcome}")
        conftest_logger.info("-" * 10 + f"  End of test {report.head_line}  " + "-" * 10)


@pytest.fixture(scope='function')
def rtm_eom(remote, itf):
    """ Generate a PNG of the eye diagram if test fails.
        This image is embedded in the HTML report.
    """
    eom = EOM(remote)
    yield eom


@pytest.fixture(scope='function')
def record_testcase_element(request):
    from _pytest.junitxml import xml_key
    from xml.etree.ElementTree import Element

    def append_tc_element(name, content):
        xml = request.config._store.get(xml_key, None)
        if xml is not None:
            node_reporter = xml.node_reporter(request.node.nodeid)
            el = Element(name)
            el.text = content
            node_reporter.append(el)

    return append_tc_element


@pytest.fixture(scope='function', autouse=True)
def set_junit_properties(request, record_testsuite_property, record_xml_attribute, record_testcase_element, run_cmd):
    if not any(['--junitxml=' in x for x in request.config.invocation_params.args]):
        return

    if not hasattr(pytest, "set_junit_properties_done"):
        record_testsuite_property("host.name", run_cmd('hostname')[1])
        record_testsuite_property("host.kernel.arch", run_cmd('uname -p')[1])
        record_testsuite_property("host.kernel.release", run_cmd('uname -r')[1])
        if os.getenv("INTEGRATION_BRANCH"):
            record_testsuite_property("branch", os.getenv("INTEGRATION_BRANCH"))
        if os.getenv("label"):
            record_testsuite_property("label", os.getenv("label"))
        if os.getenv("STEP_NAME"):
            record_testsuite_property("step", os.getenv("STEP_NAME"))
        if os.getenv("INFO_LABEL"):
            record_testsuite_property("info_label", os.getenv("INFO_LABEL"))
        if os.getenv("JOB_NAME"):
            record_testsuite_property("job", os.getenv("JOB_NAME"))
        record_testsuite_property("sha1", run_cmd('git rev-parse HEAD')[1])
        record_testsuite_property("date", run_cmd('git show -s --format=%ci')[1])
        if os.path.exists("/etc/kalray/connected_device_type"):
            with open("/etc/kalray/connected_device_type", 'r') as f:
                record_testsuite_property("machine_type", f.read().strip())
        elif os.getenv("label"):
            record_testsuite_property("machine_type", os.getenv("label"))
        pytest.set_junit_properties_done = True

    step_name = os.getenv("STEP_NAME")
    info_label = os.getenv("INFO_LABEL")
    test_id = request.node.nodeid.replace('/', '.').replace('::', '.').replace('.py', '')
    record_xml_attribute("classname", f"{step_name}.{info_label}.linux_valid.conf_mppa_debug.{test_id}")
    record_xml_attribute("cmd", f"pytest {request.node.nodeid}")
    record_xml_attribute("module", "linux_valid")
    record_xml_attribute("target", "conf_mppa_debug")
    record_testcase_element("type-test", "valid")


@pytest.fixture
def suspend_capture(pytestconfig):
    """ This fixture allows to get user input during the execution of a test.
    How to use it:
    with suspend_capture:
        i = input('name ?')
    """
    if pytest.conf['no-interaction']:
        pytest.skip("Test case needs user interaction")

    class suspend_guard:
        def __init__(self):
            self.capmanager = pytestconfig.pluginmanager.getplugin('capturemanager')
        def __enter__(self):
            self.capmanager.suspend_global_capture(in_=True)
        def __exit__(self, _1, _2, _3):
            self.capmanager.resume_global_capture()

    yield suspend_guard()


@pytest.fixture(scope='session')
def stats_counter(pytestconfig, device, acceptance_db, run_cmd, minicom):
    """ Keep track of user-defined counters during test execution and write the statistics to a CSV file
        + .email file + database at the end of the session. A 'counter' is composed of 2 counters: 'success'
        and 'total' (sum of success and failure).

        In your test case, call the fixture as follows to update a counter for a given set of test case
        parameters (conf) and mppa interface:
            stats_csv_email(conf, mppa_itf, counter_label, success)
        The counter is automatically created if it does not exist
    """
    stats = {}

    def increase_counter(conf, mppa_itf, counter_label, success=True):
        """
            conf: test parameters
            mppa_itf: mppa interface
            counter_label: name of the counter
            success: if True, increase the success counter of 1
        """
        conf_id = pytest.conf['test-parameters'].index(conf)
        stats.setdefault(conf_id, {})
        stats[conf_id].setdefault(mppa_itf, {})
        stats[conf_id][mppa_itf].setdefault(counter_label, {'success': 0, 'total': 0})
        if success:
            stats[conf_id][mppa_itf][counter_label]['success'] += 1
        stats[conf_id][mppa_itf][counter_label]['total'] += 1
    yield increase_counter

    if pytest.keyboard_interrupt:
        capmanager = pytestconfig.pluginmanager.getplugin('capturemanager')
        capmanager.suspend_global_capture(in_=True)
        ret = None
        while ret is None or ret not in ['y', 'n']:
            ret = input("Execution was interrupted with Ctrl+C. Do you want to save the results of this session? (y/n)")
        capmanager.resume_global_capture()
        if ret == 'n':
            conftest_logger.info("Execution interrupted. Results are not saved in database.")
            return

    # serialize the stats dictionnary to a list
    stats_ser = []
    el = OrderedDict()
    for conf_id, v1 in stats.items():
        for k,v in pytest.conf['test-parameters'][conf_id].items():
            el[k] = " ".join([f"{x}:{y}" for x,y in v.items()]) if isinstance(v, dict) else v
        for mppa_itf, v2 in v1.items():
            el['interface'] = mppa_itf
            el.update({k:f"{v['success']}/{v['total']}" for k,v in v2.items()})
            stats_ser.append(el)
            el = OrderedDict()

    if not stats_ser:
        return

    # write the stats to the CSV file
    csv_path = os.path.join(pytest.conf['report-path'], 'stats.csv')
    with open(csv_path, 'w') as f:
        f.write(f"Test results for {device}\n")
        headers = sorted(set().union(*stats_ser), key=lambda x: list(stats_ser[0].keys()).index(x) if x in stats_ser[0] else 100)
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        writer.writerows(stats_ser)

    # generate email
    if pytest.conf['email']:
        email_path = os.path.join(pytest.conf['report-path'], 'acceptance.email')
        template_path = os.path.join(DIR, 'acceptance/email_template.txt')
        with open(csv_path, 'r') as f:
            csv_content = ''.join(f.readlines())
        csv_content = csv_content.replace(',', '\t\t')
        with open(template_path, 'r') as f:
            email_content = ''.join(f.readlines())
        email_content = email_content.format(csv_stats=csv_content)
        # parse env variables in email template
        email_content = os.path.expandvars(email_content)
        with open(email_path, 'w') as f:
            f.write(email_content)

    if acceptance_db is None:
        return

    if pytest.conf['loopback']:
        conftest_logger.warning('Loopback mode: database not available')
        return

    # detect hardware and save stats to database
    release = pytest.conf['release']
    k200_id = K200.detect_hw(session=acceptance_db)
    test_id = AcceptanceTest.add(session=acceptance_db, linux_release=release, vmlinux_path=pytest.conf['vmlinux'],
                                 iterations=pytest.conf['iterations'])
    if pytest.switch:
        lp_id = LinkPartner.detect_switch(session=acceptance_db, switch=pytest.switch)
    else:
        host_itf = [x.binded_iface for x in pytest.interfaces if x.iface == stats_ser[0]['interface']][0]
        lp_id = LinkPartner.detect_nic(session=acceptance_db, itf=host_itf, run_cmd=run_cmd)

    # we need to get the SN of cables connected to the MPPA
    # so we check whether we can still ssh
    ret, _, _ = ut.run_cmd(f"ping -c1 -W2 {MPPA_SSH_HOSTNAME}", disable_logging=True)
    jtag = None
    ssh = None
    try:
        if ret != 0:
            jtag = new_jtag_instance()
            jtag.start()
            time.sleep(20)
        ssh = new_ssh_instance()

        cables = {}
        for mppa_itf in pytest.interfaces:
            mppa_itf.set_remote(ssh)
            cables[mppa_itf.iface] = EthernetCable.detect_hw(session=acceptance_db, itf=mppa_itf)
    finally:
        if ssh is not None:
            ssh.close()
        if jtag is not None:
            jtag.interrupt()

    for conf_id,d1 in stats.items():
        conf = pytest.conf['test-parameters'][conf_id]
        for mppa_itf,d2 in d1.items():
            config_id = AcceptanceConfig.add(session=acceptance_db, k200=k200_id, lp=lp_id, cable=cables[mppa_itf][0])
            run_id = AcceptanceRun.create(acceptance_db, test=test_id, mppa_interface=mppa_itf, config=config_id, cable_sn=cables[mppa_itf][1]).id
            TestScenarioParam.add(session=acceptance_db, conf=conf, run_id=run_id)
            TestCaseResult.add_results(session=acceptance_db, results=d2, run_id=run_id)
    conftest_logger.info("Test results were successfully saved in database")

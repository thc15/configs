import pytest
import logging
import time
import os
import shutil
from scapy.packet import Raw
from scapy.layers.l2 import Ether, Dot1Q
from scapy.layers.inet import IP, UDP
from scapy.volatile import RandString

from utils.scapy_modules.cbfc import MacControl, CBFC
from utils.utils import install_package_on_host, send_packets


PFC_CLASSES             = range(0, 8)
RX_NOC_LINKS            = range(0, 5)
PFC_ALERT_LEVEL         = 30000
PFC_RELEASE_LEVEL       = 10000
RX_NOC_VCHAN_PPS_TIMER  = 32000
PFC_QUANTA              = 60000
PFC_QUANTA_THRES        = 100
PARSER_FILTER_IDX       = range(0, 4)
NB_PACKETS_THRES        = 500 # threshold at which we consider fifo is full and pause frames are sent


@pytest.fixture(scope="session", autouse=True)
def install_system_dependencies():
    # check that tcpreplay is installed
    if not shutil.which("tcpreplay"):
        install_package_on_host("tcpreplay")


@pytest.fixture(scope='class', params=[
    {'pfc_class_en': [1], 'nb_packets': 1000000},
    {'pfc_class_en': [0, 1], 'nb_packets': 1000000},
    {'pfc_class_en': [0, 1], 'nb_packets': 10},
    {'pfc_class_en': [0], 'nb_packets': 10},
])
def setup_pfc(request, remote, itf):
    itf.sysfs.lb[0].rx_noc[:].vchan1_pps_timer = RX_NOC_VCHAN_PPS_TIMER
    itf.sysfs.lb[0].pfc_cl[:].release_level = PFC_RELEASE_LEVEL
    itf.sysfs.lb[0].pfc_cl[:].alert_level = PFC_ALERT_LEVEL
    itf.sysfs.lb[0].pfc_cl[:].quanta = PFC_QUANTA
    itf.sysfs.lb[0].pfc_cl[:].quanta_thres = PFC_QUANTA_THRES
    for parser in PARSER_FILTER_IDX:
        remote.run_cmd(f"ethtool -U {itf.iface} delete {parser}")
    yield request.param


@pytest.mark.testsuite
@pytest.mark.link_required
class TestPFC:
    logger = logging.getLogger('TestPFC')

    def init(self, **kwargs):
        self.__dict__.update(kwargs)
        # Disable packet flow control
        self.remote.run_cmd(f"ethtool -A {self.itf.iface} rx off tx off")

    ##### Utility functions #####

    def mppa_enable_pfc(self):
        """ Enable PFC
        """
        for parser, cla in zip(list(PARSER_FILTER_IDX), self.pfc_class_en):
            self.remote.run_cmd(f"ethtool -U {self.itf.iface} flow-type ether vlan {cla << 13} m 0xe000 loc {parser}")
        self.itf.sysfs.tx[0].pfc_en = 1
        for cla in PFC_CLASSES:
            self.itf.sysfs.lb[0].pfc_cl[cla].pfc_ena = int(cla in self.pfc_class_en)
        time.sleep(1)
        assert self.itf.sysfs.mac.pfc_mode == 1

    def mppa_disable_pfc(self):
        for parser in PARSER_FILTER_IDX:
            self.remote.run_cmd(f"ethtool -U {self.itf.iface} delete {parser}")
        self.itf.sysfs.tx[0].pfc_en = 0
        self.itf.sysfs.lb[0].pfc_cl[:].pfc_ena = 0
        time.sleep(1)
        assert self.itf.sysfs.mac.pfc_mode == 0

    def mppa_pause_frames_cnt(self, mode="TX"):
        """ Returns a list of pause frame counters of all pfc classes
        """
        _, out, _ = self.remote.run_cmd(f"ethtool -S {self.itf.iface} | egrep -i \"{mode} cbfcpauseframes\\[.*\\]\" | cut -f 2 -d :", expect_ret=0)
        return [int(x.strip()) for x in out.split('\n') if x != '']

    def host_flood_udp(self):
        TestPFC.logger.info("Getting initial pause frame, pfc req and drop counters")
        pf_before = self.mppa_pause_frames_cnt()
        dr_before = self.itf.sysfs.lb[0].pfc_cl[:].drop_cnt
        req_before = self.itf.sysfs.lb[0].pfc_cl[:].pfc_req_cnt
        TestPFC.logger.info("Starting UDP flood")
        pkts = []
        for id in self.pfc_class_en:
            pkts.append(Ether(dst=self.itf.mac_address, src=self.itf.get_binded_interface().mac_address) /\
                        Dot1Q(prio=id, vlan=1) /\
                        IP(dst=self.itf.ip_address, src=self.itf.get_binded_interface().ip_address) /\
                        UDP(sport=1000 + id, dport=1000 + id) /\
                        Raw(RandString(size=100))
                        )
        send_packets(pkts, loop=self.nb_packets, itf=self.itf.binded_iface)
        TestPFC.logger.info("Getting final pause frame, pfc req and drop counters")
        pf_after = self.mppa_pause_frames_cnt()
        dr_after = self.itf.sysfs.lb[0].pfc_cl[:].drop_cnt
        req_after = self.itf.sysfs.lb[0].pfc_cl[:].pfc_req_cnt
        pf_diff = [int(y)-int(x) for x,y in zip(pf_before, pf_after)]
        dr_diff = [int(y)-int(x) for x,y in zip(dr_before.values(), dr_after.values())]
        req_diff = [int(y)-int(x) for x,y in zip(req_before.values(), req_after.values())]
        return pf_diff, dr_diff, req_diff

    def host_send_pause_frame(self):
        pf_before = self.mppa_pause_frames_cnt(mode="RX")
        dir = os.path.dirname(__file__)
        time_per_class = {}
        class_vector = 0x0
        for class_id in self.pfc_class_en:
            class_vector |= 1 << class_id
            time_per_class[f"C{class_id}"] = 0xffff
        pkt = Ether(dst="01:80:C2:00:00:01", src=self.itf.get_binded_interface().mac_address) / MacControl() / CBFC(Class_Enable_Vector=class_vector, **time_per_class)
        pkt = pkt.Padd()
        send_packets(pkt, itf=self.itf.binded_iface)
        pf_after = self.mppa_pause_frames_cnt(mode="RX")
        return [int(y)-int(x) for x,y in zip(pf_before, pf_after)]

    ##### Test cases #####

    @pytest.mark.dependency(name="TestPFC::test_ping")
    def test_ping(self, itf, setup_pfc, run_cmd):
        """ Make sure ping works before testing PFC
        """
        run_cmd(f"ping -A -c1 -I {itf.binded_iface} {itf.ip_address}", expect_ret=0)

    @pytest.mark.dependency(depends=["TestPFC::test_ping"])
    def test_rx_pfc_disabled(self, itf, remote, conf, setup_pfc):
        """ Test that no pause frame is sent when PFC mode is disabled
        """
        self.init(itf=itf, remote=remote, conf=conf, pfc_class_en=setup_pfc['pfc_class_en'], nb_packets=setup_pfc['nb_packets'])
        self.mppa_disable_pfc()
        pf_cnt, drop_cnt, req_cnt = self.host_flood_udp()
        assert sum(pf_cnt) == 0, "At least one pause frame was sent while PFC is disabled"
        assert sum(drop_cnt) == 0, "drop_cnt should not be incremented while PFC is disabled"
        assert sum(req_cnt) == 0, "pfc_req_cnt should not be incremented when PFC is disabled"

    @pytest.mark.dependency(depends=["TestPFC::test_ping"])
    def test_rx_pfc_enabled(self, itf, remote, conf, setup_pfc):
        """ Test that pause frames are sent when PFC mode is enabled and the interface is flooded with UDP packets
        """
        self.init(itf=itf, remote=remote, conf=conf, pfc_class_en=setup_pfc['pfc_class_en'], nb_packets=setup_pfc['nb_packets'])
        self.mppa_enable_pfc()
        pf_cnt, drop_cnt, req_cnt = self.host_flood_udp()
        if self.nb_packets < NB_PACKETS_THRES:
            assert all([pf_cnt[x] == 0 for x in PFC_CLASSES]), \
                "At least one pause frame was sent whereas it should not"
            assert all([drop_cnt[x] == 0 for x in PFC_CLASSES]), \
                "At least one frame was dropped whereas it should not"
        else:
            assert all([pf_cnt[x] > 0 for x in self.pfc_class_en]), \
                f"A pause frame was not sent in one of the classes {self.pfc_class_en} whereas it should"
            assert all([pf_cnt[x] == 0 for x in PFC_CLASSES if x != 0 and x not in self.pfc_class_en]), \
                f"At least one pause frame was sent in class out of {self.pfc_class_en} whereas it should not"
            assert all([drop_cnt[x] == 0 for x in PFC_CLASSES if x not in self.pfc_class_en]), \
                f"At least one frame was dropped in one of the classes out of {self.pfc_class_en} whereas it should not"
            assert all([req_cnt[x] >= 1 for x in self.pfc_class_en]), \
                f"At least one counter pfc_req_cnt of class {self.pfc_class_en} was not increased by at least 1"

    @pytest.mark.dependency(depends=["TestPFC::test_ping"])
    def test_tx_pfc_enabled(self, itf, remote, conf, setup_pfc):
        """ Test that pfc frames are received by the mppa
        """
        self.init(itf=itf, remote=remote, conf=conf, pfc_class_en=setup_pfc['pfc_class_en'], nb_packets=setup_pfc['nb_packets'])
        self.mppa_enable_pfc()
        pf_diff = self.host_send_pause_frame()
        assert all([pf_diff[x] == 1 for x in self.pfc_class_en]), \
                f"A pause frame was not received in one of the classes {self.pfc_class_en} whereas it should"

    @pytest.mark.dependency(depends=["TestPFC::test_ping"])
    def test_tx_pfc_disabled(self, itf, remote, conf, setup_pfc):
        """ Test that pfc frames are not processed by the mppa when pfc is disabled
        """
        self.init(itf=itf, remote=remote, conf=conf, pfc_class_en=setup_pfc['pfc_class_en'], nb_packets=setup_pfc['nb_packets'])
        self.mppa_disable_pfc()
        pf_diff = self.host_send_pause_frame()
        assert all([pf_diff[x] == 0 for x in self.pfc_class_en]), \
                f"A pause frame was received in one of the classes {self.pfc_class_en} whereas it should not"


@pytest.mark.testsuite
@pytest.mark.loopback
class TestDCBNL:
    logger = logging.getLogger('TestDCBNL')

    def test_dcbx_supported_modes(self, itf, remote):
        """ Test that "host cee" and "host ieee" are supported
        """
        for mode in ['host cee', 'host ieee']:
            remote.run_cmd(f"dcb dcbx set dev {itf.iface} {mode}", expect_ret=0)
            remote.run_cmd(f"dcb dcbx show dev {itf.iface}", expect_ret=0, expect_kw=mode)

    def test_dcbx_unsupported_modes(self, itf, remote):
        """ Test that lld_managed and cee+ieee modes are not supported
        """
        _, cur_mode, _ = remote.run_cmd(f"dcb dcbx show dev {itf.iface}", expect_ret=0)
        for mode in ['lld_managed ieee', 'host cee ieee']:
            remote.run_cmd(f"dcb dcbx set dev {itf.iface} {mode}", expect_not_ret=0)
            remote.run_cmd(f"dcb dcbx show dev {itf.iface}", expect_ret=0, expect_output=cur_mode)

    def test_pfc_prio_enabled(self, itf, remote):
        for prio,prio_str in [(0, '0:on'), (1, '0:off 1:on')]:
            remote.run_cmd(f"dcb pfc set dev {itf.iface} prio-pfc {prio_str}", expect_ret=0)
            remote.run_cmd(f"dcb pfc show dev {itf.iface}", expect_ret=0, expect_kw=prio_str)
            pfc = itf.sysfs.lb[0].pfc._all_            
            assert pfc['global_pfc_en'] == 0, "global pfc should be disabled"
            assert pfc['global_pause_en'] == 0, "global pause should be disabled"
            assert itf.sysfs.lb[0].pfc_cl[prio].pfc_ena == 1, f"pfc for class {prio} should be enabled"
            assert itf.sysfs.mac.pfc_mode == 1, "mac pfc mode should be set to PFC"
            tx_fifo = itf.sysfs.tx[0]._all_
            assert tx_fifo['pfc_en'] == 1, "tx pfc should be enabled"
            assert tx_fifo['pause_en'] == 0, "tx global pause should be disabled"

    def test_global_pfc_enabled(self, itf, remote):
        remote.run_cmd(f"dcb pfc set dev {itf.iface} prio-pfc all:on", expect_ret=0)
        expected_out = " ".join([f"{x}:on" for x in PFC_CLASSES])
        remote.run_cmd(f"dcb pfc show dev {itf.iface}", expect_ret=0, expect_kw=expected_out)
        pfc = itf.sysfs.lb[0].pfc._all_
        assert pfc['global_pfc_en'] == 1, "global pfc should be enabled"
        assert pfc['global_pause_en'] == 0, "global pause should be disabled"
        assert itf.sysfs.mac.pfc_mode == 1, "mac pfc mode should be set to PFC"
        assert all(map(lambda x: x == 1, itf.sysfs.lb[0].pfc_cl[:].pfc_ena.values())), \
               "all pfc classes should be enabled"
        tx_fifo = itf.sysfs.tx[0]._all_
        assert tx_fifo['pfc_en'] == 1, "tx pfc should be enabled"
        assert tx_fifo['pause_en'] == 0, "tx global pause should be disabled"

    def test_global_pause_enabled(self, itf, remote):
        remote.run_cmd(f"dcb pfc set dev {itf.iface} prio-pfc all:off", expect_ret=0)
        expected_out = " ".join([f"{x}:off" for x in PFC_CLASSES])
        remote.run_cmd(f"dcb pfc show dev {itf.iface}", expect_ret=0, expect_kw=expected_out)
        pfc = itf.sysfs.lb[0].pfc._all_
        assert pfc['global_pfc_en'] == 0, "global pfc should be disabled"
        assert pfc['global_pause_en'] == 1, "global pause should be enabled"
        assert itf.sysfs.mac.pfc_mode == 2, "mac pfc mode should be set to PAUSE"
        assert all(map(lambda x: x == 0, itf.sysfs.lb[0].pfc_cl[:].pfc_ena.values())), \
               "all pfc classes should be disabled"
        tx_fifo = itf.sysfs.tx[0]._all_
        assert tx_fifo['pfc_en'] == 0, "tx pfc should be disabled"
        assert tx_fifo['pause_en'] == 1, "tx global pause should be enabled"

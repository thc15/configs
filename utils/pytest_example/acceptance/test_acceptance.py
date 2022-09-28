import pytest
import logging
import time
import json
import tempfile
import os
from datetime import datetime, timedelta

from utils.utils import timeout
from utils.ssh import SSHCmdTimeoutException


logger = logging.getLogger('TestPing')


IPERF_DURATION     = 30   # seconds
IPERF_MPPA_PORT    = 1234 # available port on MPPA
IPERF_RX_MIN_SPEED = 300  # Mbps
IPERF_TX_MIN_SPEED = 300  # Mbps
IPERF_PID_FILE     = f"{tempfile.gettempdir()}/eth-acceptance-iperf.pid"


@pytest.mark.acceptance
@pytest.mark.link_required
class TestAcceptance:

    def send_ping(self, itf, run_cmd):
        mppa_ip = pytest.conf['ip-bindings'][itf.iface]['mppa'].split('/')[0]

        # workaround for switch cisco: a port is operational ~1min after configuration
        # ping might not work if we do not wait
        ping_timeout = datetime.now() + timedelta(minutes=1, seconds=30)
        while datetime.now() <= ping_timeout:
            ret, _, _ = run_cmd(f"ping -c 1 -I {itf.binded_iface} {mppa_ip}")
            if ret == 0:
                break
        return ret == 0

    def operstate_test(self, remote, itf, status_expected="up"):
        for _ in range(10):
            status = itf.sysfs.operstate
            logger.info(f"Link operstate = {status}")
            if status == status_expected:
                return True
            time.sleep(1)
        return False

    @pytest.mark.dependency(name="eeprom_read")
    @pytest.mark.loopback
    def test_eeprom_qsfp_readable(self, conf, itf, remote, stats_counter):
        ret, _, _ = remote.run_cmd(f"ethtool -m {itf.iface}")
        test_ok = ret == 0
        stats_counter(conf, itf.iface, 'EEPROM read', success=test_ok)
        assert test_ok, f"Could not read eeprom data on interface {itf.iface}"

    @pytest.mark.dependency(name='link_up', depends=['eeprom_read'])
    @pytest.mark.loopback
    # BUG WORKAROUND: temporarily disable EOM dump because of timeout (T18758)
    # add the argument 'rtm_eom' to enable it
    def test_link_up(self, conf, itf, remote, stats_counter):
        """ Test that the link is up at boot. If not, try to force it using ifdown/ifup
        """
        test_ok = self.operstate_test(remote, itf, status_expected="up")
        stats_counter(conf, itf.iface, 'Link up at boot', success=test_ok)
        if test_ok:
            logger.info("Link is up !")

        # try to force the link up
        if not test_ok:
            logger.info("Link is not up, trying to force it...")
            for _ in range(10):
                remote.run_cmd(f'ifdown {itf.iface}')
                time.sleep(1)
                remote.run_cmd(f'ifup {itf.iface}')
                time.sleep(5) # T16883: avoid sysfs being read too fast
                test_ok = self.operstate_test(remote, itf, status_expected="up")
                stats_counter(conf, itf.iface, 'Force link up', success=test_ok)
                if test_ok:
                    break

        # test whether speed is correct
        speed_ok = True
        if test_ok and 'speed' in conf:
            speed_ok = itf.sysfs.speed == conf['speed']['mppa']
            stats_counter(conf, itf.iface, 'Speed test', success=speed_ok)

        assert test_ok, "Link is still not up after workaround"
        assert speed_ok, "Speed is incorrect"

    @pytest.mark.dependency(name='simple_ping', depends=['link_up'])
    def test_simple_ping(self, conf, itf, run_cmd, remote, stats_counter):
        """ Test interface with 1 ping
        """
        ping_ok = self.send_ping(itf, run_cmd)
        stats_counter(conf, itf.iface, 'Simple ping', success=ping_ok)
        assert ping_ok, "Could not ping MPPA"

    @pytest.mark.dependency(depends=['link_up'])
    @pytest.mark.loopback_only
    def test_simple_ping_loopback(self, conf, itf, remote, stats_counter):
        """ Test interface with 1 ping.
            We are in loopback, so we are just checking if we receive a packet on the
            other side with tcpdump (IP doesn't matter in this case)
        """
        remote.run_cmd(f"tcpdump -i {itf.binded_iface} -c1 -q 2> /tmp/out", as_daemon=True, timeout=5)
        remote.run_cmd(f"ping -W1 -I {itf.iface} -c1 1.1.1.1")
        time.sleep(2)
        _, out, _ = remote.run_cmd('cat /tmp/out')
        ping_ok = "1 packet captured" in out
        stats_counter(conf, itf.iface, 'Simple ping', success=ping_ok)
        assert ping_ok, "Could not ping MPPA"

    @pytest.mark.dependency(depends=['simple_ping'])
    @pytest.mark.parametrize("mode", ["RX", "TX"])
    def test_iperf(self, remote, run_cmd, conf, itf, stats_counter, mode):
        """ Test iperf3. Server is on host and client on MPPA.  Rx/Tx average speeds
            are measured and must be above a threshold.
        """
        logger.info("Starting iperf3 server on host")
        if os.path.exists(IPERF_PID_FILE):
            run_cmd(f"pkill -F {IPERF_PID_FILE}")
        run_cmd(f'iperf3 -1sD -p {IPERF_MPPA_PORT} -I {IPERF_PID_FILE}', expect_ret=0)

        logger.info("Starting iperf3 client on MPPA")
        host_ip = pytest.conf['ip-bindings'][itf.iface]['host'].split('/')[0]
        op_mode = '-R' if mode == 'RX' else ''
        cmd = f'iperf3 {op_mode} -c {host_ip} -J -t {IPERF_DURATION} -p {IPERF_MPPA_PORT}'
        try:
            _, out, _ = remote.run_cmd(cmd, expect_ret=0, timeout=IPERF_DURATION + 10)
        except SSHCmdTimeoutException:
            remote.kill_process(cmd)
            assert False, "iperf3 took longer than expected"

        iperf_data = json.loads(out)
        sent_MB =  iperf_data['end']['sum_sent']['bytes'] / 1000**2
        received_MB =  iperf_data['end']['sum_received']['bytes'] / 1000**2
        loss = round(100 * sent_MB / received_MB - 100, 2)
        logger.info(f"iperf3 results: Sent: {sent_MB} MB  |  Received: {received_MB} MB  |  Packet loss: {loss}%")
        thres = IPERF_TX_MIN_SPEED if mode == 'TX' else IPERF_RX_MIN_SPEED
        avg_speed = iperf_data['end']['sum_received']['bits_per_second'] / 1000**2
        logger.info(f"Average speed: {avg_speed} Mbps")
        stats_counter(conf, itf.iface, f'Iperf3 {mode}', success=avg_speed >= thres)
        assert avg_speed >= thres, f"{mode} speed measured is lower than the minium required {thres} Mbps"

    @pytest.mark.dependency(depends=['simple_ping'])
    @pytest.mark.skipif(pytest.switch is None, reason="Works only with a switch")
    def test_qsfp_unplug(self, conf, itf, run_cmd, stats_counter, remote):
        # disable port on switch side
        port = itf.get_binded_switch_port()
        switch_port = pytest.switch.get_port(port)
        switch_port.disable()
        time.sleep(5)

        # check that carrier is down
        if not self.operstate_test(remote, itf, status_expected="down"):
            stats_counter(conf, itf.iface, 'QSFP unplug', success=False)
            assert False, "carrier is supposed to be down"

        # enable port on host/switch side
        switch_port.enable()
        time.sleep(5)

        # check that carrier came up
        if not self.operstate_test(remote, itf, status_expected="up"):
            stats_counter(conf, itf.iface, 'QSFP unplug', success=False)
            assert False, "carrier is supposed to be up"

        # test with a ping
        ping_ok = self.send_ping(itf, run_cmd)
        stats_counter(conf, itf.iface, 'QSFP unplug', success=ping_ok)
        assert ping_ok, "simple ping did not work"

import pytest
import logging
import re

from utils.parsers import EthtoolTransceiverParser

logger = logging.getLogger('TestQSFP')

PAGE_SIZE           = 128
ETHTOOL_E_HEX_REGEX = r"([0-9a-f]{2})[^\w:]"


@pytest.mark.testsuite
@pytest.mark.link_required
class TestQSFP:
    """ Test cases for the QSFP driver"""

    eeprom_len = 0
    qsfp_tuning_param = [
        {'page': 3, "offset": 236, "value": "00"}, # expected value
        {'page': 3, "offset": 237, "value": "00"},
        {'page': 3, "offset": 238, "value": "33"},
        {'page': 3, "offset": 238, "value": "33"}
    ]
    qsfp_write_param = [
        {'page': 3, "offset": 238, "value": "ff"}
    ]

    ##### Utility functions #####

    def check_offset(self, off):
        # the test case can be incompatible with the cable
        if off > TestQSFP.eeprom_len:
            pytest.skip("offset is bigger than eeprom size")

    def dump_bytes(self, itf, remote, off, length=1):
        _, out, _ = remote.run_cmd(f"ethtool -e {itf.iface} offset {off} length {length}", expect_ret=0)
        return re.findall(ETHTOOL_E_HEX_REGEX, out + ' ')

    def write_byte(self, itf, remote, off, value):
        # value is in hex
        remote.run_cmd(f"ethtool -E {itf.iface} offset {off} length 1 value 0x{value}", expect_ret=0)

    ##### Test functions #####

    def test_ethtool_transceiver_infos(self, itf, run_cmd, remote):
        """ Compare output of 'ethtool -m' on link partner and mppa
        """
        _, out, _ = run_cmd(f"sudo ethtool -m {itf.binded_iface}", expect_ret=0)
        trans_host = EthtoolTransceiverParser(out)

        _, out, _ = remote.run_cmd(f"ethtool -m {itf.iface}", expect_ret=0)
        trans_mppa = EthtoolTransceiverParser(out)

        assert trans_host.vendor_name() == trans_mppa.vendor_name(), "Vendor names are different"
        assert trans_host.vendor_pn() == trans_mppa.vendor_pn(), "Vendor PNs are different"
        assert trans_host.identifier() == trans_mppa.identifier(), "Ids are different"
        assert trans_host.vendor_rev() == trans_mppa.vendor_rev(), "Vendor revs are different"
        assert trans_host.transmitter_tech() == trans_mppa.transmitter_tech(), "Techs are different"

    @pytest.mark.dependency(name="eeprom_dump")
    def test_ethtool_dump_eeprom(self, itf, remote):
        """ Check that the eeprom can be dumped with ethtool
        """
        _, out, _ = remote.run_cmd(f"ethtool -e {itf.iface}", expect_ret=0)
        TestQSFP.eeprom_len = len(re.findall(ETHTOOL_E_HEX_REGEX, out))
        logger.info(f"eeprom size= {TestQSFP.eeprom_len}")

        # check with offset and length
        offset = 50
        length = 16
        _, out, _ = remote.run_cmd(f"ethtool -e {itf.iface} offset {offset} length {length}", expect_ret=0)
        assert f"0x{offset:04x}:" in out, "Could not find offset index in the output"
        assert len(re.findall(ETHTOOL_E_HEX_REGEX, out + ' ')) == length, "Incorrect dump length"

    @pytest.mark.dependency(name="eeprom_write", depends=["eeprom_dump"])
    def test_qsfp_tuning(self, itf, remote):
        """ Check that qsfp params are correctly tuned at boot (if fiber cable)
        """
        for p in TestQSFP.qsfp_tuning_param:
            off = p['page'] * PAGE_SIZE + p['offset']
            self.check_offset(off)
            val = self.dump_bytes(itf, remote, off)[0]
            assert val == p['value'], f"QSFP param at page {p['page']} offset {p['offset']} isn't correct"

    @pytest.mark.dependency(name="eeprom_write", depends=["eeprom_dump"])
    def test_ethtool_write_eeprom(self, itf, remote):
        """ Check that a register's value can be changed using ethtool -E
        """
        for p in TestQSFP.qsfp_write_param:
            off = p['page'] * PAGE_SIZE + p['offset']
            self.check_offset(off)

            val = self.dump_bytes(itf, remote, off)[0]
            if val == p['value']:
                pytest.skip("cannot check ethtool write eeprom")
            self.write_byte(itf, remote, off, p['value'])
            new_val = self.dump_bytes(itf, remote, off)[0]
            assert new_val == p['value'], "eeprom write failed"

            # restore old value
            logger.info("Restore previous value")
            self.write_byte(itf, remote, off, val)

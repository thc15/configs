import pytest


@pytest.mark.eth0
class TestEth0:

    def test_ping(self, itf, run_cmd):
        run_cmd(f"ping -c 10 -I {itf.binded_iface} {itf.ip_address}", expect_ret=0)

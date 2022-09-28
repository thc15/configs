import pytest
import logging
import time
import os

from utils.utils import run_cmd

logger = logging.getLogger('TestDMA')

BUF_SIZE_MIN                = [10]
BUF_SIZE_MAX                = [9200]
FIRST_CHAN_RX               = [10]
FIRST_CHAN_TX               = [10]
NB_CHANNELS                 = range(1,  3,  1)
THREADS_PER_TX_CHAN         = [1,5]

@pytest.fixture(params=BUF_SIZE_MIN)
def buf_size_min(request):
    """fixture: returns buf size
    """
    logger.info(f"Starting tests with buffer size min: {request.param}")
    return request.param

@pytest.fixture(params=BUF_SIZE_MAX)
def buf_size_max(request):
    """fixture: returns buf size
    """
    logger.info(f"Starting tests with buffer size max: {request.param}")
    return request.param

@pytest.fixture(params=FIRST_CHAN_RX)
def first_chan_rx(request):
    """fixture: returns buf size
    """
    logger.info(f"Starting tests with first Rx channel: {request.param}")
    return request.param

@pytest.fixture(params=FIRST_CHAN_TX)
def first_chan_tx(request):
    """fixture: returns buf size
    """
    logger.info(f"Starting tests with first Tx channel: {request.param}")
    return request.param

@pytest.fixture(params=THREADS_PER_TX_CHAN)
def thread_per_tx_chan(request):
    """fixture: returns buf size
    """
    logger.info(f"Starting tests with Number of thread per Tx channel: {request.param}")
    return request.param

@pytest.fixture(params=NB_CHANNELS)
def nb_channels(request):
    """fixture: returns buf size
    """
    logger.info(f"Starting tests with Number of channels : {request.param}")
    return request.param

@pytest.mark.haps_cv2
@pytest.mark.testsuite
@pytest.mark.loopback
class TestDMA:

    ##### Test cases #####

    # @pytest.mark.run('first')
    def test_basic_dma(self, remote, buf_size_min, buf_size_max, first_chan_rx, first_chan_tx, thread_per_tx_chan, nb_channels):
        remote.run_cmd("rmmod test_dma_eth") # insure next modprobe not rejected if already installed
        cmd = "modprobe test_dma_eth"
        cmd += f" first_chan_rx={first_chan_rx}"
        cmd += f" first_chan_tx={first_chan_tx}"
        cmd += f" buf_sz_min={buf_size_min}"
        cmd += f" buf_sz_max={buf_size_max}"
        cmd += f" nb_chan={nb_channels}"
        cmd += f" thread_per_tx_chan={thread_per_tx_chan}"
        remote.run_cmd(cmd)
        remote.run_cmd("echo 1 > /sys/module/test_dma_eth/parameters/start", expect_ret=0)
        for t_id in range(nb_channels) :
            remote.run_cmd(f"cat /sys/module/test_dma_eth/parameters/result | grep 'chan {t_id}'", expect_kw = "valid: Y - error: 0 ", expect_not_kw = "check: 0", expect_ret=0)
        remote.run_cmd("rmmod test_dma_eth")


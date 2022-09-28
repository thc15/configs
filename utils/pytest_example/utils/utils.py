import logging
import subprocess
import netifaces
import os
import pytest
import tempfile
import re
import signal
import copy
from contextlib import contextmanager
from scapy.utils import wrpcap


def run_cmd(cmd, expect_ret=None, expect_not_ret=None, expect_kw=None, expect_not_kw=None, expect_output=None, timeout=None, shell=True, disable_logging=False):
    """run cmd on host (where pytest is executed) with/without checking return status/keywords

    Arguments:
        cmd {string} -- cmd to run
        expect_ret {int} -- expected return status
        expect_not_ret {int} -- unexpected return status
        expect_kw {string} -- string expected in output
        expect_not_kw {string} -- string not expected in output
        expect_output {string} -- string exactly the same as output
        timeout {int} -- timeout in seconds

    Return:
        (status, output, stderr) -- cmd return code and output and errors

    """
    logger = logging.getLogger('host cmd')
    logger.disabled = disable_logging
    logger.info("CMD: %s", cmd.strip())
    if timeout:
        cmd = "timeout %i %s" % (timeout, cmd)
    if not shell:
        cmd = cmd.split(' ')
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=shell)
    output, error = proc.communicate()
    try:
        output = output.decode('utf-8')
    except UnicodeDecodeError as ex:
        logger.error(f'Could not decode stdout: {ex}')
        output = ''
    try:
        error = error.decode('utf-8')
    except UnicodeDecodeError as ex:
        logger.error(f'Could not decode stderr: {ex}')
        error = ''
    status = proc.returncode
    logger.info("CMD return code: %s" % status)
    logger.info("CMD stdout:")
    for line in output.split('\n'):
        logger.info("%s" % line.rstrip('\n'))
    logger.info("CMD stderr:")
    for line in error.split('\n'):
        logger.info("%s" % line.rstrip('\n'))

    output = output.strip()
    error = error.strip()
    if expect_ret is not None:
        assert status == expect_ret, 'status %s not equal to expect_ret %s' % (
            status, expect_ret)
    if expect_not_ret is not None:
        assert status != expect_not_ret, 'status %s should not equal to expect_not_ret %s' % (
            status, expect_not_ret)
    if expect_kw is not None:
        assert expect_kw in output, 'expected %s not in output %s' % (
            expect_kw, output)
    if expect_not_kw is not None:
        assert expect_not_kw not in output, '%s is not expected in output %s' % (
            expect_not_kw, output)
    if expect_output is not None:
        assert expect_output == output, 'expected %s  is not %s' % (
            expect_output, output)

    return status, output.strip(), error.strip()


def run_cmd_as_root(cmd, expect_ret=None, expect_not_ret=None, expect_kw=None, expect_not_kw=None, expect_output=None, timeout=None, shell=True):
    """run cmd as root on host with/without checking return status/keywords
    """
    if os.getenv('VIRTUAL_ENV') is not None:
        venv_path = os.path.join(os.getenv('VIRTUAL_ENV'), "bin/activate")
        venv_cmd = f"source {venv_path};"
    else:
        venv_cmd = ""
    dir = os.path.dirname(os.path.abspath(os.path.dirname(__file__)))
    cmd = cmd.replace('"', '\"')
    cmd = f'sudo -- bash -c "cd {dir}; {venv_cmd} {cmd}"'
    return run_cmd(cmd, expect_ret, expect_not_ret, expect_kw, expect_not_kw, expect_output, timeout, shell)


def send_packets(pkts, itf, mbps=100000, loop=1):
    """ Send a(many) Scapy packet(s) via a raw socket
    """
    _, pcap_path = tempfile.mkstemp(suffix='.pcap')
    wrpcap(pcap_path, pkts)
    script_path = os.path.join(os.path.dirname(__file__), "send_packet.py")
    ret, _, _ = run_cmd_as_root(f"python {script_path} --pcap {pcap_path} --itf {itf} --loop {loop} --mbps={mbps}")
    os.remove(pcap_path)
    return ret == 0


@contextmanager
def timeout(timeout, error_msg=None):
    """ Limit the execution time of a block of code. How to use it:

    with timeout(60): # timeout of 60 sec
        time.sleep(70)
        print("This should never get printed")
    """
    # Register a function to raise a TimeoutError on the signal.
    signal.signal(signal.SIGALRM, raise_timeout)
    # Schedule the signal to be sent after ``time``.
    signal.alarm(timeout)

    try:
        yield
    except TimeoutError:
        if error_msg is not None:
            assert False, error_msg
    finally:
        # Unregister the signal so it won't be triggered
        # if the timeout is not reached.
        signal.signal(signal.SIGALRM, signal.SIG_IGN)


def raise_timeout(signum, frame):
    raise TimeoutError


def dict_has_keys(data, *args):
    """Returns True if data is a dictionnary and contains all keys in args.
       If data is a list of dictionnaries, then returns True if all dictionnaries contain all keys.
    """
    if data is None:
        return False
    if isinstance(data, dict):
        return set(args).issubset(data.keys())
    elif isinstance(data, list):
        assert all([isinstance(x, dict) for x in data]), "At least one element is not a dictionnary"
        return all([dict_has_keys(x, *args) for x in data])


def install_package_on_host(pkg_name):
    run_cmd(f"sudo apt install -y {pkg_name}", expect_ret=0)


class MppaSysfsException(Exception):

    def __init__(self, sysfs, msg):
        fpath = sysfs._path_format_unix()
        return super().__init__(f"{msg}: {sysfs._attrs_['base_path']}/{fpath}")


class MppaSysfs:
    path_shortcuts = {
        '{net}': '/sys/class/net',
        '{qsfp_enmppa0}': '/sys/devices/platform/axi/axi\\:qsfp0@0',
        '{qsfp_enmppa4}': '/sys/devices/platform/axi/axi\\:qsfp0@1',
    }

    def __init__(self, remote=None, path=None):
        # warning: all class attributes must be in this dict because __getattr__
        # and __setattr__ are overwritten
        self._attrs_ = {}
        if remote is None and path is None: # cf. _copy_myself()
            return super().__init__()

        self._attrs_['remote'] = remote
        self._attrs_['logger'] = logging.getLogger('MPPA Sysfs')
        for k,v in MppaSysfs.path_shortcuts.items():
            path = path.replace(k, v)
        self._attrs_['base_path'] = path
        self._attrs_['path'] = []
        self._attrs_['sysfs_all_files'] = []
        self._attrs_['sysfs_all_dirs'] = []

        # init sysfs tree: get list of files and directories
        _, files, _ = self._run_cmd(f"find {path}/ -type f -print", expect_ret=0)
        self._attrs_['sysfs_all_files'] = list(map(lambda x: x.replace(path, '').strip('/'), files.split('\n')))
        _, dirs, _ = self._run_cmd(f"find {path}/ -type d -print", expect_ret=0)
        self._attrs_['sysfs_all_dirs'] = list(map(lambda x: x.replace(path, '')[1:], dirs.split('\n')))
        return super().__init__()

    def _run_cmd(self, cmd, **kwargs):
        self._attrs_['remote'].disable_logging()
        ret = self._attrs_['remote'].run_cmd(cmd, **kwargs)
        self._attrs_['remote'].enable_logging()
        return ret

    def _read_sysfs(self):
        data = {}
        upath = self._path_format_unix()
        rpath = self._path_format_regex()
        cmd = f"find {self._attrs_['base_path']}/{upath} -type f -exec awk 'END {{print FILENAME \"$cat$\" $0 \"$end$\"}}' {{}} \\;"
        self._attrs_['logger'].info(f"Read request: {self._attrs_['base_path']}/{upath}")
        ret, out, _ = self._run_cmd(cmd)
        if ret != 0:
            raise MppaSysfsException(self, "read failed")

        for fpath, content in re.findall(r'(.+)\$cat\$(.*)\$end\$', out):
            fpath = fpath.replace(self._attrs_['base_path'], '').strip('/')
            k = re.search(rpath, fpath).groups() or fpath.split('/')[-1]
            k = k[0] if len(k) == 1 else k # if data contains 1 key, return only the value
            try:
                data[k] = int(content)
            except ValueError:
                data[k] = content

        if len(data) == 1:
            data = list(data.values())[0]
            try:
                return int(data)
            except ValueError:
                pass
        return data

    def _write_sysfs(self, value):
        value = str(value)
        upath = self._path_format_unix()
        self._attrs_['logger'].info(f"Write request: {value} > {self._attrs_['base_path']}/{upath}")
        ret, out, _ = self._run_cmd(f"echo '{value}' | tee {self._attrs_['base_path']}/{upath}")
        if ret != 0:
            raise MppaSysfsException(self, "write failed")
        if out != '':
            self._attrs_['logger'].info(f"output: {out}")

    def _path_format_regex(self, path=None):
        path = path or self._attrs_['path']
        rpath = []
        for p in self._attrs_['path']:
            if isinstance(p, str):
                if p == '*':
                    rpath.append('([^/]+)')
                else:
                    rpath.append(p)
            elif isinstance(p, slice):
                if p == slice(None, None, None):
                    rpath.append('([0-9]+)')
                else:
                    n = self._nb_directory_match('/'.join(rpath) + '/*')
                    r = range(p.start or 0, p.stop or n, p.step or 1)
                    rpath.append('(' + '|'.join([str(x) for x in r]) + ')')
        return '/'.join(rpath)

    def _path_format_unix(self):
        upath = []
        for p in self._attrs_['path']:
            if isinstance(p, str):
                upath.append(p)
            elif isinstance(p, slice):
                if p == slice(None, None, None):
                    upath.append('*')
                else:
                    n = self._nb_directory_match('/'.join(upath) + '/*')
                    r = range(p.start or 0, p.stop or n, p.step or 1)
                    upath.append('{' + ','.join([str(x) for x in r]) + '}')
        return '/'.join(upath)

    def _is_directory(self):
        rpath = self._path_format_regex()
        return self._nb_directory_match(rpath) > 0

    def _is_file(self):
        rpath = self._path_format_regex()
        rpath = rpath.replace('*', '([^/]+)')
        return any([re.fullmatch(rpath, x) is not None for x in self._attrs_['sysfs_all_files']])

    def _nb_directory_match(self, rpath):
        rpath = rpath.replace('*', '([0-9]+)')
        return len([1 for x in self._attrs_['sysfs_all_dirs'] if re.fullmatch(rpath, x) is not None])

    def _append_path_item(self, item):
        if isinstance(item, int):
            item = str(item)
        if item == '_all_':
            item = '*'
        self._attrs_['path'].append(item)

    def __getattr__(self, item):
        if item == '_attrs_':
            return super(MppaSysfs, self).__getattr__(item)
        new_self = self._copy_myself()
        new_self._append_path_item(item)
        if new_self._is_file():
            return new_self._read_sysfs()
        if not new_self._is_directory():
            raise MppaSysfsException(new_self, "not found")
        return new_self

    def __setattr__(self, item, value):
        if item == '_attrs_':
            return super(MppaSysfs, self).__setattr__(item, value)
        new_self = self._copy_myself()
        new_self._append_path_item(item)
        if not new_self._is_file():
            raise MppaSysfsException(new_self, "not found")
        new_self._write_sysfs(value)

    def __getitem__(self, index):
        new_self = self._copy_myself()
        new_self._append_path_item(index)
        if not new_self._is_directory():
            raise MppaSysfsException(new_self, "not found")
        return new_self

    def __setitem__(self, index, item):
        raise Exception("This method should not be called")

    def _copy_myself(self):
        new_self = MppaSysfs()
        new_self._attrs_ = copy.copy(self._attrs_)
        new_self._attrs_['path'] = copy.deepcopy(self._attrs_['path'])
        return new_self

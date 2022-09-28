import logging
import shutil
import serial
import threading
import collections
import time
import os
import tempfile
import re
import uuid
from queue import Queue
import datetime as dt

from utils.utils import install_package_on_host, run_cmd


class Minicom(threading.Thread):
    MSG_QUEUE_MAX_LEN = 1000
    CMD_PROMPT = '# '
    DMESG_PARSER = re.compile(r"^\[([\d\. ]+)\]\s(.*)")
    CTRL_C = b'\x03'
    CTRL_D = b'\x04'

    def __init__(self, serial_port, baudrate=115200):
        super(Minicom, self).__init__()
        self.serial_port = serial_port
        self.baudrate = baudrate
        self.logger = logging.getLogger('minicom')
        self.interrupt_com = False
        self.rw_lock = threading.Lock()
        # queue that pops older message when new one is pushed and queue size is reached
        self.msg_queue = collections.deque(maxlen=Minicom.MSG_QUEUE_MAX_LEN)
        self.write_queue = Queue()
        self.mppa_stdout_file = f"/tmp/{uuid.uuid4()}.txt"
        self.mppa_stderr_file = f"/tmp/{uuid.uuid4()}.txt"

    def run(self):
        self.logger.info("Starting Minicom on serial port %s" % self.serial_port)
        data_logger = logging.getLogger('serial')
        # sometimes we don't have any output before sending a CF
        with serial.Serial(self.serial_port, baudrate=self.baudrate, timeout=1) as ser:
            ser.write(b'\r\n')
            ser.read(250)
        while not self.interrupt_com:
            with serial.Serial(self.serial_port, baudrate=self.baudrate, timeout=0.1) as ser:
                ser.reset_input_buffer()
                ser.reset_output_buffer()
                while not self.interrupt_com:
                    while not self.write_queue.empty():
                        ser.write(self.write_queue.get())
                    try:
                        line = ser.readline().decode('utf-8')[:-1]
                    except Exception:
                        break
                    if line != '':
                        if not self.rw_lock.locked():
                            data_logger.info(line)
                        self.msg_queue.append(line)
        self.logger.info('Minicom exited')

    def interrupt(self):
        """ Stop listenning on serial port
        """
        if not self.interrupt_com:
            self.interrupt_com = True
            self.logger.warning("Interrupt received. Closing minicom.")

    def get_last_messages(self):
        return self.msg_queue

    def _readline(self, timeout=1):
        """ Internal method for reading a line from serial port.
            This method should not be used outside of the class Minicom.
        """
        data_logger = logging.getLogger('serial')
        timeout = dt.datetime.now() + dt.timedelta(seconds=timeout)
        while dt.datetime.now() < timeout:
            try:
                line = self.msg_queue.popleft()
                if re.fullmatch(Minicom.DMESG_PARSER, line): # parse out msg from dmesg
                    data_logger.info(line)
                else:
                    return line.strip('\r\n')
            except IndexError:
                time.sleep(0.1)
                continue
        return ''

    def _write(self, data):
        """ Internal method for writing a line to serial port.
            This method should not be used outside of the class Minicom.
        """
        self.write_queue.put(data)

    def login_console(self, login, password):
        self.rw_lock.acquire()
        # we make sure the serial is waiting for login
        for _ in range(2):
            self._write(Minicom.CTRL_C)
            time.sleep(1)
        self._write(Minicom.CTRL_D)
        time.sleep(2)
        self.msg_queue.clear()
        self._write(login.encode('utf-8') + b'\r\n') # send login
        time.sleep(1)
        self._write(password.encode('utf-8') + b'\r\n') # send password
        i = 10
        while i > 0:
            line = self._readline()
            if line == Minicom.CMD_PROMPT:
                self.logger.info("Login successful")
                break
            i -= 1
        self.rw_lock.release()
        assert line == Minicom.CMD_PROMPT, "Login was unsuccessful, check credentials"

    def run_cmd(self, cmd, expect_ret=None, expect_not_ret=None, expect_kw=None, expect_not_kw=None, expect_output=None, msg=None, timeout=None,
                log_output=True, as_daemon=False):
        """run cmd with/without checking return status/keywords

        Arguments:
            cmd {string} -- cmd to run
            expect_ret {int} -- expected return status
            expect_not_ret {int} -- unexpected return status
            expect_kw {string} -- string expected in output
            expect_not_kw {string} -- string not expected in output
            expect_output {string} -- string exactly the same as output
            cancel_kw {string} -- cancel case if kw not found
            msg {string} -- addtional info to mark cmd run.

        Return:
            (status, output) -- cmd return code and output

        """
        data_logger = logging.getLogger('cmd via serial')
        data_logger.disabled = not log_output
        if msg is not None:
            data_logger.info(msg)
        data_logger.info("CMD: %s", cmd)
        if timeout:
            cmd = f"timeout {timeout} \"{cmd}\""
        else:
            cmd = f"sh -c \"{cmd}\""
        cmd += " > /dev/null 2>&1 &" if as_daemon else f" > {self.mppa_stdout_file} 2> {self.mppa_stderr_file}"

        def _run_cmd(cmd):
            for _cmd in [cmd, 'echo $?']:
                self._write(_cmd.encode('utf-8') + b'\r\n')
                line = ['']
                self._readline() # read cmd line written to serial
                while line[-1] != Minicom.CMD_PROMPT:
                    line.append(self._readline(timeout=30))
                self._readline() # read cmd prompt
            return int(line[-2].strip())

        def _read_cmd_output(file_path, log=True):
            output = ''
            self._write(f"cat {file_path}\r\n".encode('utf-8'))
            line = ''
            self._readline()
            while line != Minicom.CMD_PROMPT:
                line = self._readline(timeout=10)
                if line != Minicom.CMD_PROMPT and line != '':
                    if log:
                        data_logger.info(line.strip())
                    output += line + '\n'
            self._readline()
            return output.strip('\r\n')

        self.rw_lock.acquire()
        self.msg_queue.clear()
        ret = _run_cmd(cmd)
        if as_daemon:
            self.rw_lock.release()
            return
        data_logger.info("CMD stdout:")
        output = _read_cmd_output(self.mppa_stdout_file, log=log_output)
        data_logger.info("CMD stderr:")
        stderr = _read_cmd_output(self.mppa_stderr_file, log=log_output)
        self.rw_lock.release()
        data_logger.info("CMD return code: %s" % ret)
        output, stderr = output.strip('\r\n'), stderr.strip('\r\n')

        if expect_ret is not None:
            assert ret == expect_ret, 'status %s not equal to expect_ret %s' % (ret, expect_ret)
        if expect_not_ret is not None:
            assert ret != expect_not_ret, 'status %s should not equal to expect_not_ret %s' % (ret, expect_not_ret)
        if expect_kw is not None:
            assert expect_kw in output, 'expected %s not in output %s' % (expect_kw, output)
        if expect_not_kw is not None:
            assert expect_not_kw not in output, '%s is not expected in output %s' % (expect_not_kw, output)
        if expect_output is not None:
            assert expect_output == output, 'expected %s  is not %s' % (expect_output, output)

        return ret, output, stderr

    def get(self, remote_path, local_path=None):
        if local_path is None:
            local_path = remote_path
        # convert file to base64 and read it
        _, out, _ = self.run_cmd(f"cat {remote_path} | uuencode {remote_path}", expect_ret=0, log_output=False)
        # write to temporary file
        fd, temp_path = tempfile.mkstemp()
        with os.fdopen(fd, 'w') as f:
            f.write(out + "\n")
        # check that uudecode is installed on host
        if not shutil.which("uudecode"):
            install_package_on_host("sharutils")
        # decode base64 received from mppa
        run_cmd(f"uudecode -o {local_path} {temp_path}", expect_ret=0)

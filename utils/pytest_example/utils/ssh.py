import logging
import paramiko
import pytest
import time
import socket
import datetime
import re
from scp import SCPClient

ssh_logger = logging.getLogger("ssh")


class SSHCmdTimeoutException(Exception):
    pass


# Source : https://github.com/liangxiao1/pytest-ssh
class SSHClient(object):
    def __init__(self, hostname=None, username=None, keyfile=None, password=None, port=22, timeout=5, logger=ssh_logger):
        self.hostname = hostname
        self.username = username
        self.password = password
        self.keyfile = keyfile
        self.port = port
        self.timeout = timeout
        self.scp = None
        self.logger = logger

    def connect(self):
        self.ssh_client = paramiko.SSHClient()
        self.ssh_client.load_system_host_keys()
        self.ssh_client.set_missing_host_key_policy(paramiko.WarningPolicy())
        start_time = time.time()
        success = False
        while time.time() - start_time < self.timeout:
            try:
                if self.keyfile is None:
                    self.ssh_client.connect(self.hostname, username=self.username, password=self.password,
                                            allow_agent=False, look_for_keys=False)
                else:
                    self.ssh_client.connect(self.hostname, username=self.username, key_filename=self.keyfile,
                                            allow_agent=False, look_for_keys=False)
                self.scp = SCPClient(self.ssh_client.get_transport())
                success = True
                break
            except Exception as e:
                self.logger.error(f"Could not ssh {self.hostname}. Trying again until timeout is reached...")
                time.sleep(10)

        if not success:
            self.logger.error(f'Unable to make connection to {self.hostname}')
        return success

    def isalive(self):
        self.logger.info('Checking ssh connection is alive')
        self.run_cmd('\n', expect_ret=0)

    def close(self):
        self.scp.close()
        self.ssh_client.close()

    def disable_logging(self):
        self.logger.disabled = True

    def enable_logging(self):
        self.logger.disabled = False

    def run_cmd(self, cmd, expect_ret=None, expect_not_ret=None, expect_kw=None, expect_not_kw=None,
                expect_output=None, timeout=300, as_daemon=False):
        """run cmd with/without checking return status/keywords

        Arguments:
            cmd {string} -- cmd to run
            expect_ret {int} -- expected return status
            expect_not_ret {int} -- unexpected return status
            expect_kw {string} -- string expected in output
            expect_not_kw {string} -- string not expected in output
            expect_output {string} -- string exactly the same as output
            timeout {int} -- cmd timeout in seconds
            as_daemon {bool} -- run command in background with nohup

        Return:
            (return code, stdout, stderr) -- cmd return code, stdout and stderr output

        """
        self.logger.info("CMD: %s", cmd)
        assert self.ssh_client is not None, 'No connection made!'

        if as_daemon:
            self.ssh_client.exec_command(f"nohup {cmd} &")
            return

        stdin, stdout, stderr = self.ssh_client.exec_command(cmd, timeout=timeout)
        try:
            output = stdout.readlines()
            error = stderr.readlines()
        except socket.timeout:
            self.logger.error("ssh command timed out")
            raise SSHCmdTimeoutException()
        finally:
            stdin.close()
            stdout.close()
            stderr.close()

        status = stdout.channel.recv_exit_status()
        self.logger.info("CMD return code: %s" % status)
        self.logger.info("CMD stdout:")
        for line in output:
            self.logger.info("%s" % line.rstrip('\n'))
        output = ''.join(output).strip()
        self.logger.info("CMD stderr:")
        for line in error:
            self.logger.info("%s" % line.rstrip('\n'))
        error = ''.join(error).strip()

        if expect_ret is not None:
            assert status == expect_ret, f"expected return code {expect_ret} but got {status}"
        if expect_not_ret is not None:
            assert status != expect_not_ret, f"unexpected return code {status}"
        if expect_kw is not None:
            assert expect_kw in output, f"keyword {expect_kw} was not found in output"
        if expect_not_kw is not None:
            assert expect_not_kw not in output, f"unexpected keyword {expect_not_kw} was found in output"
        if expect_output is not None:
            assert expect_output == output, f'expected output "{expect_output}" but got "{output}"'

        return status, output, error

    def get(self, remote_path, local_path=None):
        if local_path is None:
            local_path = remote_path
        self.scp.get(remote_path, local_path)

    def kill_process(self, cmd):
        cmd = cmd.split(' ')[0]
        ret, pid, _ = self.run_cmd(f"pidof {cmd}")
        if ret != 0:
            self.logger.error(f"Could not find pid of {cmd}")
        self.run_cmd(f"kill {pid}")


class SSHClientTTY(SSHClient):

    def connect(self):
        super().connect()
        # request an interactive shell session on remote
        # shell size is huge to avoid \n and capture all lines
        self.shell = self.ssh_client.invoke_shell(width=10000, height=10000)
        self._recv() # read and discard welcome message
        return True

    def close(self):
        super().close()
        self.shell.close()

    def get(self, remote_path, local_path=None):
        raise NotImplemented()

    def kill_process(self, cmd):
        raise NotImplemented()

    def set_prompt_regex(self, prompt):
        self.prompt = prompt

    def _recv(self, timeout=20):
        self.shell.settimeout(1)
        timeout = datetime.datetime.today() + datetime.timedelta(seconds=timeout)
        out = ""
        while datetime.datetime.today() < timeout:
            try:
                out += self.shell.recv(65535).decode('utf-8')
            except socket.timeout:
                continue
            if re.search(self.prompt, out):
                # remove prompt from output
                out = re.sub(self.prompt, '', out)
                break
        return out

    @staticmethod
    def escape_ansi(line):
        ansi_escape = re.compile(r'\x1b(?:[@-Z\\-_=]|\[[0-?]*[ -/]*[@-~])')
        return ansi_escape.sub('', line)

    def run_cmd(self, cmd, timeout=10):
        """ Run command on remote in an interactive shell.
            Warning: it's best to run 1 command at a time
        """
        try:
            self.shell.recv(65535) # discard read buffer before sending new command
        except socket.timeout:
            pass
        ret = self.shell.send(f"{cmd}\n")
        if ret == 0:
            self.logger.error("could not send data: ssh channel is closed")
            raise Exception("ssh channel closed")
        out = self._recv()
        out = out.replace('\r', '')
        # truncate the command and \r\n at beginning of output
        if out.startswith(cmd):
            out = out[len(cmd):]
        return SSHClientTTY.escape_ansi(out.strip()).strip('\n')

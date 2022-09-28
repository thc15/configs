import logging
import signal
import threading
import asyncio
import time


class JtagSubprocessProtocol(asyncio.SubprocessProtocol):
    
    def __init__(self, logger):
        super(JtagSubprocessProtocol, self).__init__()
        self.logger = logger
    
    def pipe_data_received(self, fd, data):
        """ Processes stdout and stderr from jtag subprocess
        """
        logger = logging.getLogger('jtag')
        data = data.decode('ascii').replace('  ', '').replace('\r', '')
        
        def log_data(logger_f, data):
            for line in data.split('\n'):
                if line != '':
                    logger_f(line[:-1])

        log_data(logger.info if fd == 1 else logger.error, data)
    
    def connection_made(self, transport):
        self.transport = transport
        return super().connection_made(transport)
    
    def process_exited(self):
        self.logger.warning("Jtag subprocess exited")
        self.transport.close()
        return super().process_exited()


class JTAGLink(threading.Thread):
    
    def __init__(self, command):
        super(JTAGLink, self).__init__()
        self.command = command
        self.logger = logging.getLogger('jtag mgmt')
        self.interrupt_jtag = False
        self.linux_boot_done = False
        self.loop = asyncio.new_event_loop()
        asyncio.get_event_loop()
        asyncio.get_child_watcher().attach_loop(self.loop)
    
    def interrupt(self):
        """ Kill jtag subprocess and stop the asyncio loop. 
        """
        if not self.interrupt_jtag:
            self.interrupt_jtag = True
            self.logger.warning("Interrupt received. Stopping JTAG link.")
            self._kill_jtag()
            self.loop.stop()
            time.sleep(1)
    
    def _kill_jtag(self):
        try:
            self.process.send_signal(signal.SIGINT)
            self.process.close()
        except Exception:
            self.logger.info("Could not kill jtag process with PID=%i" % self.process.get_pid())
        
    def run(self):
        asyncio.set_event_loop(self.loop)
        self.logger.warning('Starting JTAG link')
        while not self.interrupt_jtag:
            coro = self.loop.subprocess_shell(lambda: JtagSubprocessProtocol(self.logger), "exec " + self.command)
            self.process, self.protocol = self.loop.run_until_complete(coro)
            self.loop.run_forever()
    
    def wait_for_linux_boot(self, minicom, welcome_msg, boot_timeout=90):
        """ Waits for Linux to boot by watching the minicom for a specific welcome message.

        Args:
            minicom (minicom): instance from minicom fixture
            welcome_msg (str): welcome message expected on the minicom once Linux has booted up
            boot_timeout (int, optional): Timeout. Defaults to 90.
        """
        if self.linux_boot_done:
            return
        self.logger.info('Waiting for Linux to boot...')
        msg_queue = minicom.get_last_messages()
        i = 0
        while len(msg_queue) == 0 or welcome_msg not in msg_queue.pop():
            if i > boot_timeout:
                self.logger.error("Timeout reached : Linux boot seems to have failed")
                self.interrupt()
                assert False, "Timeout reached : Linux boot seems to have failed"
            else:
                i += 1
                time.sleep(1)
        self.logger.info("Linux has booted up successfully")
        self.linux_boot_done = True

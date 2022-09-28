import enum
import pytest
import paramiko
from sqlalchemy.sql.sqltypes import Enum
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql.schema import ForeignKey
from sqlalchemy.orm import declarative_base
import re

from utils.parsers import KvxBoardDiagParser
from utils.utils import run_cmd


class Base:
    @classmethod
    def get_or_create(cls, session, **kwargs):
        instance = session.query(cls).filter_by(**kwargs).first()
        if instance:
            return instance
        else:
            return cls.create(session, **kwargs)

    @classmethod
    def create(cls, session, **kwargs):
        instance = cls(**kwargs)
        session.add(instance)
        session.commit()
        return instance


Base = declarative_base(cls=Base)


class EthernetCable(Base):
    __tablename__ = 'eth_cable'

    class Type(enum.Enum):
        copper = 0
        fiber = 1
        other = 2
        not_found = 3
    
    SFF8636_TRANS_TYPE = {
        Type.copper: [x << 4 for x in range(10, 16)],
        Type.fiber: [x << 4 for x in range(0, 8)] + [(9 << 4)],
        Type.other: [(8 << 4)]
    }

    id = Column(Integer, primary_key=True, autoincrement=True)
    type = Column(Enum(Type))
    vendor = Column(String)
    pn = Column(String, comment='product number')
    rev = Column(String, comment='revision')
    
    @classmethod
    def detect_hw(cls, session, itf):
        """ Detect ethernet cables

        Args:
            session : database session
            itf (str): mppa interface
        """
        sn = itf.get_cable_sn()
        pn = itf.get_cable_pn()
        rev = itf.get_cable_rev()
        
        type_code = itf.get_cable_type()
        if type_code is not None:
            type = [x for x,y in cls.SFF8636_TRANS_TYPE.items() if type_code in y][0]
        else:
            type = cls.Type.not_found
        
        vendor = itf.get_cable_vendor()
        pytest.html_report_metadata[f'Cable {itf}'] = f"{vendor} {type} {pn}  (SN:{sn})"
        el = cls.get_or_create(session=session, type=type, vendor=vendor, rev=rev, pn=pn)
        sn_id = EthernetCableSN.add(session=session, eth_cable_id=el.id, sn=sn)
        return el.id, sn_id


class EthernetCableSN(Base):
    __tablename__ = 'eth_cable_sn'

    id = Column(Integer, primary_key=True, autoincrement=True)
    eth_cable = Column(Integer, ForeignKey('eth_cable.id'))
    sn = Column(String, comment='serial number')

    @classmethod
    def add(cls, session, eth_cable_id, sn):
        el = cls.get_or_create(session=session, eth_cable=eth_cable_id, sn=sn)
        return el.id


class LinkPartner(Base):
    __tablename__ = 'link_partner'
    
    class Type(enum.Enum):
        nic = 0
        switch = 1

    id = Column(Integer, primary_key=True, autoincrement=True)
    type = Column(Enum(Type))
    vendor = Column(String)
    description = Column(String) # description of the product given by lspci
    hw_version = Column(String)
    fw_version = Column(String)
    hostname = Column(String, nullable=True)
    group = Column(Integer) # for grouping together identical link partners in the report. Must be filled manually
    # mac_addr_1 = Column(String, comment='MAC address of first interface')
    # mac_addr_2 = Column(String, nullable=True, comment='MAC address of second interface')
    
    @classmethod
    def detect_nic(cls, session, itf, run_cmd):
        _, ethtool_i_out, _ = run_cmd(f'ethtool -i {itf}', expect_ret=0)
        lp_pci_id = re.search(r'bus-info: 0000:([0-9:.]+)\n', ethtool_i_out).group(1)
        _, out2, _ = run_cmd(f'lspci | grep {lp_pci_id}', expect_ret=0)
        desc = out2.replace(lp_pci_id, "")
        pytest.html_report_metadata['NIC'] = desc
        hw_version = re.search(r'version: ([0-9a-zA-Z.-]+)\n', ethtool_i_out).group(1)
        fw_version = re.search(r'firmware-version: ([0-9a-zA-Z.-/, ]+)(?:[ \n])', ethtool_i_out).group(1)
        el = cls.get_or_create(session=session, type=LinkPartner.Type.nic, description=desc,
                               fw_version=fw_version, hw_version=hw_version)
        return el.id
    
    @classmethod
    def detect_switch(cls, session, switch):
        vendor, version = switch.get_switch_vendor_version()
        pytest.html_report_metadata['Switch'] = f"Vendor:{vendor}  Version:{version}  Hostname:{switch.mgmt_ip}"
        hw_version = switch.hw_version()
        el = cls.get_or_create(session=session, type=LinkPartner.Type.switch, vendor=vendor, 
                               hostname=switch.mgmt_ip, fw_version=version, 
                               hw_version=hw_version)
        return el.id


class LinkParner_Groups(Base):
    """ Used for grouping identical link partners together in the final report.
        The table must be filled manually in the DB.
    """
    __tablename__ = 'lp_groups'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String)


class K200(Base):
    __tablename__ = 'k200'

    id = Column(Integer, primary_key=True, autoincrement=True)
    type = Column(String) # e.g. k200_rev2
    sn = Column(String, comment='serial number')
    config = Column(String)
    
    _cache = {}

    class NoKvxEnvironnement(Exception):
        pass

    @classmethod
    def kvx_board_diag(cls, restart=False):
        restart = '--restart' if restart else ''
        ret, out_kvx_diag, _ = run_cmd(f'kvx-board-diag {restart}')
        if ret != 0:
            raise K200.NoKvxEnvironnement()

        parser = KvxBoardDiagParser(out_kvx_diag)
        config = parser.k200_config()
        sn = parser.k200_sn()
        board = parser.k200_board_type()
        rev = parser.k200_board_rev()
        cls._cache = {'config': config, 'sn': sn, 'board': board, 'rev': rev}
        return config, sn, board, rev
    
    @classmethod
    def detect_hw(cls, session):
        if not cls._cache:
            cls.kvx_board_program()
        el = cls.get_or_create(session=session, type=f"{cls._cache['board']}_{cls._cache['rev']}", 
                               sn=cls._cache['sn'], config=cls._cache['config'])
        return el.id


class AcceptanceRun(Base):
    __tablename__ = 'acceptance_run'

    class Autoneg(enum.Enum):
        on = 'on'
        off = 'off'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    test = Column(Integer, ForeignKey('acceptance_test.id'))
    config = Column(Integer, ForeignKey('acceptance_config.id'))
    mppa_interface = Column(String)
    cable_sn = Column(Integer, ForeignKey('eth_cable_sn.id'))


class TestScenarioParam(Base):
    __tablename__ = 'test_scenario_param'

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String)
    value = Column(String, nullable=True)

    @classmethod
    def add(cls, session, conf, run_id):
        param_ids = []
        for k,v in conf.items():
            if isinstance(v, dict):
                v = ','.join([f'{x}={y}' for x,y in v.items()])
            id = cls.get_or_create(session, name=k, value=v).id
            param_ids.append(id)
            Run_TSParam.create(session, run=run_id, tsp=id)
        return param_ids


class Run_TSParam(Base): # many-to-many relationship table between AcceptanceRun and TestScenarioParam
    __tablename__ = 'run_tsparam'

    id = Column(Integer, primary_key=True, autoincrement=True)
    run = Column(Integer, ForeignKey('acceptance_run.id'))
    tsp = Column(Integer, ForeignKey('test_scenario_param.id'))


class TestCaseResult(Base):
    __tablename__ = 'testcase_result'

    id = Column(Integer, primary_key=True, autoincrement=True)
    label = Column(String, comment="Label of the test case")
    success = Column(Integer, default=0, comment="Number of iterations successul")
    total = Column(Integer, default=0, comment="Total number of iterations")

    @classmethod
    def add_results(cls, session, results, run_id):
        results_ids = []
        for label,res in results.items():
            id = cls.get_or_create(session, label=label, success=res['success'], total=res['total']).id
            Run_TCResult.create(session=session, run=run_id, tcr=id)
            results_ids.append(id)
        return results_ids


class Run_TCResult(Base): # many-to-many relationship table between AcceptanceRun and TestCaseResult
    __tablename__ = 'run_tcresult'

    id = Column(Integer, primary_key=True, autoincrement=True)
    run = Column(Integer, ForeignKey('acceptance_run.id'))
    tcr = Column(Integer, ForeignKey('testcase_result.id'))


class AcceptanceConfig(Base):
    __tablename__ = 'acceptance_config'

    id = Column(Integer, primary_key=True, autoincrement=True)
    k200 = Column(Integer, ForeignKey('k200.id'))
    link_partner = Column(Integer, ForeignKey('link_partner.id'))
    cable = Column(Integer, ForeignKey('eth_cable.id'))
    
    @classmethod
    def add(cls, session, k200, lp, cable):
        el = cls.get_or_create(session=session, k200=k200, link_partner=lp, cable=cable)
        return el.id


class AcceptanceTest(Base):
    __tablename__ = 'acceptance_test'

    id = Column(Integer, primary_key=True, autoincrement=True)
    linux_release = Column(String)
    date_time = Column(DateTime)
    git_branch = Column(String)
    git_last_commit = Column(String)
    vmlinux_sha1sum = Column(String)
    iterations = Column(Integer)
    
    @classmethod
    def add(cls, session, linux_release, vmlinux_path, iterations):
        _, git_branch, _ = run_cmd('git rev-parse --abbrev-ref HEAD', expect_ret=0)
        _, git_commit, _ = run_cmd('git rev-parse HEAD')
        _, vmlinux_sum, _ = run_cmd(f'sha1sum {vmlinux_path}')
        test = cls.get_or_create(session=session, linux_release=linux_release, iterations=iterations,
                                 date_time=pytest.start_time, vmlinux_sha1sum=vmlinux_sum,
                                 git_branch=git_branch, git_last_commit=git_commit)            
        return test.id

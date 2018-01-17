# --- BEGIN COPYRIGHT BLOCK ---
# Copyright (C) 2017 Red Hat, Inc.
# All rights reserved.
#
# License: GPL (version 3 or any later version).
# See LICENSE for details.
# --- END COPYRIGHT BLOCK ---
#
import pytest
from lib389.idm.user import TEST_USER_PROPERTIES, UserAccounts
from lib389.utils import *
from lib389.topologies import topology_m2 as topo_m2, TopologyMain
from lib389._constants import *
from . import get_repl_entries
from lib389.idm.organisationalunit import OrganisationalUnits
from lib389.idm.user import UserAccount
from lib389.replica import Replicas, ReplicationManager

NEW_SUFFIX_NAME = 'test_repl'
NEW_SUFFIX = 'o={}'.format(NEW_SUFFIX_NAME)
NEW_BACKEND = 'repl_base'

DEBUGGING = os.getenv("DEBUGGING", default=False)
if DEBUGGING:
    logging.getLogger(__name__).setLevel(logging.DEBUG)
else:
    logging.getLogger(__name__).setLevel(logging.INFO)
log = logging.getLogger(__name__)


@pytest.fixture()
def test_entry(topo_m2, request):
    """Add test entry using UserAccounts"""

    log.info('Adding a test entry user')
    users = UserAccounts(topo_m2.ms["master1"], DEFAULT_SUFFIX)
    tuser = users.ensure_state(properties=TEST_USER_PROPERTIES)
    return tuser


def test_double_delete(topo_m2, test_entry):
    """Check that double delete of the entry doesn't crash server

    :id: 3496c82d-636a-48c9-973c-2455b12164cc
    :setup: Two masters replication setup, a test entry
    :steps:
        1. Delete the entry on the first master
        2. Delete the entry on the second master
        3. Check that server is alive
    :expectedresults:
        1. Entry should be successfully deleted from first master
        2. Entry should be successfully deleted from second aster
        3. Server should me alive
    """

    m1 = topo_m2.ms["master1"]
    m2 = topo_m2.ms["master2"]

    repl = ReplicationManager(DEFAULT_SUFFIX)
    repl.disable_to_master(m1, [m2])
    repl.disable_to_master(m2, [m1])

    log.info('Deleting entry {} from master1'.format(test_entry.dn))
    topo_m2.ms["master1"].delete_s(test_entry.dn)

    log.info('Deleting entry {} from master2'.format(test_entry.dn))
    topo_m2.ms["master2"].delete_s(test_entry.dn)

    repl.enable_to_master(m2, [m1])
    repl.enable_to_master(m1, [m2])

    repl.test_replication(m1, m2)
    repl.test_replication(m2, m1)

@pytest.mark.bz1506831
def test_repl_modrdn(topo_m2):
    """Test that replicated MODRDN does not break replication

    :id: a3e17698-9eb4-41e0-b537-8724b9915fa6
    :setup: Two masters replication setup
    :steps:
        1. Add 3 test OrganisationalUnits A, B and C
        2. Add 1 test user under OU=A
        3. Add same test user under OU=B
        4. Stop Replication
        5. Apply modrdn to M1 - move test user from OU A -> C
        6. Apply modrdn on M2 - move test user from OU B -> C
        7. Start Replication
        8. Check that there should be only one test entry under ou=C on both masters
        9. Check that the replication is working fine both ways M1 <-> M2
    :expectedresults:
        1. This should pass
        2. This should pass
        3. This should pass
        4. This should pass
        5. This should pass
        6. This should pass
        7. This should pass
        8. This should pass
        9. This should pass
    """

    master1 = topo_m2.ms["master1"]
    master2 = topo_m2.ms["master2"]

    repl = ReplicationManager(DEFAULT_SUFFIX)

    log.info("Add test entries - Add 3 OUs and 2 same users under 2 different OUs")
    OUs = OrganisationalUnits(master1, DEFAULT_SUFFIX)
    OU_A = OUs.create(properties={
        'ou': 'A',
        'description': 'A',
    })
    OU_B = OUs.create(properties={
        'ou': 'B',
        'description': 'B',
    })
    OU_C = OUs.create(properties={
        'ou': 'C',
        'description': 'C',
    })

    users = UserAccounts(master1, DEFAULT_SUFFIX, rdn='ou={}'.format(OU_A.rdn))
    tuser_A = users.create(properties=TEST_USER_PROPERTIES)

    users = UserAccounts(master1, DEFAULT_SUFFIX, rdn='ou={}'.format(OU_B.rdn))
    tuser_B = users.create(properties=TEST_USER_PROPERTIES)

    repl.test_replication(master1, master2)
    repl.test_replication(master2, master1)

    log.info("Stop Replication")
    topo_m2.pause_all_replicas()

    log.info("Apply modrdn to M1 - move test user from OU A -> C")
    master1.rename_s(tuser_A.dn,'uid=testuser1',newsuperior=OU_C.dn,delold=1)

    log.info("Apply modrdn on M2 - move test user from OU B -> C")
    master2.rename_s(tuser_B.dn,'uid=testuser1',newsuperior=OU_C.dn,delold=1)

    log.info("Start Replication")
    topo_m2.resume_all_replicas()

    log.info("Wait for sometime for repl to resume")
    repl.test_replication(master1, master2)
    repl.test_replication(master2, master1)

    log.info("Check that there should be only one test entry under ou=C on both masters")
    users = UserAccounts(master1, DEFAULT_SUFFIX, rdn='ou={}'.format(OU_C.rdn))
    assert len(users.list()) == 1

    users = UserAccounts(master2, DEFAULT_SUFFIX, rdn='ou={}'.format(OU_C.rdn))
    assert len(users.list()) == 1

    log.info("Check that the replication is working fine both ways, M1 <-> M2")
    repl.test_replication(master1, master2)
    repl.test_replication(master2, master1)



def test_password_repl_error(topo_m2, test_entry):
    """Check that error about userpassword replication is properly logged

    :id: 714130ff-e4f0-4633-9def-c1f4b24abfef
    :setup: Four masters replication setup, a test entry
    :steps:
        1. Change userpassword on the first master
        2. Restart the servers to flush the logs
        3. Check the error log for an replication error
    :expectedresults:
        1. Password should be successfully changed
        2. Server should be successfully restarted
        3. There should be no replication errors in the error log
    """

    m1 = topo_m2.ms["master1"]
    m2 = topo_m2.ms["master2"]
    TEST_ENTRY_NEW_PASS = 'new_pass'

    log.info('Clean the error log')
    m2.deleteErrorLogs()

    log.info('Set replication loglevel')
    m2.setLogLevel(LOG_REPLICA)

    log.info('Modifying entry {} - change userpassword on master 1'.format(test_entry.dn))

    test_entry.set('userpassword', TEST_ENTRY_NEW_PASS)

    repl = ReplicationManager(DEFAULT_SUFFIX)
    repl.wait_for_replication(m1, m2)

    log.info('Restart the servers to flush the logs')
    for num in range(1, 3):
        topo_m2.ms["master{}".format(num)].restart()

    try:
        log.info('Check that password works on master 2')
        test_entry_m2 = UserAccount(m2, test_entry.dn)
        test_entry_m2.bind(TEST_ENTRY_NEW_PASS)

        log.info('Check the error log for the error with {}'.format(test_entry.dn))
        assert not m2.ds_error_log.match('.*can.t add a change for {}.*'.format(test_entry.dn))
    finally:
        log.info('Set the default loglevel')
        m2.setLogLevel(LOG_DEFAULT)


def test_invalid_agmt(topo_m2):
    """Test adding that an invalid agreement is properly rejected and does not crash the server

    :id: 6c3b2a7e-edcd-4327-a003-6bd878ff722b
    :setup: Four masters replication setup
    :steps:
        1. Add invalid agreement (nsds5ReplicaEnabled set to invalid value)
        2. Verify the server is still running
    :expectedresults:
        1. Invalid repl agreement should be rejected
        2. Server should be still running
    """

    m1 = topo_m2.ms["master1"]
    m2 = topo_m2.ms["master2"]

    repl = ReplicationManager(DEFAULT_SUFFIX)

    replicas = Replicas(m1)
    replica = replicas.get(DEFAULT_SUFFIX)
    agmts = replica.get_agreements()

    # Add invalid agreement (nsds5ReplicaEnabled set to invalid value)
    with pytest.raises(ldap.UNWILLING_TO_PERFORM):
        agmts.create(properties={
            'cn': 'whatever',
            'nsDS5ReplicaRoot': DEFAULT_SUFFIX,
            'nsDS5ReplicaBindDN': 'cn=replication manager,cn=config',
            'nsDS5ReplicaBindMethod': 'simple' ,
            'nsDS5ReplicaTransportInfo': 'LDAP',
            'nsds5replicaTimeout': '5',
            'description': "test agreement",
            'nsDS5ReplicaHost': m2.host,
            'nsDS5ReplicaPort': str(m2.port),
            'nsDS5ReplicaCredentials': 'whatever',
            'nsds5ReplicaEnabled': 'YEAH MATE, LETS REPLICATE'
        })

    # Verify the server is still running
    repl = ReplicationManager(DEFAULT_SUFFIX)
    repl.test_replication(m1, m2)
    repl.test_replication(m2, m1)

if __name__ == '__main__':
    # Run isolated
    # -s for DEBUG mode
    CURRENT_FILE = os.path.realpath(__file__)
    pytest.main("-s %s" % CURRENT_FILE)

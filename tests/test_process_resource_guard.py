"""Resource/ownership controls; none qualifies a compiler or package."""
import json
import os
from pathlib import Path
import signal
import ctypes
import shutil
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

from gambit_smp.process_observation import capture
from gambit_smp.task_processes import stop_run


class GroupResourceTests(unittest.TestCase):
    def test_reaped_or_reused_capture_leader_is_never_signalled(self):
        from types import SimpleNamespace
        from gambit_smp.process_observation import terminate_capture
        owner=dict(pid=123,pgid=123,startSeconds=1,startMicroseconds=1)
        target=SimpleNamespace(pid=123,returncode=0,spawn_birth={'process':owner})
        with patch('gambit_smp.process_identity.process',return_value=dict(owner,startSeconds=2)),patch('os.killpg') as kill:
            terminate_capture(target)
        kill.assert_not_called()
        target=SimpleNamespace(pid=123,returncode=0)
        with patch('gambit_smp.process_identity.process',return_value=None),patch('os.killpg') as kill:
            terminate_capture(target)
        kill.assert_not_called()

    def test_incomplete_drain_retains_raw_prefix_and_bounds_cleanup(self):
        from unittest.mock import Mock
        from gambit_smp.process_observation import drain_capture
        target=Mock()
        target.communicate.side_effect=subprocess.TimeoutExpired(['child'],5,output=b'\xffprefix',stderr=b'\x80error')
        out,err,complete,raw_out,raw_err=drain_capture(target,True)
        self.assertFalse(complete)
        self.assertEqual(b'\xffprefix',raw_out);self.assertEqual(b'\x80error',raw_err)
        self.assertEqual('\\xffprefix',out)
        target.communicate.assert_called_once_with(timeout=5)
        target.wait.assert_called_once_with(timeout=1)
        target.stdout.close.assert_called_once();target.stderr.close.assert_called_once()

    def test_timeout_stops_child_in_another_group_of_the_owned_session(self):
        import time
        child='import time; print("CHILD-STARTED",flush=True); time.sleep(20)'
        source=('import subprocess,sys,time,os; '
                'child=subprocess.Popen([sys.executable,"-c",'+repr(child)+'],preexec_fn=os.setpgrp); '
                'print(child.pid,flush=True); time.sleep(20)')
        start=time.monotonic()
        with TemporaryDirectory() as temp:
            events=[]
            def record(event,token,fields):events.append((event,fields))
            record.root=Path(temp).resolve();record.spawn_root=record.root/'spawns'
            result=capture([sys.executable,'-c',source],Path.cwd(),1,dict(os.environ),recorder=record)
            self.assertTrue(any(event=='started' and fields.get('birth') for event,fields in events))
        self.assertTrue(result.timeout)
        self.assertTrue(result.streams_complete)
        self.assertLess(time.monotonic()-start,5)
        from gambit_smp.process_identity import process
        observed=process(int(result.stdout.splitlines()[0]))
        self.assertTrue(observed is None or observed.get('status')==5)

    def test_session_census_includes_new_group_without_querying_other_sessions(self):
        from gambit_smp.process_identity import groups_memory
        owner=dict(pid=7,pgid=7,startSeconds=1,startMicroseconds=2)
        child=dict(pid=8,pgid=8,startSeconds=2,startMicroseconds=3)
        with patch('gambit_smp.process_identity.sys.platform','darwin'),patch(
                'gambit_smp.process_identity.pids',side_effect=lambda uid=None,**kw:[7] if kw else [7,8,9]),patch(
                'gambit_smp.process_identity.os.getsid',side_effect=lambda pid:7 if pid in (7,8) else 9),patch(
                'gambit_smp.process_identity.process',side_effect={7:owner,8:child}.get) as identity,patch(
                'gambit_smp.process_identity.resident_bytes',return_value=10):
            result=groups_memory({7},sessions={7:owner})
        self.assertEqual(20,result['rssBytes'])
        self.assertEqual([7,8],[row['process']['pid'] for row in result['members']])
        self.assertEqual(owner,result['members'][1]['sessionOwnerBirth'])
        self.assertNotIn(9,[call.args[0] for call in identity.call_args_list])
        self.assertFalse(result['detachedSessionsCovered'])

    def test_session_transition_does_not_return_a_partial_census(self):
        from gambit_smp.process_identity import CensusChanged, groups_memory
        owner=dict(pid=7,pgid=7,startSeconds=1,startMicroseconds=2)
        with patch('gambit_smp.process_identity.sys.platform','darwin'),patch(
                'gambit_smp.process_identity.pids',return_value=[7]),patch(
                'gambit_smp.process_identity.os.getsid',side_effect=[7,8]),patch(
                'gambit_smp.process_identity.process',return_value=owner),patch(
                'gambit_smp.process_identity.resident_bytes',return_value=10):
            with self.assertRaises(CensusChanged) as caught:
                groups_memory({7},sessions={7:owner})
        self.assertEqual(dict(pid=7,previousSession=7,currentSession=8),caught.exception.observation)

    def test_census_transition_restarts_boundedly_and_retains_observation(self):
        from gambit_smp.process_identity import CensusChanged
        from gambit_smp.task_processes import memory_sample
        with TemporaryDirectory() as temp, patch('gambit_smp.process_identity.groups_memory',
                side_effect=[CensusChanged(7,7,8),dict(rssBytes=10,footprintBytes=9,members=[])]) as sample:
            result=memory_sample(Path(temp),'task','run',footprint=True)
        self.assertEqual(2,sample.call_count)
        self.assertEqual(9,result['footprintBytes'])
        self.assertEqual([dict(pid=7,previousSession=7,currentSession=8)],result['censusRestarts'])

    def test_perpetual_census_transition_and_unreadable_resource_still_refuse(self):
        from gambit_smp.process_identity import CensusChanged
        from gambit_smp.task_processes import memory_sample
        with TemporaryDirectory() as temp, patch('gambit_smp.process_identity.groups_memory',
                side_effect=CensusChanged(7,7,8)) as sample:
            with self.assertRaises(CensusChanged):memory_sample(Path(temp),'task','run',footprint=True)
            self.assertEqual(3,sample.call_count)
        with TemporaryDirectory() as temp, patch('gambit_smp.process_identity.groups_memory',
                side_effect=PermissionError('unreadable live process')) as sample:
            with self.assertRaises(PermissionError):memory_sample(Path(temp),'task','run',footprint=True)
            self.assertEqual(1,sample.call_count)

    if sys.platform == 'darwin':
        def test_native_sdk_layout_and_live_footprint(self):
            from gambit_smp.process_identity import RusageInfoV0,footprint_bytes,process
            compiler=shutil.which('gcc-16')
            self.assertIsNotNone(compiler,'explicit C23 compiler required for SDK ABI calibration')
            code=('#include <stdio.h>\n#include <stddef.h>\n#include <sys/resource.h>\n'
                  'int main(void){printf("%zu %zu\\n",sizeof(struct rusage_info_v0),'
                  'offsetof(struct rusage_info_v0,ri_phys_footprint));}\n')
            with TemporaryDirectory() as temp:
                target=Path(temp)/'abi'
                sdk=subprocess.check_output(['/usr/bin/xcrun','--show-sdk-path'],text=True,timeout=5).strip()
                compilation=subprocess.run([compiler,'-std=c23','-B/usr/bin/','-isysroot',sdk,
                    '-x','c','-','-o',str(target)],input=code,text=True,capture_output=True,timeout=10)
                self.assertEqual(0,compilation.returncode,compilation.stderr)
                observed=subprocess.check_output([target],text=True,timeout=3).split()
            self.assertEqual([ctypes.sizeof(RusageInfoV0),RusageInfoV0.phys_footprint.offset],
                             [int(x) for x in observed])
            self.assertGreater(footprint_bytes(process(os.getpid())),0)

    def test_footprint_is_not_inferred_from_resident_bytes(self):
        from gambit_smp.process_identity import groups_memory
        info=dict(pid=8,pgid=7,startSeconds=1,startMicroseconds=2)
        with patch('gambit_smp.process_identity.sys.platform','darwin'),patch(
                'gambit_smp.process_identity.pids',return_value=[8]),patch(
                'gambit_smp.process_identity.process',return_value=info),patch(
                'gambit_smp.process_identity.resident_bytes',return_value=1000),patch(
                'gambit_smp.process_identity.footprint_bytes',return_value=10):
            result=groups_memory({7},footprint=True)
        self.assertEqual(1000,result['rssBytes'])
        self.assertEqual(10,result['footprintBytes'])
        self.assertFalse(result['physicalMemoryQuotaEquivalent'])

    def test_unavailable_footprint_is_not_a_zero_charge(self):
        from gambit_smp.process_identity import groups_memory
        with patch('gambit_smp.process_identity.sys.platform','darwin'),patch(
                'gambit_smp.process_identity.pids',return_value=[8]),patch(
                'gambit_smp.process_identity.process',return_value=dict(pid=8,pgid=7)),patch(
                'gambit_smp.process_identity.resident_bytes',return_value=1000),patch(
                'gambit_smp.process_identity.footprint_bytes',side_effect=OSError('ledger unavailable')):
            with self.assertRaisesRegex(OSError,'ledger unavailable'):
                groups_memory({7},footprint=True)

    def test_kernel_group_census_does_not_query_unrelated_protected_pids(self):
        from gambit_smp.process_identity import groups_memory
        info=dict(pid=8,pgid=7,startSeconds=1,startMicroseconds=2)
        with patch('gambit_smp.process_identity.sys.platform','darwin'),patch(
                'gambit_smp.process_identity.pids',return_value=[8]) as census,patch(
                'gambit_smp.process_identity.process',return_value=info) as identity,patch(
                'gambit_smp.process_identity.resident_bytes',return_value=10):
            result=groups_memory({7})
        census.assert_called_once_with(pgid=7)
        identity.assert_called_once_with(8)
        self.assertEqual(10,result['rssBytes'])
        self.assertEqual('sum-process-rss',result['metric'])
        self.assertFalse(result['physicalMemoryQuotaEquivalent'])
        self.assertFalse(result['sharedPagesDeduplicated'])
        self.assertFalse(result['atomicSnapshot'])

    def test_pid_deduplication_is_not_shared_page_deduplication(self):
        from gambit_smp.process_identity import groups_memory
        infos={8:dict(pid=8,pgid=7),9:dict(pid=9,pgid=11)}
        with patch('gambit_smp.process_identity.sys.platform','darwin'),patch(
                'gambit_smp.process_identity.pids',return_value=[8,9]),patch(
                'gambit_smp.process_identity.process',side_effect=infos.get),patch(
                'gambit_smp.process_identity.resident_bytes',return_value=100):
            result=groups_memory({7,11})
        self.assertEqual(2,len(result['members']))
        self.assertEqual(200,result['rssBytes'])
        self.assertFalse(result['physicalMemoryQuotaEquivalent'])

    def test_invalid_resource_request_cannot_spawn(self):
        with patch('gambit_smp.process_observation._task_spawn') as spawn:
            for cap in (0,-1,True,1.5):
                with self.assertRaisesRegex(ValueError,'positive integer'):
                    capture(['unused'],'.',1,{},rss_limit_bytes=cap)
            with self.assertRaisesRegex(ValueError,'fixed wall-clock'):
                capture(['unused'],'.',1,{},rss_limit_bytes=1,progress=lambda *_:0)
            spawn.assert_not_called()

    def test_gradual_growth_is_guarded_with_phase_boundary(self):
        source=('import time; chunks=[]\n'
                'for index in range(16):\n'
                ' chunks.append(bytearray(8*1024*1024)); print(index,flush=True); time.sleep(.15)\n'
                'time.sleep(10)')
        samples=[]; boundaries=[]
        result=capture([sys.executable,'-c',source],Path.cwd(),5,dict(os.environ),
                       rss_limit_bytes=64*1024*1024,
                       recorder=lambda kind,token,fields: samples.append(fields) if kind=='resource-sample' else None,
                       boundary=lambda out,err: boundaries.append(out))
        self.assertTrue(result.rss_limit_exceeded)
        self.assertFalse(result.timeout)
        self.assertGreater(result.peak_group_rss_bytes,64*1024*1024)
        self.assertGreaterEqual(len(samples),3)
        self.assertLess(samples[0]['resourceSample']['rssBytes'],64*1024*1024)
        peaks=[sample['peakGroupRssBytes'] for sample in samples]
        self.assertEqual(sorted(peaks),peaks)
        self.assertEqual(list(range(1,len(samples)+1)),
                         [sample['resourceSampleSequence'] for sample in samples])
        self.assertGreater(peaks[-1],peaks[0])
        self.assertEqual(result.peak_group_rss_bytes,peaks[-1])
        self.assertTrue(any(value.strip() for value in boundaries))
        self.assertTrue(result.group_quiescent)

    def test_real_group_memory_includes_child_and_limit_aborts(self):
        child='import time; data=bytearray(32*1024*1024); time.sleep(10)'
        source=('import subprocess,sys,time; child=subprocess.Popen([sys.executable,"-c",'+repr(child)+']); '
                'print(child.pid,flush=True); data=bytearray(32*1024*1024); time.sleep(10)')
        result=capture([sys.executable,'-c',source],Path.cwd(),5,dict(os.environ),
                       rss_limit_bytes=64*1024*1024)
        self.assertTrue(result.rss_limit_exceeded)
        self.assertFalse(result.timeout)
        self.assertNotEqual(0,result.exit)
        self.assertGreater(result.peak_group_rss_bytes,64*1024*1024)
        from gambit_smp.process_identity import process
        child_pid=int(result.stdout.strip())
        observed=process(child_pid)
        self.assertTrue(observed is None or observed.get('status')==5)

    def test_unavailable_live_measurement_is_not_zero_and_child_is_stopped(self):
        with patch('gambit_smp.process_identity.group_memory',side_effect=OSError('RSS unavailable')):
            with self.assertRaisesRegex(OSError,'RSS unavailable'):
                capture([sys.executable,'-c','import time;time.sleep(10)'],Path.cwd(),3,
                        dict(os.environ),rss_limit_bytes=64*1024*1024)


class ExactRunStopTests(unittest.TestCase):
    def test_nested_cleanup_refuses_missing_root_group(self):
        self.record()
        with patch('os.killpg') as kill:
            result = stop_run(self.root, 'darwin-acceleration', 'run1', root_group=124)
        kill.assert_not_called()
        self.assertEqual(124, result['unresolved'][0]['pgid'])

    def test_nested_cleanup_keeps_provider_and_sibling_groups(self):
        self.record()
        identities = {123: self.birth}
        for group, parent in ((124, 123), (125, 124), (126, 123)):
            identity = dict(pid=group, pgid=group, startSeconds=group, startMicroseconds=0)
            identities[group] = identity
            row = dict(task='darwin-acceleration', run='run1', token=str(group), pgid=group,
                       birth=dict(bootId='boot', process=identity),
                       spawnProtocol=dict(parent=dict(pgid=parent)))
            (self.folder / (str(group) + '.json')).write_text(json.dumps(row))
        with patch('gambit_smp.process_identity.process', side_effect=identities.get), \
             patch('gambit_smp.process_identity.boot_id', return_value='boot'), \
             patch('gambit_smp.task_processes.observe_group', return_value={'result': 'present'}), \
             patch('os.killpg') as kill:
            result = stop_run(self.root, 'darwin-acceleration', 'run1', root_group=124)
        self.assertEqual({124, 125}, {call.args[0] for call in kill.call_args_list})
        self.assertEqual([], result['unresolved'])

    def test_nested_group_requires_session_and_birth_witness(self):
        self.record(groupObservation={'result':'absent'})
        member=dict(pid=125,pgid=124,startSeconds=11,startMicroseconds=21)
        anchor=dict(process=member,sessionId=123,sessionOwnerBirth=self.birth)
        with self.observe(member),patch('os.getsid',return_value=123),patch('os.killpg') as kill:
            result=stop_run(self.root,'darwin-acceleration','run1',anchors=[anchor])
        kill.assert_called_once_with(124,signal.SIGKILL)
        self.assertFalse(result['unresolved'])
        with self.observe(dict(member,startSeconds=99)),patch('os.getsid',return_value=123),patch('os.killpg') as kill:
            result=stop_run(self.root,'darwin-acceleration','run1',anchors=[anchor])
        kill.assert_not_called();self.assertTrue(result['unresolved'])
        with self.observe(member),patch('os.getsid',return_value=999),patch('os.killpg') as kill:
            result=stop_run(self.root,'darwin-acceleration','run1',anchors=[anchor])
        kill.assert_not_called();self.assertTrue(result['unresolved'])

    def setUp(self):
        self.tmp=TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name);self.folder=self.root/'.state/task-processes/darwin-acceleration/run1'
        self.folder.mkdir(parents=True)
        self.birth=dict(pid=123,pgid=123,startSeconds=10,startMicroseconds=20)

    def record(self,**extra):
        row=dict(task='darwin-acceleration',run='run1',token='token1',pgid=123,
                 birth=dict(bootId='boot',process=self.birth),**extra)
        (self.folder/'token1.json').write_text(json.dumps(row))

    def observe(self,current):
        return patch.multiple('gambit_smp.process_identity',process=lambda _:current,boot_id=lambda:'boot')

    def test_current_birth_is_stopped(self):
        self.record()
        with self.observe(self.birth),patch('gambit_smp.task_processes.observe_group',return_value={'result':'present'}),patch('os.killpg') as kill:
            result=stop_run(self.root,'darwin-acceleration','run1')
        kill.assert_called_once_with(123,signal.SIGKILL)
        self.assertEqual([],result['unresolved'])

    def test_reused_birth_is_never_signalled(self):
        self.record()
        with self.observe(dict(self.birth,startSeconds=99)),patch('gambit_smp.task_processes.observe_group',return_value={'result':'present'}),patch('os.killpg') as kill:
            result=stop_run(self.root,'darwin-acceleration','run1')
        kill.assert_not_called();self.assertEqual(1,len(result['unresolved']))

    def test_dead_leader_requires_attested_live_member(self):
        member=dict(pid=124,pgid=123,startSeconds=11,startMicroseconds=21)
        self.record(resourceSample={'members':[dict(process=member,rssBytes=10)]})
        with patch('gambit_smp.process_identity.process',side_effect=lambda pid:member if pid==124 else None),patch('gambit_smp.process_identity.boot_id',return_value='boot'),patch('gambit_smp.task_processes.observe_group',return_value={'result':'present'}),patch('os.killpg') as kill:
            result=stop_run(self.root,'darwin-acceleration','run1')
        kill.assert_called_once_with(123,signal.SIGKILL);self.assertFalse(result['unresolved'])

    def test_retired_group_does_not_claim_a_reused_number(self):
        self.record(groupObservation={'result':'absent'})
        with patch('os.killpg') as kill:
            self.assertEqual(dict(stopped=[],unresolved=[]),stop_run(self.root,'darwin-acceleration','run1'))
        kill.assert_not_called()

    def test_other_execution_is_not_touched(self):
        self.record()
        with patch('os.killpg') as kill:
            self.assertEqual(dict(stopped=[],unresolved=[]),stop_run(self.root,'darwin-acceleration','other'))
        kill.assert_not_called()

    def test_nested_descendant_memory_sample_charges_compiler_sessions(self):
        from gambit_smp.task_processes import memory_sample
        self.record()
        identities = {123: self.birth}
        for group, parent in ((124, 123), (125, 124), (126, 123)):
            identity = dict(pid=group, pgid=group, startSeconds=group, startMicroseconds=0)
            identities[group] = identity
            row = dict(task='darwin-acceleration', run='run1', token=str(group), pgid=group,
                       birth=dict(bootId='boot', process=identity),
                       spawnProtocol=dict(parent=dict(pgid=parent)))
            (self.folder / (str(group) + '.json')).write_text(json.dumps(row))
        with patch('gambit_smp.process_identity.process', side_effect=identities.get), \
             patch('gambit_smp.process_identity.boot_id', return_value='boot'), \
             patch('os.getsid', side_effect=lambda pid: pid), \
             patch('gambit_smp.process_identity.groups_memory',
                   side_effect=lambda groups, **kw: dict(pgids=sorted(groups), rssBytes=len(groups) * 100, members=[])):
            sample = memory_sample(self.root, 'darwin-acceleration', 'run1', root_group=124)
        self.assertEqual([124, 125], sample['pgids'])
        self.assertEqual(200, sample['rssBytes'])
        self.assertEqual(124, sample['pgid'])

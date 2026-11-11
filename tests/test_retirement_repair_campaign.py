"""Repeated retirement and repair-evidence workflow; no native admission."""
from dataclasses import asdict
from contextlib import contextmanager
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.artifact_storage import cache_path, runtime_output
from gambit_smp.framework import ROOT, available_processors, digest
from gambit_smp.model_schedule import physical_memory, resources
from gambit_smp.process_observation import capture
from gambit_smp.quint_backend import check


@contextmanager
def prepared_compiler(folder, jar):
    """Real, process-owned compiler setup; each source check keeps its 30 s cap.

    Reusing one listening tool service avoids charging JVM startup to every
    unrelated property. RPC still compiles the current source each time.
    """
    from concurrent.futures import ThreadPoolExecutor
    from unittest.mock import patch
    import signal
    import socket
    import time
    from gambit_smp.framework import execute
    from gambit_smp.quint_backend import isolated_endpoint
    folder.mkdir(parents=True, exist_ok=False)
    endpoint = isolated_endpoint();port = endpoint.rsplit(':', 1)[1]
    observed = {};before = digest(jar);started = time.monotonic()
    with ThreadPoolExecutor(max_workers=1) as pool:
        future = pool.submit(execute, [shutil.which('java'), '-Xmx2G', '-jar', str(jar),
            'server', '--port='+port], folder, 460, metadata=observed)
        ready = False
        try:
            while time.monotonic()-started < 30:
                if future.done():
                    raise AssertionError('compiler exited during setup: '+str(future.result()))
                try:
                    with socket.create_connection(('127.0.0.1', int(port)), timeout=.1):
                        ready = True
                        break
                except OSError:
                    time.sleep(.05)
            if not ready:raise AssertionError('compiler setup did not listen within 30 seconds')
            observed['startupSeconds'] = time.monotonic()-started
            with patch('gambit_smp.quint_backend.isolated_endpoint', return_value=endpoint):
                yield endpoint
            if future.done():raise AssertionError('compiler exited before controlled retirement')
            if digest(jar)!=before:raise AssertionError('compiler binary changed')
        finally:
            pid = observed.get('pid')
            if pid is not None and not future.done():
                try:os.killpg(pid, signal.SIGTERM)
                except ProcessLookupError:pass
                try:future.result(timeout=5)
                except TimeoutError:
                    try:os.killpg(pid, signal.SIGKILL)
                    except ProcessLookupError:pass
            code,output,timed_out,seconds = future.result(timeout=5)
            (folder/'server.log').write_text(output)
            (folder/'receipt.json').write_text(json.dumps(dict(observed, exit=code,
                timeout=timed_out,seconds=seconds,toolSha256=before,endpoint=endpoint,
                setupReady=ready,nativeAdmitted=False),indent=2)+'\n')
            if timed_out or not observed.get('parentReaped') or not observed.get('processGroupQuiescent'):
                raise AssertionError('compiler fixture did not retire quiescently')


def compiled_control(compiled, folder, invariant, jar, *, expected_sha, jar_sha, model_sha, workers):
    """Select a real compiled invariant through TLC config, retaining its trace."""
    import re
    from gambit_smp.framework import execute
    from gambit_smp.quint_backend import counterexample, summarize
    if digest(compiled)!=expected_sha or digest(jar)!=jar_sha:
        raise ValueError('compiled source/tool identity changed')
    if not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', invariant) or not re.search(
            r'^'+invariant+r'\s*==',compiled.read_text(),re.MULTILINE):
        raise ValueError('property absent from the actual compiled source')
    target=folder/compiled.name;shutil.copyfile(compiled,target)
    cfg=folder/'control.cfg';cfg.write_text(f'INIT q_init\nNEXT q_step\nINVARIANT {invariant}\n')
    snapshots={target.name:digest(target),cfg.name:digest(cfg)}
    code,log,timed_out,seconds=execute([shutil.which('java'),'-Xmx1G','-Xss8m','-cp',str(jar),
        'tlc2.TLC','-deadlock','-lncheck','final','-workers',str(workers),'-metadir',str(folder/'states'),
        '-config',str(cfg),str(target)],folder,30)
    stable=all(digest(folder/name)==sha for name,sha in snapshots.items())
    accepted=code!=0 and not timed_out and stable and f'Error: Invariant {invariant} is violated.' in log
    trace=counterexample(log) if accepted else None
    row=dict(accepted=accepted,exit=code,timeout=timed_out,seconds=round(seconds,3),temporal=None,
        states=summarize(log),checker=dict(backend='same-compiled-TLC',artifacts=snapshots,
        compiledFromModelSha256=model_sha,tlcJarSha256=jar_sha,inputsStable=stable,workers=workers))
    shutil.rmtree(folder/'states',ignore_errors=True)
    return row,log,trace


class RetirementRepairCampaignTests(unittest.TestCase):
    validation_after_domains = True

    @classmethod
    def setUpClass(cls):
        cls.compiled = None
        cls.maintained_model = ROOT / "models/gambit/retirement_repair_campaign.qnt"
        parent = runtime_output(ROOT, ".cache/retirement-repair-campaign")
        parent.mkdir(parents=True, exist_ok=True)
        cls.out = Path(tempfile.mkdtemp(prefix="run-", dir=parent))
        source = cls.out / "source"
        cls.model = source / "models/gambit/retirement_repair_campaign.qnt"
        cls.model.parent.mkdir(parents=True)
        maintained = cls.maintained_model.read_bytes()
        marker = b'module retirement_recovery_model {'
        selected = maintained[:maintained.index(marker)] if marker in maintained else maintained
        cls.model.write_bytes(selected)
        copied=[]
        for name in ('retirement_exit_handoff.qnt','callback_return_owned_result.qnt',
                     'resize_saved_stack_retirement_isolated.qnt','sync_slot_retained_resources.qnt'):
            target=cls.model.parent/name;shutil.copyfile(ROOT/'models/gambit'/name,target);copied.append(target)
        work=source/'models/library/gc/WorkObligations.qnt';work.parent.mkdir(parents=True)
        shutil.copyfile(ROOT/'models/library/gc/WorkObligations.qnt',work);copied.append(work)
        (cls.out/'selected-model.json').write_text(json.dumps(dict(
            maintainedSource=str(cls.maintained_model.relative_to(ROOT)),maintainedSha256=digest(cls.maintained_model),
            selectedModule='retirement_repair_campaign',selectedSha256=digest(cls.model),
            literalByteRange=[0,len(selected)],nativeAdmitted=False),indent=2)+'\n')
        files = [cls.maintained_model, cls.model, *copied, ROOT / "models/gambit/lean/RetirementRepairCampaign.lean",
                 ROOT / "models/gambit/lean/lean-toolchain", Path(__file__)]
        files += [ROOT / "models/gambit" / f for f in (
            "retirement_exit_handoff.qnt", "callback_return_owned_result.qnt",
            "resize_saved_stack_retirement_isolated.qnt", "sync_slot_retained_resources.qnt")]
        files.append(ROOT / "models/library/gc/WorkObligations.qnt")
        cls.inputs = {str(p.relative_to(ROOT)): digest(p) for p in files}
        cls.plan = resources(available_processors(), physical_memory(), None)
        cls.jar = Path(os.environ.get("QUINT_TLC_JAR", ROOT / ".cache/tools/apalache-0.62.1/lib/apalache.jar"))
        cls.config = cls.out / "tlc-config.json"
        cls.config.write_text(json.dumps({"workers": cls.plan["controlTlcWorkers"],
            "maxHeap": "-Xmx1G", "stackSize": "-Xss8m"}))
        cls.compiler = prepared_compiler(cls.out / "compiler", cls.jar)
        cls.compiler.__enter__()
        cls.addClassCleanup(cls.compiler.__exit__, None, None, None)
        print("Repair campaign receipt:", cls.out, flush=True)

    @classmethod
    def tearDownClass(cls):
        changed = [p for p, sha in cls.inputs.items() if digest(ROOT / p) != sha]
        if changed:
            raise AssertionError("campaign inputs changed: " + repr(changed))

    def verify(self, initializer, invariant="fixedSafe", negative=False, witness=False):
        self.assertIsNotNone(shutil.which("quint"))
        self.assertTrue(self.jar.is_file(), "fixed TLC required; no skip")
        directory = self.out / (initializer + "-" + invariant)
        directory.mkdir()
        if negative and self.compiled is not None:
            row, log, trace = compiled_control(self.compiled,directory,invariant,self.jar,
                expected_sha=self.compiled_sha,jar_sha=self.jar_sha,model_sha=digest(self.model),
                workers=self.plan['controlTlcWorkers'])
        else:
            row, log, trace = check(self.model, initializer="init", invariant=invariant,
                negative=negative, timeout=30, cwd=directory, config=self.config,
                executable=shutil.which("quint"), temporal=None if negative else "campaignCompletion", step="campaignStep",
                liveness_schedule="final", tlc_jar=self.jar)
            if row['checker'].get('phase')=='tlc' and row['checker']['inputsStable']:
                type(self).compiled=directory/'retirement_repair_campaign.tla'
                type(self).compiled_sha=digest(self.compiled)
                type(self).jar_sha=digest(self.jar)
        (directory / "checker.log").write_text(log)
        (directory / "receipt.json").write_text(json.dumps(dict(row, trace=trace,
            inputs=self.inputs, resources=self.plan, runtimeAdmitted=False,
            purpose="reachable-witness" if witness else "workflow-control"), indent=2))
        self.assertTrue(row["accepted"], initializer + "\n" + log[-2200:])
        self.assertFalse(row["timeout"])
        return trace

    def test_composed_safety_and_failure_controls(self):
        self.verify("corrected-policies")

        def negative(initializer):
            properties = {"initStaleBuild": "rejectStaleBuild", "initReplayReceipt": "rejectReplay",
                "initPartialInventory": "rejectPartialInventory", "initFailedAsPass": "rejectFailedAsPass",
                "initEraseFailure": "rejectEraseFailure", "initLostRecipient": "rejectLostRecipient"}
            trace = self.verify(initializer, properties[initializer], negative=True)
            state = trace["states"][-1]
            c, h = state["c"], state["h"]
            if initializer == "initStaleBuild":
                self.assertEqual((c["source"], c["built"]), (2, 1))
                self.assertTrue(c["credited"]["$integerSet"])
            elif initializer == "initReplayReceipt":
                self.assertIn(1, c["credited"]["$integerSet"])
                self.assertNotIn(1, c["observed"]["$integerSet"])
                self.assertEqual(h["joinCalls"], 0)
            elif initializer == "initPartialInventory":
                self.assertEqual(c["phase"], "done")
                self.assertEqual(c["credited"], {"$integerSet": [0]})
            elif initializer == "initFailedAsPass":
                self.assertTrue(h["joinFailed"])
                self.assertFalse(h["reclaimed"])
            elif initializer == "initLostRecipient":
                self.assertTrue(c["receivedWork"]["$integerSet"])
                self.assertEqual(c["ownedWork"], {"$integerSet": []})
                self.assertEqual(c["completedWork"], {"$integerSet": []})
                self.assertTrue(c["receivedRoots"]["$integerSet"])
                self.assertEqual(h["targetWork"], {"$integerSet": []})
            elif initializer == "initEraseFailure":
                self.assertTrue(c["erasedFailure"])
                previous = trace["states"][-2]
                self.assertTrue(previous["h"]["joinFailed"])
                self.assertEqual(previous["h"]["joinCalls"], 1)
                self.assertFalse(h["joinFailed"])
                self.assertEqual(h["joinCalls"], 0)
                self.assertEqual(previous["c"]["generation"], c["generation"])
            else:
                self.fail("unregistered control")

        controls = ("initStaleBuild", "initReplayReceipt", "initPartialInventory",
                    "initFailedAsPass", "initEraseFailure", "initLostRecipient")
        # One compiler/checker at a time; each TLC already uses the declared
        # host-derived worker allocation within the original 30 s watchdog.
        for initializer in controls:
            negative(initializer)

    def test_repeated_success_retention_cancellation_and_stale_rejection_reachable(self):
        requests = (("initFixed", "noRepeatedSuccess"), ("initFixed", "campaignNoRetainedFailure"),
                    ("initCancelled", "noCancelled"), ("initSourceChange", "noStaleRejected"), ("initFixed", "noRecipientCompletion"))

        def witness(request):
            trace = self.verify(*request, negative=True, witness=True)
            c, h = trace["states"][-1]["c"], trace["states"][-1]["h"]
            if request[1] == "noRepeatedSuccess":
                self.assertEqual(c["observed"], {"$integerSet": [0, 1]})
                self.assertEqual(c["credited"], c["observed"])
                self.assertEqual(h["joinCalls"], 1)
                self.assertIn(0, c["ownedWork"]["$integerSet"])
            elif request[1] == "noRecipientCompletion":
                self.assertIn(0, c["completedWork"]["$integerSet"])
                self.assertNotIn(0, c["ownedWork"]["$integerSet"])
            elif request[1] == "campaignNoRetainedFailure":
                self.assertTrue(h["joinFailed"])
                self.assertFalse(h["handed"] or h["reclaimed"])
            elif request[1] == "noCancelled":
                self.assertEqual(c["phase"], "cancelled")
                self.assertFalse(h["handed"] or h["reclaimed"])
            else:
                self.assertTrue(c["changed"])
                self.assertEqual(c["phase"], "failed")
                self.assertEqual(c["credited"], {"$integerSet": []})

        # Each witness traverses the composed cohort graph and already has
        # controlTlcWorkers threads. Parallel compiler/TLC instances exceeded
        # the unchanged 30 s check budget; retain capacity and serialize them.
        for request in requests:
            witness(request)

    def test_general_trace_lean_contract(self):
        lean = ROOT / "models/gambit/lean"
        row = capture([shutil.which("lean"), "-j1", "-DmaxHeartbeats=200000",
            "-DmaxRecDepth=512", "RetirementRepairCampaign.lean"], lean, 15,
            dict(os.environ, ELAN_TOOLCHAIN=(lean / "lean-toolchain").read_text().strip()))
        (self.out / "lean.json").write_text(json.dumps(dict(asdict(row),
            inputs=self.inputs, runtimeAdmitted=False), indent=2))
        self.assertEqual(row.exit, 0, row.stdout + row.stderr)
        self.assertFalse(row.timeout)
        self.assertTrue(row.group_quiescent)
        self.assertNotIn("sorryAx", row.stdout + row.stderr)
        for name in ("trace_preserves", "all_receipts_join_once", "failed_trace_retains",
                     "repeated_completion_is_reachable", "stale_join_is_ignored",
                     "old_generation_is_not_current", "other_vm_is_not_current",
                     "ledger_trace_preserves", "next_cohort_keeps_recipient",
                     "recipient_completion_is_reachable", "forgetting_recipient_is_rejected"):
            self.assertIn(name, row.stdout)
        for line in row.stdout.splitlines():
            if "depends on axioms: [" in line:
                names = line.split("depends on axioms: [", 1)[1].rstrip("]").split(",")
                self.assertLessEqual({n.strip() for n in names}, {"propext", "Quot.sound"})

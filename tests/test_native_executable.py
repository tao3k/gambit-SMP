"""Standalone transport checks; mock executions are not runtime qualification."""
from pathlib import Path
import copy
import json
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from gambit_smp import native_capabilities as native
from gambit_smp.framework import digest


class SharedFixtureTests(unittest.TestCase):
    """Transport/refusal controls only; these fake programs are never native evidence."""
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name).resolve()
        self.out = self.root/'run'; self.out.mkdir()
        self.runtime = self.root/'runtime'; self.runtime.mkdir()
        (self.runtime/'abi.h').write_text('runtime ABI')
        self.identity = self.root/'identity.json'; self.identity.write_text('{}')
        self.source = self.root/'fixture.scm'; self.source.write_text('(display "PASS")')
        self.compiler = self.root/'gcc'; self.compiler.write_text('fake tool identity')
        self.frontend = self.root/'cc1'; self.frontend.write_text('fake frontend identity')
        self.steps = []; self.calls = []; self.mutation = None
        self.args = dict(runtime=dict(step='runtime',output='runtime'),
                         identity=dict(step='runtime',output='identity'),program='fixture.scm',stdout='PASS\n')

    def context(self, name):
        directory=self.out/name;directory.mkdir()
        ctx=SimpleNamespace(root=self.root,out=self.out,directory=directory,env={'CC':str(self.compiler)},
            commands=[],extra_inputs={},receipt={'steps':self.steps},tools={'gcc':str(self.compiler)},remaining=lambda:10)
        def artifact(ref, kind):
            if ref['output']=='runtime':return self.runtime
            if ref['output']=='identity':return self.identity
            row=next(s for s in self.steps if s['id']==ref['step'])['outputs'][ref['output']]
            path=self.out/row['path']
            if row['type']!=kind or digest(path)!=row['sha256']:raise ValueError('artifact drift')
            return path
        ctx.artifact=artifact
        def bind(paths):
            ctx.extra_inputs.update({str(p.resolve()):digest(p) for p in paths})
        ctx.bind=bind
        ctx.publish=lambda name,kind,path:{name:dict(type=kind,path=str(path.relative_to(self.out)),sha256=digest(path))}
        def require(stage, argv, cwd, cap, **kwargs):
            row=dict(stage=stage,argv=list(map(str,argv)),cwd=str(cwd),environment=dict(ctx.env),
                     seconds=.001,exit=0,timeout=False,parentReaped=True,processGroupQuiescent=True,stderrBytes=0)
            ctx.commands.append(row);self.calls.append((name,stage,str(cwd)))
            if stage=='compile-executable':
                output=directory/'fixture';output.write_text('fake executable');output.chmod(0o700)
                (directory/'compile-executable.process.json').write_text(json.dumps(dict(
                    schema='recipe-process-observation.v1',state='OBSERVED',completionObserved=True,**row)))
            if self.mutation:self.mutation(stage,ctx)
            return '' if stage=='compile-executable' else 'PASS\n'
        ctx.require=require
        return ctx

    def invoke(self, args, ctx):
        def compiler(context):
            context.bind([self.frontend]);return self.compiler
        with patch.object(native,'compiler',side_effect=compiler), \
             patch.object(native,'gnu_build_driver',return_value={}), \
             patch.object(native,'available_processors',return_value=12), \
             patch('gambit_smp.suite_primitives.check_runtime'):
            return native.executable_test(args,ctx)

    def producer(self):
        args=dict(self.args,publishCompilation=True);ctx=self.context('wide')
        result=self.invoke(args,ctx)
        self.steps.append(dict(id='wide',capability='gambit.executable-test',arguments=args,
                               outcome='PASS',commands=ctx.commands,**result))
        return ctx

    def consumer(self):
        return dict(self.args,processorTopology='host-managed',compilation=dict(step='wide',output='compilation'))

    def change_manifest(self, change):
        path=self.out/'wide/compilation.json';record=json.loads(path.read_text());change(record)
        path.write_text(json.dumps(record));self.steps[0]['outputs']['compilation']['sha256']=digest(path)

    def test_one_compile_and_two_real_invocations_keep_the_original_cwd(self):
        original=self.producer();ctx=self.context('wide-host')
        result=self.invoke(self.consumer(),ctx)
        self.assertTrue(result['compilationReused']);self.assertFalse(result['compilationLaunched'])
        self.assertEqual(11,result['executionProcessors'])
        self.assertEqual([('wide','compile-executable'),('wide','run-executable'),('wide-host','run-executable')],
                         [(a,b) for a,b,_ in self.calls])
        self.assertEqual(str(original.directory),self.calls[-1][2])
        self.assertFalse((ctx.directory/'fixture').exists())
        self.assertFalse((ctx.directory/'fixture.scm').exists())

    def test_source_tool_backend_runtime_output_and_origin_drift_refuse_without_fallback(self):
        for kind in ('source','tool','backend','runtime','candidate','copied','output','mode','receipt','cross-run','cwd','cpu','alias','manifest-alias','replayed','failed'):
            with self.subTest(kind=kind):
                self.setUp();self.producer();ctx=self.context('consumer')
                paths={'source':self.source,'tool':self.compiler,'backend':self.frontend,
                       'runtime':self.runtime/'abi.h','candidate':self.identity,
                       'copied':self.out/'wide/fixture.scm','output':self.out/'wide/fixture',
                       'receipt':self.out/'wide/compile-executable.process.json'}
                if kind in paths:paths[kind].write_text('changed')
                elif kind=='mode':(self.out/'wide/fixture').chmod(0o600)
                elif kind=='cross-run':self.change_manifest(lambda r:r.update(run=str(self.out/'different')))
                elif kind=='cwd':self.change_manifest(lambda r:r.update(cwd=str(ctx.directory)))
                elif kind=='cpu':self.change_manifest(lambda r:r.update(hostCpuCapacity=1))
                elif kind in ('alias','manifest-alias'):
                    path=self.out/'wide'/('fixture' if kind=='alias' else 'compilation.json')
                    target=path.with_name('retained-original');path.rename(target);path.symlink_to(target.name)
                elif kind=='replayed':self.steps[0]['reused']={'run':'past'}
                elif kind=='failed':self.steps[0]['outcome']='DENY'
                with self.assertRaises((ValueError,KeyError,json.JSONDecodeError)):
                    self.invoke(self.consumer(),ctx)
                self.assertEqual([],ctx.commands)

    def test_environment_or_recorded_command_cannot_be_normalized(self):
        for kind in ('environment','argv'):
            with self.subTest(kind=kind):
                self.setUp();self.producer();ctx=self.context('consumer')
                if kind=='environment':ctx.env['EXTRA_CONTEXT']='changed'
                else:self.change_manifest(lambda r:r['command']['argv'].append('-different'))
                with self.assertRaises(ValueError):self.invoke(self.consumer(),ctx)
                self.assertEqual([],ctx.commands)

    def test_bad_compile_receipt_and_mutation_during_execution_cannot_publish_or_pass(self):
        for kind in ('receipt','source-during-compile','runtime-during-compile','after-share'):
            with self.subTest(kind=kind):
                self.setUp()
                if kind=='after-share':
                    self.producer();args=self.consumer();ctx=self.context('consumer')
                    self.mutation=lambda stage,c:(self.out/'wide/fixture').write_text('changed')
                else:
                    args=dict(self.args,publishCompilation=True);ctx=self.context('producer')
                    def mutate(stage,c):
                        if stage!='compile-executable':return
                        if kind=='receipt':
                            path=c.directory/'compile-executable.process.json';r=json.loads(path.read_text());r['timeout']=True;path.write_text(json.dumps(r))
                        elif kind=='source-during-compile':(c.directory/'fixture.scm').write_text('changed')
                        else:(self.runtime/'abi.h').write_text('changed')
                    self.mutation=mutate
                with self.assertRaises(ValueError):self.invoke(args,ctx)
                self.assertFalse((ctx.directory/'compilation.json').exists())

    def test_graph_requires_direct_same_program_runtime_and_publication(self):
        from gambit_smp.recipes import CAPABILITIES
        runtime=dict(id='runtime',capability='gambit.native-development',arguments={})
        producer=dict(id='wide',capability='gambit.executable-test',arguments=dict(self.args,publishCompilation=True))
        target=dict(id='host',capability='gambit.executable-test',arguments=self.consumer(),dependsOn=['runtime','wide'])
        native.graph(target,{'runtime':runtime,'wide':producer},CAPABILITIES)
        for kind in ('dependency','program','runtime','gsi','chain','publication'):
            with self.subTest(kind=kind):
                p,t=copy.deepcopy(producer),copy.deepcopy(target)
                if kind=='dependency':t['dependsOn'].remove('wide')
                elif kind=='program':p['arguments']['program']='other.scm'
                elif kind=='runtime':p['arguments']['runtime']={'step':'other','output':'runtime'}
                elif kind=='gsi':p['arguments']['mode']='gsi'
                elif kind=='chain':p['arguments']['compilation']={'step':'earlier','output':'compilation'}
                else:p['arguments'].pop('publishCompilation')
                with self.assertRaises(ValueError):native.graph(t,{'runtime':runtime,'wide':p},CAPABILITIES)

    def test_interpreted_or_chained_publication_is_rejected(self):
        for args in (dict(self.args,mode='gsi',publishCompilation=True),dict(self.consumer(),publishCompilation=True),
                     dict(self.args,publishCompilation='yes')):
            with self.assertRaises(ValueError):native.validate_executable_test(args,['fixture.scm'])


class NativeExecutableTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.directory = self.root / "step"
        self.directory.mkdir()
        self.runtime = self.root / "runtime"
        self.runtime.mkdir()
        self.identity = self.root / "identity.json"
        self.identity.write_text("{}")
        self.source = self.root / "fixture.scm"
        self.source.write_text('(display "PASS\\n")')
        self.args = {"runtime": {"step": "producer", "output": "runtime"},
                     "identity": {"step": "producer", "output": "identity"},
                     "program": "fixture.scm", "stdout": "PASS\n"}
        self.ctx = SimpleNamespace(root=self.root, directory=self.directory, env={}, commands=[],
            artifact=lambda ref, kind: self.runtime if ref["output"] == "runtime" else self.identity,
            bind=lambda paths: list(paths), remaining=lambda: 10)
        self.log, self.stderr, self.change = "PASS\n", 0, None
        def require(stage, argv, cwd, cap, **kwargs):
            self.ctx.commands.append({"stderrBytes": self.stderr, "seconds": 1})
            if stage == "compile-executable":
                (self.directory / "fixture").write_text("mock executable")
                return ""
            if self.change:
                self.change()
            return self.log
        self.ctx.require = require

    def execute(self, capacity=5):
        with patch.object(native, "compiler", return_value=Path("/usr/bin/gcc")), \
                patch.object(native, "gnu_build_driver", return_value={"verified": True}), \
                patch.object(native, "available_processors", return_value=capacity), \
                patch("gambit_smp.suite_primitives.check_runtime"):
            return native.executable_test(self.args, self.ctx)

    def test_exact_source_runtime_and_capacity_without_admission(self):
        native.validate_executable_test(self.args, ["fixture.scm"])
        result = self.execute()
        self.assertEqual(5, result["hostCpuCapacity"])
        self.assertEqual("5", self.ctx.env["GAMBIT_SMP_AVAILABLE_CPUS"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertFalse(result["nativeGcPassed"])
        self.assertEqual("fixture-managed", result["processorTopology"])
        self.assertEqual(1, result["executionProcessors"])
        self.assertTrue(self.ctx.env["GAMBOPT"].startswith("p1,"))

    def test_host_managed_topology_is_derived_from_available_capacity(self):
        self.args["processorTopology"] = "host-managed"
        native.validate_executable_test(self.args, ["fixture.scm"])
        for cpu in (1, 5, 12):
            with self.subTest(cpu=cpu):
                result = self.execute(capacity=cpu)
                self.assertEqual(max(1, cpu - 1), result["executionProcessors"])
                self.assertTrue(self.ctx.env["GAMBOPT"].startswith(
                    f"p{result['executionProcessors']},"))
                self.assertEqual(str(cpu), self.ctx.env["GAMBIT_SMP_AVAILABLE_CPUS"])
                self.assertEqual(str(result["executionProcessors"]),
                                 self.ctx.env["GAMBIT_SMP_EXPECTED_PROCESSORS"])

    def test_interpreted_fixture_uses_same_runtime_without_compile_or_test_tree_copy(self):
        interpreter = self.runtime/'gsi/gsi';interpreter.parent.mkdir()
        interpreter.write_bytes(b'synthetic interpreter identity, not native acceptance')
        self.args.update(mode='gsi', processorTopology='host-managed')
        native.validate_executable_test(self.args, ['fixture.scm'])
        with patch.object(self.ctx, 'require', wraps=self.ctx.require) as require:
            result = self.execute(capacity=7)
        self.assertEqual(1, require.call_count)
        self.assertEqual('run-executable', require.call_args.args[0])
        self.assertEqual(interpreter, require.call_args.args[1][0])
        self.assertEqual(self.directory/'fixture.scm', require.call_args.args[1][-1])
        self.assertEqual(6, result['executionProcessors'])
        self.assertFalse(result['compilationLaunched'])
        self.assertNotIn('compileProcessors', result)
        self.assertFalse((self.directory/'runtime').exists())
        self.assertFalse((self.directory/'fixture').exists())
        self.assertFalse(result['runtimeAdmitted'])

    def test_unknown_standalone_mode_is_rejected(self):
        self.args['mode'] = 'unknown'
        with self.assertRaisesRegex(ValueError, 'standalone fixture mode'):
            native.validate_executable_test(self.args, ['fixture.scm'])

    def test_unknown_topology_cannot_silently_use_one_processor(self):
        self.args["processorTopology"] = "unknown"
        with self.assertRaisesRegex(ValueError, "processor topology"):
            native.validate_executable_test(self.args, ["fixture.scm"])

    def test_completed_units_bind_exact_results_without_runtime_admission(self):
        self.ctx.progress_mode = True
        self.args["completedUnits"] = {"marker": "ROOT-DONE", "count": 2, "result": "987"}
        self.log = "ROOT-DONE 1/2 987\nROOT-DONE 2/2 987\nPASS\n"
        native.validate_executable_test(self.args, ["fixture.scm"])
        with patch.object(self.ctx, "require", wraps=self.ctx.require) as require:
            result = self.execute()
        self.assertEqual(2, result["completedUnitCount"])
        self.assertIn("progress", require.call_args.kwargs)
        self.assertFalse(result["runtimeAdmitted"])

    def test_completed_units_cannot_be_used_as_wall_timer_or_partial_pass(self):
        self.args["completedUnits"] = {"marker": "ROOT-DONE", "count": 2, "result": "987"}
        with self.assertRaisesRegex(ValueError, "inactivity"):
            self.execute()
        self.ctx.progress_mode = True
        with self.assertRaisesRegex(ValueError, "incomplete"):
            self.execute()

    def test_execution_cap_remains_nested_in_the_whole_step(self):
        for requested, expected in ((3, 3), (30, 10)):
            self.args["executionBudgetSeconds"] = requested
            native.validate_executable_test(self.args, ["fixture.scm"])
            with patch.object(self.ctx, "require", wraps=self.ctx.require) as require:
                self.execute()
            self.assertEqual(expected, require.call_args.args[3])

    def test_invalid_execution_budgets_are_rejected(self):
        for cap in (True, 0, -1, float("inf"), float("nan"), "30"):
            self.args["executionBudgetSeconds"] = cap
            with self.subTest(cap=cap), self.assertRaises(ValueError):
                native.validate_executable_test(self.args, ["fixture.scm"])

    def test_declared_parameters_reach_fixture_without_overriding_capacity(self):
        shared_environment = self.ctx.env
        self.args["parameters"] = {"GAMBIT_SMP_DEPTH": 131072}
        native.validate_executable_test(self.args, ["fixture.scm"])
        self.execute(capacity=5)
        self.assertEqual("131072", self.ctx.env["GAMBIT_SMP_DEPTH"])
        self.assertEqual("5", self.ctx.env["GAMBIT_SMP_AVAILABLE_CPUS"])
        self.assertNotIn("GAMBIT_SMP_DEPTH", shared_environment)

    def test_parameters_cannot_replace_tools_capacity_or_identity(self):
        for name, value in (("PATH", 1), ("GAMBOPT", 1), ("LD_PRELOAD", 1),
                            ("GAMBIT_SMP_ROOT", 1), ("GAMBIT_SMP_AVAILABLE_CPUS", 12),
                            ("GAMBIT_SMP_EXPECTED_PROCESSORS", 12),
                            ("GAMBIT_SMP_DEPTH", True), ("GAMBIT_SMP_DEPTH", 0),
                            ("GAMBIT_SMP_DEPTH", "131072"), ("GAMBIT_SMP_DEPTH", 2147483648)):
            self.args["parameters"] = {name: value}
            with self.subTest(name=name, value=value), self.assertRaises(ValueError):
                native.validate_executable_test(self.args, ["fixture.scm"])

    def test_declared_stderr_must_match_every_byte(self):
        transcript = "TRACE:gc-request\nTRACE:gc-request\n"
        self.args["stderr"] = transcript
        native.validate_executable_test(self.args, ["fixture.scm"])
        self.stderr = len(transcript.encode())
        path = self.directory / "run-executable.stderr"
        path.write_text(transcript)
        self.execute()
        path.write_text(transcript.replace("gc-request", "xx-request"))
        with self.assertRaises(ValueError):
            self.execute()
        path.write_text(transcript + "warning\n")
        self.stderr = path.stat().st_size
        with self.assertRaises(ValueError):
            self.execute()

    def test_nontext_stderr_contract_is_rejected(self):
        self.args["stderr"] = True
        with self.assertRaises(ValueError):
            native.validate_executable_test(self.args, ["fixture.scm"])

    def test_output_stderr_and_binary_drift_fail_closed(self):
        for kind in ("output", "stderr", "binary", "source", "copied-source"):
            with self.subTest(kind=kind):
                self.log, self.stderr, self.change = "PASS\n", 0, None
                if kind == "output":
                    self.log = "PARTIAL\n"
                elif kind == "stderr":
                    self.stderr = 1
                elif kind == "binary":
                    self.change = lambda: (self.directory / "fixture").write_text("changed")
                elif kind == "source":
                    self.change = lambda: self.source.write_text("changed source")
                else:
                    self.change = lambda: (self.directory / "fixture.scm").write_text("changed copy")
                with self.assertRaises(ValueError):
                    self.execute()

    def test_undeclared_program_is_rejected(self):
        with self.assertRaises(ValueError):
            native.validate_executable_test(self.args, [])

    def test_optional_latency_uses_observed_cpu_and_execution_time(self):
        options = {"path": "latencies.jsonl", "minimumSamples": 1000,
                   "percentiles": [55, 99]}
        self.args["latency"] = options
        native.validate_executable_test(self.args, ["fixture.scm"])
        with patch("gambit_smp.latency_observation.summarize", return_value={"samples": 1000}) as observe:
            result = self.execute(capacity=12)
        observe.assert_called_once_with(self.directory, options, 12, 1)
        self.assertEqual({"samples": 1000}, result["latencyObservation"])
        self.assertFalse(result["runtimeAdmitted"])

    def test_transcript_review_does_not_replace_native_latency_duration(self):
        self.args["stdoutTranscript"] = {"contract": "contract.json", "rules": "rules.ss"}
        self.args["latency"] = {"path": "latencies.jsonl", "minimumSamples": 1000,
                                "percentiles": [55, 99]}
        native.validate_executable_test(self.args, ["fixture.scm", "contract.json", "rules.ss"])
        def reviewed(*args):
            self.ctx.commands.append({"stderrBytes": 0, "seconds": 99})
            return {"answers": {"bad": [], "missing": []}}
        with patch("gambit_smp.native_transcript.review", side_effect=reviewed), \
                patch("gambit_smp.latency_observation.summarize", return_value={}) as observe:
            self.execute(capacity=12)
        observe.assert_called_once_with(self.directory, self.args["latency"], 12, 1)

    def test_complete_grid_requires_both_modes_and_independent_vms(self):
        from gambit_smp.framework import ROOT
        from gambit_smp.recipes import read_json
        grid = read_json(ROOT / "evidence/research/smp-threaded-vm-native-grid/native.recipe.json")
        steps = {step["id"]: step for step in grid["steps"]}
        target = steps["independent-vms"]
        self.assertTrue({"native-gsi", "native-gsc", "entry-safe-binding",
                         "entry-bypass-control", "entry-trajectories"} <= set(target["dependsOn"]))
        self.assertIn("independent-vms", steps["verdict"]["dependsOn"])
        self.assertEqual(steps["native-gsi"]["arguments"]["identity"], target["arguments"]["identity"])
        self.assertEqual(steps["native-gsc"]["arguments"]["runtime"], target["arguments"]["runtime"])
        self.assertNotIn("processors", target["arguments"])

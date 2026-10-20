"""Launcher controls, never native/model acceptance or an external API test."""
import json
import fnmatch
import os
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from gambit_smp.grok_session import Launch, run, terminal_deliveries
from gambit_smp.workspace import start
import subprocess
import shlex
import shutil
from dataclasses import replace
from gambit_smp import task_migration as migration, workspace as w


def provider_path(root):
    """Fake providers must not fall through to a real CLI on the host PATH."""
    tools = root / 'host-tools'
    tools.mkdir(exist_ok=True)
    for name in ('git', 'lsof', 'ps'):
        target = shutil.which(name)
        if target is None:
            raise FileNotFoundError(name)
        link = tools / name
        if not link.exists():
            link.symlink_to(target)
    return os.pathsep.join((str(root), str(tools)))


class GrokSessionTests(unittest.TestCase):
    def make_launch(self, root, **extra):
        if not (root / ".git").exists():
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "-C", str(root), "-c", "user.name=Test",
                            "-c", "user.email=test@example.invalid", "commit",
                            "--allow-empty", "-qm", "initial"], check=True)
        start(root, "repair", adopt=True)
        owned = root / ".cache/tasks/repair/agents/diagnostic"
        owned.mkdir(parents=True, exist_ok=True)
        prompt = owned / "prompt.txt"
        prompt.write_text("authorized diagnostic")
        return Launch(root, "diagnostic", prompt, "user consent in current thread", task="repair", **extra)

    def test_owner_escape_and_shell_script_payload_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            launch = self.make_launch(root, scripts=("work.py; echo unsafe.py",))
            with self.assertRaisesRegex(ValueError, "literal"):
                launch.prepare()
            (root / ".cache/tasks/repair/agents/diagnostic/outside.py").symlink_to(Path(__file__).resolve())
            launch = self.make_launch(root, scripts=("outside.py",))
            with self.assertRaisesRegex(ValueError, "literal"):
                launch.prepare()
            outside = root / "outside.txt"
            outside.write_text("unrelated")
            with self.assertRaisesRegex(ValueError, "prompt"):
                Launch(root, "diagnostic", outside, "consent", task="repair").prepare()

    def test_high_and_sealed_terminal_grants(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            launch = self.make_launch(root)
            (root / ".cache/tasks/repair/agents/diagnostic/work.py").write_text("pass\n")
            entry=migration.migrate(root,'repair','.cache/tasks/repair/agents/diagnostic/work.py',enabled=True,opened=[])
            launch = self.make_launch(root, scripts=(entry['key'],))
            result = run(launch)
            self.assertEqual(result["reasoningEffort"], "high")
            argv = result["argv"]
            self.assertEqual(argv[argv.index("--reasoning-effort") + 1], "high")
            grant=next(arg for arg in argv if arg.startswith('Bash('))
            self.assertIn('run-script --provider grok repair '+entry['key'],grant)
            self.assertNotIn('work.py)',grant)
            self.assertNotIn("authorized diagnostic", json.dumps(result))
            self.assertFalse(result["executed"])
            self.assertIn('Read(' + str(Path.home() / '.grok') + '/**)', argv)
            self.assertIn('Read(' + str(Path.home() / '.codex') + '/**)', argv)
            self.assertIn('Edit(' + str(root / '.cache/tasks/repair/agents/diagnostic/grok-runs') + '/**)', argv)

    def test_evidence_read_is_a_separate_literal_grant_not_an_editable_script(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            launch = self.make_launch(root)
            result = run(launch)
            read = result["evidenceRead"]
            self.assertEqual(Path(read["request"]).parent,
                             root / ".cache/tasks/repair/agents/diagnostic")
            self.assertIn("trajectory clues < ", read["command"])
            tools = result["argv"][result["argv"].index("--tools") + 1].split(",")
            self.assertIn("run_terminal_cmd", tools)
            self.assertIn("list_dir", tools)
            self.assertNotIn("run_terminal_command", tools)
            self.assertNotIn("<", read["permission"])
            self.assertEqual(read["command"], read["permission"] + " < " + shlex.quote(read["request"]))
            self.assertIn("Bash(" + read["permission"] + ")", result["argv"])
            self.assertFalse(Path(read["request"]).exists())
            self.assertEqual([a for a in result["argv"] if a.startswith("Bash(")],
                             ["Bash(" + p + ")" for p in read['permissions']])
            interface = result['argv'][result['argv'].index('--rules') + 1]
            self.assertEqual(interface,
                'Available project Evidence CLI (read-only): ' + read['command']
                + '\nCaller-authored Scheme request data: ' + read['request']
                + '\nWritable scratch directory: ' + str(Path(read['request']).parent)
                + '\nEvidence wire window: ' + str(read['wireBytes'])
                + ' UTF-8 bytes; deferred references remain expandable. This does not bound query scope.'
                + '\nInterface help: ' + read['permission'] + ' --help'
                + '\nQuery output: Scheme data on stdout. Shell output redirection and mixed command chains'
                + ' are outside the read grant; owner-local writes use the edit tools.'
                + '\nTerminal permission covers registered read/help commands, not general shell.')
            disabled = run(replace(launch, query_request=None))
            self.assertIsNone(disabled['evidenceRead'])
            self.assertNotIn('--rules', disabled['argv'])
            configured = run(replace(launch, read_window_bytes=4096))['evidenceRead']
            self.assertEqual(configured['wireBytes'], 4096)
            self.assertEqual(configured['permissions'], read['permissions'])
            for invalid in (0, -1, True, '4096'):
                with self.assertRaisesRegex(ValueError, 'wire window'):
                    run(replace(launch, read_window_bytes=invalid))
            for bad in ("../outside.ss", "query.ss; echo unsafe", "request.py"):
                with self.subTest(name=bad), self.assertRaisesRegex(ValueError, "basename"):
                    run(replace(launch, query_request=bad))

    def test_documented_console_aliases_receive_only_read_and_help_grants(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            launch = self.make_launch(root)
            binary = root / '.venv/bin/gambit-smp'
            binary.parent.mkdir(parents=True)
            binary.write_text('console entry fixture')
            with patch('gambit_smp.grok_session.sys.executable', str(binary.with_name('python3'))):
                read = run(launch)['evidenceRead']
            for executable in (str(binary), '.venv/bin/gambit-smp'):
                self.assertIn(shlex.join([executable, 'trajectory', 'clues']), read['permissions'])
                self.assertIn(shlex.join([executable, 'research', '--help']), read['permissions'])
                self.assertIn(shlex.join([executable, 'trajectory', '--help']), read['permissions'])
            metadata = {p for p in read['permissions'] if ' -c ' in p}
            for executable in (str(binary.with_name('python3')), '.venv/bin/python3'):
                command = ' '.join([executable, '-c',
                    'from gambit_smp import repository_clues; help(repository_clues)'])
                matches = [p for p in metadata if fnmatch.fnmatchcase(command, p)]
                self.assertEqual(len(matches), 1)
                self.assertFalse(command.startswith(matches[0]))
                self.assertFalse(fnmatch.fnmatchcase(command + '; print("extra")', matches[0]))
                self.assertFalse(fnmatch.fnmatchcase(command.replace('help(repository_clues)',
                    'print("other code")'), matches[0]))
            self.assertTrue(metadata <= set(read['permissions']))
            self.assertTrue(all(p.endswith(('trajectory clues', 'trajectory catalog', '--help'))
                                or p in metadata for p in read['permissions']))
            binary.unlink()
            with patch('gambit_smp.grok_session.sys.executable', str(binary.with_name('python3'))):
                without_console = run(launch)['evidenceRead']['permissions']
                self.assertFalse(any(shlex.join([executable, 'trajectory', 'clues']) in without_console
                                     for executable in (str(binary), '.venv/bin/gambit-smp')))
            self.assertFalse(any(p.endswith(('submit', 'record', 'inspect', 'context', 'research'))
                                 for p in read['permissions']))

    def test_replay_evidence_root_reuses_cli_without_changing_execution_workspace(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            launch = self.make_launch(root)
            data = root / '.cache/tasks/repair/agents/diagnostic/data'
            data.mkdir()
            result = run(replace(launch, query_root=data))
            self.assertEqual(result['argv'][result['argv'].index('--cwd') + 1], str(root))
            self.assertEqual(result['evidenceRead']['root'], str(data))
            self.assertIn('Edit(' + str(data) + '/**)', result['argv'])
            self.assertIn('--root ' + str(data) + ' trajectory clues', result['evidenceRead']['command'])
            self.assertFalse(any(p.endswith('-m gambit_smp trajectory clues')
                                 for p in result['evidenceRead']['permissions']))
            with self.assertRaises(ValueError):
                run(replace(launch, query_root=root.parent))
            with self.assertRaisesRegex(ValueError, 'mutable request'):
                run(replace(launch, query_root=data.parent))
            alias = data.with_name('alias')
            alias.symlink_to(data, target_is_directory=True)
            with self.assertRaisesRegex(ValueError, 'aliases'):
                run(replace(launch, query_root=alias))

    def test_provider_executes_real_evidence_cli_without_native_program_or_cleanup(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            launch = self.make_launch(root)
            (root / "models/gambit").mkdir(parents=True)
            (root / "models/gambit/cases.json").write_text("{}")
            (root / "evidence").mkdir()
            from gambit_smp.framework import ROOT, digest
            dsl = root / "evidence/dsl"
            dsl.mkdir()
            for name in ("storage.ss", "history.ss"):
                (dsl / name).write_text((ROOT / "evidence/dsl" / name).read_text())
            storage = json.loads((ROOT / "evidence/dsl/components.json").read_text())
            storage["components"] = [c for c in storage["components"] if c["id"] == "state-storage"]
            (dsl / "components.json").write_text(json.dumps(storage))
            (root / "evidence/clues.ss").write_text(
                (ROOT / "evidence/scenarios/stack-header/clues.ss").read_text())
            (root / "evidence/components.json").write_text(json.dumps({
                "schema": "ascent.evidence-components.v1", "components": [{
                    "id": "clues", "source": "clues.ss",
                    "exports": ["make-stack-entry-clues"], "dependencies": []}]}))
            receipt = root / "evidence/receipt.md"
            receipt.write_text("Controlled query evidence, not native acceptance.\n")
            (root / "evidence/query.view.json").write_text(json.dumps({
                "schema": "ascent.evidence-view.v1", "id": "controlled-read",
                "manifest": "evidence/components.json", "entry": "clues",
                "constructor": "make-stack-entry-clues",
                "facts": {"observation": [["observed", "unknown-native-cause", "counter", "receipt"]],
                          "attribute": [["observed", "evidence-state", "unclosed"]],
                          "reference": {"references": True}},
                "queries": {name: name for name in ("clue", "factor", "link", "inventory")},
                "references": [{"id": "receipt", "path": "evidence/receipt.md",
                                "sha256": digest(receipt), "pointer": None}]}))
            (root / "evidence/views.json").write_text(json.dumps({
                "schema": "ascent.evidence-views.v1", "views": ["evidence/query.view.json"]}))
            read = run(launch)["evidenceRead"]
            Path(read["request"]).write_text('((questions ("unknown-native-cause")))')
            binary = root / "grok"
            binary.write_text("#!" + sys.executable + "\nimport json,subprocess,sys\n"
                "grant=next(a for a in sys.argv if a == " + repr('Bash(' + read['permission'] + ')') + ")\n"
                "subprocess.run(grant[len('Bash('):-1],stdin=open(" + repr(read['request']) + "),shell=True,check=True)\n"
                "print(json.dumps({'type':'end','stopReason':'end_turn','sessionId':'01a15562-916b-7da0-b55e-5d85db65485a'}))\n")
            binary.chmod(0o700)
            with patch.dict(os.environ, PATH=provider_path(root)):
                result = run(launch, execute=True, wall_seconds=20)
            self.assertTrue(result["sessionCompleted"],
                            (Path(result["attempt"]) / "stderr.private.log").read_text())
            self.assertFalse(result["nativeAdmitted"])
            output = (Path(result["attempt"]) / "events.private.jsonl").read_text()
            self.assertIn("unknown-native-cause", output)
            self.assertIn("clue-read:", output)
            self.assertFalse(list((root / ".cache/tasks/repair/programs").glob("*.py")))

    def test_terminal_delivery_observation_is_distinct_from_provider_completion(self):
        with tempfile.TemporaryDirectory() as tmp:
            events = Path(tmp) / 'events.jsonl'
            row = dict(type='tool_call_update', status='completed', toolCallId='read',
                       rawOutput=dict(type='Bash', total_bytes=56233, truncated=True))
            events.write_text('\n'.join(json.dumps(event) for event in (
                dict(type='thought', data='not inspected'), row, row,
                dict(type='end', stopReason='end_turn'))))
            self.assertEqual(terminal_deliveries(events),
                             [dict(toolCallId='read', bytes=56233, truncated=True)])

    def test_private_events_and_repeated_runs_keep_separate_receipts(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            launch = self.make_launch(root)
            binary = root / "grok"
            binary.write_text(f"#!{sys.executable}\n" +
                              "import json\n" +
                              "print(json.dumps({'type':'thought','text':'private-test-payload'}))\n" +
                              "print(json.dumps({'type':'tool_call_update','text':'raw-scene-test-payload'}))\n" +
                              "print(json.dumps({'type':'end','sessionId':'01a15562-916b-7da0-b55e-5d85db65485a','stopReason':'end_turn','num_turns':1}))\n")
            binary.chmod(0o700)
            with patch.dict(os.environ, PATH=provider_path(root)):
                first = run(launch, execute=True, wall_seconds=5)
                second = run(replace(launch,resume=first["completion"]["sessionId"]), execute=True, wall_seconds=5)
            self.assertEqual(first["exit"], 0)
            self.assertEqual(first["completion"]["stopReason"], "end_turn")
            self.assertNotEqual(first["attempt"], second["attempt"])
            self.assertNotIn("private-test-payload", json.dumps(first))
            self.assertNotIn("raw-scene-test-payload", json.dumps(first))
            self.assertEqual(Path(first["attempt"]).stat().st_mode & 0o777, 0o700)
            self.assertEqual(first["nativeDescendantQuiescence"], "not-inferred")
            self.assertFalse(first["nativeAdmitted"])
            self.assertIn('--resume',second['argv'])
            with self.assertRaisesRegex(ValueError,'not bound'):
                run(replace(launch,resume='01a15562-916b-7da0-b55e-5d85db65485b'))

    def test_real_descriptor_handoff_after_provider_closes_fds(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp).resolve();launch=self.make_launch(root)
            source=root/'.cache/program.py'
            source.write_text("from pathlib import Path;import os\np=Path(os.environ['GAMBIT_SMP_TASK_CACHE'])/'runs'/os.environ['GAMBIT_SMP_TASK_RUN']/'outputs'\np.mkdir(parents=True,exist_ok=True);(p/'actual-tool').write_text('real tool ran')\n")
            entry=migration.migrate(root,'repair','.cache/program.py',enabled=True,opened=[])
            launch=replace(launch,scripts=(entry['key'],))
            binary=root/'grok'
            binary.write_text('#!'+sys.executable+'\nimport os,sys,subprocess,json,shlex\n'
                'for fd in range(3,256):\n try:os.close(fd)\n except OSError:pass\n'
                "grant=next(arg for arg in sys.argv if arg.startswith('Bash('))\n"
                "subprocess.run(shlex.split(grant[len('Bash('):-1]),check=True)\n"
                "print(json.dumps({'type':'end','stopReason':'end_turn','sessionId':'01a15562-916b-7da0-b55e-5d85db65485a'}))\n")
            binary.chmod(0o700)
            with patch.dict(os.environ,PATH=provider_path(root)):
                result=run(launch,execute=True,wall_seconds=10)
            self.assertTrue(result['sessionCompleted'])
            self.assertEqual(1,len(list((root/'.cache/tasks/repair/runs').glob('*/outputs/actual-tool'))))
            receipts=list((root/'.state/task-runs/repair').glob('*.json'))
            self.assertEqual(1,len(receipts))
            processes=list((root/'.state/task-processes/repair').glob('*/*.json'))
            self.assertEqual(2,len(processes))
            self.assertTrue(all(json.loads(p.read_text())['event']=='finished' for p in processes))
            w.finish(root,'repair')

    def test_timeout_requires_real_reconciliation_before_session_resume(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp).resolve();launch=self.make_launch(root)
            binary=root/'grok'
            binary.write_text('#!/bin/sh\n'
                "printf '%s\\n' '{\"type\":\"init\",\"sessionId\":\"01a15562-916b-7da0-b55e-5d85db65485a\"}'\n"
                'case "$*" in *--resume*) ;; *) /bin/sleep 20 ;; esac\n'
                "printf '%s\\n' '{\"type\":\"end\",\"sessionId\":\"01a15562-916b-7da0-b55e-5d85db65485a\",\"stopReason\":\"end_turn\"}'\n")
            binary.chmod(0o700)
            with patch.dict(os.environ,PATH=provider_path(root)):
                from gambit_smp.grok_session import write_record

                def initialized(path, record):
                    write_record(path, record)
                    if record.get("executed") and record.get("pid") and not record.get("parentReaped"):
                        # This case tests post-init timeout; pre-init interruption is distinct.
                        events = path.parent / "events.private.jsonl"
                        deadline = time.monotonic() + 5
                        while '"type":"init"' not in events.read_text():
                            if time.monotonic() >= deadline:
                                self.fail("controlled provider did not initialize")
                            time.sleep(.005)

                with patch("gambit_smp.grok_session.write_record", side_effect=initialized):
                    failed=run(launch,execute=True,wall_seconds=1)
                self.assertTrue(failed['timedOut']);self.assertFalse(failed['sessionCompleted'])
                self.assertTrue((root/'.state/provider-sessions/repair/diagnostic.json').exists())
                with self.assertRaisesRegex(ValueError,'explicit workspace resume'):run(launch,execute=True)
                w.resume(root,'repair')
                done=run(replace(launch,resume='01a15562-916b-7da0-b55e-5d85db65485a'),execute=True,wall_seconds=5)
            self.assertTrue(done['sessionCompleted']);self.assertFalse(done['nativeAdmitted'])

    def test_interruption_before_initialization_does_not_invent_a_resumable_session(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            launch = self.make_launch(root)
            binary = root / "grok"
            binary.write_text("#!/bin/sh\n/bin/sleep 20\n")
            binary.chmod(0o700)
            with patch.dict(os.environ, PATH=provider_path(root)):
                failed = run(launch, execute=True, wall_seconds=1)
                self.assertTrue(failed["timedOut"])
                self.assertFalse(failed["sessionCompleted"])
                self.assertFalse((root / ".state/provider-sessions/repair/diagnostic.json").exists())
                w.resume(root, "repair")
                with self.assertRaisesRegex(ValueError, "not bound"):
                    run(replace(launch, resume="01a15562-916b-7da0-b55e-5d85db65485a"))

    def test_codex_launcher_tools_use_the_same_real_custody_handoff(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp).resolve();self.make_launch(root)
            source=root/'.cache/control.py'
            source.write_text("from pathlib import Path;import os\np=Path(os.environ['GAMBIT_SMP_TASK_CACHE'])/'runs'/os.environ['GAMBIT_SMP_TASK_RUN']/'outputs'\np.mkdir(parents=True,exist_ok=True);(p/'codex-control').write_text('real child')\n")
            entry=migration.migrate(root,'repair','.cache/control.py',enabled=True,opened=[])
            binary=root/'codex'
            binary.write_text('#!'+sys.executable+'\nimport os,sys,subprocess\n'
                'for fd in range(3,256):\n try:os.close(fd)\n except OSError:pass\n'
                "subprocess.run([sys.executable,'-m','gambit_smp','workspace','--root',"+repr(str(root))+",'run-script','repair',"+repr(entry['key'])+"],check=True)\n")
            binary.chmod(0o700)
            self.assertEqual(0,w.execute(root,'repair',[str(binary)],provider='codex',wall_seconds=10))
            self.assertEqual(1,len(list((root/'.cache/tasks/repair/runs').glob('*/outputs/codex-control'))))
            self.assertEqual(1,len(list((root/'.state/task-runs/repair').glob('*.json'))))
            w.finish(root,'repair')

    def test_public_agent_entry_records_the_same_task_protocol(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp).resolve();launch=self.make_launch(root)
            (root/'models/gambit').mkdir(parents=True);(root/'models/gambit/cases.json').write_text('{}');(root/'evidence').mkdir()
            binary=root/'grok';binary.write_text('#!'+sys.executable+'\nimport json\n'
                "print(json.dumps({'type':'end','sessionId':'01a15562-916b-7da0-b55e-5d85db65485a','stopReason':'end_turn'}))\n")
            binary.chmod(0o700)
            env=dict(os.environ,PATH=provider_path(root))
            command=[sys.executable,'-m','gambit_smp','--root',str(root),'--task','repair','agent',
                     '--owner','diagnostic','--prompt-file',str(launch.prompt),'--authorization',launch.authorization,'--execute']
            result=subprocess.run(command,env=env,capture_output=True,text=True,timeout=15)
            self.assertEqual(0,result.returncode,result.stderr)
            body=json.loads(result.stdout);self.assertEqual('high',body['reasoningEffort']);self.assertTrue(body['sessionCompleted'])
            rows=[json.loads(p.read_text()) for p in (root/'.state/task-runs/repair').glob('*.json')]
            self.assertEqual(1,len(rows));self.assertEqual(3,rows[0]['custodyProtocol']);self.assertEqual('grok',rows[0]['provider'])


if __name__ == "__main__":
    unittest.main()

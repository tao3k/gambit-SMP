"""Reproducible, owner-scoped Grok launches; external approval stays external.

Use ``python -m gambit_smp.grok_session --help``.  Dry-run is the default.
Raw CLI output can contain private reasoning and debugger output: it is saved
privately, never forwarded as a public transcript. Native scripts remain
responsible for their own process groups and unchanged acceptance budgets.
"""

import argparse
import glob
import hashlib
import json
import os
import re
import signal
import subprocess
import time
import uuid
import shlex
import sys
from contextlib import nullcontext
from dataclasses import dataclass
from pathlib import Path

MODEL = "grok-4.7"
REASONING_EFFORT = "high"


def metadata_routes(parser, prefix):
    """Read-only help forms from the real parser, not a parallel CLI inventory."""
    yield (*prefix, '--help')
    for action in parser._actions:
        if isinstance(action, argparse._SubParsersAction):
            for name, child in action.choices.items():
                yield from metadata_routes(child, (*prefix, name))
        elif not action.option_strings and action.choices is not None:
            for name in action.choices:
                if type(name) is str:
                    yield (*prefix, name, '--help')


@dataclass(frozen=True)
class Launch:
    workspace: Path
    owner: str
    prompt: Path
    authorization: str
    resume: str | None = None
    scripts: tuple[str, ...] = ()
    max_turns: int = 45
    task: str | None = None
    query_request: str | None = "query.ss"
    query_root: Path | None = None
    read_window_bytes: int | None = None

    def profile(self, root, owned):
        """Transport the work-item's reviewed capability boundary; never infer permissions."""
        from gambit_smp.work_items import admit
        from gambit_smp.workspace import bounded
        from gambit_smp.cli import COMMANDS
        item = admit(root, self.task)
        profile = item.get('agent', {})
        if (not isinstance(profile, dict) or set(profile) - {'read', 'edit', 'commands'}
                or any(not isinstance(value, list) or any(type(v) is not str for v in value)
                       for value in profile.values())):
            raise ValueError('registered Agent read/edit/commands lists required')
        result = {'read': [], 'edit': [], 'commands': profile.get('commands', [])}
        for mode in ('read', 'edit'):
            for pattern in profile.get(mode, []):
                path = pattern.format(task=self.task, owner=self.owner)
                if (not path or Path(path).is_absolute() or '..' in Path(path).parts
                        or any(p in {'.git', '.ssh', '.aws', '.codex', '.grok', '.claude', '.cursor'}
                               for p in Path(path).parts)):
                    raise ValueError('project-relative Agent profile path required')
                stem = re.split(r'[*?\[]', path, maxsplit=1)[0].rstrip('/')
                if not stem:
                    raise ValueError('Agent profile cannot grant the whole checkout')
                bounded(root, stem)
                result[mode].append(str(root) + '/' + path)
        if any(name not in COMMANDS for name in result['commands']):
            raise ValueError('Agent command must name the existing dispatcher registry')
        if not profile:
            result['read'] = [str(root/'AGENTS.md'), str(root/'docs')+'/**',
                              str(root/'evidence')+'/**', str(root/'models')+'/**']
        result['read'].append(str(owned)+'/**')
        result['edit'].append(str(owned)+'/**')
        return result

    def evidence_read(self, root, owned):
        """One literal read command; the request is inert Scheme, not a script."""
        if self.query_request is None:
            return None
        if not isinstance(self.query_request, str) or not re.fullmatch(r"[A-Za-z0-9_-]+\.ss", self.query_request):
            raise ValueError("query request must be an owner-local Scheme basename")
        from gambit_smp.workspace import bounded
        request = bounded(root, (owned / self.query_request).relative_to(root))
        query_root = root
        if self.query_root is not None:
            selected = Path(self.query_root)
            relative = selected.relative_to(root) if selected.is_absolute() else selected
            query_root = bounded(root, relative)
            if not query_root.is_dir():
                raise ValueError('existing evidence root required')
            if query_root != root and request.is_relative_to(query_root):
                raise ValueError('evidence data must not contain the mutable request')
        base = [sys.executable, "-m", "gambit_smp", "--root", str(query_root)]
        preferred = base
        # The project documents the installed dispatcher; grant only equivalent
        # read routes, not the interpreter or the whole dispatcher.
        bases = [base]
        if query_root == root:
            bases.append([sys.executable, "-m", "gambit_smp"])
        console = Path(sys.executable).parent / "gambit-smp"
        if console.is_file() and console.parent == root / ".venv/bin":
            preferred = [str(console)]
            if query_root != root:
                preferred += ['--root', str(query_root)]
            elif self.task:
                preferred += ['--task', self.task]
            for executable in (str(console), ".venv/bin/gambit-smp"):
                bases.append([executable] if query_root == root else
                             [executable, '--root', str(query_root)])
        if self.task:
            bases += [[*entry, '--task', self.task] for entry in list(bases)]
        program = shlex.join([*preferred, "trajectory", "clues"])
        command = program + " < " + shlex.quote(str(request))
        from gambit_smp.trajectory_exploration import argument_parser, DEFAULT_CLUE_DISPLAY_BYTES
        window = self.read_window_bytes
        if window is None:
            window = DEFAULT_CLUE_DISPLAY_BYTES
        if type(window) is not int or window <= 0:
            raise ValueError('positive Evidence wire window required')
        parser = argument_parser()
        routes = [("trajectory", name) for action in parser._actions
                  if isinstance(action, argparse._SubParsersAction)
                  for name, operation in action.choices.items()
                  if operation.get_default('execution_policy') == 'read']
        from gambit_smp.cli import COMMANDS
        from importlib import import_module
        configured = set(self.profile(root, owned)['commands'])
        for name, module_name in COMMANDS.items():
            factory = (getattr(import_module('gambit_smp.'+module_name), 'argument_parser', None)
                       if name in configured else None)
            routes += list(metadata_routes(factory(), (name,))) if callable(factory) else [(name, '--help')]
        routes += [("--help",)]
        routes = sorted(set(routes))
        permissions = [shlex.join([*entry, *route]) for entry in bases for route in routes]
        # Dispatcher help is read-only even for lazily registered subcommands.
        # Whole-command glob matching covers future metadata routes, not execution.
        permissions += [shlex.join([*entry, name]) + ' * --help'
                        for entry in bases for name in COMMANDS]
        # Public introspection is not a grant for arbitrary interpreter code.
        help_code = "from gambit_smp import repository_clues; help(repository_clues)"
        interpreters = [sys.executable]
        if Path(sys.executable).parent == root / '.venv/bin':
            interpreters.append('.venv/bin/' + Path(sys.executable).name)
        for executable in interpreters:
            # Grok matches parsed words without quotes. Force whole-command
            # glob matching, not its otherwise permissive string-prefix rule.
            literal = ' '.join([executable, '-c', help_code])
            permissions.append('[' + literal[0] + ']' + glob.escape(literal[1:]))
        return dict(root=str(query_root), wireBytes=window,
                    request=str(request), command=command, permission=program,
                    permissions=permissions)

    def prepare(self):
        root = self.workspace.resolve(strict=True)
        if not re.fullmatch(r"[A-Za-z0-9_-]+", self.owner):
            raise ValueError("owner must be a single cache directory name")
        from gambit_smp.workspace import paths, bounded
        if not self.task:
            raise ValueError("--task is required; initialize one provider-independent workspace task")
        record, cache, _ = paths(root, self.task)
        state = json.loads(record.read_text())
        if state["state"] != "open":
            raise ValueError("Grok requires an open task")
        checkout = Path(state["checkout"]).resolve(strict=True)
        owned = bounded(root, cache.relative_to(root) / "agents" / self.owner)
        prompt = self.prompt.resolve(strict=True)
        if not prompt.is_relative_to(owned.resolve()):
            raise ValueError("prompt must belong to the owner directory")
        if not self.authorization.strip():
            raise ValueError("record the applicable user authorization reference")
        if not 1 <= self.max_turns <= 200:
            raise ValueError("max-turns must be in 1..200")
        argv = ["grok", "--cwd", str(checkout), "--model", MODEL,
                "--reasoning-effort", REASONING_EFFORT,
                "--permission-mode", "dontAsk", "--no-plan", "--no-subagents",
                "--disable-web-search"]
        if self.resume:
            argv += ["--resume", str(uuid.UUID(self.resume))]
        read = self.evidence_read(root, owned)
        profile = self.profile(root, owned)
        tools = "read_file,list_dir,grep,write,search_replace"
        if self.scripts or read or profile['commands']:
            tools += ",run_terminal_cmd"
        argv += ["--tools", tools, "--deny", f"Edit({owned}/grok-runs/**)"]
        from gambit_smp.storage_policy import EVIDENCE_CACHE_SUFFIXES
        for suffix in sorted(EVIDENCE_CACHE_SUFFIXES):
            argv += ['--deny', f'Edit({root}/evidence/**/*{suffix})']
        for mode, rule in (('read', 'Read'), ('edit', 'Edit')):
            for path in profile[mode]:
                argv += ['--allow', rule+'('+path+')']
        executables = [str(root/'.venv/bin/gambit-smp'), '.venv/bin/gambit-smp']
        for executable in executables:
            for command in profile['commands']:
                argv += ['--allow', 'Bash('+shlex.join([executable, '--task', self.task, command])+' *)']
        if read and read['root'] != str(root):
            argv += ['--deny', 'Edit(' + read['root'] + '/**)']
        for directory in (".grok", ".codex", ".claude", ".cursor", ".ssh", ".aws"):
            argv += ["--deny", "Read(" + str(Path.home() / directory) + "/**)"]
        for key in self.scripts:
            if not re.fullmatch(r"[a-f0-9]{64}",key):raise ValueError("terminal grants require a literal sealed program key")
            from gambit_smp.task_migration import script_record
            from gambit_smp.workspace import identifier
            entry=json.loads(script_record(root,self.task,identifier(key)).read_text())
            if entry['state']!='migrated' or not entry['enabled']:
                raise ValueError('terminal grant requires enabled sealed task program')
            script=bounded(root,Path(entry['path']).relative_to(root))
            if not script.is_relative_to(cache/'programs') or hashlib.sha256(script.read_bytes()).hexdigest()!=entry['sha256']:
                raise ValueError('terminal task program source changed')
            command=[sys.executable,'-m','gambit_smp','workspace','--root',str(root),'run-script','--provider','grok',self.task,key]
            argv += ['--allow','Bash('+shlex.join(command)+')']
        if read:
            for permission in read["permissions"]:
                argv += ["--allow", "Bash(" + permission + ")"]
            argv += ["--rules", "Available project Evidence CLI (read-only): " + read["command"]
                     + "\nCaller-authored Scheme request data: " + read["request"]
                     + "\nWritable scratch directory: " + str(owned)
                     + "\nEvidence wire window: " + str(read['wireBytes'])
                     + " UTF-8 bytes; deferred references remain expandable. This does not bound query scope."
                     + "\nInterface help: " + read["permission"] + " --help"
                     + "\nQuery output: Scheme data on stdout. Shell output redirection and mixed command chains"
                     + " are outside the read grant; owner-local writes use the edit tools."
                     + "\nRegistered task commands: " + (', '.join(profile['commands']) or 'none')
                     + "\nTerminal permission covers those dispatcher commands and read/help routes, not general shell."
                     + " Execution remains subject to the framework's source and evidence checks."]
        if self.resume:
            session=bounded(root,'.state/provider-sessions/'+self.task+'/'+self.owner+'.json')
            prior=json.loads(session.read_text()) if session.exists() else {}
            if (prior.get('sessionId')!=str(uuid.UUID(self.resume)) or prior.get('task')!=self.task or
                    prior.get('authorizationReference')!=self.authorization):
                raise ValueError('resume session is not bound to this task, owner and authorization')
        text = prompt.read_text()
        argv += ["--max-turns", str(self.max_turns), "--output-format", "streaming-json", "-p", text]
        return root, owned, argv, hashlib.sha256(text.encode()).hexdigest()


def completion(path):
    """Expose terminal metadata only, never thought/text/tool payloads."""
    result = None
    with path.open() as stream:
        for line in stream:
            try:
                event = json.loads(line)
            except (ValueError, TypeError):
                continue
            if isinstance(event, dict) and event.get("type") == "end":
                result = {key: event.get(key) for key in
                          ("sessionId", "stopReason", "num_turns", "total_cost_usd")}
    return result


def write_record(path, value):
    temporary = path.with_suffix(".tmp")
    with temporary.open("w") as stream:
        json.dump(value, stream, indent=2)
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())
    temporary.replace(path)


def terminal_deliveries(path):
    """Observe public terminal delivery, not private reasoning or query intent."""
    completed = {}
    with path.open() as stream:
        for line in stream:
            try:
                event = json.loads(line)
            except (ValueError, TypeError):
                continue
            if not isinstance(event, dict) or event.get('type') != 'tool_call_update' or event.get('status') != 'completed':
                continue
            output = event.get('rawOutput') or {}
            if isinstance(output, dict) and output.get('type') == 'Bash':
                completed[event['toolCallId']] = dict(
                    toolCallId=event['toolCallId'], bytes=output.get('total_bytes'),
                    truncated=output.get('truncated'))
    return list(completed.values())


def run(launch, *, execute=False, wall_seconds=1800):
    if execute:
        if os.environ.get('GAMBIT_SMP_TASK_PROCESS'):
            raise ValueError('provider sessions require the work-item execution owner; maintenance processes run bounded tools')
        from gambit_smp.workspace import execution_scope, paths, inherited_lease, resume
        if not launch.task:
            raise ValueError("--task is required")
        root = launch.workspace.resolve(strict=True)
        if launch.resume and inherited_lease(root, launch.task) is None:
            state_path, _, _ = paths(root, launch.task)
            state = json.loads(state_path.read_text())
            if state.get('execution') in {'running', 'interrupted'} and state.get('lastProvider') == 'grok':
                # Authentication precedes reconciliation; the existing reconciler
                # rejects live/unknown custody and never reruns a native action.
                launch.prepare()
                resume(root, launch.task)
        with execution_scope(launch.workspace, launch.task, "grok") as (value, _, common):
            from gambit_smp.task_broker import serve
            broker=nullcontext() if os.environ.get("GAMBIT_SMP_TASK_SOCKET") else serve(launch.workspace,launch.task,os.environ["GAMBIT_SMP_TASK_RUN"],int(os.environ["GAMBIT_SMP_TASK_LOCK_FD"]))
            with broker:
                result = _run(launch, execute=True, wall_seconds=wall_seconds)
            value["exit"] = result["exit"]
            if not result.get("sessionCompleted"):value["execution"]="interrupted"
            return result
    return _run(launch, execute=False, wall_seconds=wall_seconds)


def _run(launch, *, execute=False, wall_seconds=1800):
    if wall_seconds <= 0:
        raise ValueError("positive Grok supervisor budget required")
    registration = launch.workspace.resolve()/'docs/work-items.json'
    registration_sha = hashlib.sha256(registration.read_bytes()).hexdigest() if registration.is_file() else None
    root, owned, argv, digest = launch.prepare()
    public_argv = argv[:-1] + [f"<prompt sha256={digest}>"]
    record = dict(argv=public_argv, promptSha256=digest,
                  task=launch.task,
                  authorizationReference=launch.authorization,
                  authorizationIsNotAnApprovalBypass=True,
                  reasoningEffort=REASONING_EFFORT, model=MODEL,
                  nativeAcceptanceBudgetChanged=False, executed=False)
    record["evidenceRead"] = launch.evidence_read(root, owned)
    record['agentProfile'] = launch.profile(root, owned)
    record['agentRegistrationSha256'] = registration_sha
    def registration_current():
        return (hashlib.sha256(registration.read_bytes()).hexdigest() if registration.is_file() else None) == registration_sha
    if not registration_current():
        raise ValueError('Agent registration changed during launch preparation')
    if not execute:
        return record
    attempts = owned / "grok-runs"
    attempts.mkdir(exist_ok=True)
    if not attempts.resolve().is_relative_to(owned.resolve()):
        raise ValueError("attempt directory escapes owner")
    for index in range(1, 10000):
        attempt = attempts / f"{index:04d}"
        try:
            attempt.mkdir(mode=0o700)
            break
        except FileExistsError:
            continue
    else:
        raise RuntimeError("no fresh Grok attempt directory")
    receipt = attempt / "receipt.json"
    record.update(attempt=str(attempt), wallSeconds=wall_seconds)
    write_record(receipt, record)
    started = time.monotonic()
    raw = attempt / "events.private.jsonl"
    from gambit_smp.task_processes import recorder
    child_record=recorder();child_token=uuid.uuid4().hex
    with raw.open("xb") as output, (attempt / "stderr.private.log").open("xb") as error:
        environment = dict(os.environ, GAMBIT_SMP_TASK_ID=launch.task,
                           GAMBIT_SMP_TASK_ROOT=str(root), GAMBIT_SMP_TASK_CACHE=str(owned.parent.parent))
        if record['evidenceRead']:
            environment['GAMBIT_SMP_CLUE_WIRE_BYTES'] = str(record['evidenceRead']['wireBytes'])
            environment['PYTHONIOENCODING'] = 'utf-8'
        else:
            environment.pop('GAMBIT_SMP_CLUE_WIRE_BYTES', None)
        try:
            if not registration_current():
                raise ValueError('Agent registration changed before launch')
            from gambit_smp.spawn_protocol import launch as launch_process
            process = launch_process(argv,record=child_record,token=child_token,birth_budget=min(10,wall_seconds),launch_deadline=started+wall_seconds,cwd=root,stdout=output,stderr=error,
                                       stdin=subprocess.DEVNULL, start_new_session=True,
                                       pass_fds=(int(os.environ["GAMBIT_SMP_TASK_LOCK_FD"]),),
                                       env=environment)
        except OSError as exc:
            child_record("spawn-failed",child_token,{})
            record.update(spawnError=type(exc).__name__, detail=str(exc), nativeAdmitted=False)
            write_record(receipt, record)
            raise
        from gambit_smp.workspace import bounded, write
        common = bounded(root, ".state/task-runs/" + launch.task + "/" + os.environ["GAMBIT_SMP_TASK_RUN"] + ".json")
        common_record = json.loads(common.read_text())
        common_record.update(pid=process.pid, pgid=process.pid)
        write(common, common_record)
        record.update(executed=True, pid=process.pid, pgid=process.pid)
        write_record(receipt, record)
        timed_out = False
        try:
            process.wait(timeout=max(.001,started+wall_seconds-time.monotonic()))
        except subprocess.TimeoutExpired:
            timed_out = True
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait()
        except BaseException:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()
            raise
    child_record("finished",child_token,dict(exit=process.returncode,parentReaped=True,timedOut=timed_out))
    ending = completion(raw)
    completed = (process.returncode == 0 and not timed_out
                 and ending is not None and ending.get("stopReason") == "end_turn")
    record.update(exit=process.returncode, timedOut=timed_out,
                  seconds=time.monotonic() - started, parentReaped=True,
                  completion=ending, sessionCompleted=completed,
                  nativeDescendantQuiescence="not-inferred",
                  terminalDeliveries=terminal_deliveries(raw),
                  nativeAdmitted=False)
    write_record(receipt, record)
    observed_session=None
    with raw.open() as events:
        for line in events:
            try:event=json.loads(line)
            except ValueError:continue
            if isinstance(event,dict) and event.get('type') in {'init','system','end'} and event.get('sessionId'):
                observed_session=str(uuid.UUID(event['sessionId']))
    if observed_session:
        session=bounded(root,'.state/provider-sessions/'+launch.task+'/'+launch.owner+'.json')
        write(session,dict(task=launch.task,owner=launch.owner,sessionId=observed_session,
                           authorizationReference=launch.authorization,receiptSha256=hashlib.sha256(receipt.read_bytes()).hexdigest(),
                           sessionCompleted=completed,nativeAdmitted=False))
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", type=Path, default=Path.cwd())
    parser.add_argument("--task", required=True, help="stable campaign ID shared with Codex")
    parser.add_argument("--owner", required=True)
    parser.add_argument("--prompt-file", type=Path, required=True)
    parser.add_argument("--authorization", required=True,
                        help="reference to existing user consent; does not grant approval")
    parser.add_argument("--resume")
    parser.add_argument("--script", action="append", default=[],
                        help="sealed task program key; repeat for each exact grant")
    parser.add_argument("--max-turns", type=int, default=45)
    parser.add_argument("--wall-seconds", type=float, default=1800,
                        help="Grok supervisor budget, never a native acceptance timeout")
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    launch = Launch(args.workspace, args.owner, args.prompt_file, args.authorization,
                    args.resume, tuple(args.script), args.max_turns, args.task)
    result = run(launch, execute=args.execute, wall_seconds=args.wall_seconds)
    public = result
    if args.execute:
        public = {key: result.get(key) for key in ('task', 'attempt', 'exit', 'seconds', 'completion',
            'sessionCompleted', 'nativeAdmitted', 'agentRegistrationSha256', 'model', 'reasoningEffort')}
        public['receipt'] = str(Path(result['attempt'])/'receipt.json')
    print(json.dumps(public, indent=2))
    return int(args.execute and not result.get("sessionCompleted"))


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('agent')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('agent', main))

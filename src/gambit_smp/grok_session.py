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
        program = shlex.join([*base, "trajectory", "clues"])
        command = program + " < " + shlex.quote(str(request))
        # The project documents the installed dispatcher; grant only equivalent
        # read routes, not the interpreter or the whole dispatcher.
        bases = [base]
        if query_root == root:
            bases.append([sys.executable, "-m", "gambit_smp"])
        console = Path(sys.executable).parent / "gambit-smp"
        if console.is_file() and console.parent == root / ".venv/bin":
            for executable in (str(console), ".venv/bin/gambit-smp"):
                bases.append([executable] if query_root == root else
                             [executable, '--root', str(query_root)])
        from gambit_smp.trajectory_exploration import argument_parser
        parser = argument_parser()
        routes = [("trajectory", name) for action in parser._actions
                  if isinstance(action, argparse._SubParsersAction)
                  for name, operation in action.choices.items()
                  if operation.get_default('execution_policy') == 'read']
        routes += [("trajectory", "--help"), ("research", "--help"), ("--help",)]
        permissions = [shlex.join([*entry, *route]) for entry in bases for route in routes]
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
        return dict(root=str(query_root), request=str(request), command=command, permission=program,
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
        tools = "read_file,list_dir,write,search_replace"
        if self.scripts or read:
            tools += ",run_terminal_cmd"
        argv += ["--tools", tools, "--allow", "read_file",
                 "--allow", f"Edit({owned}/**)"]
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
                     + "\nInterface help: " + read["permission"] + " --help"
                     + "\nTerminal permission covers registered read/help commands, not general shell."]
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


def run(launch, *, execute=False, wall_seconds=1800):
    if execute:
        from gambit_smp.workspace import execution_scope
        if not launch.task:
            raise ValueError("--task is required")
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
    root, owned, argv, digest = launch.prepare()
    public_argv = argv[:-1] + [f"<prompt sha256={digest}>"]
    record = dict(argv=public_argv, promptSha256=digest,
                  task=launch.task,
                  authorizationReference=launch.authorization,
                  authorizationIsNotAnApprovalBypass=True,
                  reasoningEffort=REASONING_EFFORT, model=MODEL,
                  nativeAcceptanceBudgetChanged=False, executed=False)
    record["evidenceRead"] = launch.evidence_read(root, owned)
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
    child_record("planned",child_token,dict(argv=argv,cwd=root))
    with raw.open("xb") as output, (attempt / "stderr.private.log").open("xb") as error:
        try:
            process = subprocess.Popen(argv, cwd=root, stdout=output, stderr=error,
                                       stdin=subprocess.DEVNULL, start_new_session=True,
                                       pass_fds=(int(os.environ["GAMBIT_SMP_TASK_LOCK_FD"]),),
                                       env=dict(os.environ, GAMBIT_SMP_TASK_ID=launch.task,
                                                GAMBIT_SMP_TASK_ROOT=str(root),
                                                GAMBIT_SMP_TASK_CACHE=str(owned.parent.parent)))
        except OSError as exc:
            child_record("spawn-failed",child_token,{})
            record.update(spawnError=type(exc).__name__, detail=str(exc), nativeAdmitted=False)
            write_record(receipt, record)
            raise
        child_record("started",child_token,dict(pid=process.pid))
        from gambit_smp.workspace import bounded, write
        common = bounded(root, ".state/task-runs/" + launch.task + "/" + os.environ["GAMBIT_SMP_TASK_RUN"] + ".json")
        common_record = json.loads(common.read_text())
        common_record.update(pid=process.pid, pgid=process.pid)
        write(common, common_record)
        record.update(executed=True, pid=process.pid, pgid=process.pid)
        write_record(receipt, record)
        timed_out = False
        try:
            process.wait(timeout=wall_seconds)
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
    print(json.dumps(result, indent=2))
    return int(args.execute and not result.get("sessionCompleted"))


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('agent')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('agent', main))

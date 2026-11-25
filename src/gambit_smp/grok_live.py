"""ACP provider execution under the existing task lease and process journal."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import signal
import shlex
import shutil
import subprocess
import sys
import threading
import time
import uuid

from gambit_smp.grok_acp import AcpConnection, AcpOutcomeUnknown
from gambit_smp.grok_control import serve
from gambit_smp.grok_session import MODEL, REASONING_EFFORT, write_record


def supervisor_sources(root):
    names = sorted(str(path.relative_to(root)) for path in (root / 'src/gambit_smp').rglob('*.py'))
    names.append('docs/work-items.json')
    return {name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in names}


def permission_boundary_verified(launch):
    """Admit only the exact provider and supervisor covered by retained controls."""
    try:
        from gambit_smp.workspace import bounded, identifier
        root = launch.workspace.resolve(strict=True)
        task = identifier(launch.task)
        path = bounded(root, ".state/provider-validation/" + task + ".json")
        attestation = json.loads(path.read_text())
        if attestation.get("task") != launch.task or attestation.get("result") != "passed":
            return False
        required_sources = set(supervisor_sources(root))
        if set(attestation["sources"]) != required_sources:
            return False
        prefix = ".cache/tasks/" + launch.task + "/agents/dev-acp-read-v3/grok-runs/"
        required_controls = {prefix + attempt + "/events.private.jsonl" for attempt in
                             ("0017", "0018", "0019", "0020", "0021", "0022", "0023")}
        if set(attestation["controls"]) != required_controls:
            return False
        binary = Path(shutil.which("grok")).resolve(strict=True)
        if hashlib.sha256(binary.read_bytes()).hexdigest() != attestation["providerSha256"]:
            return False
        for relative, digest in attestation["sources"].items():
            if hashlib.sha256((root / relative).read_bytes()).hexdigest() != digest:
                return False
        for relative, digest in attestation["controls"].items():
            if hashlib.sha256((root / relative).read_bytes()).hexdigest() != digest:
                return False
            receipt = json.loads((root / relative).with_name("receipt.json").read_text())
            if receipt.get("supervisorSources") != attestation["sources"] or receipt.get("providerSha256") != attestation["providerSha256"]:
                return False
        return True
    except (OSError, ValueError, TypeError, KeyError):
        return False


def run(launch, *, wall_seconds):
    if not permission_boundary_verified(launch):
        raise RuntimeError("ACP live execution disabled: provider read permissions are not verified")
    from gambit_smp.spawn_protocol import launch as spawn
    from gambit_smp.task_processes import recorder
    from gambit_smp.workspace import bounded, context_run, write

    root, owned, original, prompt_digest = launch.prepare()
    registration = root / "docs/work-items.json"
    registration_digest = hashlib.sha256(registration.read_bytes()).hexdigest() if registration.is_file() else None
    source_digests = supervisor_sources(root)
    provider_digest = hashlib.sha256(Path(shutil.which("grok")).resolve(strict=True).read_bytes()).hexdigest()
    # The headless prompt and resume switches are replaced by ACP requests.
    argv = original[:original.index("--max-turns")]
    if launch.resume:
        index = argv.index("--resume")
        del argv[index:index + 2]
    argv += ["--max-turns", str(launch.max_turns), "agent", "--model", MODEL,
             "--reasoning-effort", REASONING_EFFORT]
    attempts = owned / "grok-runs"
    attempts.mkdir(exist_ok=True)
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
    # Project-native permission rules are loaded from the process/session cwd;
    # a private attempt directory avoids changing the shared checkout policy.
    policy_text = '[permission]\nask = ["Read", "Grep", "Edit", "Bash"]\n'
    if launch.resume:
        previous = []
        for item in attempts.iterdir():
            saved = item / "receipt.json"
            if item == attempt or not saved.is_file():
                continue
            prior = json.loads(saved.read_text())
            if prior.get("sessionId") == launch.resume and prior.get("sessionCwd"):
                previous.append(prior)
        if not previous:
            raise ValueError("ACP resume requires the original session context")
        context = Path(previous[0]["sessionCwd"]).resolve(strict=True)
        if not context.is_relative_to(attempts.resolve()) or context.name != "context":
            raise ValueError("ACP resume context escapes task custody")
        policy = context / ".grok/config.toml"
        if policy.is_symlink() or policy.read_text() != policy_text:
            raise ValueError("ACP resume policy changed")
        if any(p.get("sessionCwd") != str(context) or p.get("policySha256") != hashlib.sha256(policy.read_bytes()).hexdigest() for p in previous):
            raise ValueError("ACP session context binding changed")
    else:
        context = attempt / "context"
        policy_dir = context / ".grok"
        policy_dir.mkdir(parents=True, mode=0o700)
        policy = policy_dir / "config.toml"
        policy.write_text(policy_text)
    policy_digest = hashlib.sha256(policy.read_bytes()).hexdigest()
    argv[argv.index("--cwd") + 1] = str(context)
    agent_profile = attempt / "agent-profile.md"
    agent_profile.write_text(
        "---\nname: smp-task\ndescription: Task-scoped execution\ntools:\n"
        "  - read_file\n  - list_dir\n  - grep\n  - write\n"
        "  - search_replace\n  - run_terminal_cmd\n---\n"
        "Follow the task instructions and the registered workspace rules.\n")
    argv += ["--agent-profile", str(agent_profile), "stdio"]
    record = {
        "task": launch.task, "owner": launch.owner, "attempt": str(attempt),
        "transport": "acp", "promptSha256": prompt_digest,
        "authorizationReference": launch.authorization, "model": MODEL,
        "reasoningEffort": REASONING_EFFORT, "agentRegistrationSha256": registration_digest,
        "nativeAcceptanceBudgetChanged": False, "nativeAdmitted": False,
        "executed": False, "sessionCompleted": False, "wallSeconds": wall_seconds,
        "policySha256": policy_digest, "sessionCwd": str(context),
        "supervisorSources": source_digests, "providerSha256": provider_digest,
    }
    write_record(receipt, record)
    started = time.monotonic()
    child_record = recorder()
    token = uuid.uuid4().hex
    process = None
    session = None
    result = None
    error = None
    timed_out = False
    ready = threading.Event()
    prompt_open = threading.Event()
    notification_lock = threading.Lock()
    raw_path = attempt / "events.private.jsonl"
    environment = dict(os.environ, GAMBIT_SMP_TASK_ID=launch.task,
                       GAMBIT_SMP_TASK_ROOT=str(root),
                       GAMBIT_SMP_TASK_CACHE=str(owned.parent.parent),
                       PYTHONIOENCODING="utf-8")
    # GROK_CONFIG does not carry permission rules: Grok drops that table from
    # the environment overlay. Never represent it as a permission boundary.
    environment.update(GROK_SUBAGENTS="0", GROK_DISABLE_AUTOUPDATER="1", GROK_WEB_FETCH="0")
    read = launch.evidence_read(root, owned)
    profile = {**launch.profile(root, owned), 'task': launch.task}
    script_grants = {
        shlex.join([sys.executable, '-m', 'gambit_smp', 'workspace', '--root', str(root),
                    'run-script', '--provider', 'grok', launch.task, key])
        for key in launch.scripts
    }
    if read:
        environment["GAMBIT_SMP_CLUE_WIRE_BYTES"] = str(read["wireBytes"])
    else:
        environment.pop("GAMBIT_SMP_CLUE_WIRE_BYTES", None)

    def remaining():
        seconds = wall_seconds - (time.monotonic() - started)
        if seconds <= 0:
            raise TimeoutError("ACP supervisor deadline elapsed")
        return seconds

    with raw_path.open("x", encoding="utf-8") as raw, (attempt / "stderr.private.log").open("x") as stderr:
        def notification(message):
            with notification_lock:
                raw.write(json.dumps(message, ensure_ascii=False) + "\n")
                raw.flush()
            if prompt_open.is_set() and message.get("method") == "session/update":
                kind = message.get("params", {}).get("update", {}).get("sessionUpdate")
                if kind in {"agent_thought_chunk", "agent_message_chunk", "tool_call"}:
                    ready.set()

        def permission_request(params):
            from gambit_smp.grok_permissions import permission_decision
            option = permission_decision(params, root=root, session=session, profile=profile,
                                         evidence_read=read, script_grants=script_grants)
            with notification_lock:
                raw.write(json.dumps({"permissionRequest": params, "selectedOption": option}, ensure_ascii=False) + "\n")
                raw.flush()
            return option

        try:
            current_digest = hashlib.sha256(registration.read_bytes()).hexdigest() if registration.is_file() else None
            if current_digest != registration_digest:
                raise ValueError("Agent registration changed before launch")
            process = spawn(
                argv, record=child_record, token=token,
                birth_budget=min(10, remaining()), launch_deadline=started + wall_seconds,
                cwd=context, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=stderr,
                text=True, bufsize=1, start_new_session=True,
                pass_fds=(int(os.environ["GAMBIT_SMP_TASK_LOCK_FD"]),), env=environment)
            common = context_run(root, launch.task, os.environ["GAMBIT_SMP_TASK_RUN"])
            current = json.loads(common.read_text())
            current.update(pid=process.pid, pgid=process.pid)
            write(common, current)
            record.update(executed=True, pid=process.pid, pgid=process.pid)
            write_record(receipt, record)
            client = AcpConnection(process.stdout, process.stdin, on_notification=notification,
                                   on_permission=permission_request)
            init = client.request("initialize", {"protocolVersion": 1, "clientCapabilities": {}},
                                  timeout=min(20, remaining()))
            if init.get("protocolVersion") != 1:
                raise ValueError("ACP protocol version mismatch")
            methods = [row["id"] for row in init.get("authMethods", [])]
            auth = init.get("_meta", {}).get("defaultAuthMethodId")
            if auth not in methods:
                auth = "cached_token"
            if auth in methods:
                client.request("authenticate", {"methodId": auth}, timeout=min(30, remaining()))
            if launch.resume:
                session = str(uuid.UUID(launch.resume))
                client.request("session/load", {"sessionId": session, "cwd": str(context), "mcpServers": []},
                               timeout=min(30, remaining()))
            else:
                created = client.request("session/new", {"cwd": str(context), "mcpServers": []},
                                         timeout=min(30, remaining()))
                session = str(uuid.UUID(created["sessionId"]))
            record["sessionId"] = session
            write_record(receipt, record)
            descriptor = bounded(root, ".state/provider-control/" + launch.task + "/" + launch.owner + ".json")
            prompt = launch.prompt.read_text()
            if hashlib.sha256(prompt.encode()).hexdigest() != prompt_digest:
                raise ValueError("prompt changed before submission")
            with ThreadPoolExecutor(max_workers=1) as executor:
                prompt_open.set()
                future = executor.submit(client.request, "session/prompt", {
                    "sessionId": session, "prompt": [{"type": "text", "text": prompt}],
                }, timeout=remaining())
                while not ready.wait(min(.2, remaining())) and not future.done():
                    pass
                if future.done():
                    result = future.result()
                else:
                    with serve(client, task=launch.task, owner=launch.owner,
                               run=os.environ["GAMBIT_SMP_TASK_RUN"], session=session,
                               authorization=launch.authorization, descriptor=descriptor, attempt=attempt):
                        result = future.result()
        except (AcpOutcomeUnknown, TimeoutError) as exc:
            timed_out = isinstance(exc, TimeoutError) or 'deadline elapsed' in str(exc)
            error = type(exc).__name__
        except Exception as exc:
            error = type(exc).__name__ + ": " + str(exc)[:500]
        finally:
            if process is not None:
                try:
                    process.stdin.close()
                except OSError:
                    pass
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
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
                child_record("finished", token, {
                    "exit": process.returncode, "parentReaped": True, "timedOut": timed_out,
                })
                if 'client' in locals():
                    client._thread.join(timeout=5)
                process.stdout.close()
    completed = (result is not None and result.get("stopReason") == "end_turn" and error is None
                 and process is not None and process.returncode == 0
                 and policy.is_file() and hashlib.sha256(policy.read_bytes()).hexdigest() == policy_digest
                 and (hashlib.sha256(registration.read_bytes()).hexdigest() if registration.is_file() else None)
                 == registration_digest)
    record.update(exit=0 if completed else 1, processExit=process.returncode if process else None,
                  parentReaped=process is not None, timedOut=timed_out, error=error,
                  completion={"sessionId": session, "stopReason": result.get("stopReason")} if result else None,
                  sessionCompleted=completed, seconds=time.monotonic() - started,
                  nativeDescendantQuiescence="not-inferred")
    write_record(receipt, record)
    if session:
        binding = bounded(root, ".state/provider-sessions/" + launch.task + "/" + launch.owner + ".json")
        write(binding, {"task": launch.task, "owner": launch.owner, "sessionId": session,
                        "authorizationReference": launch.authorization,
                        "receiptSha256": hashlib.sha256(receipt.read_bytes()).hexdigest(),
                        "sessionCompleted": completed, "nativeAdmitted": False})
    return record

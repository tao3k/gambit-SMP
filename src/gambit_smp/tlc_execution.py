"""Compile unchanged Quint properties and run TLC with explicit liveness scheduling."""
import hashlib
import json
from pathlib import Path
import re
import shutil
import time

from gambit_smp.framework import available_processors, digest, execute


def runtime_config(path):
    saved = json.loads(Path(path).read_text()) if path else {}
    if set(saved) - {"workers", "maxHeap", "stackSize"}:
        raise ValueError("unsupported TLC runtime config key")
    workers = saved.get("workers", available_processors())
    if type(workers) is not int or workers <= 0:
        raise ValueError("positive TLC worker count required")
    heap, stack = saved.get("maxHeap", "-Xmx8G"), saved.get("stackSize", "-Xss515m")
    if not re.fullmatch(r"-Xmx[1-9][0-9]*[kKmMgG]", heap) or not re.fullmatch(
            r"-Xss[1-9][0-9]*[kKmMgG]", stack):
        raise ValueError("invalid JVM heap or stack setting")
    return workers, heap, stack


def compiled_check(snapshot, *, initializer, invariant, timeout, cwd, endpoint,
                   jar, temporal=None, step=None, config=None, executable="quint"):
    """One total deadline, no state constraints or omitted final temporal property."""
    started = time.monotonic()
    deadline = started + timeout
    snapshot, cwd, jar = Path(snapshot), Path(cwd), Path(jar).resolve(strict=True)
    java = Path(shutil.which("java") or "java").resolve(strict=True)
    workers, heap, stack = runtime_config(config)
    jar_hash, java_hash, model_hash = digest(jar), digest(java), digest(snapshot)
    config_hash = digest(config) if config else None
    identity = {"backend": "quint-compile-tlc", "livenessSchedule": "final",
                "tlcJarSha256": jar_hash, "javaLauncherSha256": java_hash,
                "modelSha256": model_hash, "workers": workers,
                "maxHeap": heap, "stackSize": stack, "artifacts": {}}
    output = ""

    def result(code, timed_out, phase):
        stable = (digest(jar) == jar_hash and digest(java) == java_hash and
                  digest(snapshot) == model_hash and
                  (config is None or digest(config) == config_hash))
        identity.update(phase=phase, inputsStable=stable)
        return code, output, timed_out, time.monotonic() - started, identity

    remaining = deadline - time.monotonic()
    if remaining <= 0:
        return result(-9, True, "identity")
    code, version, timed_out, _ = execute([str(java), "-version"], cwd, remaining)
    identity["javaVersionSha256"] = hashlib.sha256(version.encode()).hexdigest()
    if code != 0 or timed_out:
        output = "[java-identity]\n" + version
        return result(code, timed_out, "identity")
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", snapshot.stem):
        raise ValueError("invalid compiled model module name")
    tla, cfg = cwd / (snapshot.stem + ".tla"), cwd / (snapshot.stem + ".cfg")
    if tla.exists() or cfg.exists():
        raise ValueError("fresh compiled model output required")
    # Quint 0.33.0's --out serializes the compiler IR before target output. The
    # public TLA+ target is stdout, even when --target and --out are both given.
    command = [executable, "compile", str(snapshot), "--target", "tlaplus", "--verbosity", "0",
               "--init", initializer, "--step", step or "step", "--invariant", invariant,
               "--apalache-version", "0.62.1", "--server-endpoint", endpoint]
    if temporal:
        command.extend(["--temporal", temporal])
    remaining = deadline - time.monotonic()
    if remaining <= 0:
        return result(-9, True, "compile")
    code, compiled, timed_out, _ = execute(command, cwd, remaining)
    output = "[quint-compile]\n" + compiled
    if code != 0 or timed_out:
        return result(code, timed_out, "compile")
    headers = list(re.finditer(r"^-+ MODULE ([A-Za-z_][A-Za-z0-9_]*) -+[^\n]*\n",
                              compiled, re.MULTILINE))
    header = headers[0] if len(headers) == 1 else None
    end = re.search(r"^=+[ \t]*$", compiled[header.end():], re.MULTILINE) if header else None
    text = (compiled[header.start():header.end() + end.end()] + "\n") if end else ""
    wrappers = ["q_init", "q_step", "q_inv"] + (["q_temporalProps"] if temporal else [])
    if not text or header.group(1) != snapshot.stem or any(
            not re.search(r"^" + name + r"\s*==", text, re.MULTILINE) for name in wrappers):
        output += "\nCompiled model does not expose the requested Quint wrappers.\n"
        return result(2, False, "compile")
    tla.write_text(text)
    cfg.write_text("INIT q_init\nNEXT q_step\nINVARIANT q_inv\n" +
                   ("PROPERTY q_temporalProps\n" if temporal else ""))
    identity["artifacts"] = {tla.name: digest(tla), cfg.name: digest(cfg)}
    remaining = deadline - time.monotonic()
    if remaining <= 0:
        return result(-9, True, "tlc")
    # Match Quint's normal deadlock flag; the explicit progress property keeps
    # its own enabled(step) check. `final` is not `off`: finalCheck still runs.
    scratch = cwd / "states"
    scratch.mkdir(exist_ok=False)
    command = [str(java), heap, stack, "-Djava.io.tmpdir=" + str(cwd), "-cp", str(jar),
               "tlc2.TLC", "-deadlock", "-lncheck", "final", "-workers", str(workers),
               "-metadir", str(scratch), str(tla)]
    try:
        code, checked, timed_out, _ = execute(command, cwd, remaining)
    finally:
        # execute waits for exit or kills and reaps its process group first.
        # Preserve the compiled spec, logs and traces, not the disk-state cache.
        shutil.rmtree(scratch)
        identity["tlcScratchRemoved"] = True
    output += "\n[TLC-final]\n" + checked
    if any(digest(cwd / name) != sha for name, sha in identity["artifacts"].items()):
        output += "\nCompiled checker inputs changed.\n"
        code = 2
    return result(code, timed_out, "tlc")

"""Witness Gambit's existing Make recipes inside a managed bootstrap lease."""

import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import time

from gambit_smp.framework import digest
from gambit_smp.workspace import write


def _build_memory_budget_bytes():
    """Return the active runner RSS budget (flag/env overridable, <= 8 GiB default)."""
    env_budget = os.environ.get("GAMBIT_BUILD_MEMORY_BYTES")
    if env_budget is not None and env_budget.strip():
        return max(512 * 1024 ** 2, int(env_budget))
    try:
        physical = os.sysconf("SC_PAGE_SIZE") * os.sysconf("SC_PHYS_PAGES")
        if isinstance(physical, int) and physical > 0:
            return min(physical, 8 * 1024 ** 3)
    except (AttributeError, OSError, ValueError):
        pass
    return 8 * 1024 ** 3


def estimate_recipe_memory_bytes(kind, ordered_paths):
    """Estimate peak RSS of one compiler/emitter recipe from its input size.

    Allows full make -j8 concurrency for normal C files (160 MiB each -> 8 jobs
    = 1.28 GiB) while dynamically throttling simultaneous giant generated C files
    (2-8 MiB -> 1.2-2.2 GiB each) so the process group stays strictly < 8 GiB.
    """
    mib = 1024 * 1024
    if kind == "object":
        c_bytes = 0
        for p in ordered_paths:
            path = Path(p)
            if path.suffix == ".c" and path.is_file():
                c_bytes += path.stat().st_size
        # Empirical GCC-16 peak RSS on Gambit generated C: ~450x source bytes
        # clamped to [160 MiB, 2200 MiB].
        est = max(160 * mib, min(2200 * mib, c_bytes * 450))
        return est
    if kind == "emit":
        return 768 * mib
    return 256 * mib


def _live_group_rss_bytes():
    """Read live kernel RSS of our current process group without spawning a child."""
    try:
        from gambit_smp.process_identity import group_memory
        return int(group_memory(os.getpgrp()).get("rssBytes", 0))
    except Exception:
        return 0


def _pid_alive(pid):
    try:
        os.kill(int(pid), 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    except OSError:
        return False


class _AdaptiveMemorySlot:
    """Deadlock-free real-time memory-pressure admission gate across make -jN workers."""

    def __init__(self, directory, est_bytes, budget_bytes=None):
        self.directory = Path(directory)
        self.lock_path = self.directory / ".memory-slots.lock"
        self.state_path = self.directory / ".memory-slots.json"
        self.est_bytes = int(est_bytes)
        self.budget_bytes = int(budget_bytes) if budget_bytes else _build_memory_budget_bytes()
        self.pid_key = str(os.getpid())
        self.acquired = False

    def _read_active(self):
        if not self.state_path.is_file():
            return {}
        try:
            data = json.loads(self.state_path.read_text())
            if not isinstance(data, dict):
                return {}
            return {k: int(v) for k, v in data.items() if k.isdigit() and _pid_alive(int(k))}
        except (OSError, ValueError, TypeError):
            return {}

    def _write_active(self, active):
        tmp = self.state_path.with_suffix(f".tmp.{self.pid_key}")
        tmp.write_text(json.dumps(active, sort_keys=True) + "\n")
        tmp.replace(self.state_path)

    def __enter__(self):
        soft_est_limit = int(self.budget_bytes * 0.68)
        live_limit = int(self.budget_bytes * 0.75)
        self.directory.mkdir(parents=True, exist_ok=True)
        while True:
            with self.lock_path.open("a+") as lock_file:
                fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
                try:
                    active = self._read_active()
                    active_est = sum(active.values())
                    # Empty active set ALWAYS admits (strict deadlock freedom).
                    if not active:
                        admit = True
                    else:
                        live_rss = _live_group_rss_bytes()
                        admit = (
                            active_est + self.est_bytes <= soft_est_limit
                            and live_rss + self.est_bytes <= live_limit
                        )
                    if admit:
                        active[self.pid_key] = self.est_bytes
                        self._write_active(active)
                        self.acquired = True
                        return self
                finally:
                    fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)
            time.sleep(0.25)

    def __exit__(self, exc_type, exc, tb):
        if not self.acquired:
            return False
        try:
            with self.lock_path.open("a+") as lock_file:
                fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
                try:
                    active = self._read_active()
                    active.pop(self.pid_key, None)
                    self._write_active(active)
                finally:
                    fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)
        except OSError:
            pass
        self.acquired = False
        return False


def read(path):
    return json.loads(path.read_text())


def file_identity(path):
    stat = path.stat()
    return {"sha256": digest(path), "device": stat.st_dev, "inode": stat.st_ino,
            "size": stat.st_size, "mode": stat.st_mode & 0o777}


def capture_command(argv):
    """Read a loader tool through the same birth/exec boundary as Make recipes."""
    from gambit_smp.research_flow import _approved_command
    from gambit_smp.task_processes import check_output
    approval = _approved_command.set(tuple(str(part) for part in argv))
    try:
        return check_output(argv, text=True)
    finally:
        _approved_command.reset(approval)


def emitter_loader_identity(path, run=capture_command):
    if sys.platform == "darwin":
        output = run(["/usr/bin/otool", "-L", str(path)])
        libraries = [line.strip().split(" (compatibility version ", 1)[0]
                     for line in output.splitlines() if line.startswith("\t")]
        if not libraries or any(not name.startswith(("/usr/lib/", "/System/Library/"))
                                for name in libraries):
            raise ValueError("witnessed emitter must use the static Gambit profile and system libraries")
    elif sys.platform.startswith("linux"):
        output = run(["readelf", "-d", str(path)])
        libraries = re.findall(r"\(NEEDED\).*?\[([^\]]+)\]", output)
        if ("(RPATH)" in output or "(RUNPATH)" in output
                or any(not re.fullmatch(
                    r"(?:lib(?:c|m|dl|pthread|rt|util|gcc_s)|ld-linux(?:-[a-z0-9_]+)?)\.so(?:\.\d+)*",
                    name)
                       for name in libraries)):
            raise ValueError("witnessed emitter must use the static Gambit profile and system libraries")
    else:
        raise ValueError("Make emitter witness requires a supported native loader")
    return {"system": list(os.uname()), "libraries": libraries}


def freeze_emitter(directory, source, pass_number, run=capture_command):
    target = directory / f"emitter-{pass_number}" / "gsc-boot"
    target.parent.mkdir()
    before = file_identity(source)
    shutil.copyfile(source, target)
    target.chmod(0o555)
    identity = file_identity(target)
    if before != file_identity(source) or identity["sha256"] != before["sha256"]:
        raise ValueError("bootstrap emitter changed during preservation")
    write(target.parent / "identity.json", {"file": identity, "installed": before,
                                           "loader": emitter_loader_identity(target, run)})
    return target


def prepare(directory, source, generated, gcc, scheme_inputs, run=capture_command, *, prior_origins=None):
    directory.mkdir()
    source = source.resolve()
    boot = source / "gsc-boot"
    freeze_emitter(directory, boot, 1, run)
    gcc = Path(gcc).resolve(strict=True)
    write(directory / "inputs.json", {
        "workspace": str(source), "generated": sorted(generated), "schemeInputs": scheme_inputs,
        "gcc": str(gcc), "gccSha256": digest(gcc),
        **({"priorOrigins": prior_origins} if prior_origins else {}),
        "makefiles": {name: digest(source / name)
                      for name in ("makefile", "lib/makefile", "gsi/makefile", "gsc/makefile")},
    })
    package_root = Path(__file__).resolve().parent.parent
    return "GAMBIT_BUILD_WITNESS=" + shlex.join(
        ["env", "PYTHONPATH=" + str(package_root), sys.executable,
         str(Path(__file__).resolve()), str(directory.resolve())])


def prepare_memory_gate(directory):
    """Return a GAMBIT_BUILD_WITNESS assignment enforcing only _AdaptiveMemorySlot."""
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True)
    package_root = Path(__file__).resolve().parent.parent
    return "GAMBIT_BUILD_WITNESS=" + shlex.join(
        ["env", "PYTHONPATH=" + str(package_root), sys.executable,
         str(Path(__file__).resolve()), "--memory-gate", str(directory.resolve())])


def action_directory(directory, pass_number, kind, name):
    key = hashlib.sha256(name.encode()).hexdigest()
    return directory / f"pass-{pass_number}" / kind / key


def completed_action(directory, pass_number, kind, name, sha=None):
    path = action_directory(directory, pass_number, kind, name) / "receipt.json"
    origin_pass = pass_number
    if not path.is_file() and pass_number == 1 and (directory / 'inputs.json').is_file():
        # Only the source-core owner supplies these already authenticated
        # per-target origins. A skipped Make target never creates a new edge.
        prior = read(directory / 'inputs.json').get('priorOrigins', {}).get(kind + ':' + name)
        if prior:
            path = Path(prior['path'])
            if digest(path) != prior['sha256']:
                raise ValueError('retained Make origin changed: ' + name)
            origin_pass = prior.get('pass', 1)
    if not path.is_file():
        raise ValueError(f"missing Make {kind} origin for {name} in pass {pass_number}")
    row = read(path)
    if (row["kind"] != kind or row["pass"] != origin_pass or row["output"] != name
            or row["exit"] != 0 or (sha is not None and row["outputSha256"] != sha)):
        raise ValueError(f"changed or incomplete Make {kind} origin for {name}")
    return row


def check_inputs(directory, pass_number, config, kind, paths):
    source = Path(config["workspace"])
    inputs = {}
    for path in dict.fromkeys(paths):
        sha = digest(path)
        inputs[str(path)] = sha
        if not path.is_relative_to(source):
            continue
        name = path.relative_to(source).as_posix()
        if path.suffix == ".o":
            completed_action(directory, pass_number, "object", name, sha)
        elif path.suffix == ".a":
            previous = "archive" if kind == "index" else "index"
            completed_action(directory, pass_number, previous, name, sha)
        elif name in config["generated"]:
            completed_action(directory, pass_number, "emit", name, sha)
    return inputs


def run_recipe(directory, pass_number, kind, target, prerequisites, argv):
    config = read(directory / "inputs.json")
    source = Path(config["workspace"])
    cwd = Path.cwd()
    output = (cwd / target).resolve()
    if (not output.is_relative_to(source) or output.parent != cwd
            or cwd.parent != source or cwd.name not in {"lib", "gsc", "gsi"}
            or (cwd / target).is_symlink()):
        raise ValueError("Make output escapes its managed build directory")
    name = output.relative_to(source).as_posix()
    command = list(argv)
    executable = Path(shutil.which(command[0]) or command[0]).resolve(strict=True)
    boot = source / "gsc-boot"
    if kind == "emit":
        if executable != boot:
            raise ValueError("Make emitter does not resolve to the stage bootstrap path")
        executable = directory / f"emitter-{pass_number}" / "gsc-boot"
        emitter = read(executable.parent / "identity.json")
        if any(os.environ.get(name) for name in ("DYLD_LIBRARY_PATH", "DYLD_INSERT_LIBRARIES",
                                                "DYLD_FRAMEWORK_PATH", "DYLD_FALLBACK_LIBRARY_PATH",
                                                "LD_LIBRARY_PATH", "LD_PRELOAD", "LD_AUDIT")):
            raise ValueError("Make emitter loader has an unbound library override")
        if file_identity(executable) != emitter["file"] or file_identity(boot) != emitter["installed"]:
            raise ValueError("Make bootstrap seed was replaced")
    if kind in {"object", "link"}:
        if str(executable) != config["gcc"] or digest(executable) != config["gccSha256"]:
            raise ValueError("Make GCC differs from the configured tool")
        if argv.count("-o") != 1 or (cwd / argv[argv.index("-o") + 1]).resolve() != output:
            raise ValueError("Make GCC output differs from the declared target")
    paths = [(cwd / path).resolve(strict=True) for path in prerequisites]
    # The expanded command supplies actual argument order, including the
    # runtime archive selected by configure for this static build.
    ordered = [(cwd / arg).resolve(strict=True) for arg in argv[1:]
               if not arg.startswith("-") and Path(arg).suffix in {".scm", ".c", ".o", ".a"}
               and (cwd / arg).resolve() != output]
    paths += ordered
    if kind == "index":
        paths.append(output)
    inputs = check_inputs(directory, pass_number, config, kind, paths)
    if kind == "link" and source / "lib/libgambit.a" not in ordered:
        raise ValueError("Make witness requires the configured static Gambit runtime archive")
    action = action_directory(directory, pass_number, kind, name)
    action.mkdir(parents=True)
    old = digest(output) if output.is_file() else None
    if kind == "emit":
        command[0] = str(executable)
    dependencies = action / "gcc.d"
    if kind == "object":
        command.extend(["-MD", "-MF", str(dependencies)])
    if kind == "link":
        link_map = action / "link.map"
        map_flag = "-map" if sys.platform == "darwin" else "-Map"
        command.extend(["-Xlinker", map_flag, "-Xlinker", str(link_map)])
    tool = file_identity(executable)
    row = {"kind": kind, "pass": pass_number, "cwd": str(cwd), "argv": argv,
           "executedArgv": command, "executable": str(executable), "tool": tool, "inputs": inputs,
           "orderedFileArguments": [str(path) for path in ordered],
           "output": name, "beforeSha256": old}
    write(action / "started.json", row)
    if old is not None and kind != "index":
        # Once Make chose to run this target, require the recipe to produce
        # a file. A successful no-op must not turn an old file into evidence.
        output.replace(action / "previous-output")
    # Multicall tools such as Darwin's ranlib select behavior from argv[0].
    # Task children install the storage audit on import, so this compiler
    # invocation uses the same birth/exec launcher as other managed commands.
    from gambit_smp.research_flow import _approved_command
    from gambit_smp.task_processes import spawn
    est_bytes = estimate_recipe_memory_bytes(kind, ordered)
    with _AdaptiveMemorySlot(directory, est_bytes):
        approval = _approved_command.set(tuple(str(part) for part in command))
        try:
            process = spawn(command, executable=str(executable))
        finally:
            _approved_command.reset(approval)
        returncode = process.wait()
    if returncode:
        if output.exists() or output.is_symlink():
            # Preserve the failed child's exact bytes, outside Make's target
            # path. A partial file cannot make the next attempt look current.
            output.replace(action / 'failed-output')
        write(action / "failed.json", {**row, "exit": returncode})
        return returncode if returncode > 0 else 128 - returncode
    if (not output.is_file() or output.is_symlink() or not output.stat().st_size
            or file_identity(executable) != tool
            or (kind == "emit" and file_identity(boot) != emitter["installed"])):
        raise ValueError(f"Make {kind} did not establish stable production of {name}")
    if any(digest(Path(path)) != sha for path, sha in inputs.items()
           if kind != "index" or Path(path) != output):
        raise ValueError(f"Make input changed during {name}")
    if kind == "object":
        _, separator, dep_paths = dependencies.read_text().replace("\\\n", " ").partition(":")
        if not separator or not dep_paths.strip():
            raise ValueError("GCC did not record the configured include closure")
        row["headersAndSources"] = {
            str(path): digest(path) for path in
            dict.fromkeys((cwd / token).resolve(strict=True) for token in shlex.split(dep_paths))}
    if kind == "link":
        if not link_map.is_file() or link_map.is_symlink() or not link_map.stat().st_size:
            raise ValueError(f"linker did not retain its map for {name}")
        row["linkMap"] = {"sha256": digest(link_map),
                          "format": "darwin" if sys.platform == "darwin" else "gnu"}
    write(action / "receipt.json", {**row, "exit": 0, "outputSha256": digest(output)})
    return 0


def promote(directory, pass_number, target, compiler):
    config = read(directory / "inputs.json")
    source = Path(config["workspace"])
    target, compiler = Path(target).resolve(), Path(compiler).resolve()
    if pass_number != 1 or target != source / "gsc-boot" or compiler != source / "gsc/gsc":
        raise ValueError("unexpected Make bootstrap promotion")
    row = completed_action(directory, 1, "link", "gsc/gsc", digest(compiler))
    if digest(target) != row["outputSha256"]:
        raise ValueError("bootstrap-post did not install the recorded compiler")
    freeze_emitter(directory, target, 2)


def finish(directory, source):
    config = read(directory / "inputs.json")
    if any(digest(source / name) != sha for name, sha in config["makefiles"].items()):
        raise ValueError("configured Make inputs changed during bootstrap")
    if any(digest(source / name) != sha for name, sha in config["schemeInputs"].items()):
        raise ValueError("Scheme generation inputs changed during bootstrap")
    passes = []
    for pass_number in (1, 2):
        emitter = directory / f"emitter-{pass_number}" / "gsc-boot"
        record = read(emitter.parent / "identity.json")
        identity = record["file"]
        if file_identity(emitter) != identity or emitter_loader_identity(emitter) != record["loader"]:
            raise ValueError("frozen emitter changed")
        for name in config["generated"]:
            completed_action(directory, pass_number, "emit", name,
                             digest(source / name) if pass_number == 2 else None)
        for kind, name in (("link", "gsc/gsc"), ("link", "gsi/gsi"), ("index", "lib/libgambit.a")):
            completed_action(directory, pass_number, kind, name,
                             digest(source / name) if pass_number == 2 else None)
        if pass_number == 2:
            completed_action(directory, 1, "link", "gsc/gsc", identity["sha256"])
            if file_identity(source / "gsc-boot") != record["installed"]:
                raise ValueError("installed bootstrap compiler differs from pass two")
        events = sorted((directory / f"pass-{pass_number}").glob("*/*/receipt.json"))
        passes.append({"emitter": str(emitter.relative_to(directory)),
                       "emitterSha256": identity["sha256"],
                       "loader": record["loader"],
                       "actions": {str(path.relative_to(directory)): digest(path) for path in events}})
    result = {"schema": "gambit-make-lineage.v1", "inputs": config, "passes": passes,
              "gsiSha256": digest(source / "gsi/gsi"), "familyAdmitted": False}
    path = directory / "lineage.json"
    write(path, result)
    return path


def verify_retained(run, binding, gsi_sha):
    """Recheck the files referenced by an admitted producer's step receipt."""
    path = (run / binding["path"]).resolve(strict=True)
    if (not path.is_relative_to(run.resolve()) or path.name != "lineage.json"
            or digest(path) != binding["sha256"] or binding["gsiSha256"] != gsi_sha):
        raise ValueError("completed Make lineage binding differs")
    record = read(path)
    if (record["schema"] != "gambit-make-lineage.v1" or record["gsiSha256"] != gsi_sha
            or len(record["passes"]) != 2):
        raise ValueError("complete two-pass Make lineage required")
    files = [path]
    for row in record["passes"]:
        for name, sha in [(row["emitter"], row["emitterSha256"]), *row["actions"].items()]:
            artifact = (path.parent / name).resolve(strict=True)
            if not artifact.is_relative_to(path.parent) or digest(artifact) != sha:
                raise ValueError(f"retained Make lineage artifact changed: {name}")
            files.append(artifact)
    return files


def audit_retained_graph(run, binding, gsi_sha, inventory, gcc_sha, *, seed_sha, locked_files=None):
    """Check the retained Make edges and their outputs against the sealed tree."""
    from gambit_smp.recipes import decode_json

    def check(condition, reason):
        if not condition:
            raise ValueError(reason)

    def bound(path, sha):
        raw = path.read_bytes()
        check(hashlib.sha256(raw).hexdigest() == sha, f"Make receipt changed: {path}")
        return decode_json(raw)

    manifest, *_ = verify_retained(run, binding, gsi_sha)
    record = bound(manifest, binding["sha256"])
    config = record["inputs"]
    workspace = Path(config["workspace"])
    generated = set(config["generated"])
    scheme = config["schemeInputs"]
    check(workspace.is_absolute() and generated and len(generated) == len(config["generated"])
          and scheme and config["gccSha256"] == gcc_sha
          and set(config["makefiles"]) == {"makefile", "lib/makefile", "gsi/makefile", "gsc/makefile"},
          "Make input inventory or GCC differs from the completed producer")

    def tree_sha(name):
        return inventory.get(name, {}).get("sha256")

    actual_scheme = {name: tree_sha(name) for name in inventory if name.endswith(".scm")
                     and Path(name).parts[0] in {"lib", "gsc", "gsi"}}
    check(actual_scheme == scheme and all(tree_sha(name) == sha for name, sha in config["makefiles"].items()),
          "Make Scheme inputs or configured makefiles differ from the sealed tree")
    for name, sha in (locked_files or {}).items():
        if name not in generated and Path(name).suffix in {".scm", ".c", ".h", ".inc"}:
            check(tree_sha(name) == sha, f"sealed Make input differs from the source lock: {name}")
    links = {"gsc/gsc", "gsi/gsi"}
    first = None
    emitter_sha = seed_sha
    for number, receipt in enumerate(record["passes"], 1):
        label = f"Make pass {number}"
        emitter = manifest.parent / f"emitter-{number}/gsc-boot"
        check(receipt["emitter"] == emitter.relative_to(manifest.parent).as_posix()
              and receipt["emitterSha256"] == emitter_sha,
              label + ": frozen emitter differs from its recorded seed or preceding GSC link")
        actions = {}
        kinds = {kind: set() for kind in ("emit", "object", "archive", "index", "link")}
        for name, sha in receipt["actions"].items():
            path = manifest.parent / name
            action = bound(path, sha)
            kind, output = action["kind"], action["output"]
            check(kind in kinds and (kind, output) not in actions
                  and action["pass"] == number and action["exit"] == 0
                  and path == action_directory(manifest.parent, number, kind, output) / "receipt.json",
                  label + ": wrong action identity for " + output)
            kinds[kind].add(output)
            actions[kind, output] = action
        check(kinds["emit"] == generated and kinds["object"] and kinds["archive"] == kinds["index"]
              and "lib/libgambit.a" in kinds["index"] and kinds["link"] == links
              and (first is None or kinds == first), label + ": incomplete or different action inventory")
        first = kinds
        dependencies = {}
        for (kind, output), action in actions.items():
            if kind == "emit":
                check(action["tool"]["sha256"] == receipt["emitterSha256"]
                      and Path(action["executedArgv"][0]) == emitter, label + ": wrong emitter for " + output)
            if kind in {"object", "link"}:
                check(action["tool"]["sha256"] == gcc_sha and action["executable"] == config["gcc"],
                      label + ": wrong GCC for " + output)
            if kind == "object":
                closure = action["headersAndSources"]
                check(bool(closure) and "-std=c23" in action["executedArgv"],
                      label + ": missing GCC/C23 input closure for " + output)
                for path, sha in closure.items():
                    source = Path(path)
                    if source.is_relative_to(workspace):
                        name = source.relative_to(workspace).as_posix()
                        expected = (actions["emit", name]["outputSha256"] if name in generated
                                    else tree_sha(name))
                        check(expected == sha, f"{label}: GCC input differs for {output}: {name}")
            if kind == "link":
                check(str(workspace / "lib/libgambit.a") in action["orderedFileArguments"],
                      label + ": missing static runtime in link for " + output)
            edges = set()
            for path, sha in action["inputs"].items():
                source = Path(path)
                if not source.is_relative_to(workspace):
                    continue
                source = source.relative_to(workspace).as_posix()
                origin = ("object" if source.endswith(".o") else
                          ("archive" if kind == "index" else "index") if source.endswith(".a") else
                          "emit" if source in generated else None)
                if origin:
                    edge = (origin, source)
                    check(actions.get(edge, {}).get("outputSha256") == sha,
                          f"{label}: {output} has no matching {origin} for {source}")
                    edges.add(edge)
                elif source in scheme:
                    check(scheme[source] == sha, f"{label}: Scheme input changed: {source}")
            if kind in {"index", "archive", "link"}:
                upstream = {"index": {"archive"}, "archive": {"object"}, "link": {"index", "object"}}[kind]
                check(bool(edges) and all(origin in upstream for origin, _ in edges)
                      and all(path in action["inputs"] for path in action["orderedFileArguments"]),
                      label + ": missing or invalid prerequisites for " + output)
            dependencies[kind, output] = edges
            if number == 2 and kind != "archive":
                check(tree_sha(output) == action["outputSha256"],
                      label + ": sealed tree differs from Make output " + output)
        reached, visiting = set(), set()

        def visit(action):
            check(action not in visiting, f"{label}: cyclic Make dependency at {action[1]}")
            if action in reached:
                return
            visiting.add(action)
            for dependency in sorted(dependencies[action]):
                visit(dependency)
            visiting.remove(action)
            reached.add(action)

        for link in sorted(links):
            visit(("link", link))
        check(reached == actions.keys(), label + ": action receipts outside the executable link closures")
        emitter_sha = actions["link", "gsc/gsc"]["outputSha256"]
    check(actions["link", "gsi/gsi"]["outputSha256"] == gsi_sha, "final Make link differs from the sealed GSI")
    return ({kind: len(names) for kind, names in first.items()},
            dict(workspace=workspace, directory=manifest.parent, actions=actions))


def preflight(ctx, configured, gcc):
    """Exercise Make's Python/loader/spawn/promotion transport before core.

    This tiny C copier is a transport fixture, never a Scheme compiler or a
    Gambit qualification. Hook definitions and the two-pass recipe come from
    the configured producer that is about to run.
    """
    from gambit_smp.gambit_build_primitives import scheme_inputs
    templates = {name: (configured / name).read_text() for name in
                 ("makefile", "lib/makefile", "gsi/makefile", "gsc/makefile")}
    hooks = {name: "\n".join(line for line in text.splitlines()
                            if line.startswith(("WITNESS_", "GAMBIT_WITNESS_PASS")))
             for name, text in templates.items() if name != "makefile"}
    if len(set(hooks.values())) != 1 or not all(hooks.values()):
        raise ValueError("Make lineage preflight requires matching configured hook definitions")
    if "from-scratch: fake_target\n" not in templates["makefile"]:
        raise ValueError("configured two-pass Make recipe missing")
    top = templates["makefile"].split("from-scratch: fake_target\n", 1)[1].split("\n\n", 1)[0]
    promotions = [line for line in templates["gsc/makefile"].splitlines()
                  if "GAMBIT_WITNESS_PASS) promote" in line]
    if len(promotions) != 1:
        raise ValueError("configured Make promotion hook missing or ambiguous")
    promotion, = promotions
    binding = {"hooks": hooks, "fromScratch": top, "promotion": promotion,
               "helperSha256": digest(Path(__file__)), "gccSha256": digest(Path(gcc)),
               "makeSha256": digest(Path(ctx.tools["make"]).resolve()),
               "pythonSha256": digest(Path(sys.executable).resolve()),
               "engineId": ctx.receipt.get("engine", {}).get("engineId")}
    # Within this one sealed run, the source-core preflight also covers the
    # following bootstrap. A changed hook/tool/helper requires a fresh check.
    for step in ctx.receipt["steps"]:
        prior = step.get("makeLineagePreflight")
        if (step.get("outcome") == "PASS" and not step.get("reused")
                and prior and prior.get("binding") == binding):
            path = ctx.out / prior["path"]
            if digest(path) != prior["sha256"] or read(path).get("binding") != binding:
                raise ValueError("retained Make lineage preflight changed")
            return prior
    directory = ctx.directory / "make-lineage-preflight"
    directory.mkdir()
    source = directory / "source"
    source.mkdir()
    emitter = r'''
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv) {
  char name[128]; const char *input = argv[argc - 1];
  if (strlen(input) < 5 || strlen(input) >= sizeof(name)) return 2;
  strcpy(name, input); strcpy(name + strlen(name) - 4, ".c");
  FILE *in = fopen(input, "rb"), *out = fopen(name, "wb");
  if (!in || !out) return 3;
  int byte; while ((byte = fgetc(in)) != EOF)
    if (fputc(byte, out) == EOF) return 4;
  return fclose(in) || fclose(out);
}
'''
    for unit in ("lib", "gsi", "gsc"):
        (source / unit).mkdir()
        (source / unit / "makefile").write_text(hooks[unit + "/makefile"] + "\n" + f'''
CC := {shlex.quote(str(gcc))}
.SECONDARY:
BUILD_OBJ_INPUT_FILENAMES_PARAM = $*.c
%.c: %.scm
	$(WITNESS_EMIT) ../gsc-boot -c $<
%.o: %.c
	$(WITNESS_OBJECT) $(CC) -std=c23 -c -o $@ $<
''')
    (source / "seed.c").write_text(emitter)
    (source / "lib/_gambit.scm").write_text("int transport_fixture(void) { return 0; }\n")
    (source / "gsc/_gsc.scm").write_text(emitter)
    (source / "gsi/_gsi.scm").write_text('#include "entry.h"\nint main(void) { return FIXTURE_EXIT; }\n')
    (source / "gsi/entry.h").write_text("#define FIXTURE_EXIT 0\n")
    for unit in ("gsi", "gsc"):
        with (source / unit / "makefile").open("a") as stream:
            stream.write(f"\n{unit}: _{unit}.o ../lib/libgambit.a\n\t$(WITNESS_LINK) $(CC) -o $@ $^\n")
    with (source / "lib/makefile").open("a") as stream:
        stream.write('''
LIBRARY_OBJECTS = _gambit.o
libgambit.a: $(LIBRARY_OBJECTS)
	$(WITNESS_ARCHIVE) ar rc $@ $^
	$(WITNESS_INDEX) ranlib $@
''')
    with (source / "gsc/makefile").open("a") as stream:
        stream.write("\nrootfromhere = ..\nEXECUTABLE = gsc\npromote: gsc\n"
                     "\tcp gsc ../gsc-boot\n" + promotion + "\n")
    (source / "makefile").write_text("from-scratch: fake_target\n" + top + "\n" + '''
fake_target:
bootclean:
	rm -f lib/*.c lib/*.o lib/*.a gsi/*.c gsi/*.o gsi/gsi gsc/*.c gsc/*.o gsc/gsc
core:
	$(MAKE) -C lib libgambit.a
	$(MAKE) -C gsi gsi
	$(MAKE) -C gsc gsc
bootstrap: core
	$(MAKE) -C gsc promote
''')
    ctx.require("lineage-preflight-seed", [str(gcc), "-std=c23", "seed.c", "-o", "gsc-boot"],
                source, min(30, ctx.remaining()))
    witness = prepare(directory / "lineage", source,
                      ["lib/_gambit.c", "gsi/_gsi.c", "gsc/_gsc.c"], gcc, scheme_inputs(source),
                      lambda argv: ctx.require("lineage-preflight-loader", argv, source, min(10, ctx.remaining())))
    ctx.require("lineage-preflight-make", [ctx.tools["make"], witness, "from-scratch"],
                source, min(60, ctx.remaining()))
    manifest = finish(directory / "lineage", source)
    ctx.require("lineage-preflight-executable", [str(source / "gsi/gsi")], source, min(5, ctx.remaining()))
    path = directory / "receipt.json"
    write(path, {"schema": "make-lineage-transport-preflight.v1", "binding": binding,
                 "lineageSha256": digest(manifest), "familyAdmitted": False})
    return {"path": str(path.relative_to(ctx.out)), "sha256": digest(path), "binding": binding}


def main(args):
    if args and args[0] == "--memory-gate":
        gate_dir = Path(args[1])
        rest = list(args[2:])
        if rest and rest[0] in {"1", "2"}:
            rest = rest[1:]
        kind = rest[0]
        if kind == "promote":
            return 0
        if kind not in {"emit", "object", "archive", "index", "link"}:
            raise ValueError("unknown Make memory-gate recipe kind")
        separator = rest.index("--")
        ordered_paths = rest[2:separator]
        command = rest[separator + 1:]
        est_bytes = estimate_recipe_memory_bytes(kind, ordered_paths)
        from gambit_smp.research_flow import _approved_command
        from gambit_smp.task_processes import spawn
        resolved = shutil.which(command[0]) or command[0]
        with _AdaptiveMemorySlot(gate_dir, est_bytes):
            approval = _approved_command.set(tuple(str(part) for part in command))
            try:
                process = spawn(command, executable=str(Path(resolved).resolve()))
            finally:
                _approved_command.reset(approval)
            rc = process.wait()
        return rc if rc >= 0 else 128 - rc
    directory, pass_number, kind, target, *rest = args
    directory = Path(directory)
    pass_number = int(pass_number)
    if pass_number not in {1, 2}:
        raise ValueError("unknown Make bootstrap pass")
    if kind == "promote":
        compiler, = rest
        promote(directory, pass_number, target, compiler)
        return 0
    if kind not in {"emit", "object", "archive", "index", "link"}:
        raise ValueError("unknown Make recipe witness")
    separator = rest.index("--")
    return run_recipe(directory, pass_number, kind, target, rest[:separator], rest[separator + 1:])


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(f"Make lineage refused: {error}")

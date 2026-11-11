"""Source-bound child GC observations; admission remains in Scheme.

Completed GC is not completed mutator work. This collector is diagnostic until
the configured observation premise has been qualified against observer effects.
"""
from contextlib import ExitStack
import hashlib
import json
import re
import secrets
import socket
import struct

from gambit_smp.framework import digest
from gambit_smp.process_observation import EvidenceProgress
from gambit_smp.suite_primitives import SuiteCompletionProgress


NUMBER = r"[0-9]+(?:\.[0-9]+)?"
GC = re.compile(r"\*\*\* GC: " + NUMBER + r"(?:us|ms|s), (-?" + NUMBER
    + r")([KMG]) alloc, " + NUMBER + r"[KMG] heap, " + NUMBER
    + r"[KMG] live \([0-9]+% [0-9]+\+[0-9]+\)\n")
READ = "(read-line port #f)"
LOAD = '(run "../gsi/gsi" (add-inst-dirs "-:debug-settings=-,io-settings=lu") "-f" file)'


def validate(config, inputs):
    from gambit_smp.recipes import fields
    fields(config, ("kind", "files", "forwarder", "runnerSha256", "reporterSha256", "manifest", "entry", "constructor"),
           ("transport", "observer"))
    if config["kind"] != "completed-child-gc":
        raise ValueError("known source-bound child observation required")
    if (not isinstance(config["files"], list) or not config["files"]
            or any(not isinstance(name, str) for name in config["files"])
            or len(set(config["files"])) != len(config["files"])
            or any(not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9_./-]+", name)
                   or ".." in name.split("/") or name.startswith("/") for name in config["files"])):
        raise ValueError("explicit unique relative child observation inventory required")
    for name in ("runnerSha256", "reporterSha256"):
        if not isinstance(config[name], str) or not re.fullmatch(r"[0-9a-f]{64}", config[name]):
            raise ValueError("exact runner/reporter source hashes required")
    if config["manifest"] not in inputs or not all(isinstance(config[name], str)
            and config[name] for name in ("manifest", "entry", "constructor")):
        raise ValueError("declared registered Scheme progress component required")
    if (not isinstance(config["forwarder"], str) or config["forwarder"] not in inputs
            or not config["forwarder"].endswith(".scm")):
        raise ValueError("declared native Scheme observer asset required")
    if "transport" in config or "observer" in config:
        if (config.get("transport") != "native-datagram" or config.get("observer") not in inputs
                or not config["observer"].endswith(".scm")):
            raise ValueError("declared compiled datagram observer required")


def child_cookie(nonce, file):
    return hashlib.sha256((nonce + ":" + file).encode()).digest()[:16]


def instrument(work, runtime, files, config, *, root, endpoint=None, module=None):
    """Change the owned driver only; retain original child inputs and output."""
    runner = work / "run-unit-tests.scm"
    reporter = runtime / "lib/_nonstd.scm"
    if digest(runner) != config["runnerSha256"] or digest(reporter) != config["reporterSha256"]:
        raise ValueError("child observation source correspondence drift")
    original = runner.read_text()
    if original.count(READ) != 1 or original.count(LOAD) != 1:
        raise ValueError("unique upstream child launch/read boundaries required")
    if any(not re.fullmatch(r"[A-Za-z0-9_./-]+", str(file)) for file in files):
        raise ValueError("unambiguous child file identities required")
    nonce = secrets.token_hex(16)
    observed_files = ["unit-tests/" + str(file) for file in files if str(file) in config["files"]]
    if not observed_files:
        raise ValueError("child observation inventory does not intersect this group")
    selection = "(list " + " ".join(json.dumps(file) for file in observed_files) + ")"
    from gambit_smp.recipes import source_path
    forwarder = source_path(root, config["forwarder"])
    helper = forwarder.read_text().replace("__SMP_NONCE__", nonce).replace("__SMP_OBSERVED_FILES__", selection)
    instrumented = original.replace(READ, "(smp-read-child port args)")
    instrumented = instrumented.replace("(define (run path . args)", helper + "\n(define (run path . args)")
    observed_launch = LOAD.replace('"-f" file)', '\"-f\" \"-e\" \"(gc-report-set! #t)\" file)')
    if config.get("transport") == "native-datagram":
        if not endpoint or module is None or not module.is_file():
            raise ValueError("bound local receiver and compiled observer required")
        options = []
        cookies = [child_cookie(nonce, file).hex() for file in observed_files]
        if len(set(cookies)) != len(cookies):
            raise ValueError("distinct child file cookies required")
        for file, cookie in zip(observed_files, cookies):
            prelude = ('(load ' + json.dumps(module.name) + ') (if (smp-enable-gc-datagram! '
                       + str(endpoint) + ' "' + cookie + '") (void) (exit 70))')
            options.append("(cons " + json.dumps(file) + " " + json.dumps(prelude) + ")")
        options = "(list " + " ".join(options) + ")"
        observed_launch = LOAD.replace('"-f" file)', '"-f" "-e" (cdr (assoc file ' + options + ')) file)')
    instrumented = instrumented.replace(LOAD, "(if (member file " + selection + ")\n"
        + observed_launch + "\n" + LOAD + ")")
    runner.write_text(instrumented)
    source = {"runner": config["runnerSha256"], "observedRunner": digest(runner),
              "forwarder": digest(forwarder),
              "reporter": config["reporterSha256"], "binary": digest(runtime / "gsi/gsi"),
              "files": {"unit-tests/" + str(file): digest(work / "unit-tests" / file) for file in files}}
    if module is not None:
        source.update(observerSource=digest(source_path(root, config["observer"])),
                      observerModule=digest(module), observerC=digest(module.with_suffix(".c")))
    return nonce, source


class ChildGCProgress:
    """Incremental I/O decoding, not a second applicability evaluator."""
    def __init__(self, root, config, nonce, source, expected):
        from gambit_smp.ascent_program import load_component_catalog, definitions
        catalog = load_component_catalog(root / config["manifest"], entry=config["entry"],
            constructor=config["constructor"], trusted=True)
        self.owners = ExitStack()
        try:
            module, binding = self.owners.enter_context(definitions(catalog))
            with module.call(config["constructor"]) as value:
                self.session = value.open_session()
            self.inputs = binding["sourceInputs"]
        except BaseException:
            self.owners.close()
            raise
        self.config, self.nonce, self.source = config, nonce, source
        self.offset, self.pending, self.actor = 0, "", None
        self.seen, self.errors, self.contexts = set(), [], []
        self.progress, self.witness, self.renewals = None, None, 0
        self.files = SuiteCompletionProgress(expected)
        self.completed = 0

    def __call__(self, stdout, stderr):
        if len(stderr) < self.offset:
            raise ValueError("child observation transport regressed")
        self.pending += stderr[self.offset:]
        self.offset = len(stderr)
        while "\n" in self.pending:
            line, self.pending = self.pending.split("\n", 1)
            if not line.startswith(("SMP-CHILD ", "SMP-GC ")):
                continue
            parts = line.split(" ", 4)
            if len(parts) < 4:
                self.errors.append("malformed-child-envelope")
                continue
            tag, nonce, pid, file = parts[:4]
            if nonce != self.nonce or not pid.isdigit() or int(pid) <= 0 or file not in self.source["files"]:
                self.errors.append("unattested-child-envelope")
                continue
            if tag == "SMP-CHILD":
                if file in self.seen or len(parts) != 4:
                    self.errors.append("replayed-child-incarnation")
                    continue
                self.seen.add(file)
                identity = (file, pid, nonce + ":" + file, self.config["kind"],
                    hashlib.sha256(json.dumps(self.source, sort_keys=True).encode()).hexdigest())
                self.actor = (pid, file)
                self.contexts.append({"pid": int(pid), "file": file, "epoch": identity[2]})
                facts = {"progress_contract": [identity], "progress_active": [identity[:3]],
                         "progress_cursor": [(*identity, 0)]}
                self.progress = EvidenceProgress(self.session, facts, lambda *_: self.sample)
            elif self.actor != (pid, file) or self.progress is None:
                self.errors.append("inactive-child-report")
            else:
                if self.config.get("transport") == "native-datagram":
                    self.errors.append("unexpected-text-gc-record")
                    continue
                report = parts[4].split(" ", 1) if len(parts) == 5 else []
                match = GC.fullmatch(report[1] + "\n") if len(report) == 2 else None
                if not match or not report[0].isdigit():
                    self.errors.append("incomplete-or-unknown-gc-report")
                    continue
                value = int(report[0])
                self.record(value, hashlib.sha256(line.encode()).hexdigest())
        count = self.files(stdout, stderr)
        self.renewals += max(0, count - self.completed)
        self.completed = count
        return self.renewals

    def record(self, value, event):
        identity = self.progress.facts["progress_contract"][0]
        self.sample = {"progress_sample": [(event, *identity, value)],
                       "progress_attested": [(event,)], "progress_completed": [(event,)]}
        before = self.progress.renewals
        self.progress("", "")
        self.witness = self.progress.witness
        self.renewals += self.progress.renewals - before

    def close(self):
        try:
            self.session.close()
        finally:
            self.owners.close()

    def observation(self):
        return {"source": self.source, "children": self.contexts, "errors": self.errors,
                "renewals": self.renewals, "kind": self.config["kind"],
                "mutatorProgressEstablished": False, "observerInterferenceExcluded": False,
                "runtimeAdmitted": False}


class ChildGCDatagramProgress(ChildGCProgress):
    """Decode atomic packets; the registered Scheme rules still admit cursors."""
    def __init__(self, *args, receiver, **kwargs):
        super().__init__(*args, **kwargs)
        self.receiver = receiver
        self.rejected_packets = 0

    def __call__(self, stdout, stderr):
        super().__call__(stdout, stderr)
        capacity = max(1, self.receiver.getsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF) // 40)
        for _ in range(capacity):
            try:
                packet, peer = self.receiver.recvfrom(65536)
            except BlockingIOError:
                break
            if len(packet) != 40 or peer[0] != "127.0.0.1":
                self.rejected_packets += 1
                continue
            magic, nonce, pid, sequence = struct.unpack("!8s16sQQ", packet)
            if self.actor is None:
                self.rejected_packets += 1
                continue
            actor_pid, file = self.actor
            if (magic != b"SMPGC001" or str(pid) != actor_pid
                    or nonce != child_cookie(self.nonce, file) or sequence == 0):
                self.rejected_packets += 1
                continue
            self.record(sequence, hashlib.sha256(packet).hexdigest())
        return self.renewals

    def close(self):
        try:
            super().close()
        finally:
            self.receiver.close()

    def observation(self):
        return {**super().observation(), "transport": "native-datagram",
                "rejectedPackets": self.rejected_packets,
                "callbackImplementation": "source-bound-native-no-argument-void",
                "allocationQualification": "separate-source-and-control-evidence-required"}


def prepare_datagram(ctx, runtime, work, group, config, name, cap, option):
    from gambit_smp.recipes import source_path
    from gambit_smp.suite_primitives import runner_option
    import shutil
    asset = source_path(ctx.root, config["observer"])
    source, module = work / "gc-observer.scm", work / "gc-observer.o1"
    shutil.copyfile(asset, source)
    ctx.bind([asset])
    phases = [
        ("scheme", '(exit (if (compile-file-to-target "gc-observer.scm" options: (quote ((module-ref gc-observer) (linker-name "gc-observer.o1"))) output: "gc-observer.c") 0 1))'),
        ("native", '(exit (if (compile-file "gc-observer.c" output: "gc-observer.o1") 0 1))'),
    ]
    for phase, expression in phases:
        ctx.require(name + "-observer-" + phase, [runtime / "gsc/gsc", "-:" + runner_option(option),
                    "-f", "-e", expression], work, cap)
    if not module.is_file() or not source.with_suffix(".c").is_file():
        raise ValueError("compiled observer and generated C correspondence required")
    receiver = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        receiver.bind(("127.0.0.1", 0))
        receiver.setblocking(False)
        nonce, sources = instrument(work, runtime, group, config, root=ctx.root,
                                   endpoint=receiver.getsockname()[1], module=module)
        return ChildGCDatagramProgress(ctx.root, config, nonce, sources, len(group), receiver=receiver)
    except BaseException:
        receiver.close()
        raise

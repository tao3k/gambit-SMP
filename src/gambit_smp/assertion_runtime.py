"""Project shared assertion code while keeping fixture state and installation."""
import json
from contextlib import contextmanager

from gambit_smp.framework import digest


def shared_assertion_sources(harness, runner, provider):
    """Return provider, fixture and runner bytes for the original C load path.

    The caller owns compilation, the worker lease and process settlement.
    Unexpected source shapes refuse extraction before any source is changed.
    """
    if not isinstance(harness, bytes) or not isinstance(runner, bytes):
        raise TypeError("assertion inputs must be source bytes")
    anchors = (
        b"(define (##failed-test ",
        b"(##define-macro (##setup-test)",
        b"(let ((##exit-old ##exit))",
        b"(define (exception-description-string",
    )
    if any(harness.count(anchor) != 1 for anchor in anchors):
        raise ValueError("original assertion source anchors must be unique")
    first, last, hook, suffix = [harness.index(anchor) for anchor in anchors]
    if not first < last < hook < suffix:
        raise ValueError("original assertion source order changed")
    end = harness.find(b";;;============================================================================", suffix)
    if end < suffix:
        raise ValueError("original assertion suffix boundary is missing")
    state_read = b"                       ##tested-procs)"
    hook_body = harness[hook:suffix]
    if hook_body.count(state_read) != 1:
        raise ValueError("exit hook must have one fixture-owned tested-procs read")
    support = (
        harness[first:last]
        + b"\n(define (##test-install-exit-hook tested-procs)\n"
        + hook_body.replace(state_read, b"                       (tested-procs))")
        + b")\n" + harness[suffix:end]
    )
    fixture = (
        harness[:first]
        + b"(##demand-module assertion-support)"
        + b"\n" * harness[first:last].count(b"\n")
        + harness[last:hook]
        + b"(##test-install-exit-hook (lambda () ##tested-procs))"
        + b"\n" * harness[hook:end].count(b"\n")
        + harness[end:]
    )
    call = b'(run "../gsi/gsi" (add-inst-dirs "-:debug-settings=-,io-settings=lu") "-f" file)'
    if runner.count(call) != 1:
        raise ValueError("original C fixture loader must be unique")
    provider = str(provider)
    if "\0" in provider:
        raise ValueError("provider path cannot contain a null byte")
    encoded = json.dumps(provider, ensure_ascii=False).encode()
    load = call.replace(b'"-f" file)', b'"-f" ' + encoded + b" file)")
    return support, fixture, runner.replace(call, load)


class SharedAssertionRuntime:
    """One compiled provider, with worker-owned fixture source overlays."""

    def __init__(self, ctx, runtime, copied, option):
        self.ctx = ctx
        self.harness = (copied / "unit-tests/#.scm").read_bytes()
        self.runner = (copied / "run-unit-tests.scm").read_bytes()
        directory = ctx.directory / "support"
        directory.mkdir()
        provider = directory / "assertion-support.scm"
        target = provider.with_suffix(".c")
        self.bundle = provider.with_suffix(".o1")
        source, self.fixture, self.loader = shared_assertion_sources(
            self.harness, self.runner, self.bundle)
        provider.write_bytes(source)
        quote = lambda value: json.dumps(str(value), ensure_ascii=False)
        expression = (
            "(exit (if (and (compile-file-to-target " + quote(provider)
            + ' options: (quote ((module-ref assertion-support) (linker-name "assertion-support.o1"))) output: '
            + quote(target) + ") (compile-file " + quote(target)
            + " options: (quote (verbose)) output: " + quote(self.bundle) + ")) 0 1))"
        )
        cap = min(30, ctx.remaining())
        processors, separator, aliases = option.partition(",")
        runtime_options = "-:" + processors + ",debug-settings=-,io-settings=lu,file-settings=lf"
        if separator:
            runtime_options += "," + aliases
        code, output, timed, seconds = ctx.run(
            "suite-support-build", [runtime / "gsc/gsc", runtime_options, "-f", "-e", expression],
            directory, cap)
        commands = [row for row in ctx.commands if row.get("stage") == "suite-support-build"]
        if (code != 0 or timed or "*** WARNING" in output
                or len(commands) != 1 or commands[0].get("parentReaped") is not True
                or commands[0].get("processGroupQuiescent") is not True
                or not self.bundle.is_file() or not self.bundle.stat().st_size
                or not target.is_file() or not target.stat().st_size):
            raise ValueError("shared assertion runtime build did not complete")
        self.identity = dict(
            sourceSha256=digest(provider), generatedSha256=digest(target),
            nativeSha256=digest(self.bundle), buildSeconds=seconds,
            originalHarnessSha256=digest(copied / "unit-tests/#.scm"),
            originalRunnerSha256=digest(copied / "run-unit-tests.scm"))
        ctx.receipt["sharedAssertionRuntime"] = self.identity

    @contextmanager
    def fixture_sources(self, work, stage):
        harness, runner = work / "unit-tests/#.scm", work / "run-unit-tests.scm"
        if (harness.read_bytes() != self.harness or runner.read_bytes() != self.runner
                or digest(self.bundle) != self.identity["nativeSha256"]):
            raise ValueError("shared assertion source or provider changed")
        harness.write_bytes(self.fixture)
        runner.write_bytes(self.loader)
        try:
            yield
        finally:
            commands = [row for row in self.ctx.commands if row.get("stage") == stage]
            if (len(commands) != 1 or commands[0].get("parentReaped") is not True
                    or commands[0].get("processGroupQuiescent") is not True):
                raise ValueError("unsettled fixture retains its source overlay")
            if (harness.read_bytes() != self.fixture or runner.read_bytes() != self.loader
                    or digest(self.bundle) != self.identity["nativeSha256"]):
                raise ValueError("fixture source changed during execution")
            runner.write_bytes(self.runner)
            harness.write_bytes(self.harness)

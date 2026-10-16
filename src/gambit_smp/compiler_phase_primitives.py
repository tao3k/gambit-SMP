"""Pure compiler phase commands and observation predicates, no execution."""
from pathlib import Path
import json

EXECUTION_WITNESS = "COMPILER-PHASE:module-initialized,assertions-passed"
LOAD_PROBE = '''(begin
  (##eval '(define ##failed-test? 'phase-module-not-executed))
  (##load "probe.o1" (lambda (script path) #f) #t #t "probe" #f)
  (if (eq? ##failed-test? #f)
      (begin (display "COMPILER-PHASE:module-initialized,assertions-passed\\n") (exit 0))
      (exit 2)))'''


def stage_accepted(code, timed_out, output, artifact, witness=None):
    return (code == 0 and not timed_out and "FAILED" not in output
            and "Unknown or improperly placed" not in output
            and (artifact is None or artifact.is_file())
            and (witness is None or output.splitlines().count(witness) == 1))


def phase_commands(selection, work):
    return [
        ("scheme-to-c", "gsc/gsc", ["-f", "-verbose", "-c", "-o", "probe.c", str(Path("unit-tests") / selection)], work / "probe.c"),
        ("c-to-dynamic-module", "gsc/gsc", ["-f", "-e", '(exit (if (compile-file "probe.c" options: (quote (verbose)) output: "probe.o1") 0 1))'], work / "probe.o1"),
        ("compiled-execution", "gsi/gsi", ["-f", "-e", LOAD_PROBE], None),
    ]


def suite_phase_commands(selection, work):
    """Preserve run-unit-tests.scm's module/linker names and original loader."""
    selected = Path(selection)
    if selected.is_absolute() or ".." in selected.parts or selected.suffix != ".scm":
        raise ValueError("one relative Scheme fixture required")
    source = Path("unit-tests") / selected
    target = source.with_suffix(".c")
    emit = ('(exit (if (compile-file-to-target ' + json.dumps(str(source)) +
            ' options: (quote ((module-ref _test) (linker-name "_test.o1"))) '
            'output: ' + json.dumps(str(target)) + ') 0 1))')
    compile_c = ('(exit (if (compile-file ' + json.dumps(str(target)) +
                 ' options: (quote (verbose)) output: "_test.o1") 0 1))')
    return [
        ("scheme-to-c", "gsc/gsc", ["-:debug-settings=-,io-settings=lu", "-f", "-e", emit], work / target),
        ("c-to-dynamic-module", "gsc/gsc", ["-:debug-settings=-,io-settings=lu", "-f", "-e", compile_c], work / "_test.o1"),
        ("compiled-execution", "gsi/gsi", ["-:debug-settings=-,io-settings=lu", "-f", "_test.o1"], None),
    ]


def run_suite_phases(ctx, runtime, work, selection, prefix, idle_window):
    """Record real phase exits; never synthesize an upstream suite PASS marker."""
    plan = suite_phase_commands(selection, work)
    if any(artifact is not None and artifact.exists() for _, _, _, artifact in plan):
        raise ValueError("compiled phase output must not reuse an existing artifact")
    results = []
    for name, executable, options, artifact in plan:
        code, output, timeout, seconds = ctx.run(prefix + "-" + name,
            [runtime / executable, *options], work, idle_window)
        accepted = stage_accepted(code, timeout, output, artifact)
        # A successful subprocess is necessary but cannot stand in for its output.
        if accepted and artifact is not None:
            from gambit_smp.framework import digest
            artifact_sha = digest(artifact)
        else:
            artifact_sha = None
        results.append({"phase": name, "exit": code, "timeout": timeout,
                        "seconds": seconds, "accepted": accepted,
                        "artifactSha256": artifact_sha})
        if not accepted:
            break
    return results

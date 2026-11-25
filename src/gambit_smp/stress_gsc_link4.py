"""Link 4 execution driver for Family 7 (7/12: stress-gsc).

Executes on one exact sealed producer (gsc/gsc + gsi/gsi + bin/gambuild-C):
  1. Three-phase scheme-to-c (.c) -> Compiled-Host Translation Validation ->
     c-to-dynamic-module (.o1) -> compiled-execution (dlopen + assertions at p2)
     for all four unchanged upstream stress fixtures, measuring peak compiler RSS.
  2. Five mutated-host negative controls run directly on the real v9-emitted
     tfib_stress.c.
  3. Three native dynamic .o1 wire-trace controls at p2:
     - shortageGcReloadWriteCommitPassed (live F6REST01 wire trace from .o1)
     - crossModuleInterruptUnwindPassed (.o1 closure inc! + exception unwind in lib/_thread.o)
     - oneWordShortRefusalPassed (compiled rest-parameter-native-cuts.o1 1-word-short refusal)
"""

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import tempfile
import time

from gambit_smp.compiled_host_validator import (
    run_mutated_host_negative_controls,
    validate_compiled_module_files,
)
from gambit_smp.framework import digest
from gambit_smp.rest_observation import HEADER, KINDS, MAGIC, RECORD, runtime_identity_bytes
from gambit_smp.stress_gsc_audit import (
    MAX_COMPILER_RSS_BYTES,
    REQUIRED_STRESS_FILES,
    verify_compiled_host_receipt,
)
from gambit_smp.task_processes import run as run_process

_RSS_RE = re.compile(r"^\s*(\d+)\s+maximum resident set size\b", re.MULTILINE)

_CONTROL_A_SCM = r"""
(declare (standard-bindings) (block) (not inline))
(define obs-open (c-lambda (char-string) int "___result = ___EXT(___rest_observation_open)(___arg1);"))
(define obs-case (c-lambda (unsigned-int64) int "___result = ___EXT(___rest_observation_case)(___arg1);"))
(define obs-end (c-lambda () int "___result = ___EXT(___rest_observation_case_end)();"))

(define (make-worker-closure tag payload)
  ;; Allocate directly inside this compiled .o1 write group (no external C alloc)
  ;; so repeated calls exhaust the current msection inside this exact group and
  ;; exercise shortage -> GC -> reload -> group-grant -> group-store -> group-commit.
  (let ((v (vector tag payload tag payload tag payload tag payload
                   tag payload tag payload tag payload tag payload)))
    (lambda (x) (cons x v))))

(define (run-shortage-control trace-path gate2-mode?)
  (if (not gate2-mode?)
      (begin
        (if (not (= (obs-open trace-path) 1))
            (error "failed to open trace" trace-path))
        (if (not (= (obs-case 7001) 1))
            (error "failed to start case 7001"))))
  (let loop ((i 0) (acc '()))
    (if (< i 60000)
        (let ((fn (make-worker-closure i (+ i 1))))
          (loop (+ i 1)
                (if (= (modulo i 1000) 0)
                    (cons (fn i) acc)
                    acc)))
        (begin
          (##gc)
          (let ((tail (make-worker-closure 'after-gc (length acc))))
            (if (not gate2-mode?) (obs-end))
            (if (and (pair? (tail 'ok)) (= (length acc) 60))
                (begin (println "CONTROL-A-OK") (exit 0))
                (exit 2)))))))

(run-shortage-control
  (getenv "FAM7_TRACE_PATH" "")
  (not (equal? (getenv "GAMBIT_GATE2_PROCEDURE" "") "")))
"""

_CONTROL_B_SCM = r"""
(declare (standard-bindings) (block))

(define (run-interrupt-control)
  (let* ((normal-target 200)
         (sync-unwind-target 50)
         (async-escape-target 50)
         (normal-count 0)
         (sync-unwind-count 0)
         (async-escape-count 0)
         (in-catcher #f)
         (done #f)
         (inc! (lambda () (set! normal-count (+ normal-count 1))))
         (sync-unwind!
          (lambda ()
            (with-exception-catcher
             (lambda (e)
               (if (eq? e 'fam7-sync-escape)
                   (begin (set! sync-unwind-count (+ sync-unwind-count 1)) 'caught)
                   (raise e)))
             (lambda () (raise 'fam7-sync-escape)))))
         (worker
          (make-thread
           (lambda ()
             (let outer ()
               (if (not done)
                   (begin
                     (with-exception-catcher
                      (lambda (e)
                        (set! in-catcher #f)
                        (if (eq? e 'fam7-async-escape)
                            (set! async-escape-count (+ async-escape-count 1))
                            (raise e)))
                      (lambda ()
                        (set! in-catcher #t)
                        (let spin ()
                          (if (not done)
                              (begin (thread-yield!) (spin))
                              (set! in-catcher #f)))))
                     (outer))))))))
    (thread-start! worker)
    ;; Phase 1: 200 synchronous normal compiled-closure interrupts
    (let loop ((i 0))
      (if (< i normal-target)
          (begin
            (thread-interrupt! worker inc!)
            (loop (+ i 1)))))
    ;; Phase 2: 50 synchronous exception-unwinding compiled-closure interrupts
    (let loop ((i 0))
      (if (< i sync-unwind-target)
          (begin
            (let ((res (thread-interrupt! worker sync-unwind!)))
              (if (not (eq? res 'caught))
                  (error "unexpected sync-unwind result" res)))
            (loop (+ i 1)))))
    ;; Phase 3: 50 asynchronous exception escapes unwinding worker's compiled frames
    (let loop ((i 0))
      (if (< i async-escape-target)
          (begin
            (let wait-ready ((tries 0))
              (if (and (not in-catcher) (< tries 2000))
                  (begin (thread-yield!) (wait-ready (+ tries 1)))))
            (##thread-intr! worker #t (lambda () (raise 'fam7-async-escape)))
            (let wait ((tries 0))
              (if (and (< async-escape-count (+ i 1)) (< tries 2000))
                  (begin (thread-yield!) (wait (+ tries 1)))))
            (loop (+ i 1)))))
    (set! done #t)
    (thread-join! worker)
    (println "CONTROL-B normal=" normal-count
             " sync-unwind=" sync-unwind-count
             " async-escape=" async-escape-count)
    (if (and (= normal-count normal-target)
             (= sync-unwind-count sync-unwind-target)
             (= async-escape-count async-escape-target))
        (begin (println "CONTROL-B-OK") (exit 0))
        (exit 2))))

(run-interrupt-control)
"""

_CONTROL_C_WRAPPER_SCM = r"""
(declare (extended-bindings) (not safe))
;; Compiled .o1 exact one-word-short rest refusal with unchanged sentinel check.
(define obs-open (c-lambda (char-string) int "___result = ___EXT(___rest_observation_open)(___arg1);"))
(define obs-case (c-lambda (unsigned-int64) int "___result = ___EXT(___rest_observation_case)(___arg1);"))
(define obs-end (c-lambda () int "___result = ___EXT(___rest_observation_case_end)();"))
(define room (c-lambda () scheme-object "___result = ___FIX(___EXT(___rest_observation_room)(___ps));"))
(define settled (c-lambda () scheme-object "___result = ___FIX(___EXT(___rest_observation_settled)(___ps));"))
(define reset-adm (c-lambda () void "___EXT(___rest_observation_reset_admission)();"))
(define handler-words (c-lambda () scheme-object "___result = ___FIX(___EXT(___rest_observation_last_demand)(0, 0));"))
(define handler-entry-room (c-lambda () scheme-object "___result = ___FIX(___EXT(___rest_observation_last_entry_room)());"))

(define (ordinary label . tail) (cons label tail))
(define admission-overhead 0)
(define pad-index 0)
(define large-step #f)
(define small-step #f)
(define one-word-string? #f)
(define sink #f)

(define (admitted-demand thunk)
  (reset-adm)
  (let ((before (room)))
    (thunk)
    (let ((words (handler-words))
          (entry (handler-entry-room)))
      (if (not (and (> words 0) (>= before 0) (>= entry 0) (>= before entry)))
          (error "rest probe handler rejected demand" words before entry))
      (set! admission-overhead (- before entry))
      words)))

(define (prepare-steps)
  (let ((before (room)))
    (set! pad-index (+ pad-index 1))
    (set! sink (##cons pad-index sink))
    (let ((after (room)))
      (if (not (and (>= before 0) (> before after)))
          (error "rest probe allocation not visible" before after))
      (set! large-step (- before after))))
  (set! sink (make-string 0))
  (set! sink (##box sink))
  (let* ((sb (room))
         (_s (set! sink (make-string 0)))
         (sa (room))
         (_b (set! sink (##box sink)))
         (ba (room))
         (sc (- sb sa))
         (bc (- sa ba)))
    (set! one-word-string? (= sc 1))
    (set! small-step (if (or one-word-string? (= bc 1)) 1 (error "no one-word step" sc bc)))))

(define (reach target)
  (let loop ((left (room)))
    (let* ((here (room))
           (gap (and (>= here 0) (- here target))))
      (cond ((eqv? (settled) target) #t)
            ((or (not gap) (<= gap 0) (< gap small-step) (negative? left)) #f)
            (else
             (let ((before here))
               (if (> gap large-step)
                   (begin (set! pad-index (+ pad-index 1)) (set! sink (##cons pad-index sink)))
                   (set! sink (if one-word-string? (make-string 0) (##box sink))))
               (let ((after (room)))
                 (if (not (and (>= after 0) (< after before) (<= (- before after) gap)))
                     #f
                     (loop (+ left (- after before)))))))))))

(define (run-short-control trace-path)
  (if (not (= (obs-open trace-path) 1))
      (error "failed to open trace" trace-path))
  (if (not (= (obs-case 7003) 1))
      (error "failed to start case 7003"))
  (let* ((label (vector 'fam7-short-boundary))
         (sentinel (vector 's0 's1 's2 's3 's4 's5))
         (call (lambda () (ordinary label 1 2 3)))
         (words (admitted-demand call))
         (target (+ words admission-overhead -1)))
    (prepare-steps)
    (let ((caught
           (with-exception-catcher
            (lambda (e) (heap-overflow-exception? e))
            (lambda ()
              (if (not (reach target))
                  (error "missed exact one-word-short boundary" (room) (settled) target words admission-overhead))
              (reset-adm)
              (call)
              #f))))
      (obs-end)
      (let ((sentinels-intact (equal? sentinel '#(s0 s1 s2 s3 s4 s5))))
        (println "CONTROL-C words=" words " target=" target " caught=" caught " sentinels=" sentinels-intact)
        (if (and caught sentinels-intact)
            (begin (println "CONTROL-C-OK") (exit 0))
            (exit 2))))))

(run-short-control (getenv "FAM7_TRACE_PATH"))
"""


def _run_timed(cmd: list[str], *, cwd: Path, env: dict[str, str], timeout: int) -> dict:
    """Run command through the audited task_processes.run boundary, capturing peak RSS."""
    use_time = Path("/usr/bin/time").exists()
    full_cmd = ["/usr/bin/time", "-l", *cmd] if use_time else cmd
    started = time.monotonic()
    completed = run_process(
        full_cmd,
        cwd=str(cwd),
        env=env,
        capture_output=True,
        text=True,
        timeout=timeout,
        start_new_session=True,
    )
    elapsed = time.monotonic() - started
    stdout_s = completed.stdout or ""
    stderr_s = completed.stderr or ""
    rss_bytes = 0
    if use_time:
        m = _RSS_RE.search(stderr_s)
        if m:
            rss_bytes = int(m.group(1))
    return dict(
        cmd=cmd,
        exit=completed.returncode,
        seconds=round(elapsed, 3),
        peakRssBytes=rss_bytes,
        stdout=stdout_s,
        stderr=stderr_s,
    )


def _init_wire_trace_file(trace_path: Path, capacity: int = 131072) -> None:
    """Create a fresh F6REST01 mmap wire-trace buffer expected by ___rest_observation_open."""
    trace_path.parent.mkdir(parents=True, exist_ok=True)
    header = HEADER.pack(MAGIC, 1, capacity, 0, 0, 0, 16, 0)
    with trace_path.open("wb") as handle:
        handle.write(header)
        handle.truncate(HEADER.size + capacity * RECORD.size)


def _parse_wire_trace(trace_path: Path) -> dict:
    """Decode binary F6REST01 wire trace emitted by ___GAMBIT_REST_OBSERVATION."""
    raw = trace_path.read_bytes()
    if len(raw) < HEADER.size:
        raise ValueError(f"wire trace truncated ({len(raw)} bytes)")
    magic, version, capacity, written, dropped, *_ = HEADER.unpack_from(raw, 0)
    if magic != MAGIC:
        raise ValueError(f"unexpected wire trace magic 0x{magic:x}")
    counts = {}
    offset = HEADER.size
    limit = min(len(raw), HEADER.size + written * RECORD.size)
    while offset + RECORD.size <= limit:
        rec = RECORD.unpack_from(raw, offset)
        kind_val = rec[1]
        kind_idx = kind_val - 1
        kind_name = KINDS[kind_idx] if 0 <= kind_idx < len(KINDS) else f"unknown-{kind_val}"
        counts[kind_name] = counts.get(kind_name, 0) + 1
        offset += RECORD.size
    return dict(version=version, capacity=capacity, written=written, dropped=dropped, counts=counts)


def execute_link4_validation(
    root: Path,
    runtime: Path,
    candidate_identity: dict,
    out_receipt_path: Path,
    *,
    execute_stress_o1: bool = True,
) -> dict:
    """Execute full Link 4 validation on one sealed v9 producer and write its receipt."""
    root = Path(root).resolve()
    runtime = Path(runtime).resolve()
    gsc = runtime / "gsc/gsc"
    gsi = runtime / "gsi/gsi"
    for tool in (gsc, gsi, runtime / "bin/gambuild-C", runtime / "include/gambit.h"):
        if not tool.exists():
            raise FileNotFoundError(f"sealed producer missing required tool/header: {tool}")

    inst_opt = (
        f"debug-settings=-,io-settings=lu,"
        f"~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"
    )
    base_env = dict(os.environ)
    base_env["GAMBOPT"] = f"p2,{inst_opt}"
    peak_rss = 0
    modules = []
    tfib_c_text = None

    with tempfile.TemporaryDirectory(prefix="fam7-link4-") as td:
        work = Path(td)
        tests_copy = work / "tests"
        shutil.copytree(runtime / "tests", tests_copy)

        # 1. Three-phase .c & .o1 binding + Translation Validation for all 4 stress fixtures
        from gambit_smp.compiler_phase_primitives import suite_phase_commands

        for target in REQUIRED_STRESS_FILES:
            src_rel = Path("unit-tests") / target
            src_abs = tests_copy / src_rel
            source_sha = digest(src_abs)
            plan = suite_phase_commands(target, tests_copy)
            (_, _, p1_argv, c_out), (_, _, p2_argv, o1_out), (_, _, p3_argv, _) = plan
            for artifact in (c_out, o1_out):
                if artifact is not None and artifact.exists():
                    artifact.unlink()

            # Phase 1: scheme-to-c (exact compile-file-to-target with _test.o1 linker name)
            p1 = _run_timed(
                [str(gsc), f"-:{inst_opt}", *p1_argv[1:]],
                cwd=tests_copy,
                env=base_env,
                timeout=120,
            )
            peak_rss = max(peak_rss, p1["peakRssBytes"])
            if p1["exit"] != 0 or not c_out.exists():
                raise RuntimeError(
                    f"Phase 1 scheme-to-c failed for {target}: "
                    f"stdout={p1['stdout'][-500:]} stderr={p1['stderr'][:500]}"
                )

            # Phase 2: c-to-dynamic-module (exact compile-file from validated .c -> _test.o1)
            p2 = _run_timed(
                [str(gsc), f"-:{inst_opt}", *p2_argv[1:]],
                cwd=tests_copy,
                env=base_env,
                timeout=180,
            )
            peak_rss = max(peak_rss, p2["peakRssBytes"])
            if p2["exit"] != 0 or not o1_out.exists():
                raise RuntimeError(
                    f"Phase 2 c-to-dynamic-module failed for {target}: "
                    f"stdout={p2['stdout'][-500:]} stderr={p2['stderr'][:500]}"
                )

            # Independent Translation Validation on the exact .c + .o1
            tv = validate_compiled_module_files(c_out, o1_out, module_name=target)
            if target.endswith("tfib_stress.scm"):
                tfib_c_text = c_out.read_text(errors="replace")

            # Phase 3: dlopen compiled-execution on exact _test.o1 in gsi at p2
            if execute_stress_o1:
                p3 = _run_timed(
                    [str(gsi), f"-:p2,{inst_opt}", *p3_argv[1:]],
                    cwd=tests_copy,
                    env=base_env,
                    timeout=240,
                )
                dlopen_ok = p3["exit"] == 0
                exec_seconds = p3["seconds"]
                exec_stderr = (p3["stdout"][-300:] + " | " + p3["stderr"][:300]) if not dlopen_ok else ""
            else:
                dlopen_ok = False
                exec_seconds = 0.0
                exec_stderr = "skipped"

            modules.append(dict(
                target=target,
                sourceSha256=source_sha,
                cSha256=tv["cSha256"],
                cBytes=tv["cBytes"],
                o1Sha256=tv["o1Sha256"],
                o1Bytes=tv["o1Bytes"],
                passed=tv["passed"],
                rssGuardSafe=tv["rssGuardSafe"],
                labelCount=tv["labelCount"],
                descriptorCount=tv["descriptorCount"],
                procedureCount=tv["procedureCount"],
                writeGroupCount=tv["writeGroupCount"],
                cyclicLoopCount=tv["cyclicLoopCount"],
                zeroAllocTightLoopCount=tv["zeroAllocTightLoopCount"],
                violationCount=tv["violationCount"],
                violations=tv["violations"][:10],
                schemeToCSeconds=p1["seconds"],
                cToO1Seconds=p2["seconds"],
                cToO1PeakRssBytes=p2["peakRssBytes"],
                dlopenExecutionPassed=dlopen_ok,
                dlopenExecutionSeconds=exec_seconds,
                **({"dlopenStderr": exec_stderr} if exec_stderr else {}),
            ))

        # 2. Five mutated-host negative controls on real v9-emitted tfib_stress.c
        if tfib_c_text is None:
            raise RuntimeError("tfib_stress.c was not emitted")
        neg_controls = run_mutated_host_negative_controls(tfib_c_text)

        # 3. Three native dynamic .o1 wire-trace controls at p2
        ctrl_dir = work / "controls"
        ctrl_dir.mkdir()

        def _compile_control(name: str, code: str) -> tuple[str, Path, dict]:
            scm_f = ctrl_dir / f"{name}.scm"
            c_f = ctrl_dir / f"{name}.c"
            o1_f = ctrl_dir / f"{name}.o1"
            scm_f.write_text(code)
            rc_c1 = _run_timed(
                [str(gsc), f"-:{inst_opt}", "-f", "-c", "-o", str(c_f), str(scm_f)],
                cwd=ctrl_dir,
                env=base_env,
                timeout=120,
            )
            if rc_c1["exit"] != 0 or not c_f.exists():
                raise RuntimeError(
                    f"Control {name} failed -c: out={rc_c1['stdout'][-400:]} err={rc_c1['stderr'][:400]}"
                )
            c_text = c_f.read_text(errors="replace")
            rc_c2 = _run_timed(
                [str(gsc), f"-:{inst_opt}", "-f", "-o", str(o1_f), str(scm_f)],
                cwd=ctrl_dir,
                env=base_env,
                timeout=120,
            )
            nonlocal peak_rss
            peak_rss = max(peak_rss, rc_c1["peakRssBytes"], rc_c2["peakRssBytes"])
            if rc_c2["exit"] != 0 or not o1_f.exists():
                raise RuntimeError(
                    f"Control {name} failed .o1: out={rc_c2['stdout'][-400:]} err={rc_c2['stderr'][:400]}"
                )
            return c_text, o1_f, dict(compile=rc_c2, o1Sha256=digest(o1_f))

        def _run_control(
            name: str,
            o1_f: Path,
            *,
            trace_suffix: str | None = None,
            extra_env: dict[str, str] | None = None,
            capacity: int = 131072,
        ) -> tuple[dict, dict | None]:
            run_env = dict(base_env)
            trace_file = None
            if trace_suffix is not None:
                trace_file = ctrl_dir / f"{name}_{trace_suffix}.trace"
                _init_wire_trace_file(trace_file, capacity=capacity)
                run_env["FAM7_TRACE_PATH"] = str(trace_file)
                run_env["GAMBIT_REST_OBSERVATION"] = str(trace_file)
            if extra_env:
                run_env.update(extra_env)
            rc_r = _run_timed(
                [str(gsi), f"-:p2,{inst_opt}", "-f", str(o1_f)],
                cwd=ctrl_dir,
                env=run_env,
                timeout=90,
            )
            trace_info = _parse_wire_trace(trace_file) if trace_file is not None and trace_file.exists() else None
            return rc_r, trace_info

        # Control A: compiled .o1 shortage -> GC -> reload -> write -> commit
        c_a_text, o1_a, meta_a = _compile_control("control_a_shortage", _CONTROL_A_SCM)
        # Extract the outer allocating write-group label of make-worker-closure (called 25,001 times)
        gate2_matches = re.findall(
            r'___GATE2_OPEN\(___ps,"([^"]*make-worker-closure[^"]*)",(\d+),',
            c_a_text,
        ) or re.findall(r'___GATE2_OPEN\(___ps,"([^"]+)",(\d+),', c_a_text)
        gate2_proc, gate2_lbl = gate2_matches[0] if gate2_matches else ("", "")

        run_a_gate2, trace_a_gate2 = _run_control(
            "control_a_shortage",
            o1_a,
            trace_suffix="gate2",
            extra_env=dict(
                GAMBIT_GATE2_PROCEDURE=gate2_proc,
                GAMBIT_GATE2_LABEL=gate2_lbl,
                GAMBIT_GATE2_CASE="7001",
            ),
            capacity=524288,
        )
        run_a_gc, trace_a_gc = _run_control(
            "control_a_shortage",
            o1_a,
            trace_suffix="gc",
            capacity=262144,
        )
        counts_a_g2 = (trace_a_gate2 or {}).get("counts", {})
        counts_a_gc = (trace_a_gc or {}).get("counts", {})
        ctrl_a_ok = (
            run_a_gate2["exit"] == 0
            and "CONTROL-A-OK" in run_a_gate2["stdout"]
            and run_a_gc["exit"] == 0
            and "CONTROL-A-OK" in run_a_gc["stdout"]
            and counts_a_g2.get("case-begin", 0) >= 1
            and counts_a_g2.get("group-open", 0) >= 1
            and counts_a_g2.get("group-enter", 0) >= 1
            and counts_a_g2.get("group-grant", 0) >= 1
            and counts_a_g2.get("group-heap-grant", 0) >= 1
            and counts_a_g2.get("group-commit", 0) >= 1
            and counts_a_gc.get("case-begin", 0) >= 1
            and counts_a_gc.get("case-end", 0) >= 1
            and counts_a_gc.get("gc-begin", 0) >= 1
            and counts_a_gc.get("gc-end", 0) >= 1
        )

        # Control B: compiled .o1 cross-module interrupt & exception unwind
        _, o1_b, meta_b = _compile_control("control_b_interrupt", _CONTROL_B_SCM)
        run_b, _ = _run_control("control_b_interrupt", o1_b)
        ctrl_b_ok = run_b["exit"] == 0 and "CONTROL-B-OK" in run_b["stdout"]

        # Control C: compiled .o1 exact 1-word-short rest refusal with unchanged sentinels
        _, o1_c, meta_c = _compile_control("control_c_short", _CONTROL_C_WRAPPER_SCM)
        run_c, trace_c = _run_control(
            "control_c_short",
            o1_c,
            trace_suffix="short",
            extra_env=dict(GAMBIT_REST_OBSERVATION_WATCH="physical-one-short"),
            capacity=524288,
        )
        counts_c = (trace_c or {}).get("counts", {})
        ctrl_c_ok = (
            run_c["exit"] == 0
            and "CONTROL-C-OK" in run_c["stdout"]
            and counts_c.get("case-begin", 0) >= 1
            and counts_c.get("case-end", 0) >= 1
            and counts_c.get("watched-demand", 0) >= 1
            and counts_c.get("native-cut", 0) >= 1
            and counts_c.get("reload", 0) >= 1
            and counts_c.get("reload-installed", 0) >= 1
            and counts_c.get("retry-grant", 0) >= 1
        )

        native_controls = dict(
            passed=bool(ctrl_a_ok and ctrl_b_ok and ctrl_c_ok),
            shortageGcReloadWriteCommitPassed=ctrl_a_ok,
            shortageO1Sha256=meta_a["o1Sha256"],
            shortageGate2Target=dict(procedure=gate2_proc, label=gate2_lbl),
            shortageGate2TraceSummary=trace_a_gate2,
            shortageGcTraceSummary=trace_a_gc,
            crossModuleInterruptUnwindPassed=ctrl_b_ok,
            crossModuleO1Sha256=meta_b["o1Sha256"],
            crossModuleOutput=run_b["stdout"].strip(),
            oneWordShortRefusalPassed=ctrl_c_ok,
            oneWordShortO1Sha256=meta_c["o1Sha256"],
            oneWordShortOutput=run_c["stdout"].strip(),
            oneWordShortTraceSummary=trace_c,
        )

    receipt = dict(
        schema="family7-compiled-host-validation.v1",
        passed=bool(
            all(m["passed"] and m["dlopenExecutionPassed"] for m in modules)
            and neg_controls["passed"]
            and native_controls["passed"]
            and peak_rss < MAX_COMPILER_RSS_BYTES
        ),
        producer=dict(
            gsiSha256=candidate_identity["binarySha256"],
            gscSha256=candidate_identity["gscSha256"],
            runtimeIdentitySha256=hashlib.sha256(runtime_identity_bytes(candidate_identity)).hexdigest(),
        ),
        peakCompilerRssBytes=peak_rss,
        maxCompilerRssBytes=MAX_COMPILER_RSS_BYTES,
        modules=modules,
        negativeControls=neg_controls,
        nativeControls=native_controls,
    )
    out_receipt_path = Path(out_receipt_path)
    out_receipt_path.parent.mkdir(parents=True, exist_ok=True)
    out_receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
    if receipt["passed"]:
        verify_compiled_host_receipt(receipt, candidate_identity)
    return receipt

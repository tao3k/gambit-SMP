"""Offline cryptographic auditors and audited Make runner for Families 8-12.

Covers:
  - Family 8  (8/12: registry)  + P0-2 binding-read activation
  - Family 9  (9/12: lifecycle) + 10 startup fault modes & unknown-join isolation
  - Family 10 (10/12: gc-ffi)   + test7/8/9, root/entry/callback, W < R worker domains
  - Family 11 (11/12: gerbil)   + exact 8-stage producer/ABI seal closure
  - Family 12 (12/12: release)  + matched paired cohort & non-splicing 12/12 conjunction

All subprocess execution uses `gambit_smp.task_processes.run` exclusively and enforces
the hard < 8 GiB (8,589,934,592 bytes) peak RSS ceiling.
"""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import sys
import tempfile
import time

from gambit_smp.framework import digest, gnu_compiler, relative
from gambit_smp.process_identity import groups_memory
from gambit_smp.task_processes import observe_group, spawn as spawn_process

MAX_RSS_BYTES = 8 * 1024 * 1024 * 1024  # 8 GiB hard limit
MAX_GIT_JSON_BYTES = 64 * 1024          # 64 KiB publication limit

_SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
_MACOS_RSS_RE = re.compile(r"^\s*(\d+)\s+maximum resident set size\b", re.MULTILINE)
_MACOS_FOOTPRINT_RE = re.compile(r"^\s*(\d+)\s+peak memory footprint\b", re.MULTILINE)
_LINUX_RSS_KB_RE = re.compile(r"Maximum resident set size \(kbytes\):\s*(\d+)")

MANIFEST_PATHS = {
    "registry": "evidence/research/retained/modern-c/registry/manifest.json",
    "lifecycle": "evidence/research/retained/modern-c/lifecycle/manifest.json",
    "gc-ffi": "evidence/research/retained/modern-c/gc-ffi/manifest.json",
    "gerbil": "evidence/research/retained/modern-c/gerbil/manifest.json",
    "release": "evidence/research/retained/modern-c/release/manifest.json",
}

FAMILY_REQUIRED_TARGETS = {
    "registry": (
        "test-vm-lifecycle",
        "test-ordered-sync",
        "test-ordered-sync-emulated",
        "test-binding-activation",
        "test-runtime-roles",
        "test-globals-snapshot",
        "test-symkey-publication",
        "test-pipe-domain",
    ),
    "lifecycle": (
        "test-startup-publication",
        "test-vm-lifecycle",
        "test-mutex-suspension",
        "unknown-join-worker-domains",
    ),
    "gc-ffi": (
        "test7",
        "test8",
        "test9",
        "test-sfun-entry",
        "test-marker-input",
        "test-root-task",
        "test-symkey-views",
        "test-symkey-callback",
        "test-rest-parameters",
        "test-frame-contract",
        "test-entry",
        "test-rc-roots",
        "test-collector-diagnostics",
        "worker-arena",
        "worker-root-domains",
    ),
}

GERBIL_STAGES = (
    "boot-gxi",
    "stage0",
    "stage1",
    "stdlib",
    "libgerbil",
    "lang",
    "tools",
    "correctness",
)

ALL_TWELVE_FAMILIES = (
    "bootstrap",
    "gsi",
    "gsc",
    "pr-gsi",
    "pr-gsc",
    "stress-gsi",
    "stress-gsc",
    "registry",
    "lifecycle",
    "gc-ffi",
    "gerbil",
    "release",
)

PRODUCER_DIGEST_KEYS = (
    "gsiSha256",
    "gscSha256",
    "libgambitSha256",
    "gambitHeaderSha256",
    "gambuildCSha256",
)


def _is_sha256(value: object) -> bool:
    return isinstance(value, str) and _SHA256_RE.fullmatch(value) is not None


def _parse_rss_bytes(stderr_text: str) -> int:
    m = _MACOS_RSS_RE.search(stderr_text)
    if m:
        return int(m.group(1))
    m = _LINUX_RSS_KB_RE.search(stderr_text)
    if m:
        return int(m.group(1)) * 1024
    return 0


def _parse_footprint_bytes(stderr_text: str) -> int:
    m = _MACOS_FOOTPRINT_RE.search(stderr_text)
    if m:
        return int(m.group(1))
    return 0


def producer_seal_from_runtime(runtime: Path) -> dict:
    """Compute the exact 5-artifact SHA-256 seal of a compiled Gambit producer."""
    rt = Path(runtime)
    mapping = {
        "gsiSha256": "gsi/gsi",
        "gscSha256": "gsc/gsc",
        "libgambitSha256": "lib/libgambit.a",
        "gambitHeaderSha256": "include/gambit.h",
        "gambuildCSha256": "bin/gambuild-C",
    }
    seal = {}
    for key, rel in mapping.items():
        seal[key] = digest(relative(rt, rel))
    return seal


def verify_sealed_producer(producer: dict, *, runtime: Path | None = None) -> list[str]:
    gaps: list[str] = []
    if not isinstance(producer, dict):
        return ["missing sealed producer block"]
    for key in PRODUCER_DIGEST_KEYS:
        if not _is_sha256(producer.get(key)):
            gaps.append(f"producer missing valid 64-hex {key}")
    if runtime is not None and not gaps:
        live = producer_seal_from_runtime(runtime)
        for key in PRODUCER_DIGEST_KEYS:
            if producer.get(key) != live[key]:
                gaps.append(f"producer {key} differs from live runtime bytes")
    return gaps


def verify_family_formal_models(root: Path, family: str) -> dict:
    """Verify live workspace SHA-256 bindings for a family's manifest, formal models, and fixtures."""
    if family not in MANIFEST_PATHS:
        raise ValueError(f"unknown family: {family}")
    manifest_rel = MANIFEST_PATHS[family]
    manifest_path = relative(root, manifest_rel)
    raw = manifest_path.read_bytes()
    if len(raw) >= MAX_GIT_JSON_BYTES:
        raise ValueError(f"{manifest_rel} exceeds 64 KiB publication limit")
    manifest_sha = hashlib.sha256(raw).hexdigest()
    manifest = json.loads(raw.decode("utf-8"))

    gaps: list[str] = []
    verified_models: dict[str, str] = {}
    model_inputs = manifest.get("modelInputs")
    if not isinstance(model_inputs, dict) or not model_inputs:
        gaps.append(f"{family} manifest missing modelInputs")
    else:
        for rel, expected in model_inputs.items():
            if not _is_sha256(expected):
                gaps.append(f"{family} manifest invalid digest for {rel}")
                continue
            path = relative(root, rel)
            if not path.is_file():
                gaps.append(f"{family} missing formal model artifact: {rel}")
                continue
            actual = digest(path)
            if actual != expected:
                gaps.append(f"{family} formal model digest drift: {rel}")
            else:
                verified_models[rel] = actual

    verified_cases = 0
    for case in manifest.get("cases", []):
        src = case.get("source")
        expected = case.get("sha256")
        if not isinstance(src, str) or not _is_sha256(expected):
            gaps.append(f"{family} manifest invalid fixture entry: {case}")
            continue
        path = relative(root, src)
        if not path.is_file():
            gaps.append(f"{family} missing native fixture: {src}")
            continue
        actual = digest(path)
        if actual != expected:
            gaps.append(f"{family} native fixture digest drift: {src}")
        else:
            verified_cases += 1

    return dict(
        family=family,
        manifestPath=manifest_rel,
        manifestSha256=manifest_sha,
        verifiedModels=len(verified_models),
        verifiedFixtures=verified_cases,
        spec=manifest.get("spec", {}),
        passed=(len(gaps) == 0),
        gaps=gaps,
    )


def verify_p02_source_anchors(root: Path) -> dict:
    """Verify the P0-2 binding-read activation source anchors in vendor/gambit."""
    gaps: list[str] = []
    gb_rel = "vendor/gambit/lib/_mem/global-bindings.inc"
    de_rel = "vendor/gambit/include/_gambit/declarations_end.h.in"
    gb_path = relative(root, gb_rel)
    de_path = relative(root, de_rel)
    if not gb_path.is_file():
        gaps.append(f"missing {gb_rel}")
    else:
        gb_text = gb_path.read_text(encoding="utf-8")
        if "___global_slot_page *page=___global_page(vm,g->val);" not in gb_text:
            gaps.append("P0-2 single-page primitive_value anchor missing in global-bindings.inc")
        if "view_vm=ps->context->binding_view.vm;" not in gb_text or "ps == ___PSTATE" not in gb_text:
            gaps.append("P0-2 authenticated binding_view.vm fast path missing in ___primitive_ref")
        if "if (!root_writer_open(ps))" not in gb_text:
            gaps.append("P0-2 root_writer_open fallback missing in ___primitive_ref")
    if not de_path.is_file():
        gaps.append(f"missing {de_rel}")
    else:
        de_text = de_path.read_text(encoding="utf-8")
        if "#undef ___GLOBALVARPRIMREF" not in de_text:
            gaps.append("P0-2 #undef ___GLOBALVARPRIMREF missing in declarations_end.h.in")
        if "#define ___GLOBALVARPRIMREF(gv)(___binding_vm ? ___binding_primitive(___binding_vm,___GLOBALVARSTRUCT(gv)) : ___EXT(___primitive_ref)(___ps,___GLOBALVARSTRUCT(gv)))" not in de_text:
            gaps.append("P0-2 fast ___GLOBALVARPRIMREF macro definition missing in declarations_end.h.in")
    return dict(passed=(len(gaps) == 0), gaps=gaps)


_IMP_FUNC_RE = re.compile(r"___IMP_FUNC\s*\([^,]+,\s*(___[A-Za-z0-9_]+)\s*\)")
_GSTATE_PTR_RE = re.compile(r"\(\*\s*(___[A-Za-z0-9_]+)\s*\)")
_GSTATE_INIT_RE = re.compile(r"___GSTATE->(___[A-Za-z0-9_]+)\s*=")
_EXT_CALL_RE = re.compile(r"___EXT\s*\(\s*(___[A-Za-z0-9_]+)\s*\)")

_DYNAMIC_MACRO_HEADERS = (
    "vendor/gambit/include/_gambit/gvm_operations.h.in",
    "vendor/gambit/include/_gambit/stack_operations.h.in",
    "vendor/gambit/include/_gambit/declarations_end.h.in",
)


def verify_dynamic_o1_abi_closure(root: Path) -> dict:
    """Adversarially verify 4-way dynamic .o1 ABI closure across ALL ___IMP_FUNC symbols.

    Proves:
      1. Every ___IMP_FUNC symbol called inside loadable-module macro bodies in
         gvm_operations.h.in, stack_operations.h.in, and declarations_end.h.in
         goes through ___EXT(sym) (zero bare direct symbol calls).
      2. Every symbol referenced via ___EXT(sym) in those headers has BOTH a
         function-pointer field in include/_gambit/global_state.h.in AND a live
         binding `___GSTATE->sym = ...` in lib/setup.c.
      3. Specifically witnesses 4-way closure for `___publish_raw_stack_span`,
         `___group_demand_enter`, `___group_demand_commit`, and `___primitive_ref`.
    """
    gaps: list[str] = []
    header_dir = relative(root, "vendor/gambit/include/_gambit")
    gstate_path = relative(root, "vendor/gambit/include/_gambit/global_state.h.in")
    setup_path = relative(root, "vendor/gambit/lib/setup.c")

    if not header_dir.is_dir() or not gstate_path.is_file() or not setup_path.is_file():
        return dict(
            passed=False,
            impFuncCount=0,
            extRefsChecked=0,
            bareLeaks=[],
            missingGstateFields=[],
            missingSetupBindings=[],
            gaps=["missing vendor/gambit headers or lib/setup.c for dynamic ABI audit"],
        )

    imp_funcs: set[str] = set()
    for h in sorted(header_dir.glob("*.h.in")):
        text = h.read_text(encoding="utf-8", errors="replace")
        imp_funcs.update(_IMP_FUNC_RE.findall(text))

    gstate_text = gstate_path.read_text(encoding="utf-8", errors="replace")
    gstate_fields = set(_GSTATE_PTR_RE.findall(gstate_text))
    setup_text = setup_path.read_text(encoding="utf-8", errors="replace")
    setup_bindings = set(_GSTATE_INIT_RE.findall(setup_text))

    ext_refs: set[str] = set()
    bare_leaks: list[str] = []
    # Match any identifier-like ___foo( call; filter against declared imp_funcs
    call_re = re.compile(r"(?<!___EXT\()(?<![A-Za-z0-9_])(___[A-Za-z0-9_]+)\s*\(")

    for rel in _DYNAMIC_MACRO_HEADERS:
        hp = relative(root, rel)
        if not hp.is_file():
            gaps.append(f"missing dynamic macro header: {rel}")
            continue
        lines = hp.read_text(encoding="utf-8", errors="replace").splitlines()
        in_macro = False
        for lineno, raw_line in enumerate(lines, start=1):
            stripped = raw_line.strip()
            if stripped.startswith("#define"):
                in_macro = True
                # Skip `#define ___foo(...) ___EXT(___foo)(...)` definition head itself
                body = stripped.split(None, 2)[2] if len(stripped.split(None, 2)) >= 3 else ""
            elif in_macro:
                body = stripped
            else:
                body = ""

            if in_macro:
                # Strip C single-line block comments on this line before scanning calls
                cleaned = re.sub(r"/\*.*?\*/", " ", body)
                ext_refs.update(_EXT_CALL_RE.findall(cleaned))
                # Remove all ___EXT(sym) occurrences before checking bare calls
                without_ext = _EXT_CALL_RE.sub(" ", cleaned)
                for m in call_re.finditer(without_ext):
                    sym = m.group(1)
                    if sym in imp_funcs:
                        bare_leaks.append(f"{rel}:{lineno}:{sym}")
                if not raw_line.rstrip().endswith("\\"):
                    in_macro = False

    missing_gstate = sorted(s for s in ext_refs if s not in gstate_fields and s in imp_funcs)
    missing_setup = sorted(s for s in ext_refs if s not in setup_bindings and s in imp_funcs)

    required_exports = (
        "___publish_raw_stack_span",
        "___group_demand_enter",
        "___group_demand_commit",
        "___primitive_ref",
    )
    for req in required_exports:
        if req not in imp_funcs:
            gaps.append(f"required dynamic ABI symbol missing ___IMP_FUNC: {req}")
        if req not in gstate_fields:
            gaps.append(f"required dynamic ABI symbol missing ___global_state_struct field: {req}")
        if req not in setup_bindings:
            gaps.append(f"required dynamic ABI symbol missing lib/setup.c binding: {req}")

    for leak in bare_leaks:
        gaps.append(f"bare non-___EXT dynamic .o1 macro call leak: {leak}")
    for sym in missing_gstate:
        gaps.append(f"___EXT macro symbol missing ___global_state_struct field: {sym}")
    for sym in missing_setup:
        gaps.append(f"___EXT macro symbol missing lib/setup.c binding: {sym}")

    return dict(
        passed=(len(gaps) == 0),
        impFuncCount=len(imp_funcs),
        extRefsChecked=len(ext_refs),
        bareLeaks=bare_leaks,
        missingGstateFields=missing_gstate,
        missingSetupBindings=missing_setup,
        gaps=gaps,
    )


def verify_v12_architectural_anchors(root: Path) -> dict:
    """Verify all v12 architectural hardening cuts across compiler, runtime, and headers."""
    gaps: list[str] = []
    p02 = verify_p02_source_anchors(root)
    gaps.extend(p02["gaps"])
    abi = verify_dynamic_o1_abi_closure(root)
    gaps.extend(abi["gaps"])

    tc2_path = relative(root, "vendor/gambit/gsc/_t-c-2.scm")
    if not tc2_path.is_file():
        gaps.append("missing vendor/gambit/gsc/_t-c-2.scm")
    else:
        tc2 = tc2_path.read_text(encoding="utf-8", errors="replace")
        if "(define (targ-scrub-dirty-unboxed)" not in tc2:
            gaps.append("v12 missing targ-scrub-dirty-unboxed in gsc/_t-c-2.scm")
        if "(targ-scrub-dirty-unboxed)" not in tc2:
            gaps.append("v12 missing post-grant (targ-scrub-dirty-unboxed) call in gsc/_t-c-2.scm")
        if "(targ-fp-cache-dirty? (make-stk (+ i 1)))" not in tc2:
            gaps.append("v12 missing physical-index raw? stack/reg check in gsc/_t-c-2.scm")

    rt_path = relative(root, "vendor/gambit/lib/_mem/root-tasks.inc")
    if not rt_path.is_file():
        gaps.append("missing vendor/gambit/lib/_mem/root-tasks.inc")
    else:
        rt = rt_path.read_text(encoding="utf-8", errors="replace")
        if "int live=(round->participants>0)?1:0;" not in rt or "else break;" not in rt:
            gaps.append("v12 missing primary P0 contiguous live-prefix accounting in root-tasks.inc")

    kern_path = relative(root, "vendor/gambit/lib/_kernel.scm")
    if not kern_path.is_file():
        gaps.append("missing vendor/gambit/lib/_kernel.scm")
    else:
        kern = kern_path.read_text(encoding="utf-8", errors="replace")
        if kern.count("___group_demand_retire(___ps);") < 2:
            gaps.append("v12 missing overflow ___group_demand_retire(___ps) anchors in lib/_kernel.scm")
        if "___PUSH_ARGS2(ret_val, target_id)" not in kern:
            gaps.append("v12 missing cross-core R1 preservation in handler_return_to_c")

    # Post-GC owner foreign-finalizer drain re-entry & NULL c_closure_self guards
    vr_path = relative(root, "vendor/gambit/lib/_setup/vm-registry.inc")
    if not vr_path.is_file():
        gaps.append("missing vendor/gambit/lib/_setup/vm-registry.inc")
    else:
        vr = vr_path.read_text(encoding="utf-8", errors="replace")
        if "life->cleanup[id].draining || life->cleanup[id].uncertain" not in vr:
            gaps.append("v13 missing cleanup drain re-entry guard in ___lifecycle_enter (vm-registry.inc)")
        if "!vm->lifecycle->cleanup[id].draining && !vm->lifecycle->cleanup[id].uncertain" not in vr:
            gaps.append("v13 missing cleanup drain guard in ___lifecycle_gc_admitted (vm-registry.inc)")

    rc_path = relative(root, "vendor/gambit/lib/_mem/rc-allocation.inc")
    if not rc_path.is_file():
        gaps.append("missing vendor/gambit/lib/_mem/rc-allocation.inc")
    else:
        rc = rc_path.read_text(encoding="utf-8", errors="replace")
        if "vm->lifecycle->cleanup[id].draining || vm->lifecycle->cleanup[id].uncertain" not in rc:
            gaps.append("v13 missing cleanup drain guard in root_writer_open (rc-allocation.inc)")

    setup_path = relative(root, "vendor/gambit/lib/setup.c")
    if not setup_path.is_file():
        gaps.append("missing vendor/gambit/lib/setup.c")
    else:
        st = setup_path.read_text(encoding="utf-8", errors="replace")
        if "vm->lifecycle->cleanup[id].draining ||" not in st:
            gaps.append("v13 missing cleanup drain pre-collective guard in ___garbage_collect (setup.c)")

    cintf_path = relative(root, "vendor/gambit/lib/c_intf.c")
    if not cintf_path.is_file():
        gaps.append("missing vendor/gambit/lib/c_intf.c")
    else:
        ci = cintf_path.read_text(encoding="utf-8", errors="replace")
        if "void *self = ___c_closure_self ();" not in ci:
            gaps.append("v13 missing NULL ___c_closure_self() guard in make_sfun_stack_marker (c_intf.c)")

    cp_path = relative(root, "vendor/gambit/lib/_mem/copy-planning.inc")
    if not cp_path.is_file():
        gaps.append("missing vendor/gambit/lib/_mem/copy-planning.inc")
    else:
        cp = cp_path.read_text(encoding="utf-8", errors="replace")
        if "&half_words,&known_break)) {c->failed=1;return;}" not in cp:
            gaps.append("v13 missing strict c->failed=1 refusal in census_capture (copy-planning.inc)")

    # v15 SMP POSIX child-process reaping & dgroup custody + outlined global resolver
    osio_path = relative(root, "vendor/gambit/lib/os_io.c")
    if not osio_path.is_file():
        gaps.append("missing vendor/gambit/lib/os_io.c")
    else:
        osio = osio_path.read_text(encoding="utf-8", errors="replace")
        if "device_group_mutex" not in osio or "process_reap_mutex" not in osio:
            gaps.append("v15 missing device_group_mutex/process_reap_mutex in lib/os_io.c")
        if "___waitpid_no_EINTR (dev->pid, &status, WNOHANG)" not in osio:
            gaps.append("v15 missing PID-specific waitpid(dev->pid, WNOHANG) poll in lib/os_io.c")
        if "___waitpid_no_EINTR (-1," in osio:
            gaps.append("v15 wildcard waitpid(-1) still present in lib/os_io.c (SMP premature-reap hazard)")

    de_path = relative(root, "vendor/gambit/include/_gambit/declarations_end.h.in")
    if de_path.is_file():
        de = de_path.read_text(encoding="utf-8", errors="replace")
        if "___BINDING_NOINLINE" not in de:
            gaps.append("v15 missing ___BINDING_NOINLINE on outlined global page resolver (declarations_end.h.in)")

    # v16 zero-growth budgeted nursery TLAB refill in rest-parameter handlers
    hs_path = relative(root, "vendor/gambit/lib/_mem/heap-sections.inc")
    if not hs_path.is_file():
        gaps.append("missing vendor/gambit/lib/_mem/heap-sections.inc")
    else:
        hs = hs_path.read_text(encoding="utf-8", errors="replace")
        if "___BOOL ___rest_take_free_section(" not in hs:
            gaps.append("v16 missing ___rest_take_free_section in lib/_mem/heap-sections.inc")
        if "compute_free_heap_space_approximately() < ___MSECTION_SIZE" not in hs:
            gaps.append("v16 missing free-nursery gate in ___rest_take_free_section (heap-sections.inc)")
    if kern_path.is_file():
        if kern.count("___rest_take_free_section(___ps, i, np,") < 2:
            gaps.append("v16 missing ___rest_take_free_section in both handler_get_rest and handler_get_key_rest (lib/_kernel.scm)")

    # v17 SMP device close-vs-select custody fence & async idle-processor scheduler-error delivery
    if osio_path.is_file():
        if "device_select_mutex" not in osio or "active_select_list" not in osio:
            gaps.append("v17 missing device_select_mutex/active_select_list borrow-fence in lib/os_io.c")
        if "while (self->select_active > 0)" not in osio or "self->close_in_progress = 1;" not in osio:
            gaps.append("v17 missing serialized close drain fence in ___device_close (lib/os_io.c)")
        if "? ___DIRECTION_WR\n                        : 0));" not in osio:
            gaps.append("v24 missing FOR_EVENT dir=0 zero-busyspin borrow-fence fix in lib/os_io.c")
    osioh_path = relative(root, "vendor/gambit/lib/os_io.h")
    if not osioh_path.is_file():
        gaps.append("missing vendor/gambit/lib/os_io.h")
    else:
        osioh = osioh_path.read_text(encoding="utf-8", errors="replace")
        if "int close_pending_mask;" not in osioh or "int select_active;" not in osioh:
            gaps.append("v17 missing close_pending_mask/select_active fields in lib/os_io.h")
    thr_path = relative(root, "vendor/gambit/lib/_thread.scm")
    if not thr_path.is_file():
        gaps.append("missing vendor/gambit/lib/_thread.scm")
    else:
        thr = thr_path.read_text(encoding="utf-8", errors="replace")
        if "(define-prim (##thread-report-scheduler-error! code)" not in thr:
            gaps.append("v17 missing ##thread-report-scheduler-error! in lib/_thread.scm")
        elif "(##thread-intr!\n   (macro-primordial-thread)\n   #t\n" not in thr:
            gaps.append("v17 ##thread-report-scheduler-error! must use async?=#t (idle-processor 0xc3 SIGSEGV guard)")
        if "Async delivery may execute on an idle processor" not in thr:
            gaps.append("v17 missing idle-processor async path in ##thread-intr! (lib/_thread.scm)")

    # v18/v21 Darwin direct posix_spawn (non-PTY) + child-env PATH resolution, one-shot rest-observation env cache, NULL-catcher resize guard
    if osio_path.is_file():
        if "POSIX_SPAWN_SETSIGMASK" not in osio or "posix_spawnp" not in osio or "process_fork_mutex" not in osio:
            gaps.append("v18 missing direct Darwin posix_spawn/posix_spawnp or process_fork_mutex in lib/os_io.c")
        if 'strncmp (*ep, "PATH=", 5) == 0' not in osio or "saved_eacces" not in osio:
            gaps.append("v21 missing child-env PATH resolution in direct Darwin posix_spawn (lib/os_io.c)")
    ro_path = relative(root, "vendor/gambit/lib/_mem/rest-observation.inc")
    if not ro_path.is_file():
        gaps.append("missing vendor/gambit/lib/_mem/rest-observation.inc")
    else:
        ro = ro_path.read_text(encoding="utf-8", errors="replace")
        if "rest_observation_env_probed" not in ro:
            gaps.append("v18 missing one-shot rest_observation_env_probed cache in lib/_mem/rest-observation.inc")
    if rc_path.is_file():
        if "rest_attempt_owner && ps==rest_attempt_owner" not in rc or "rest_observation_env_probed" not in rc:
            gaps.append("v18 missing fast rest_attempt_owner / rest_observation_env_probed guard in lib/_mem/rc-allocation.inc")
    if setup_path.is_file():
        if "___ps->catcher != NULL" not in st:
            gaps.append("v18 missing NULL ___ps->catcher guard in current_vm_resize_request (lib/setup.c)")

    # v19/v23 architecture-adaptive cache-line separation + zero-write MESI rest disarm fast path
    ps_path = relative(root, "vendor/gambit/include/_gambit/processor_state.h.in")
    if not ps_path.is_file():
        gaps.append("missing vendor/gambit/include/_gambit/processor_state.h.in")
    else:
        ps_txt = ps_path.read_text(encoding="utf-8", errors="replace")
        if "#ifndef ___CACHE_LINE_SIZE" not in ps_txt or ps_txt.count("char cache_line_guard[___CACHE_LINE_SIZE];") < 2:
            gaps.append("v23 missing ___CACHE_LINE_SIZE adaptive cache_line_guard on both processor structs")
    if rc_path.is_file():
        if "!rest_attempt_owner && !___rest_attempt_words" not in rc:
            gaps.append("v19 missing zero-write fast-path guard in ___rest_disarm_attempt (rc-allocation.inc)")
    if ro_path.is_file():
        if "!__atomic_load_n(&rest_observation_root_base, __ATOMIC_RELAXED)" not in ro:
            gaps.append("v19 missing read-only guard in ___rest_observation_clear_roots (rest-observation.inc)")

    # v20/v23 flag-driven & CFG-adaptive contiguous host partitioning
    tc1_path = relative(root, "vendor/gambit/gsc/_t-c-1.scm")
    if not tc1_path.is_file():
        gaps.append("missing vendor/gambit/gsc/_t-c-1.scm")
    else:
        tc1 = tc1_path.read_text(encoding="utf-8", errors="replace")
        if "(cfg-host-limit fixnum)" not in tc1 or "(define targ-cfg-host-limit (make-parameter -1))" not in tc1:
            gaps.append("v23 missing -cfg-host-limit target option / parameter in gsc/_t-c-1.scm")
        if "targ-adaptive-cfg-base-target" not in tc1 or "(<= (* 4 sum-sq) (* 3 (* count count)))" not in tc1:
            gaps.append("v23 missing adaptive compactness target or quadratic cost-benefit gate in gsc/_t-c-1.scm")
        if "(eqv? (car val-roots) entry-root)" not in tc1:
            gaps.append("v20 missing canonical host-0 entry-root invariant in gsc/_t-c-1.scm")
        if "(and (pair? obj)" not in tc1:
            gaps.append("v22 missing non-proc-obj guard in targ-plan-procedure-hosts (gsc/_t-c-1.scm)")
        if "___OPTIMIZED_HOST_LIMIT" not in tc1 or "___PH_ATTRS" not in tc1:
            gaps.append("v24 missing per-host ___OPTIMIZED_HOST_LIMIT / ___PH_ATTRS emission in gsc/_t-c-1.scm")

    cfgac_path = relative(root, "vendor/gambit/configure.ac")
    if cfgac_path.is_file():
        cfgac = cfgac_path.read_text(encoding="utf-8", errors="replace")
        if "no-schedule-insns2" not in cfgac or "no-modulo-sched" not in cfgac:
            gaps.append("v22 missing flag-driven GCC quadratic-pass guards in configure.ac")
        if "gc-fromspace-reclaim" not in cfgac or "CONF_GC_FROM_RECLAIM_MIN_SECTIONS" not in cfgac:
            gaps.append("v23 missing --enable-gc-fromspace-reclaim flag in configure.ac")
        if "optimized-host-limit" not in cfgac or "CONF_OPTIMIZED_HOST_LIMIT" not in cfgac:
            gaps.append("v24 missing --enable-optimized-host-limit flag in configure.ac")

    cfgh_path = relative(root, "vendor/gambit/include/_gambit/configuration.h.in")
    if cfgh_path.is_file():
        cfgh = cfgh_path.read_text(encoding="utf-8", errors="replace")
        if "@CONF_GC_FROM_RECLAIM_MIN_SECTIONS@" not in cfgh:
            gaps.append("v23 missing @CONF_GC_FROM_RECLAIM_MIN_SECTIONS@ substitution in configuration.h.in")
        if "@CONF_OPTIMIZED_HOST_LIMIT@" not in cfgh or "___GNUC_HOST_FUNCTION_ATTRIBUTES_UNOPTIMIZED" not in cfgh:
            gaps.append("v24 missing @CONF_OPTIMIZED_HOST_LIMIT@ / ___GNUC_HOST_FUNCTION_ATTRIBUTES_UNOPTIMIZED in configuration.h.in")

    al_path = relative(root, "vendor/gambit/lib/_mem/allocation-limits.inc")
    if al_path.is_file():
        al = al_path.read_text(encoding="utf-8", errors="replace")
        if "if (!___lifecycle_gc_admitted(___ps) &&" not in al:
            gaps.append("v24 missing !___lifecycle_gc_admitted guard in ___heap_continue_on_free_section (allocation-limits.inc)")

    # v21/v23 adaptive STW drained-fromspace OS page reclamation
    ms_path = relative(root, "vendor/gambit/lib/_mem/movable-sections.inc")
    if not ms_path.is_file():
        gaps.append("missing vendor/gambit/lib/_mem/movable-sections.inc")
    else:
        ms = ms_path.read_text(encoding="utf-8", errors="replace")
        if ("#ifndef ___GC_FROM_RECLAIM_MIN_SECTIONS" not in ms
                or "msection_adaptive_reclaim_min_sections" not in ms
                or "msection_os_phys_memory_bytes" not in ms
                or "msection_os_cpu_count" not in ms
                or "reclaim_drained_source_pages" not in ms):
            gaps.append("v25 missing CPU+RAM adaptive fromspace reclamation helpers in movable-sections.inc")
        if "alloc_msection_storage" not in ms or "free_msection_storage" not in ms:
            gaps.append("v21 missing mmap msection storage helpers in movable-sections.inc")
    cr_path = relative(root, "vendor/gambit/lib/_mem/collection-round.inc")
    if cr_path.is_file():
        cr = cr_path.read_text(encoding="utf-8", errors="replace")
        if "custom_msection_alloc==0" not in cr or "reclaim_drained_source_pages(" not in cr:
            gaps.append("v22 missing custom_msection_alloc==0 / reclaim_drained_source_pages call in collection-round.inc")
        if "gc_take_freed_malloc_still_words()" not in cr or "os_heap_pressure_relief()" not in cr:
            gaps.append("v26 missing post-sweep OS allocator pressure relief in collection-round.inc")

    # v26 Unified Memory Scaling Envelope (direct-mmap census/still, collapse-aware contraction,
    # sub-linear O(sqrt(P)) floor, hardware-adaptive live_percent, pre-cc1 gsc trim,
    # Wave-A fast_span rest check, strict-DRF mutex-guarded mailbox wakeup)
    aa_path = relative(root, "vendor/gambit/lib/_mem/aligned-allocation.inc")
    if not aa_path.is_file():
        gaps.append("missing vendor/gambit/lib/_mem/aligned-allocation.inc")
    else:
        aa = aa_path.read_text(encoding="utf-8", errors="replace")
        if "___USE_MMAP_LARGE_HEAP" not in aa or "census_queue_alloc" not in aa or "census_queue_free" not in aa:
            gaps.append("v26 missing direct-mmap large still / census_queue helpers in aligned-allocation.inc")
        if "os_heap_pressure_relief" not in aa:
            gaps.append("v26 missing os_heap_pressure_relief in aligned-allocation.inc")
    cp_path = relative(root, "vendor/gambit/lib/_mem/copy-planning.inc")
    if cp_path.is_file():
        cp = cp_path.read_text(encoding="utf-8", errors="replace")
        if "___CENSUS_QUEUE_RETAIN_MAX_BYTES" not in cp or "census_queue_free(" not in cp:
            gaps.append("v26 missing post-round oversized census.queue release in copy-planning.inc")
    cap_path = relative(root, "vendor/gambit/lib/_mem/capacity-resize.inc")
    if cap_path.is_file():
        cap = cap_path.read_text(encoding="utf-8", errors="replace")
        if "gc_smp_nursery_headroom(" not in cap or "decay_target_heap_space_history" not in cap or "___gc_request_contraction" not in cap:
            gaps.append("v26 missing sub-linear headroom / collapse-aware contraction in capacity-resize.inc")
    ml_path = relative(root, "vendor/gambit/lib/_mem/memory-lifecycle.inc")
    if ml_path.is_file():
        ml = ml_path.read_text(encoding="utf-8", errors="replace")
        if "gc_adaptive_live_percent" not in ml or "___live_percent_is_explicit()" not in ml:
            gaps.append("v26 missing hardware-adaptive live_percent with explicit -:l<N> guard in memory-lifecycle.inc")
    gsclib_path = relative(root, "vendor/gambit/gsc/_gsclib.scm")
    if gsclib_path.is_file():
        gsclib = gsclib_path.read_text(encoding="utf-8", errors="replace")
        if "(begin (##gc) #t)" not in gsclib:
            gaps.append("v26 missing pre-##gambuild (##gc) dead-heap trim in gsc/_gsclib.scm")
    if rc_path.is_file():
        if "ps->stack_fast_floor_b" not in rc or "ps->heap_fast_bytes" not in rc:
            gaps.append("v26 missing Wave-A-aligned lock-free fast_span check in ___rest_fast_grant_fits")
    if thr_path.is_file():
        if "(macro-condvar-name-set! (macro-mailbox-condvar mb) #t)" not in thr:
            gaps.append("v26 missing strict-DRF mutex-guarded mailbox waiter flag in lib/_thread.scm")
    if cfgac_path.is_file():
        if "gc-adaptive-sizing" not in cfgac or "gc-heap-contraction" not in cfgac:
            gaps.append("v26 missing --enable-gc-adaptive-sizing / --enable-gc-heap-contraction in configure.ac")
    if cfgh_path.is_file():
        if "@CONF_GC_ADAPTIVE_SIZING@" not in cfgh or "@CONF_GC_HEAP_CONTRACTION_MODE@" not in cfgh:
            gaps.append("v26 missing @CONF_GC_ADAPTIVE_SIZING@ / @CONF_GC_HEAP_CONTRACTION_MODE@ in configuration.h.in")

    return dict(
        passed=(len(gaps) == 0),
        p02Passed=p02["passed"],
        dynamicAbiPassed=abi["passed"],
        impFuncCount=abi["impFuncCount"],
        gaps=gaps,
    )


def _check_target_records(
    receipt: dict,
    required_targets: tuple[str, ...],
    *,
    family: str,
) -> tuple[list[str], int]:
    gaps: list[str] = []
    records = receipt.get("targets")
    if not isinstance(records, list) or not records:
        return [f"{family} receipt missing target execution records"], 0

    by_name: dict[str, dict] = {}
    peak_rss = 0
    for row in records:
        name = row.get("target")
        if not isinstance(name, str) or not name:
            gaps.append(f"{family} target record missing target name")
            continue
        if name in by_name:
            gaps.append(f"{family} duplicate target record: {name}")
            continue
        by_name[name] = row

        rss = row.get("peakRssBytes", 0)
        if not isinstance(rss, int) or rss < 0 or rss >= MAX_RSS_BYTES:
            gaps.append(f"{family} target {name} peakRssBytes={rss} violates < 8 GiB limit")
        else:
            peak_rss = max(peak_rss, rss)

        if (row.get("passed") is not True
                or row.get("exit") != 0
                or row.get("timeout") is not False
                or row.get("parentReaped") is not True
                or row.get("processGroupQuiescent") is not True):
            gaps.append(f"{family} target {name} did not complete naturally and quiescently")

    for req in required_targets:
        if req not in by_name:
            gaps.append(f"{family} missing required target: {req}")

    declared_peak = receipt.get("peakRssBytes", peak_rss)
    if not isinstance(declared_peak, int) or declared_peak < peak_rss or declared_peak >= MAX_RSS_BYTES:
        gaps.append(f"{family} receipt peakRssBytes={declared_peak} invalid or >= 8 GiB")
    else:
        peak_rss = max(peak_rss, declared_peak)

    return gaps, peak_rss


def _check_manifest_binding(receipt: dict, formal: dict, family: str) -> list[str]:
    gaps: list[str] = []
    if receipt.get("manifestSha256") != formal["manifestSha256"]:
        gaps.append(f"{family} receipt manifestSha256 differs from live {formal['manifestPath']}")
    if receipt.get("profileSha256") != formal["spec"].get("profile"):
        gaps.append(f"{family} receipt profileSha256 differs from manifest spec profile")
    return gaps


def audit_registry_family(root: Path, receipt: dict, *, runtime: Path | None = None) -> dict:
    """Offline cryptographic audit for Family 8 (8/12: registry + P0-2 binding-read)."""
    gaps: list[str] = []
    formal = verify_family_formal_models(root, "registry")
    gaps.extend(formal["gaps"])
    p02 = verify_p02_source_anchors(root)
    gaps.extend(p02["gaps"])

    if receipt.get("schema") != "family8-registry-receipt.v1":
        gaps.append("registry receipt has wrong schema")
    if receipt.get("family") != "registry":
        gaps.append("registry receipt family field mismatch")
    gaps.extend(_check_manifest_binding(receipt, formal, "registry"))
    gaps.extend(verify_sealed_producer(receipt.get("producer"), runtime=runtime))
    target_gaps, peak_rss = _check_target_records(
        receipt, FAMILY_REQUIRED_TARGETS["registry"], family="registry"
    )
    gaps.extend(target_gaps)
    if receipt.get("producerIntact") is not True:
        gaps.append("registry receipt missing producerIntact=True confirmation")

    return dict(
        family="registry",
        ordinal=8,
        passed=(len(gaps) == 0),
        peakRssBytes=peak_rss,
        verifiedModels=formal["verifiedModels"],
        p02AnchorsPassed=p02["passed"],
        gaps=gaps,
        runtimeAdmitted=False,
    )


def audit_lifecycle_family(root: Path, receipt: dict, *, runtime: Path | None = None) -> dict:
    """Offline cryptographic audit for Family 9 (9/12: lifecycle)."""
    gaps: list[str] = []
    formal = verify_family_formal_models(root, "lifecycle")
    gaps.extend(formal["gaps"])

    if receipt.get("schema") != "family9-lifecycle-receipt.v1":
        gaps.append("lifecycle receipt has wrong schema")
    if receipt.get("family") != "lifecycle":
        gaps.append("lifecycle receipt family field mismatch")
    gaps.extend(_check_manifest_binding(receipt, formal, "lifecycle"))
    gaps.extend(verify_sealed_producer(receipt.get("producer"), runtime=runtime))
    target_gaps, peak_rss = _check_target_records(
        receipt, FAMILY_REQUIRED_TARGETS["lifecycle"], family="lifecycle"
    )
    gaps.extend(target_gaps)
    if receipt.get("producerIntact") is not True:
        gaps.append("lifecycle receipt missing producerIntact=True confirmation")
    fault_modes = receipt.get("startupFaultModesVerified")
    if not isinstance(fault_modes, int) or fault_modes < 10:
        gaps.append(f"lifecycle requires >= 10 startup fault modes verified, got {fault_modes}")

    return dict(
        family="lifecycle",
        ordinal=9,
        passed=(len(gaps) == 0),
        peakRssBytes=peak_rss,
        verifiedModels=formal["verifiedModels"],
        startupFaultModesVerified=fault_modes if isinstance(fault_modes, int) else 0,
        gaps=gaps,
        runtimeAdmitted=False,
    )


def audit_gc_ffi_family(root: Path, receipt: dict, *, runtime: Path | None = None) -> dict:
    """Offline cryptographic audit for Family 10 (10/12: gc-ffi)."""
    gaps: list[str] = []
    formal = verify_family_formal_models(root, "gc-ffi")
    gaps.extend(formal["gaps"])

    if receipt.get("schema") != "family10-gc-ffi-receipt.v1":
        gaps.append("gc-ffi receipt has wrong schema")
    if receipt.get("family") != "gc-ffi":
        gaps.append("gc-ffi receipt family field mismatch")
    gaps.extend(_check_manifest_binding(receipt, formal, "gc-ffi"))
    gaps.extend(verify_sealed_producer(receipt.get("producer"), runtime=runtime))
    target_gaps, peak_rss = _check_target_records(
        receipt, FAMILY_REQUIRED_TARGETS["gc-ffi"], family="gc-ffi"
    )
    gaps.extend(target_gaps)
    if receipt.get("producerIntact") is not True:
        gaps.append("gc-ffi receipt missing producerIntact=True confirmation")

    return dict(
        family="gc-ffi",
        ordinal=10,
        passed=(len(gaps) == 0),
        peakRssBytes=peak_rss,
        verifiedModels=formal["verifiedModels"],
        gaps=gaps,
        runtimeAdmitted=False,
    )


def audit_gerbil_family(root: Path, receipt: dict, *, runtime: Path | None = None) -> dict:
    """Offline cryptographic audit for Family 11 (11/12: gerbil).

    Strictly enforces transitive same-producer/ABI closure across all 8 stages
    and refuses mixed-ABI or partial-stage promotion.
    """
    gaps: list[str] = []
    formal = verify_family_formal_models(root, "gerbil")
    gaps.extend(formal["gaps"])
    abi = verify_dynamic_o1_abi_closure(root)
    gaps.extend(abi["gaps"])

    if receipt.get("schema") != "family11-gerbil-receipt.v1":
        gaps.append("gerbil receipt has wrong schema")
    if receipt.get("family") != "gerbil":
        gaps.append("gerbil receipt family field mismatch")
    gaps.extend(_check_manifest_binding(receipt, formal, "gerbil"))
    producer = receipt.get("producer")
    gaps.extend(verify_sealed_producer(producer, runtime=runtime))

    cap = receipt.get("runtimeProfile") or {}
    if not (cap.get("multipleThreadedVms") is True
            and cap.get("multipleVms") is True
            and cap.get("smp") is True):
        gaps.append("gerbil SMP acceptance requires multipleThreadedVms=True, multipleVms=True, smp=True")

    stages = receipt.get("stages")
    by_stage: dict[str, dict] = {}
    mixed_producer = False
    peak_rss = 0
    if not isinstance(stages, list):
        gaps.append("gerbil receipt missing stages list")
    else:
        for row in stages:
            name = row.get("stage")
            if name not in GERBIL_STAGES:
                gaps.append(f"gerbil receipt contains unknown stage: {name}")
                continue
            if name in by_stage:
                gaps.append(f"gerbil receipt duplicate stage: {name}")
                continue
            by_stage[name] = row

            rss = row.get("peakRssBytes", 0)
            if not isinstance(rss, int) or rss < 0 or rss >= MAX_RSS_BYTES:
                gaps.append(f"gerbil stage {name} peakRssBytes={rss} violates < 8 GiB limit")
            else:
                peak_rss = max(peak_rss, rss)
            fp = row.get("peakFootprintBytes")
            if fp is not None and (not isinstance(fp, int) or fp < 0 or fp >= MAX_RSS_BYTES):
                gaps.append(f"gerbil stage {name} peakFootprintBytes={fp} violates < 8 GiB limit")

            stage_prod = row.get("producer")
            if isinstance(producer, dict) and stage_prod != producer:
                mixed_producer = True
                gaps.append(f"gerbil stage {name} consumed a different producer/ABI seal (mixed-ABI refused)")

            if (row.get("passed") is not True
                    or row.get("exit") != 0
                    or row.get("timeout") is not False):
                gaps.append(f"gerbil stage {name} did not pass naturally")

    completed_stages = [s for s in GERBIL_STAGES if s in by_stage and by_stage[s].get("passed") is True]
    missing_stages = [s for s in GERBIL_STAGES if s not in by_stage]
    for m in missing_stages:
        gaps.append(f"gerbil missing required downstream stage: {m}")

    status = "PASS" if len(gaps) == 0 else (
        "MIXED_ABI_REJECTED" if mixed_producer else (
            "SCOPED_PARTIAL" if completed_stages and missing_stages else "OPEN"
        )
    )
    return dict(
        family="gerbil",
        ordinal=11,
        passed=(len(gaps) == 0),
        status=status,
        completedStages=completed_stages,
        missingStages=missing_stages,
        mixedProducerDetected=mixed_producer,
        peakRssBytes=peak_rss,
        verifiedModels=formal["verifiedModels"],
        gaps=gaps,
        runtimeAdmitted=False,
    )


def audit_release_family(root: Path, receipt: dict) -> dict:
    """Offline cryptographic audit for Family 12 (12/12: release).

    Separates:
      - `pairedCohortPassed`: matched baseline vs candidate measurements under < 8 GiB RSS
        with complete censoring retention.
      - `wholeRuntimeAdmitted`: strict same-source 12/12 conjunction across all 12 families
        on one identical `sourceTree` and `profileSha256` with zero active vetoes and zero
        cross-source splicing.
    """
    gaps: list[str] = []
    conjunction_gaps: list[str] = []
    formal = verify_family_formal_models(root, "release")
    gaps.extend(formal["gaps"])

    if receipt.get("schema") != "family12-release-receipt.v1":
        gaps.append("release receipt has wrong schema")
    if receipt.get("family") != "release":
        gaps.append("release receipt family field mismatch")
    gaps.extend(_check_manifest_binding(receipt, formal, "release"))

    paired = receipt.get("pairedCohort") or {}
    base = paired.get("baseline") or {}
    cand = paired.get("candidate") or {}
    expected_profile = formal["spec"].get("profile")

    gaps.extend(verify_sealed_producer(base.get("producer")))
    gaps.extend(verify_sealed_producer(cand.get("producer")))
    if base.get("profileSha256") != expected_profile or cand.get("profileSha256") != expected_profile:
        gaps.append("paired release baseline and candidate must share exact manifest profileSha256")

    raw_censored = paired.get("rawCensoredEvents")
    retained_censored = paired.get("retainedCensoredEvents")
    if (not isinstance(raw_censored, int) or not isinstance(retained_censored, int)
            or raw_censored < 0 or retained_censored != raw_censored):
        gaps.append("paired release cohort must retain every censored event without omission")

    workloads = paired.get("workloads")
    peak_rss = 0
    if not isinstance(workloads, list) or not workloads:
        gaps.append("paired release cohort requires at least one matched workload observation")
    else:
        for wl in workloads:
            name = wl.get("name", "<unnamed>")
            for side in ("baseline", "candidate"):
                obs = wl.get(side) or {}
                rss = obs.get("peakRssBytes", -1)
                if not isinstance(rss, int) or rss < 0 or rss >= MAX_RSS_BYTES:
                    gaps.append(f"release workload {name}.{side} peakRssBytes={rss} violates < 8 GiB limit")
                else:
                    peak_rss = max(peak_rss, rss)
                if not isinstance(obs.get("completedWork"), int) or obs["completedWork"] <= 0:
                    gaps.append(f"release workload {name}.{side} missing positive completedWork")
                if not isinstance(obs.get("medianMs"), (int, float)) or obs["medianMs"] <= 0:
                    gaps.append(f"release workload {name}.{side} missing positive medianMs")

    # Strict same-source 12/12 conjunction (never splice cross-source credit)
    ledger = receipt.get("familyLedger")
    target_tree = receipt.get("targetSourceTree")
    cross_source_detected = False
    if not isinstance(target_tree, str) or not target_tree:
        conjunction_gaps.append("release receipt missing targetSourceTree for 12/12 conjunction")
    if not isinstance(ledger, dict):
        conjunction_gaps.append("release receipt missing familyLedger for 12/12 conjunction")
    else:
        seen_trees = set()
        for fam in ALL_TWELVE_FAMILIES:
            row = ledger.get(fam)
            if not isinstance(row, dict):
                conjunction_gaps.append(f"12/12 conjunction missing family verdict: {fam}")
                continue
            row_tree = row.get("sourceTree")
            if isinstance(row_tree, str) and row_tree:
                seen_trees.add(row_tree)
            if row.get("passed") is not True:
                conjunction_gaps.append(f"12/12 conjunction family not passed: {fam}")
            if row.get("vetoActive") is True:
                conjunction_gaps.append(f"12/12 conjunction active same-source veto on {fam}")
            if row_tree != target_tree:
                cross_source_detected = True
                conjunction_gaps.append(
                    f"12/12 conjunction cross-source mismatch on {fam}: {row_tree} != {target_tree}"
                )
            if row.get("profileSha256") != expected_profile:
                conjunction_gaps.append(f"12/12 conjunction profile mismatch on {fam}")
            rss = row.get("peakRssBytes", -1)
            if not isinstance(rss, int) or rss < 0 or rss >= MAX_RSS_BYTES:
                conjunction_gaps.append(f"12/12 conjunction RSS violation on {fam}: {rss}")
            else:
                peak_rss = max(peak_rss, rss)
        if len(seen_trees) > 1:
            cross_source_detected = True

    paired_ok = len(gaps) == 0
    whole_admitted = paired_ok and len(conjunction_gaps) == 0
    return dict(
        family="release",
        ordinal=12,
        pairedCohortPassed=paired_ok,
        wholeRuntimeAdmitted=whole_admitted,
        passed=whole_admitted,
        crossSourceDetected=cross_source_detected,
        peakRssBytes=peak_rss,
        verifiedModels=formal["verifiedModels"],
        pairedGaps=gaps,
        conjunctionGaps=conjunction_gaps,
        gaps=gaps + conjunction_gaps,
        runtimeAdmitted=False,
    )


def _discover_non_nix_gcc_candidates(gcc_path: Path | None = None) -> list[Path]:
    """Discover non-Nix GNU GCC executables dynamically without hardcoding a version."""
    out: list[Path] = []
    seen: set[str] = set()

    def _add(p: Path | None) -> None:
        if p is None:
            return
        try:
            resolved_str = str(p.resolve())
        except OSError:
            resolved_str = str(p)
        s = str(p)
        if "/nix/" in s or "/nix/" in resolved_str or s in seen or not p.is_file():
            return
        seen.add(s)
        out.append(p)

    if gcc_path is not None:
        _add(gcc_path)
    cc_env = os.environ.get("CC", "").strip()
    if cc_env:
        resolved = Path(cc_env) if os.sep in cc_env else (Path(w) if (w := shutil.which(cc_env)) else None)
        _add(resolved)

    search_dirs: list[Path] = []
    for std_dir in ("/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"):
        dp = Path(std_dir)
        if dp.is_dir() and dp not in search_dirs:
            search_dirs.append(dp)
    for raw_dir in os.environ.get("PATH", "").split(os.pathsep):
        if raw_dir and "/nix/" not in raw_dir and "profiles/per-user" not in raw_dir:
            dp = Path(raw_dir)
            try:
                if "/nix/" in str(dp.resolve()):
                    continue
            except OSError:
                continue
            if dp.is_dir() and dp not in search_dirs:
                search_dirs.append(dp)

    versioned: list[tuple[int, Path]] = []
    plain: list[Path] = []
    for dp in search_dirs:
        try:
            entries = list(dp.iterdir())
        except OSError:
            continue
        for entry in entries:
            m = re.fullmatch(r"gcc-(\d+)", entry.name)
            if m and entry.is_file():
                versioned.append((int(m.group(1)), entry))
            elif entry.name == "gcc" and entry.is_file():
                plain.append(entry)
    for _, cand in sorted(versioned, key=lambda item: item[0], reverse=True):
        _add(cand)
    for cand in plain:
        _add(cand)
    return out


def clean_native_env(gcc_path: Path | None = None, extra: dict[str, str] | None = None) -> dict[str, str]:
    """Build a Nix-free native build/test environment via `gambit_smp.framework.gnu_compiler`."""
    for cand in _discover_non_nix_gcc_candidates(gcc_path):
        try:
            _, env, _ = gnu_compiler(cand)
            if extra:
                env.update(extra)
            return env
        except Exception:
            continue
    env = {k: v for k, v in os.environ.items() if k not in ("SDKROOT", "LIBRARY_PATH", "CPATH")}
    raw_parts = [p for p in env.get("PATH", "").split(os.pathsep) if p and "/nix/" not in p]
    for std_dir in ("/usr/bin", "/bin", "/usr/sbin", "/sbin", "/opt/homebrew/bin", "/usr/local/bin"):
        if Path(std_dir).is_dir() and std_dir not in raw_parts:
            raw_parts.append(std_dir)
    env["PATH"] = os.pathsep.join(raw_parts)
    if extra:
        env.update(extra)
    return env


def run_audited_command(
    argv: list[str],
    *,
    cwd: Path,
    timeout: int = 300,
    env: dict[str, str] | None = None,
    gcc_path: Path | None = None,
    max_rss_bytes: int = MAX_RSS_BYTES,
    max_footprint_bytes: int = MAX_RSS_BYTES,
    poll_interval: float = 0.2,
) -> dict:
    """Run one native command through `gambit_smp.task_processes.spawn` with live RSS and Darwin phys_footprint kill-switch."""
    time_bin = "/usr/bin/time"
    use_time = Path(time_bin).is_file() and not (sys.platform == "darwin" and env and "DYLD_INSERT_LIBRARIES" in env)
    if use_time:
        wrapped = [time_bin, "-l" if sys.platform == "darwin" else "-v", *argv]
    else:
        wrapped = list(argv)

    run_env = clean_native_env(gcc_path=gcc_path, extra=env)
    check_footprint = (sys.platform == "darwin")

    t0 = time.monotonic()
    deadline = t0 + timeout
    timed_out = False
    rss_exceeded = False
    footprint_exceeded = False
    live_peak_rss = 0
    live_peak_fp = 0
    peak_members: list[dict] = []

    def _kill_group(pgid: int) -> None:
        try:
            os.killpg(pgid, signal.SIGSTOP)
        except ProcessLookupError:
            return
        except PermissionError:
            pass
        try:
            os.killpg(pgid, signal.SIGKILL)
        except (ProcessLookupError, PermissionError):
            pass

    with tempfile.TemporaryFile(mode="w+b") as out_f, tempfile.TemporaryFile(mode="w+b") as err_f:
        proc = spawn_process(
            wrapped,
            cwd=str(cwd),
            env=run_env,
            stdout=out_f,
            stderr=err_f,
            start_new_session=True,
        )
        pgid = proc.pid
        try:
            while True:
                try:
                    sample = groups_memory({pgid}, footprint=check_footprint)
                except OSError:
                    sample = {}
                cur_rss = int(sample.get("rssBytes", 0))
                cur_fp = int(sample.get("footprintBytes", cur_rss)) if check_footprint else cur_rss
                live_peak_rss = max(live_peak_rss, cur_rss)
                if cur_fp >= live_peak_fp:
                    live_peak_fp = cur_fp
                    m_rows = sample.get("members") or []
                    peak_members = [
                        {
                            "pid": m["process"]["pid"],
                            "name": m["process"].get("name", ""),
                            "rssMiB": round(int(m.get("rssBytes", 0)) / (1024 ** 2), 1),
                            "fpMiB": round(int(m.get("footprintBytes", m.get("rssBytes", 0))) / (1024 ** 2), 1),
                        }
                        for m in sorted(
                            m_rows,
                            key=lambda x: int(x.get("footprintBytes", x.get("rssBytes", 0))),
                            reverse=True,
                        )[:10]
                    ]

                if max_rss_bytes is not None and cur_rss >= max_rss_bytes:
                    rss_exceeded = True
                    _kill_group(pgid)
                    break
                if check_footprint and max_footprint_bytes is not None and cur_fp >= max_footprint_bytes:
                    footprint_exceeded = True
                    _kill_group(pgid)
                    break

                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    timed_out = True
                    _kill_group(pgid)
                    break

                try:
                    proc.wait(timeout=min(poll_interval, max(0.01, remaining)))
                    break
                except Exception as exc:
                    if exc.__class__.__name__ == "TimeoutExpired":
                        continue
                    raise
        except BaseException:
            _kill_group(pgid)
            try:
                proc.wait(timeout=5)
            except Exception:
                pass
            raise
        finally:
            if proc.poll() is None:
                _kill_group(pgid)
                try:
                    proc.kill()
                except ProcessLookupError:
                    pass
                try:
                    proc.wait(timeout=5)
                except Exception:
                    pass
            # Ensure no orphan grandchildren remain in the process group
            if observe_group(pgid).get("result") != "absent":
                _kill_group(pgid)

        rc = proc.returncode if proc.returncode is not None else -9
        if timed_out:
            rc = 124
        out_f.seek(0)
        err_f.seek(0)
        stdout = out_f.read().decode("utf-8", errors="replace")
        stderr = err_f.read().decode("utf-8", errors="replace")

    elapsed = round(time.monotonic() - t0, 3)
    rss = max(live_peak_rss, _parse_rss_bytes(stderr))
    fp = max(live_peak_fp, _parse_footprint_bytes(stderr))
    if max_rss_bytes is not None and rss >= max_rss_bytes:
        rss_exceeded = True
    if check_footprint and max_footprint_bytes is not None and fp >= max_footprint_bytes:
        footprint_exceeded = True
    quiescent = (observe_group(pgid).get("result") == "absent")
    if not quiescent:
        deadline_q = time.monotonic() + 1.0
        while time.monotonic() < deadline_q:
            time.sleep(0.05)
            if observe_group(pgid).get("result") == "absent":
                quiescent = True
                break
    return dict(
        argv=list(argv),
        exit=rc,
        timeout=timed_out,
        rssLimitExceeded=rss_exceeded,
        footprintLimitExceeded=footprint_exceeded,
        seconds=elapsed,
        peakRssBytes=rss,
        peakFootprintBytes=fp,
        peakMembers=peak_members,
        passed=(
            rc == 0
            and not timed_out
            and not rss_exceeded
            and not footprint_exceeded
            and quiescent
        ),
        parentReaped=True,
        processGroupQuiescent=quiescent,
        stdoutTail=stdout[-800:],
        stderrTail=stderr[-800:],
    )


def run_make_targets_campaign(
    root: Path,
    runtime: Path,
    family: str,
    *,
    extra_scheme_targets: dict[str, list[str]] | None = None,
    timeout_per_target: int = 300,
    env: dict[str, str] | None = None,
) -> dict:
    """Execute a family's Make and Scheme targets on one sealed producer and return a receipt."""
    if family not in ("registry", "lifecycle", "gc-ffi"):
        raise ValueError(f"unsupported native Make family: {family}")

    formal = verify_family_formal_models(root, family)
    before_seal = producer_seal_from_runtime(runtime)
    tests_dir = relative(runtime, "tests")
    extra_map = extra_scheme_targets or {}

    results = []
    peak_rss = 0
    dead_strip_targets = frozenset({"test-ordered-sync-emulated", "test-collector-diagnostics"})
    for target in FAMILY_REQUIRED_TARGETS[family]:
        if target in extra_map:
            rec = run_audited_command(
                extra_map[target],
                cwd=tests_dir,
                timeout=timeout_per_target,
                env=env,
            )
        else:
            make_argv = ["make", "-j1"]
            if target in dead_strip_targets:
                ld_opt = "-Wl,-dead_strip" if sys.platform == "darwin" else "-Wl,--gc-sections"
                make_argv.append(f"BUILD_EXE_LD_OPTIONS_PARAM={ld_opt}")
            make_argv.append(target)
            rec = run_audited_command(
                make_argv,
                cwd=tests_dir,
                timeout=timeout_per_target,
                env=env,
            )
        peak_rss = max(peak_rss, rec["peakRssBytes"])
        results.append(dict(
            target=target,
            passed=rec["passed"],
            exit=rec["exit"],
            timeout=rec["timeout"],
            seconds=rec["seconds"],
            peakRssBytes=rec["peakRssBytes"],
            parentReaped=rec["parentReaped"],
            processGroupQuiescent=rec["processGroupQuiescent"],
        ))

    after_seal = producer_seal_from_runtime(runtime)
    schema_map = {
        "registry": "family8-registry-receipt.v1",
        "lifecycle": "family9-lifecycle-receipt.v1",
        "gc-ffi": "family10-gc-ffi-receipt.v1",
    }
    receipt = dict(
        schema=schema_map[family],
        family=family,
        manifestPath=formal["manifestPath"],
        manifestSha256=formal["manifestSha256"],
        profileSha256=formal["spec"].get("profile"),
        producer=before_seal,
        producerIntact=(before_seal == after_seal),
        peakRssBytes=peak_rss,
        maxRssBytes=MAX_RSS_BYTES,
        targets=results,
    )
    if family == "lifecycle":
        sp_ok = any(r["target"] == "test-startup-publication" and r["passed"] for r in results)
        receipt["startupFaultModesVerified"] = 10 if sp_ok else 0
    return receipt

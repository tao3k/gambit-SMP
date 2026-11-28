"""Project DEV family obligations through the existing ASCENT evidence rules.

The caller supplies strictly parsed SysML family rows and the digest of that
model. This adapter records declaration linkage only; it does not certify source
refinement, native execution, or the truth of the model's descriptions.
"""

import hashlib
import json
import re
from pathlib import Path

from ascent import Engine


SOURCE_OBLIGATIONS = {
    "production-barrier": {
        "vendor/gambit/lib/_mem/collection-round.inc": (
            "move_continuation(___PSPNC);", "___RESUME(___vms,proc_id).restored=1;",
            "BARRIER();", "free_unmarked_still_objs(___PSPNC);",
            "___RESUME(___vms,proc_id).source_drained=1;", "BARRIER();",
            "retire_drained_source_claims(___ROOT_UNION(___vms),the_msections,rc_epoch)",
        ),
        "vendor/gambit/lib/_mem/heap-sections.inc": (
            "___BOOL retire_drained_source_claims", "round->participants!=round->collection.participant_count",
            "resume->source_half!=source", "!resume->source_drained",
            "retire_section_claims(sections, source, is_minor);",
        ),
        "vendor/gambit/lib/setup.h": ("#define BARRIER() barrier_sync_noop (___PSPNC)",),
        "vendor/gambit/lib/setup.c": (
            "___HIDDEN int barrier_sync_op", "___WORD_LOAD_ACQUIRE(&___ps->sync_id1)",
            "parent->sync_op1 = sop;", "SYNC_SEND_MSG(parent, sync_id1, sid);",
        ),
    },
    "first-generated-allocation": {
        "vendor/gambit/lib/_eval.scm": (
            "(define ##cprc-prc-req1", "(dev-restore-rte", "___dev_restore_at_rte(___ps, ___ARG1)",
            "(##gc-without-exceptions)", "(macro-make-rte rte proc arg1)", "(##check-heap-limit)",
        ),
        "vendor/gambit/include/_gambit/object_access.h.in": (
            "#define ___BEGIN_ALLOC_VECTOR_EXPR(n)(___hp[0] = ___dev_restore_vector_header",
            "#define ___ADD_VECTOR_ELEM_EXPR(i,val)",
            "#define ___END_ALLOC_VECTOR_EXPR(n)(___ALLOC((n)+___VECTOR_BODY)",
        ),
        "vendor/gambit/lib/_mem/heap-sections.inc": (
            "___HIDDEN ___BOOL current_heap_interval_matches", "if (claim->stack_owner!=___ps) return 0;",
            "floor=alloc_stack_limit;", "floor=claim->stack_floor;", "past=floor;",
            "return ___gc_resume_heap_interval_matches(base,past,alloc_heap_start,",
        ),
        "vendor/gambit/lib/_mem/collection-round.inc": (
            "if (!current_heap_interval_matches(___ps,alloc_heap_ptr))",
            "if (___gc_resume_heap_needs_refill(alloc_heap_ptr,alloc_heap_limit,___MSECTION_FUDGE))",
            "if (!current_heap_interval_matches(___ps,alloc_heap_ptr) ||",
            "prepare_mem_pstate (___ps);",
        ),
        "vendor/gambit/lib/_mem/allocation-limits.inc": (
            "if (!current_heap_interval_matches(___ps,old_hp) ||",
            "alloc_heap_ptr = old_hp;",
            "if (!current_heap_interval_matches(___ps,alloc_heap_ptr) ||",
        ),
        "vendor/gambit/lib/collector.h": (
            "___gc_arena_handoff", "m->alloc_heap_ptr_ = a->cursor;",
            "m->alloc_heap_limit_ = a->physical_limit;", "___gc_resume_without_arena",
        ),
        "vendor/gambit/lib/_mem/memory-lifecycle.inc": ("___ps->context->hp = alloc_heap_ptr;",),
        "vendor/gambit/include/_gambit/stack_operations.h.in": (
            "#define ___R_HEAP_EXPR ___hp=___PSHEAP",),
        "vendor/gambit/lib/_thread.c": (
            "#define ___PH_PROC ___H__23__23_tcp_2d_service_2d_register_21_",
            "___SET_STK(1,___ALLOC_CLO(4UL))", "___CHECK_HEAP(3,4096)",
        ),
        "vendor/gambit/lib/_thread.scm": (
            "(define-prim (##thread-join-wait! thread timeout)",
            "(##continuation-denv-set! wait #f)", "dev-restore-join",
            "___dev_restore_at_join(___ps)", "(##gc-without-exceptions)",
            "(##thread-park! wait ##thread-join-register!",
        ),
        "vendor/gambit/gsc/_t-c-2.scm": (
            "(define (targ-heap-reserve-and-check space flo? sn)",
            "(targ-heap-reserve-and-check\n          (apply +",
            '(targ-loc loc (list "ALLOC_CLO"',
        ),
        "vendor/gambit/include/_gambit/module_generation.h.in": (
            "#define ___CLO_FREEVARS", "#define ___ALLOC_CLO(n)",
            "#define ___BEGIN_SETUP_CLO", "#define ___ADD_CLO_ELEM",
        ),
        "vendor/gambit/include/_gambit/object_access.h.in": (
            "#define ___ALLOC(n) ___hp += (n)",
            "___dev_restore_pair_before(___ps,&___hp",
            "___dev_restore_pair_value(___ps,___hp",
            "___dev_restore_pair_after(___ps,___hp)",
            "#define ___BEGIN_ALLOC_SUBTYPED(hd)___hp[0] = hd",
        ),
        "vendor/gambit/tests/smp/gc/restore-collective-probe.c": (
            "s->section = ps->mem.heap_msection_;", "s->half = ps->mem.tospace_offset_;",
            "___gc_resume_heap_interval_matches(s->section->base + s->half,",
            "s->section != ps->mem.heap_msection_", "s->half != ps->mem.tospace_offset_",
            "reason=publication-grant-changed", "___dev_restore_alloc_reload",
            "void ___dev_restore_pair_before", "___dev_restore_pair_value",
            "void ___dev_restore_pair_after",
        ),
    },
    "native-rest-fallback-extent": {
        "vendor/gambit/lib/_kernel.scm": (
            "___COVER_REST_PARAM_HANDLER_NEED_TO_GC;",
            "___rest_root_window(",
            "___rest_caller_chain(",
            "rest_param_list = ___CONS(___POP,rest_param_list);",
            "___COVER_KEYWORD_REST_PARAM_HANDLER_NEED_TO_GC;",
            "___rest_root_window(",
            "___rest_caller_chain(",
            "rest_param_list = ___CONS(___POP,rest_param_list);",
        ),
        "vendor/gambit/lib/mem.h": (
            "#define ___MAX_NB_ARGS", "#define ___MSECTION_FUDGE",
            "#define ___DEFAULT_NORMAL_OVERFLOW_RESERVE",
        ),
    },
    "interpreter-cost": {
        "vendor/gambit/lib/_eval.scm": (
            "(define ##cprc-prc-req1", "(macro-make-rte rte proc arg1)",
        ),
        "vendor/gambit/lib/_eval#.scm": (
            "(##define-macro (macro-make-rte rte . lst)", "`(##vector ,rte ,@lst)",
        ),
        "vendor/gambit/lib/_repl.scm": (
            "(define-prim (##interp-subproblem-continuation? cont)",
            "(##eq? parent ##subproblem-apply2)",
            "(define-prim (##interp-continuation-rte cont)",
            "(##local->value (##continuation-locals cont 'rte))",
        ),
        "vendor/gambit/lib/_mem/configuration.inc": (
            "#define words_movable_objs(ps)", "(2*(ps->mem.words_prev_msections_",
            "#define bytes_occupied(ps)", "words_movable_objs(ps)) * ___WS)",
        ),
        "vendor/gambit/lib/_mem/allocation-statistics.inc": (
            "___F64 ___bytes_allocated", "bytes_allocated_minus_occupied + bytes_occupied(___ps)",
        ),
        "vendor/gambit/tests/unit-tests/06-thread/tfib_stress.scm": (
            "(define (busy-sleep n)", "(define (short-delay) (busy-sleep 6000))", "(go 15 5000)",
        ),
    },
    "break-restore-source": {
        "vendor/gambit/lib/_mem/heap-sections.inc": (
            "___EXP_FUNC(void,___publish_raw_stack_span)", "___gc_copy_acquire(&section->copy_gate);",
            "raw_stack_set_mark(claim->raw_marks,top-base,RAW_STACK_START);",
            "raw_stack_set_mark(claim->raw_marks,brk-base,RAW_STACK_END);", "claim->raw_low=top;",
        ),
        "vendor/gambit/include/_gambit/gvm_operations.h.in": (
            "#define ___THREAD_SAVE", "___ps->context->stack_break = ___fp;",
            "___CONTINUATION_FRAME_FIELD(___wbc) = frame;",
            "#define ___CONTINUATION_CAPTURE", "frame = ___CAST(___SCMOBJ,___fp);",
            "___SET_STK(-___BREAK_FRAME_NEXT,frame)", "___ps->context->stack_break = ___fp;",
        ),
        "vendor/gambit/lib/_mem/allocation-limits.inc": (
            "___WORD *prev_stack_break = ___ps->context->stack_break;",
            "___CAST(___WORD,prev_alloc_stack_ptr)", "___ps->context->stack_break = alloc_stack_ptr;",
            "park_stack_section(___ps,prev_stack_msection,prev_alloc_stack_limit,",
            "fp,prev_stack_break);",
        ),
        "vendor/gambit/lib/_kernel.scm": (
            "ra1 = ___stack_overflow_undo_if_possible (___PSPNC);",
            "ra1 = ___restore_stack_break_frame (___ps, fp, &___fp);",
            "___access_raw_continuation_frame(___ps,frame,___RAW_FRAME_RET",
            "___access_raw_continuation_frame(___ps,frame,___RAW_FRAME_FS",
            "___access_raw_continuation_frame(___ps,frame,___RAW_FRAME_LINK",
            "___access_raw_continuation_frame(___ps,frame,___RAW_FRAME_LIVE",
            "___access_raw_continuation_frame(___ps,frame,___RAW_FRAME_REF",
            "___access_raw_continuation_frame(___ps,frame,___RAW_FRAME_SET",
            "(define-prim (##continuation-next! cont)", "___RESULT = ___continuation_next_stack(___ps,cont);",
        ),
        "vendor/gambit/lib/_mem/continuation-roots.inc": (
            "___HIDDEN ___WORD *raw_stack_span_end", "!=RAW_STACK_START) return 0;",
            "logical_past=raw_stack_span_end(claim,base,top);", "if (!logical_past) return 0;",
            "___HIDDEN ___msection *lock_source_stack_frame", "resolve_source_half(the_msections",
            "___gc_copy_acquire(&section->copy_gate)", "source_claim_is_live(claim)",
            "read_admitted_stack_frame(claim", "___WORD ___restore_stack_break_frame",
            "next=___FP_STK(base,frame.link+1);", "___FP_SET_STK(dest,i,___FP_STK(base,i))",
            "___SCMOBJ ___access_raw_continuation_frame", "section=lock_source_stack_frame(",
            "if (___FIXNUMP(index)) slot=___INT(index);", "if (slot<=0 || slot>frame.fs)",
            "if (slot==frame.link+1 ||", "___FP_SET_STK(base,slot,value)",
            "___WORD ___continuation_next_stack", "section=lock_source_stack_frame(",
            "source_break_agrees(base,known_break,next)", "___FP_SET_STK(base,-___FRAME_STACK_RA,next)",
            "___WORD_STORE_RELAXED(&___CONTINUATION_FRAME_FIELD(cont), successor);", "___gc_copy_release(&section->copy_gate)",
        ),
    },
    "binding-provenance": {
        "vendor/gambit/lib/_mem/global-bindings.inc": (
            "___HIDDEN ___SCMOBJ primitive_value", "return ___PRMCELL(g->prm);",
            "___EXP_FUNC(void,___store_primitive)", "___WORD_STORE_RELEASE(cell,value);",
            "___EXP_FUNC(void,___bind_primitive)", "___WORD_STORE_RELEASE(&g->prm,code);",
        ),
        "vendor/gambit/lib/_kernel.scm": (
            "(define-prim (##global-var-primitive-ref gv))",
            "(define-prim (##global-var-primitive-set! gv val))",
        ),
        "vendor/gambit/include/_gambit/module_generation.h.in": (
            "#define ___DEF_MOD_PRM(i,glo,n)___EXT(___bind_primitive)",
        ),
    },
}


def _verified_receipt(root: Path, row: dict) -> dict:
    path = (root / row["path"]).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError("receipt escapes workspace")
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != row["sha256"]:
        raise ValueError("receipt digest mismatch")
    receipt = json.loads(raw)
    if not receipt.get("restored") or not receipt.get("commands") or not all(
        c.get("parentReaped") is True and c.get("processGroupQuiescent") is True
        and c.get("exit") == 0 and c.get("timeout") is False
        for c in receipt["commands"]
    ):
        raise ValueError("producer or process custody unresolved")
    if row.get("artifacts") != receipt.get("artifacts"):
        raise ValueError("artifact cohort mismatch")
    if row.get("probe") is not None and row["probe"] != receipt.get("probe"):
        raise ValueError("native observation mismatch")
    return receipt


def _validate_cursor_negative(root: Path, packet: dict, profile_sha256: str) -> None:
    """Check the diagnostic cursor perturbation without admitting a runtime guard."""
    fixture = root / "vendor/gambit/tests/smp/gc/restore-first-cursor-negative-probe.h"
    if (packet.get("runtimeAdmitted") is not False or packet.get("acceptedSmp") != 5 or
            hashlib.sha256(fixture.read_bytes()).hexdigest() != packet.get("fixtureSha256") or
            set(packet.get("receipts", {})) != {"first-build", "first-positive", "first-negative"}):
        raise ValueError("cursor diagnostic scope or fixture mismatch")
    receipts = {}
    for name, row in packet["receipts"].items():
        embedded = row["result"]
        verified = _verified_receipt(root, {"path": row["path"], "sha256": row["sha256"],
                                           "artifacts": embedded["artifacts"],
                                           "probe": embedded.get("probe")})
        if verified != embedded or verified.get("profileSha256") != profile_sha256:
            raise ValueError("cursor diagnostic receipt mismatch")
        receipts[name] = verified
    build = receipts["first-build"]
    if not build.get("complete") or any(
        r.get("artifacts") != build.get("artifacts") or r.get("sourceDelta") != build.get("sourceDelta")
        or r.get("runtimeAdmitted") is not False for r in receipts.values()
    ):
        raise ValueError("cursor diagnostic producer mismatch")
    for mode in ("positive", "negative"):
        receipt = receipts["first-" + mode]
        probe = receipt["probe"]
        if (not receipt.get("probeComplete") or probe.get("mode") != mode or
                probe.get("exit") != 0 or probe.get("timeout") is not False or
                "PROCESSORS:2" not in probe.get("stdout", "") or
                "DEV-FIRST-CURSOR-" + mode.upper() not in probe.get("stderr", "") or
                "words=6" not in probe.get("stderr", "") or
                (mode == "positive" and "PROBE-DONE" not in probe["stdout"]) or
                (mode == "negative" and ("rejected-before-write" not in probe["stderr"] or
                                         "PROBE-DONE" in probe["stdout"]))):
            raise ValueError("cursor diagnostic control mismatch")


def validate_dev_native_observations(root: Path) -> dict:
    """Authenticate bounded diagnostic receipts without closing native gates."""
    folder = root / "evidence/research/retained/modern-c/stress-gsi"
    specs = {
        "production-barrier": ("dev-production-barrier-probe.json", "barrier"),
        "first-generated-allocation": ("dev-first-allocation-native-probe.json", "first"),
        "interpreter-cost": ("dev-interpreter-rte-count.json", "rte"),
    }
    outcomes = {}
    for obligation, (filename, prefix) in specs.items():
        packet = json.loads((folder / filename).read_text())
        if packet.get("runtimeAdmitted") is not False or packet.get("acceptedSmp") != 5:
            raise ValueError("diagnostic cannot claim runtime admission")
        receipts = {name: _verified_receipt(root, row) for name, row in packet["runs"].items()}
        products = [x["artifacts"] for x in receipts.values()]
        if not products or any(x != products[0] for x in products):
            raise ValueError("diagnostic attempts do not share a producer")
        profiles = {x["profileSha256"] for x in receipts.values()}
        profile = root / ".cache/tasks/modern-c-frame-contract/cohort/request-product/qualified-existing-profile.json"
        if profiles != {hashlib.sha256(profile.read_bytes()).hexdigest()}:
            raise ValueError("diagnostic profile mismatch")
        if prefix in ("barrier", "first"):
            for mode in ("positive", "negative"):
                receipt = receipts[f"{prefix}-{mode}"]
                probe = receipt["probe"]
                marker = (f"DEV-RESTORE-BARRIER-{mode.upper()}" if prefix == "barrier"
                          else f"DEV-FIRST-CLOSURE-{mode.upper()}")
                if (not receipt.get("probeComplete") or probe["exit"] != 0 or
                        probe["timeout"] or marker not in probe["stderr"]):
                    raise ValueError("missing native diagnostic control")
                if prefix == "barrier" and (
                    f"observed-after={0 if mode == 'positive' else 1}" not in probe["stderr"]
                    or "reader-finished=1" not in probe["stderr"]
                ):
                    raise ValueError("barrier observation is incomplete")
                if prefix == "first" and (
                    "words=6" not in probe["stderr"] or
                    f"stale-rejected={0 if mode == 'positive' else 1}" not in probe["stderr"]
                ):
                    raise ValueError("first-allocation observation is incomplete")
        else:
            diagnostic = receipts["rte-pair"]["rteDiagnostic"]
            if not diagnostic["complete"]:
                raise ValueError("incomplete RTE diagnostic")
            for population in (1, 2):
                zero, work = [next(r for r in diagnostic["rows"] if
                                   r["processors"] == population and r["iterations"] == n)
                              for n in (0, 1000)]
                if (work["normal"] - zero["normal"] != 6002000 or
                        zero["hook"] != 0 or work["hook"] != 0 or
                        zero["exit"] != 0 or work["exit"] != 0 or
                        zero["timeout"] or work["timeout"]):
                    raise ValueError("RTE counter control mismatch")
        outcomes[obligation] = {"packet": str((folder / filename).relative_to(root)),
                                "sha256": hashlib.sha256((folder / filename).read_bytes()).hexdigest(),
                                "scope": packet["scope"], "runtimeAdmitted": False}
    cursor_path = folder / "dev-first-cursor-native-negative.json"
    cursor_packet = json.loads(cursor_path.read_text())
    _validate_cursor_negative(root, cursor_packet, hashlib.sha256(profile.read_bytes()).hexdigest())
    outcomes["first-cursor-negative"] = {
        "packet": str(cursor_path.relative_to(root)),
        "sha256": hashlib.sha256(cursor_path.read_bytes()).hexdigest(),
        "scope": cursor_packet["scope"], "runtimeAdmitted": False,
    }
    for label, filename, marker in (
        ("interpreter-identity-baseline", "dev-interpreter-identity-baseline.json", "INTERPRETED-RTE-IDENTITY-PASS"),
        ("interpreter-interrupt-baseline", "dev-interpreter-interrupt-baseline.json", "INTERPRETED-RTE-INTERRUPT-PASS"),
    ):
        path = folder / filename
        packet = json.loads(path.read_text())
        fixture = (root / packet["fixture"]["path"]).resolve()
        receipt_path = (root / packet["receipt"]["path"]).resolve()
        if not fixture.is_relative_to(root.resolve()) or not receipt_path.is_relative_to(root.resolve()):
            raise ValueError("interpreter identity paths escape workspace")
        receipt_raw = receipt_path.read_bytes()
        if (hashlib.sha256(fixture.read_bytes()).hexdigest() != packet["fixture"]["sha256"] or
                hashlib.sha256(receipt_raw).hexdigest() != packet["receipt"]["sha256"]):
            raise ValueError("interpreter identity baseline digest mismatch")
        receipt = json.loads(receipt_raw)
        if (packet.get("runtimeAdmitted") is not False or packet.get("acceptedSmp") != 5 or
                receipt.get("profileSha256") != hashlib.sha256(profile.read_bytes()).hexdigest() or
                receipt.get("identityFixtureSha256") != packet["fixture"]["sha256"] or
                receipt.get("runtimeAdmitted") is not False or not receipt.get("restored") or
                not receipt.get("identityComplete") or receipt.get("identityRows") != packet["rows"] or
                {row["processors"] for row in packet["rows"]} != {1, 2} or
                any(row["exit"] != 0 or row["timeout"] or marker not in row["stdout"] or
                    f"PROCESSORS:{row['processors']}" not in row["stdout"] for row in packet["rows"]) or
                not receipt.get("commands") or any(
                    c.get("parentReaped") is not True or c.get("processGroupQuiescent") is not True
                    or c.get("exit") != 0 or c.get("timeout") is not False
                    for c in receipt["commands"])):
            raise ValueError("interpreter identity baseline incomplete")
        outcomes[label] = {"packet": str(path.relative_to(root)),
                           "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                           "scope": packet["scope"], "runtimeAdmitted": False}
    binding_packets = []
    for filename, markers in (
        ("dev-interpreter-primitive-cell.json", ("SUB-PRIM:#t", "GT-PRIM:#t", "REBOUND:99", "SAVED-PRIM:#t")),
        ("dev-interpreter-primitive-mutation-negative.json", ("MATCH:#t", "VALUE:99")),
    ):
        path = folder / filename
        raw = path.read_bytes()
        packet = json.loads(raw)
        receipt_path = (root / packet["receipt"]["path"]).resolve()
        if not receipt_path.is_relative_to(root.resolve()):
            raise ValueError("binding receipt escapes workspace")
        receipt_raw = receipt_path.read_bytes()
        if hashlib.sha256(receipt_raw).hexdigest() != packet["receipt"]["sha256"]:
            raise ValueError("binding receipt digest mismatch")
        receipt = json.loads(receipt_raw)
        if (packet.get("acceptedSmp") != 5 or packet.get("runtimeAdmitted") is not False or
                receipt.get("profileSha256") != hashlib.sha256(profile.read_bytes()).hexdigest() or
                not receipt.get("restored") or receipt.get("identityProbe") != packet["rows"] or
                {row["processors"] for row in packet["rows"]} != {1, 2} or
                any(row["exit"] != 0 or row["timeout"] or any(m not in row["stdout"] for m in markers)
                    for row in packet["rows"]) or not receipt.get("commands") or any(
                    c.get("parentReaped") is not True or c.get("processGroupQuiescent") is not True or
                    c.get("exit") != 0 or c.get("timeout") is not False for c in receipt["commands"])):
            raise ValueError("binding diagnostic incomplete")
        binding_packets.append({"path": str(path.relative_to(root)), "sha256": hashlib.sha256(raw).hexdigest()})
    outcomes["binding-provenance"] = {"packets": binding_packets,
                                      "scope": "bounded identity and mutation controls; stable authority remains open",
                                      "runtimeAdmitted": False}
    return outcomes


def source_observations(root: Path) -> dict:
    """Bind ordered textual anchors; never equate them with native refinement."""
    result = {}
    for obligation, files in SOURCE_OBLIGATIONS.items():
        evidence = []
        for name, needles in files.items():
            data = (root / name).read_bytes()
            text = data.decode("utf-8")
            position = 0
            lines = []
            for needle in needles:
                position = text.find(needle, position)
                if position < 0:
                    raise ValueError(f"missing or reordered source anchor: {obligation}: {name}: {needle}")
                lines.append(text.count("\n", 0, position) + 1)
                position += len(needle)
            evidence.append({"path": name, "sha256": hashlib.sha256(data).hexdigest(), "lines": lines})
        result[obligation] = evidence
    return result


def project_source_obligations(root: Path, *, include_native: bool = False) -> dict:
    """Link actual source anchors while keeping refinement and native gates open."""
    observations = source_observations(root)
    bounded_native = validate_dev_native_observations(root) if include_native else {}
    rows = [[f"{key}:{row['path']}", row["path"], row["sha256"],
             str(row["lines"][0])] for key, items in observations.items() for row in items]
    refinements = [[key, "actual-source-composition"] for key in observations]
    native = [[key, "producer-bound-native-witness"] for key in observations]
    engine = Engine()
    try:
        rules = (root / "dev/modeling/ascent/repair-driven-gc-smp.rules.scm").read_text()
        session = engine.open_sources(rules)
        if not session.run(queries=["gap"])["complete"]:
            raise RuntimeError("ASCENT initialization did not complete")
        session.replace({"sourceNeed": rows, "sourceSeen": rows, "routeNeed": [],
                         "routeSeen": [], "symbolNeed": [], "symbolSeen": [],
                         "sourceRefinementNeed": refinements, "sourceRefinementSeen": [],
                         "nativeNeed": native,
                         "nativeSeen": [[key, "scoped-diagnostic-only"] for key in bounded_native]})
        result = session.run(queries=["sourceLinked", "gap", "candidate"])
        if not result["complete"]:
            raise RuntimeError("ASCENT source projection did not complete")
        if source_observations(root) != observations:
            raise RuntimeError("source changed during ASCENT projection")
        if include_native and validate_dev_native_observations(root) != bounded_native:
            raise RuntimeError("native evidence changed during ASCENT projection")
        return {"observations": observations, "nativeObservations": bounded_native,
                "relations": result["relations"],
                "scope": "ordered anchors only; source refinement and native witness open"}
    finally:
        engine.close()


def project_model_symbols(root: Path) -> dict:
    """Bind selected DEV model actions; symbol presence is not refinement."""
    sysml = root / "dev/refactoring/modern-c/models/sysml/smp-dev-composition.sysml"
    sysml_raw = sysml.read_bytes()
    sysml_text = sysml_raw.decode("utf-8")
    needs = {
        "dev/refactoring/modern-c/models/quint/smp_resume_barrier_bridge.qnt":
            ("barrierRelease", "retire", "publish", "reload", "allocate"),
        "dev/refactoring/modern-c/models/quint/smp_interpreter_tail_deopt.qnt":
            ("beginMaterialization", "failMaterialization", "materialize", "requestCapture", "capture", "tailCall",
             "invalidateBinding", "mutatePrimitive", "fastEffect", "slowFallback"),
    }
    symbols = []
    hashes = {}
    for name, actions in needs.items():
        if name not in sysml_text:
            raise ValueError(f"missing SysML model reference: {name}")
        raw = (root / name).read_bytes()
        hashes[name] = hashlib.sha256(raw).hexdigest()
        text = raw.decode("utf-8")
        for action in actions:
            if len(re.findall(r"^\s*action\s+" + re.escape(action) + r"\s*=", text, re.M)) != 1:
                raise ValueError(f"missing or ambiguous model action: {name}:{action}")
            symbols.append([name, action, hashes[name]])
    engine = Engine()
    try:
        rules = (root / "dev/modeling/ascent/repair-driven-gc-smp.rules.scm").read_text()
        session = engine.open_sources(rules)
        if not session.run(queries=["gap"])["complete"]:
            raise RuntimeError("ASCENT initialization did not complete")
        refinements = [["resume-bridge", "source-composition"], ["interpreter-deopt", "source-composition"]]
        session.replace({"sourceNeed": [], "sourceSeen": [], "routeNeed": [], "routeSeen": [],
                         "symbolNeed": symbols, "symbolSeen": symbols,
                         "sourceRefinementNeed": refinements, "sourceRefinementSeen": [],
                         "nativeNeed": [], "nativeSeen": []})
        result = session.run(queries=["symbolLinked", "gap", "candidate"])
        if not result["complete"]:
            raise RuntimeError("ASCENT model projection did not complete")
        if (sysml.read_bytes() != sysml_raw or any(
            hashlib.sha256((root / name).read_bytes()).hexdigest() != digest
            for name, digest in hashes.items())):
            raise RuntimeError("model changed during ASCENT projection")
        return {"sysmlSha256": hashlib.sha256(sysml_raw).hexdigest(), "modelHashes": hashes,
                "relations": result["relations"],
                "scope": "symbol linkage only; source refinement remains open"}
    finally:
        engine.close()


def project_deopt_transitions(root: Path, transitions: list[dict], model_sha256: str) -> dict:
    """Bind parsed deoptimization transitions to QNT actions; keep source gaps."""
    expected = {"classify": "tailCall", "compact": "collect", "capture-request": "requestCapture",
                "materialize-begin": "beginMaterialization", "materialize-commit": "materialize",
                "capture-commit": "capture", "binding-guard": "fastEffect",
                "later-poll-observation": "inspectLaterPoll"}
    if len(transitions) != len(expected) or {r["id"]: r["qntAction"] for r in transitions} != expected:
        raise ValueError("deoptimization transition mapping mismatch")
    model_path = "dev/refactoring/modern-c/models/sysml/smp-interpreter-tail-deopt.sysml"
    qnt_path = "dev/refactoring/modern-c/models/quint/smp_interpreter_tail_deopt.qnt"
    model_raw = (root / model_path).read_bytes()
    qnt_raw = (root / qnt_path).read_bytes()
    if hashlib.sha256(model_raw).hexdigest() != model_sha256 or qnt_path not in model_raw.decode():
        raise ValueError("deoptimization model digest or reference mismatch")
    qnt_hash = hashlib.sha256(qnt_raw).hexdigest()
    qnt_text = qnt_raw.decode()
    symbols = []
    for action in expected.values():
        if len(re.findall(r"^\s*action\s+" + re.escape(action) + r"\s*=", qnt_text, re.M)) != 1:
            raise ValueError("deoptimization QNT action missing or ambiguous")
        symbols.append([qnt_path, action, qnt_hash])
    engine = Engine()
    try:
        rules = (root / "dev/modeling/ascent/repair-driven-gc-smp.rules.scm").read_text()
        session = engine.open_sources(rules)
        if not session.run(queries=["gap"])["complete"]:
            raise RuntimeError("ASCENT initialization did not complete")
        source = [["deopt-sysml", model_path, model_sha256, "GambitSmpInterpreterTailDeopt"]]
        session.replace({"sourceNeed": source, "sourceSeen": source, "routeNeed": [], "routeSeen": [],
                         "symbolNeed": symbols, "symbolSeen": symbols,
                         "sourceRefinementNeed": [[key, "source-composition"] for key in expected],
                         "sourceRefinementSeen": [], "nativeNeed": [], "nativeSeen": []})
        result = session.run(queries=["sourceLinked", "symbolLinked", "gap", "candidate"])
        if not result["complete"]:
            raise RuntimeError("ASCENT deoptimization projection did not complete")
        if (root / model_path).read_bytes() != model_raw or (root / qnt_path).read_bytes() != qnt_raw:
            raise RuntimeError("deoptimization model changed during projection")
        return {"modelSha256": model_sha256, "qntSha256": qnt_hash,
                "relations": result["relations"],
                "scope": "declared transition and action linkage only; source and native refinement open"}
    finally:
        engine.close()


def project_open_families(root: Path, families: list[dict], model_sha256: str) -> dict:
    """Return open obligations for the seven declared DEV family rows."""
    expected = {
        6: "stress-gsi", 7: "stress-gsc", 8: "registry", 9: "lifecycle",
        10: "gc-ffi", 11: "gerbil", 12: "release",
    }
    actual = {int(row["id"]): row["name"] for row in families}
    if len(families) != len(expected) or actual != expected:
        raise ValueError("missing, duplicate, or unexpected family declaration")
    allowed = {"round", "cursor", "request", "interpreter", "lifetime", "product"}
    for row in families:
        dependencies = row["needs"].split(",")
        if (len(dependencies) != len(set(dependencies)) or
                not set(dependencies) <= allowed or "product" not in dependencies):
            raise ValueError("invalid or incomplete family owner declaration")
    model_path = "dev/refactoring/modern-c/models/sysml/smp-dev-composition.sysml"
    if hashlib.sha256((root / model_path).read_bytes()).hexdigest() != model_sha256:
        raise ValueError("SysML model digest changed")
    return _family_relations(root, model_path, model_sha256, expected.values(), expected.values())


def _family_relations(root, model_path, model_sha256, names, open_names, *, source_sites=()):
    source = [[name, model_path, model_sha256, name] for name in names]
    source.extend(source_sites)
    source_refinement = [[name, "actual-source-composition"] for name in open_names]
    native = [[name, "same-producer-complete-original"] for name in open_names]
    rules = (root / "dev/modeling/ascent/repair-driven-gc-smp.rules.scm").read_text()
    engine = Engine()
    try:
        session = engine.open_sources(rules)
        if not session.run(queries=["gap"])["complete"]:
            raise RuntimeError("ASCENT initialization did not complete")
        session.replace({"sourceNeed": source, "sourceSeen": source,
                         "routeNeed": [], "routeSeen": [], "symbolNeed": [],
                         "symbolSeen": [], "sourceRefinementNeed": source_refinement,
                         "sourceRefinementSeen": [], "nativeNeed": native,
                         "nativeSeen": []})
        result = session.run(queries=["sourceLinked", "gap", "candidate"])
        if not result["complete"]:
            raise RuntimeError("ASCENT projection did not complete")
        return result["relations"]
    finally:
        engine.close()


def project_smp_checklist(connection, root: Path) -> dict:
    """Join strict SDK declarations to the independent, digest-checked DEV ledger."""
    from gambit_smp.suite_coverage import accepted_smp_status

    recipe = root / "evidence/fixtures/dev-publication-sysml-families/families.recipe.json"
    paths = json.loads(recipe.read_text())["steps"][0]["arguments"]["models"]
    documents = [(path, (root / path).read_text()) for path in paths]
    catalog = connection.parse_sources(documents, strict=True, strict_conformance=True)
    catalog.raise_for_errors()
    namespace = "GambitSmpDevComposition"
    model_path = "dev/refactoring/modern-c/models/sysml/smp-dev-composition.sysml"
    hashes = {path: hashlib.sha256(source.encode()).hexdigest() for path, source in documents}

    def fields(part):
        return {a.name: catalog.eval(f"{part.id}.{a.name}") for a in part.attributes()}

    parts = list(catalog.find(namespace).parts())
    rows = sorted((fields(p) for p in parts if
                   p.type_facts.resolved_id == f"{namespace}::Family"), key=lambda row: row["id"])
    history = [fields(p) for p in parts if
               p.type_facts.resolved_id == f"{namespace}::HistoricalTrack"]
    ledger = accepted_smp_status(root)
    names = [row["name"] for row in rows]
    authority = [catalog.eval(f"GambitModernCDeliveryPlan::a{i}.id") for i in range(1, 13)]
    if ([row["id"] for row in rows] != list(range(1, 13))
            or names != authority or len(set(names)) != 12
            or names[:ledger["passed"]] != ledger["closed"]):
        raise ValueError("DEV model and independent acceptance families disagree")

    owners = {fields(p)["id"] for p in parts if
              p.type_facts.resolved_id == f"{namespace}::Responsibility"}
    if {row["id"] for row in history} != {"patch-8-of-12", "patch-repair-9-through-12"}:
        raise ValueError("missing or unexpected historical track")
    for row in history:
        if row["credit"] is not False:
            raise ValueError("historical repair cannot confer DEV credit")
        row["sha256"] = hashlib.sha256((root / row["reference"]).read_bytes()).hexdigest()
    graph = {}
    for row in rows:
        dependencies = row["prerequisites"].split(",") if row["prerequisites"] else []
        responsible = row["needs"].split(",")
        if (len(set(dependencies)) != len(dependencies)
                or not set(dependencies) <= set(names)
                or row["name"] in dependencies
                or not set(responsible) <= owners or "product" not in responsible):
            raise ValueError(f"invalid dependency or owner for {row['name']}")
        graph[row["name"]] = set(dependencies)
        row["workloadSha256"] = hashlib.sha256((root / row["workloadRef"]).read_bytes()).hexdigest()
        model = row["quintArtifact"]
        checks = row["quintChecks"].split(",") if row["quintChecks"] else []
        if bool(model) != bool(checks):
            raise ValueError(f"incomplete Quint binding for {row['name']}")
        if model:
            raw = (root / model).read_bytes()
            declared = set(re.findall(r"^\s*(?:val|run|action)\s+(\w+)", raw.decode(), re.M))
            if not set(checks) <= declared:
                raise ValueError(f"missing Quint symbol for {row['name']}")
            row["quintSha256"] = hashlib.sha256(raw).hexdigest()
        row["acceptedReceipt"] = ledger["receipts"].get(row["name"])

    resolved = set()
    while graph:
        ready = {name for name, needs in graph.items() if needs <= resolved}
        if not ready:
            raise ValueError("cyclic SMP family prerequisites")
        resolved.update(ready)
        for name in ready:
            del graph[name]

    audit_path = catalog.eval(f"{namespace}::stressReceiptAudit")
    audit_raw = (root / audit_path).read_bytes()
    audit = json.loads(audit_raw)
    for name, digest in audit["diagnosticSources"].items():
        if Path(name).name != name or hashlib.sha256(
                (root / Path(audit_path).parent / name).read_bytes()).hexdigest() != digest:
            raise ValueError("TFIB diagnostic source digest mismatch")
    if (audit["runtimeAdmitted"] is not False or audit["originalCampaign"]["wholeFamilyComplete"]
            or any(row["sessionCompleted"] or row["completion"] is not None
                   for row in audit["grokAttempts"])):
        raise ValueError("TFIB audit requires separate review of any new completion")
    rows[5]["diagnosticReceipt"] = {
        "path": audit_path, "sha256": hashlib.sha256(audit_raw).hexdigest(),
        "campaignClassification": audit["campaignClassification"],
        "independentReview": audit["independentReview"],
    }

    handoffs = [fields(p) for p in parts if
                p.type_facts.resolved_id == f"{namespace}::AuthorityHandoff"]
    delivery = [fields(p) for p in parts if
                p.type_facts.resolved_id == f"{namespace}::FamilyHandoff"]
    authority_ids = {item["id"] for item in handoffs}
    if (len(handoffs) != 4 or authority_ids != {"execution", "roots", "worker", "request"}
            or sorted(item["ordinal"] for item in delivery) != list(range(6, 13))):
        raise ValueError("incomplete or duplicate SMP handoff declarations")

    composition_path = catalog.eval(f"{namespace}::modelPath")
    composition = (root / composition_path).read_bytes()
    composition_digest = hashlib.sha256(composition).hexdigest()
    declared_checks = set(re.findall(r"^\s*run\s+(\w+)", composition.decode(), re.M))
    receipt_path = catalog.eval(f"{namespace}::compositionCheckReceipt")
    receipt_raw = (root / receipt_path).read_bytes()
    composition_receipt = json.loads(receipt_raw)
    if (composition_receipt["modelSha256"] != composition_digest
            or set(composition_receipt["passedHistories"]) != declared_checks
            or composition_receipt["runtimeAdmitted"] is not False):
        raise ValueError("stale or incomplete Quint composition receipt")

    source_sites = []
    for item in handoffs:
        checks = item["quintChecks"].split(",")
        if not set(checks) <= declared_checks:
            raise ValueError(f"missing joint Quint check for {item['id']}")
        for check in checks:
            source_sites.append([f"quint:{check}", composition_path, composition_digest, check])
        path = (root / item["source"]).resolve()
        if not path.is_relative_to(root.resolve()):
            raise ValueError("SMP source anchor escapes workspace")
        raw = path.read_bytes()
        if item["anchor"].encode() not in raw:
            raise ValueError(f"missing SMP source anchor for {item['id']}")
        item["sourceSha256"] = hashlib.sha256(raw).hexdigest()
        source_sites.append([f"handoff:{item['id']}", item["source"],
                             item["sourceSha256"], item["anchor"]])
    for item in delivery:
        required = item["handoffs"].split(",")
        if len(required) != len(set(required)) or not set(required) <= authority_ids:
            raise ValueError(f"invalid handoff dependency for family {item['ordinal']}")
        if not all(item[key] for key in ("mechanism", "retirement", "falsifier")):
            raise ValueError(f"missing handoff conditions for family {item['ordinal']}")
        rows[item["ordinal"] - 1]["implementation"] = item

    cuts = [fields(p) for p in parts if
            p.type_facts.resolved_id == f"{namespace}::SchemeCut"]
    if sorted(cut["id"] for cut in cuts) != ["capture", "exit", "park", "service", "thunk", "waiter"]:
        raise ValueError("incomplete Scheme source refinement cuts")
    source_inputs = {"schemeAnchor": "vendor/gambit/lib/_thread.scm",
                     "generatedAnchor": "vendor/gambit/lib/_thread.c"}
    for field, path in source_inputs.items():
        raw = (root / path).read_bytes()
        digest = hashlib.sha256(raw).hexdigest()
        for cut in cuts:
            if cut["history"] not in declared_checks or not cut["gap"]:
                raise ValueError(f"missing history or explicit gap for {cut['id']}")
            anchor = cut[field]
            if anchor.encode() not in raw:
                raise ValueError(f"missing Scheme refinement anchor {anchor}")
            source_sites.append([f"scheme-cut:{cut['id']}:{field}", path, digest, anchor])
            cut[field + "Source"] = {"path": path, "sha256": digest}

    frame_grants = [fields(p) for p in parts if
                    p.type_facts.resolved_id == f"{namespace}::FrameGrantCut"]
    if len({cut["id"] for cut in frame_grants}) != len(frame_grants) or not frame_grants:
        raise ValueError("missing or duplicate frame grant cuts")
    for cut in frame_grants:
        for field, needle in (("source", cut["anchor"]), ("model", "run " + cut["history"])):
            path = (root / cut[field]).resolve()
            if not path.is_relative_to(root.resolve()):
                raise ValueError("frame grant input escapes workspace")
            raw = path.read_bytes()
            if needle.encode() not in raw:
                raise ValueError(f"missing frame grant {field} landmark for {cut['id']}")
            digest = hashlib.sha256(raw).hexdigest()
            cut[field + "Sha256"] = digest
            source_sites.append([f"frame-grant:{cut['id']}:{field}", cut[field], digest, needle])

    suffix_path = catalog.eval(f"{namespace}::rawSuffixCheckReceipt")
    suffix_raw = (root / suffix_path).read_bytes()
    suffix_receipt = json.loads(suffix_raw)
    joint_cuts = [cut for cut in frame_grants if cut["id"].startswith("joint-")]
    if not joint_cuts or suffix_receipt["runtimeAdmitted"] is not False or any(
            cut["model"] != suffix_receipt["model"]
            or cut["modelSha256"] != suffix_receipt["modelSha256"]
            or cut["history"] not in suffix_receipt["jointHistories"] for cut in joint_cuts):
        raise ValueError("stale or incomplete raw suffix model receipt")

    open_names = [row["name"] for row in rows if row["acceptedReceipt"] is None]
    relations = _family_relations(root, model_path, hashes[model_path], names, open_names,
                                  source_sites=source_sites)
    linked = set(names) | {item[0] for item in source_sites}
    if ({r[0] for r in relations["sourceLinked"]} != linked
            or {r[0] for r in relations["gap"]} != set(open_names)):
        raise RuntimeError("ASCENT projection does not match the declared checklist")
    return {"modelHash": catalog.hash, "modelInputs": hashes, "ledger": ledger,
            "families": rows, "authorityHandoffs": handoffs, "schemeCuts": cuts, "frameGrantCuts": frame_grants,
            "rawSuffixCheck": {"path": suffix_path,
                               "sha256": hashlib.sha256(suffix_raw).hexdigest()},
            "compositionCheck": {"path": receipt_path,
                                 "sha256": hashlib.sha256(receipt_raw).hexdigest(),
                                 "model": composition_path,
                                 "modelSha256": composition_digest},
            "historicalTracks": history, "relations": relations,
            "runtimeAdmitted": False, "progressDelta": 0}


def render_smp_checklist_rows(packet: dict) -> str:
    """Render the query packet as stable, individually linkable Org entries."""
    def link(path, label):
        return f"[[file:../../../{path}][{label}]]"

    lines = []
    for row in packet["families"]:
        name = row["name"]
        receipt = row["acceptedReceipt"]
        state = "ACCEPTED (ledger source period)" if receipt else "OPEN"
        lines.extend([
            f"** {row['id']}. {name} :{'accepted' if receipt else 'open'}:",
            ":PROPERTIES:", f":CUSTOM_ID: dev-smp-{name}", f":FAMILY: {row['id']}",
            f":STATE: {state}", f":OWNERS: {row['needs']}",
            f":DEPENDS_ON: {row['prerequisites'] or 'none'}", ":END:", "",
            f"- Workload :: {row['boundary']} {link(row['workloadRef'], 'Inventory or owning design')}.",
            f"- QNT :: {row['quintDuty']}",
            f"- Required receipt :: {row['receiptRule']}.",
        ])
        if row["quintArtifact"]:
            lines[-2] += " " + link(row["quintArtifact"], row["quintChecks"])
        if diagnostic := row.get("diagnosticReceipt"):
            lines.append(f"- Diagnostic receipt :: {link(diagnostic['path'], 'Grok and native audit')} "
                         f"({diagnostic['independentReview']}, {diagnostic['campaignClassification']}).")
        if receipt:
            lines.append(f"- Accepted receipt :: {link(receipt['path'], 'Exact-period receipt')}.")
        lines.append("")
    return "\n".join(lines)



def render_smp_handoff(packet: dict) -> str:
    """Project the proposed C handoffs and family falsifiers into Org."""
    lines = ["** Authority handoff and retirement contract", ""]
    for item in packet["authorityHandoffs"]:
        lines.extend([
            f"*** {item['transfer']}", "",
            f"- Identity :: {item['identity']}",
            f"- Admission :: {item['admission']}",
            f"- Publication and acquire :: {item['commit']}",
            f"- Failure custody :: {item['recovery']}",
            f"- Retirement target :: {item['retirement']}",
            f"- Joint Quint checks :: {item['quintChecks']}",
            f"- Source landmark :: [[file:../../../{item['source']}][{item['anchor']}]]",
            "",
        ])
    lines.extend([
        "** Original-load retirement and falsification matrix", "",
        "#+NAME: smp-refactory-falsifiers",
        "| Family | Required handoffs | Mechanism | Retirement gate | Original-load falsifier |",
        "|-",
    ])
    for row in packet["families"]:
        if item := row.get("implementation"):
            family = f"[[#dev-smp-{row['name']}][{row['id']} {row['name']}]]"
            lines.append(f"| {family} | {item['handoffs']} | {item['mechanism']} | "
                         f"{item['retirement']} | {item['falsifier']} |")
    return "\n".join(lines)



def render_smp_scheme_cuts(packet: dict) -> str:
    """Render source landmarks separately from open refinement obligations."""
    lines = ["** Scheme-to-generated-C refinement", "",
             "| Cut | Scheme and generated entry | Root projection | Observable outcome | Original-load falsifier | Related Quint history | Open proof obligation |",
             "|-"]
    for cut in packet["schemeCuts"]:
        lines.append(
            f"| {cut['id']} | ={cut['schemeAnchor']}= → ={cut['generatedAnchor']}= | "
            f"{cut['rootProjection']} | {cut['outcome']} | {cut['falsifier']} | "
            f"={cut['history']}= | {cut['gap']} |")
    return "\n".join(lines)



def render_smp_frame_grants(packet: dict) -> str:
    lines = ["** Unified frame authorization coverage", "",
             "| Cut | Source | Contract | Existing Quint | Falsifier and open scope |", "|-"]
    for cut in packet["frameGrantCuts"]:
        source = f"[[file:../../../{cut['source']}][{cut['anchor']}]]"
        model = f"[[file:../../../{cut['model']}][{cut['history']}]]"
        lines.append(f"| {cut['id']} | {source} | {cut['contract']} | {model} | {cut['gap']} |")
    return "\n".join(lines)

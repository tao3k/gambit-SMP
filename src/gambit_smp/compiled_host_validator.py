"""Independent Compiled-Host Translation Validator for Family 7 (stress-gsc).

Implements per-instance validation of gsc/_t-c-2.scm emitted C hosts and their
bound dynamic .o1 artifacts without trusting compiler internals:
  - Necula (PLDI 2000): basic-block write-group demand dominance and commit.
  - Diwan, Moss, Hudson (PLDI 1992): ___RETI / ___RETN / ___IFD descriptor decoding
    and label-table entry bijection.
  - Feeley (FPCA 1993): intra-procedure CFG cycle detection proving every loop
    back-edge (including (declare (not safe) (fixnum))) retains a live ___POLL
    safepoint while zero-alloc tight loops emit zero spurious demand calls.
  - Reynolds (2002) & RSS Guard: ___LBLCOUNT < 6000 ceiling (8 GiB GCC RSS cap).
"""

from collections import defaultdict
import hashlib
from pathlib import Path
import re

MAX_LABEL_COUNT_DEFAULT = 6000
FRAME_ALIGN_DEFAULT = 4
NB_GVM_REGS_DEFAULT = 5

# LP64 no-handle word sizes matching vendor/gambit/include/_gambit/object_access.h.in
PAIR_WORDS = 3           # ___PAIR_BODY(1) + ___PAIR_SIZE(2)
VECTOR_HEADER_WORDS = 1  # ___VECTOR_BODY(1)
CLO_HEADER_WORDS = 2     # header + entry label word
FLONUM_WORDS = 2         # header + f64 payload

_LBLCOUNT_RE = re.compile(r"^\s*#define\s+___LBLCOUNT\s+(\d+)\b", re.MULTILINE)
_PROC_NAME_RE = re.compile(r"^\s*#define\s+___PH_PROC\s+(\S+)")
_SLBL_RE = re.compile(r"^___DEF_SLBL\((\d+),([^,)]+)\)")
_GLBL_RE = re.compile(r"^___DEF_GLBL\(([^,)]+)\)")
_GOTO_RE = re.compile(r"___GOTO\(([^,)]+)\)")
_DEMAND_ENTER_RE = re.compile(
    r"if\s*\(\s*!\s*___group_demand_enter\s*\(\s*___ps\s*,\s*&___hp\s*,\s*&___fp\s*,"
    r"\s*(\d+)\s*,\s*(\d+)\s*,\s*___LBL\((\d+)\)\s*,\s*&___demand_attempt\s*\)\s*\)"
    r"\s*\{\s*___ps->temp1\s*=\s*___LBL\((\d+)\)\s*;"
    r"\s*___JUMPEXTPRM\s*\(\s*___NOTHING\s*,\s*___ps->handler_stack_limit\s*\)\s*;\s*\}"
)
_DEMAND_COMMIT_RE = re.compile(
    r"___group_demand_commit\s*\(\s*___ps\s*,\s*___LBL\((\d+)\)\s*,\s*___demand_attempt\s*\)"
)
_IFD_RE = re.compile(
    r"___(IFD|OFD)\s*\(\s*(___RETI|___RETN)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(0x[0-9a-fA-F]+|\d+)[uUlL]*\s*\)"
)
_LBL_RET_AT_RE = re.compile(
    r"___DEF_LBL_RET(?:_AT)?\s*\(\s*([^,]+)\s*,\s*(___(?:IFD|OFD)\([^)]+\))\s*(?:,\s*(\d+))?\s*\)"
)
_LBL_INTRO_RE = re.compile(
    r"___DEF_LBL_INTRO\s*\(\s*([^,]+)\s*,[^,]+,[^,]+,\s*(\d+)\s*,"
)
_CHECK_RE = re.compile(r"^___(POLL|CHECK_HEAP|CHECK_HEAP_FLO)\((\d+)(?:,|\))")
_TERMINAL_RE = re.compile(
    r"^___(?:GOTO|JUMPGLOSAFE|JUMPGLONOTSAFE|JUMPRET|JUMPPRM|JUMPGENSAFE|"
    r"JUMPGENNOTSAFE|JUMPEXTPRM|JUMPEXT|JUMPINT|JUMP_)\b"
)
_SAFE_JUMP_RE = re.compile(r"\b___(?:JUMPGLOSAFE|JUMPGENSAFE|POLL|CHECK_HEAP|CHECK_HEAP_FLO)\(")
_ADJFP_RE = re.compile(r"___ADJFP\(\s*(-?\d+)\s*\)")
_SET_STK_RE = re.compile(r"___SET_STK\(\s*(-?\d+)\s*,")
_ALLOC_CLO_RE = re.compile(r"___ALLOC_CLO\(\s*(\d+)[uUlL]*\s*\)")
_BEGIN_VEC_RE = re.compile(r"___BEGIN_ALLOC_VECTOR\(\s*(\d+)[uUlL]*\s*\)")
_BEGIN_PAIR_RE = re.compile(r"___BEGIN_ALLOC_PAIR\s*\(")
_CONS_RE = re.compile(r"___CONS\s*\(")
_F64BOX_RE = re.compile(r"___F64BOX\s*\(")
_RAW_ALLOC_RE = re.compile(r"___ALLOC\(\s*(\d+)[uUlL]*\s*\)")


def _round_up(value: int, align: int) -> int:
    if align <= 1:
        return value
    rem = value % align
    return value if rem == 0 else value + (align - rem)


def _decode_and_check_descriptors(
    text: str,
    *,
    frame_align: int = FRAME_ALIGN_DEFAULT,
    nb_gvm_regs: int = NB_GVM_REGS_DEFAULT,
) -> tuple[list[dict], list[dict]]:
    """Independently decode every ___IFD/___OFD descriptor in the emitted label tables."""
    descriptors = []
    violations = []
    for line_no, line in enumerate(text.splitlines(), 1):
        for match in _IFD_RE.finditer(line):
            form, kind, fs_s, link_s, gcmap_s = match.groups()
            fs = int(fs_s)
            link = int(link_s)
            gcmap = int(gcmap_s, 0)
            row = dict(line=line_no, form=form, kind=kind, fs=fs, link=link, gcmap=gcmap)
            descriptors.append(row)
            if form == "IFD" and fs >= 32:
                violations.append(dict(
                    code="invalid-frame-descriptor",
                    procedure="<label-table>",
                    line=line_no,
                    detail=f"IFD fs={fs} exceeds 5-bit ___IFD_FS_WIDTH",
                ))
                continue
            if kind == "___RETN":
                if fs <= 0:
                    violations.append(dict(
                        code="invalid-frame-descriptor",
                        procedure="<label-table>",
                        line=line_no,
                        detail=f"RETN descriptor has non-positive fs={fs}",
                    ))
                    continue
                if not (0 <= link < fs):
                    violations.append(dict(
                        code="invalid-frame-descriptor",
                        procedure="<label-table>",
                        line=line_no,
                        detail=f"RETN link={link} outside [0, {fs - 1}]",
                    ))
                if gcmap >= (1 << fs):
                    violations.append(dict(
                        code="invalid-frame-descriptor",
                        procedure="<label-table>",
                        line=line_no,
                        detail=f"RETN gcmap=0x{gcmap:x} sets bits beyond fs={fs}",
                    ))
                if not (gcmap & (1 << link)):
                    violations.append(dict(
                        code="invalid-frame-descriptor",
                        procedure="<label-table>",
                        line=line_no,
                        detail=f"RETN link slot {link} missing from gcmap=0x{gcmap:x}",
                    ))
            else:
                # ___RETI expands caller fs to frame_align plus saved GVM regs + RA.
                expanded_fs = _round_up(fs, frame_align) + nb_gvm_regs + 1
                if not (0 <= link < expanded_fs):
                    violations.append(dict(
                        code="invalid-frame-descriptor",
                        procedure="<label-table>",
                        line=line_no,
                        detail=f"RETI link={link} outside [0, {expanded_fs - 1}] (fs={fs})",
                    ))
                if gcmap >= (1 << expanded_fs):
                    violations.append(dict(
                        code="invalid-frame-descriptor",
                        procedure="<label-table>",
                        line=line_no,
                        detail=f"RETI gcmap=0x{gcmap:x} sets bits beyond expanded_fs={expanded_fs} (fs={fs})",
                    ))
                if not (gcmap & (1 << link)):
                    violations.append(dict(
                        code="invalid-frame-descriptor",
                        procedure="<label-table>",
                        line=line_no,
                        detail=f"RETI link slot {link} missing from gcmap=0x{gcmap:x}",
                    ))
    return descriptors, violations


def _extract_procedures(text: str) -> list[dict]:
    """Extract per-procedure C host bodies between ___BEGIN_P_COD and ___END_P_COD,
    including preceding #define ___PR_ALL / ___PD_ALL host reload declarations."""
    procedures = []
    name = None
    has_pr_heap_reload = False
    in_body = False
    body_lines = []
    start_line = 0
    for line_no, raw in enumerate(text.splitlines(), 1):
        m_name = _PROC_NAME_RE.match(raw)
        if m_name:
            name = m_name.group(1)
            has_pr_heap_reload = False
            continue
        stripped = raw.strip()
        if not in_body and stripped.startswith("#define ___PR_ALL "):
            if "___R_HEAP" in stripped or "___R_ALL" in stripped:
                has_pr_heap_reload = True
            continue
        if stripped == "___BEGIN_P_COD":
            in_body = True
            body_lines = []
            start_line = line_no
            continue
        if stripped == "___END_P_COD":
            if in_body:
                procedures.append(dict(
                    name=name or f"<anon@{start_line}>",
                    startLine=start_line,
                    endLine=line_no,
                    hasPrHeapReload=has_pr_heap_reload,
                    lines=body_lines,
                ))
                in_body = False
                body_lines = []
                has_pr_heap_reload = False
            continue
        if in_body:
            body_lines.append((line_no, stripped))
    return procedures


def _line_heap_words(stmt: str) -> int:
    """Lower-bound heap words allocated directly by one emitted statement."""
    words = 0
    for m in _ALLOC_CLO_RE.finditer(stmt):
        words += CLO_HEADER_WORDS + int(m.group(1))
    for m in _BEGIN_VEC_RE.finditer(stmt):
        words += VECTOR_HEADER_WORDS + int(m.group(1))
    words += len(_BEGIN_PAIR_RE.findall(stmt)) * PAIR_WORDS
    words += len(_CONS_RE.findall(stmt)) * PAIR_WORDS
    words += len(_F64BOX_RE.findall(stmt)) * FLONUM_WORDS
    # Count standalone ___ALLOC(n) only when not part of BEGIN_ALLOC_* expansion.
    if words == 0:
        for m in _RAW_ALLOC_RE.finditer(stmt):
            words += int(m.group(1))
    return words


def _find_sccs_with_cycles(node_count: int, adj: dict[int, set[int]]) -> list[list[int]]:
    """Tarjan's SCC algorithm returning only SCCs that contain at least one cycle."""
    index = 0
    stack = []
    on_stack = set()
    indices = {}
    lowlink = {}
    cyclic = []

    def strongconnect(v: int) -> None:
        nonlocal index
        indices[v] = index
        lowlink[v] = index
        index += 1
        stack.append(v)
        on_stack.add(v)
        for w in adj.get(v, ()):
            if w not in indices:
                strongconnect(w)
                lowlink[v] = min(lowlink[v], lowlink[w])
            elif w in on_stack:
                lowlink[v] = min(lowlink[v], indices[w])
        if lowlink[v] == indices[v]:
            comp = []
            while True:
                w = stack.pop()
                on_stack.remove(w)
                comp.append(w)
                if w == v:
                    break
            if len(comp) > 1 or v in adj.get(v, ()):
                cyclic.append(sorted(comp))

    for node in range(node_count):
        if node not in indices:
            strongconnect(node)
    return cyclic


def _validate_procedure(proc: dict) -> dict:
    """Run Dominance, Reload, Label-Bijection, and Back-Edge Poll checks on one procedure."""
    name = proc["name"]
    lines = proc["lines"]
    violations = []

    need_heap = bool(proc.get("hasPrHeapReload")) or any(stmt == "___NEED_HEAP" for _, stmt in lines)
    blocks = []  # list of dicts: {label, slot, line, stmts: [(line_no, stmt)]}
    current = dict(label="<entry>", slot=None, line=proc["startLine"], stmts=[])
    blocks.append(current)
    label_to_block = {}
    slot_to_block = {}

    for line_no, stmt in lines:
        if not stmt or stmt.startswith("#"):
            continue
        m_slbl = _SLBL_RE.match(stmt)
        if m_slbl:
            slot = int(m_slbl.group(1))
            lbl = m_slbl.group(2)
            current = dict(label=lbl, slot=slot, line=line_no, stmts=[])
            idx = len(blocks)
            blocks.append(current)
            label_to_block[lbl] = idx
            slot_to_block[slot] = idx
            continue
        m_glbl = _GLBL_RE.match(stmt)
        if m_glbl:
            lbl = m_glbl.group(1)
            current = dict(label=lbl, slot=None, line=line_no, stmts=[])
            idx = len(blocks)
            blocks.append(current)
            label_to_block[lbl] = idx
            continue
        current["stmts"].append((line_no, stmt))

    # Build CFG edges & check safepoint label bindings + write-group dominance.
    adj = defaultdict(set)
    write_groups = 0
    procedure_allocates = False
    demand_in_blocks = set()

    for idx, block in enumerate(blocks):
        stmts = block["stmts"]
        active_group = None  # dict(stack, heap, lbl, used_heap, peak_stack, cur_stack, line)
        cond_depth = 0
        saw_safepoint_without_reload = False

        for pos, (line_no, stmt) in enumerate(stmts):
            if stmt.startswith("___IF("):
                cond_depth += 1
            elif stmt == "___END_IF":
                cond_depth = max(0, cond_depth - 1)

            for target in _GOTO_RE.findall(stmt):
                if target in label_to_block:
                    adj[idx].add(label_to_block[target])

            # Check ___group_demand_enter
            m_enter = _DEMAND_ENTER_RE.search(stmt)
            if m_enter:
                s_words = int(m_enter.group(1))
                h_words = int(m_enter.group(2))
                pre_lbl = int(m_enter.group(3))
                retry_lbl = int(m_enter.group(4))
                if pre_lbl != retry_lbl:
                    violations.append(dict(
                        code="demand-retry-label-mismatch",
                        procedure=name,
                        line=line_no,
                        detail=f"group_demand_enter label {pre_lbl} != temp1 retry label {retry_lbl}",
                    ))
                if pre_lbl not in slot_to_block:
                    violations.append(dict(
                        code="missing-prewrite-return-label",
                        procedure=name,
                        line=line_no,
                        detail=f"group_demand_enter references undeclared ___DEF_SLBL({pre_lbl})",
                    ))
                elif block["slot"] != pre_lbl:
                    violations.append(dict(
                        code="prewrite-label-not-dominating",
                        procedure=name,
                        line=line_no,
                        detail=f"group_demand_enter label {pre_lbl} does not match current block slot {block['slot']}",
                    ))
                if active_group is not None:
                    violations.append(dict(
                        code="uncommitted-write-group",
                        procedure=name,
                        line=line_no,
                        detail=f"nested group_demand_enter before committing label {active_group['lbl']}",
                    ))
                active_group = dict(
                    stack=s_words,
                    heap=h_words,
                    lbl=pre_lbl,
                    used_heap=0,
                    peak_stack=0,
                    cur_stack=0,
                    line=line_no,
                )
                write_groups += 1
                demand_in_blocks.add(idx)
                saw_safepoint_without_reload = False
                continue

            # Check ___group_demand_commit
            m_commit = _DEMAND_COMMIT_RE.search(stmt)
            if m_commit:
                commit_lbl = int(m_commit.group(1))
                if active_group is None:
                    violations.append(dict(
                        code="orphan-demand-commit",
                        procedure=name,
                        line=line_no,
                        detail=f"group_demand_commit({commit_lbl}) with no active write group",
                    ))
                else:
                    if commit_lbl != active_group["lbl"]:
                        violations.append(dict(
                            code="demand-commit-label-mismatch",
                            procedure=name,
                            line=line_no,
                            detail=f"group_demand_commit({commit_lbl}) != active group({active_group['lbl']})",
                        ))
                    active_group = None
                continue

            # Explicit reload clears post-safepoint taint
            if "___R_HEAP" in stmt or "___R_ALL" in stmt:
                saw_safepoint_without_reload = False

            # Check safepoints (___POLL / ___CHECK_HEAP / ___CHECK_HEAP_FLO)
            m_chk = _CHECK_RE.match(stmt)
            if m_chk:
                chk_kind, chk_slot_s = m_chk.groups()
                chk_slot = int(chk_slot_s)
                next_block = blocks[idx + 1] if idx + 1 < len(blocks) else None
                if next_block is None or next_block["slot"] != chk_slot:
                    violations.append(dict(
                        code="missing-safepoint-reload-or-label-mismatch",
                        procedure=name,
                        line=line_no,
                        detail=f"{chk_kind}({chk_slot}) not immediately followed by ___DEF_SLBL({chk_slot}, ...)",
                    ))
                if pos + 1 < len(stmts):
                    # Statements remaining in the same block after a safepoint without an explicit reload
                    saw_safepoint_without_reload = True

            # Account heap allocations
            heap_w = _line_heap_words(stmt)
            if heap_w > 0:
                procedure_allocates = True
                if saw_safepoint_without_reload:
                    violations.append(dict(
                        code="missing-safepoint-reload-or-label-mismatch",
                        procedure=name,
                        line=line_no,
                        detail=f"heap store ({heap_w} words) after safepoint without ___R_HEAP reload",
                    ))
                if active_group is None:
                    violations.append(dict(
                        code="unguarded-heap-write",
                        procedure=name,
                        line=line_no,
                        detail=f"heap allocation ({heap_w} words) outside dominating ___group_demand_enter",
                    ))
                else:
                    active_group["used_heap"] += heap_w
                    if active_group["used_heap"] > active_group["heap"]:
                        violations.append(dict(
                            code="insufficient-heap-demand",
                            procedure=name,
                            line=line_no,
                            detail=(
                                f"cumulative heap allocation {active_group['used_heap']} words "
                                f"exceeds admitted H={active_group['heap']} (label {active_group['lbl']})"
                            ),
                        ))

            # Account positive stack growth inside write groups
            if active_group is not None:
                for m_stk in _SET_STK_RE.finditer(stmt):
                    slot_off = int(m_stk.group(1))
                    if slot_off > 0:
                        needed = active_group["cur_stack"] + slot_off
                        if needed > active_group["peak_stack"]:
                            active_group["peak_stack"] = needed
                for m_adj in _ADJFP_RE.finditer(stmt):
                    delta = int(m_adj.group(1))
                    active_group["cur_stack"] += delta
                    if active_group["cur_stack"] > active_group["peak_stack"]:
                        active_group["peak_stack"] = active_group["cur_stack"]
                if active_group["peak_stack"] > active_group["stack"]:
                    violations.append(dict(
                        code="insufficient-stack-demand",
                        procedure=name,
                        line=line_no,
                        detail=(
                            f"peak stack growth {active_group['peak_stack']} words "
                            f"exceeds admitted S={active_group['stack']} (label {active_group['lbl']})"
                        ),
                    ))

        if active_group is not None:
            violations.append(dict(
                code="uncommitted-write-group",
                procedure=name,
                line=active_group["line"],
                detail=f"write group for label {active_group['lbl']} reaches block end without commit",
            ))

        # Fallthrough edge to next block unless unconditionally terminated
        if idx + 1 < len(blocks):
            last_stmt = stmts[-1][1] if stmts else ""
            if cond_depth > 0 or not _TERMINAL_RE.match(last_stmt):
                adj[idx].add(idx + 1)

    if procedure_allocates and not need_heap:
        violations.append(dict(
            code="missing-safepoint-reload-or-label-mismatch",
            procedure=name,
            line=proc["startLine"],
            detail="allocating procedure omits ___NEED_HEAP host reload declaration",
        ))

    # Feeley (1993) back-edge poll audit on all CFG loop SCCs
    cyclic_sccs = _find_sccs_with_cycles(len(blocks), adj)
    zero_alloc_loops = 0
    for scc in cyclic_sccs:
        scc_stmts = [stmt for b_idx in scc for _, stmt in blocks[b_idx]["stmts"]]
        has_poll = any(_SAFE_JUMP_RE.search(stmt) for stmt in scc_stmts)
        has_alloc = any(_line_heap_words(stmt) > 0 for stmt in scc_stmts)
        has_demand = any(b_idx in demand_in_blocks for b_idx in scc)
        if not has_poll:
            first_blk = blocks[scc[0]]
            violations.append(dict(
                code="poll-free-loop-cycle",
                procedure=name,
                line=first_blk["line"],
                detail=f"intra-procedure loop SCC {[blocks[i]['label'] for i in scc]} has no ___POLL safepoint",
            ))
        if not has_alloc and not has_demand:
            zero_alloc_loops += 1

    return dict(
        name=name,
        blocks=len(blocks),
        writeGroups=write_groups,
        cyclicLoops=len(cyclic_sccs),
        zeroAllocTightLoops=zero_alloc_loops,
        allocates=procedure_allocates,
        violations=violations,
    )


def validate_compiled_c(
    source_text: str,
    *,
    module_name: str = "<module>",
    max_labels: int = MAX_LABEL_COUNT_DEFAULT,
    frame_align: int = FRAME_ALIGN_DEFAULT,
    nb_gvm_regs: int = NB_GVM_REGS_DEFAULT,
    require_demand_protocol: bool = True,
) -> dict:
    """Validate one gsc-emitted C host source against Family 7 compiled-host contracts."""
    violations = []

    m_lbl = _LBLCOUNT_RE.search(source_text)
    label_count = int(m_lbl.group(1)) if m_lbl else 0
    rss_guard_safe = 0 < label_count < max_labels
    if label_count <= 0:
        violations.append(dict(
            code="missing-label-count",
            procedure="<module>",
            line=1,
            detail="___LBLCOUNT definition missing or non-positive",
        ))
    elif label_count >= max_labels:
        violations.append(dict(
            code="label-count-exceeds-rss-guard",
            procedure="<module>",
            line=1,
            detail=f"___LBLCOUNT={label_count} >= {max_labels} RSS guard threshold",
        ))

    descriptors, desc_violations = _decode_and_check_descriptors(
        source_text, frame_align=frame_align, nb_gvm_regs=nb_gvm_regs,
    )
    violations.extend(desc_violations)

    procedures = _extract_procedures(source_text)
    proc_reports = []
    total_write_groups = 0
    total_loops = 0
    total_zero_alloc_loops = 0

    for proc in procedures:
        report = _validate_procedure(proc)
        if not require_demand_protocol:
            report["violations"] = [
                v for v in report["violations"] if v["code"] != "unguarded-heap-write"
            ]
        proc_reports.append(report)
        total_write_groups += report["writeGroups"]
        total_loops += report["cyclicLoops"]
        total_zero_alloc_loops += report["zeroAllocTightLoops"]
        violations.extend(report["violations"])

    if not procedures:
        violations.append(dict(
            code="no-generated-procedures",
            procedure="<module>",
            line=1,
            detail="no ___BEGIN_P_COD..___END_P_COD procedures found in emitted C",
        ))

    return dict(
        schema="compiled-host-translation-validation.v1",
        module=module_name,
        passed=len(violations) == 0,
        labelCount=label_count,
        maxLabelCount=max_labels,
        rssGuardSafe=rss_guard_safe,
        descriptorCount=len(descriptors),
        procedureCount=len(procedures),
        writeGroupCount=total_write_groups,
        cyclicLoopCount=total_loops,
        zeroAllocTightLoopCount=total_zero_alloc_loops,
        violationCount=len(violations),
        violations=violations,
    )


def validate_compiled_module_files(
    c_path: Path,
    o1_path: Path | None = None,
    *,
    module_name: str | None = None,
    max_labels: int = MAX_LABEL_COUNT_DEFAULT,
    require_demand_protocol: bool = True,
) -> dict:
    """Hash and translate-validate an emitted .c host and optional linked .o1 bundle."""
    c_file = Path(c_path)
    c_bytes = c_file.read_bytes()
    report = validate_compiled_c(
        c_bytes.decode("utf-8", errors="replace"),
        module_name=module_name or c_file.name,
        max_labels=max_labels,
        require_demand_protocol=require_demand_protocol,
    )
    report["cPath"] = str(c_file)
    report["cSha256"] = hashlib.sha256(c_bytes).hexdigest()
    report["cBytes"] = len(c_bytes)
    if o1_path is not None:
        o1_file = Path(o1_path)
        o1_bytes = o1_file.read_bytes()
        report["o1Path"] = str(o1_file)
        report["o1Sha256"] = hashlib.sha256(o1_bytes).hexdigest()
        report["o1Bytes"] = len(o1_bytes)
    return report


def run_mutated_host_negative_controls(valid_c_text: str) -> dict:
    """Verify the validator rejects all 5 canonical mutated-host fault classes."""
    baseline = validate_compiled_c(valid_c_text, module_name="<baseline>")
    if not baseline["passed"]:
        raise ValueError(f"baseline compiled C failed validation: {baseline['violations']}")

    controls = []

    # Pick the first ___group_demand_enter with positive heap demand (H > 0) so
    # both dropping the enter and shrinking H->0 reliably fault real heap writes.
    heap_enter_match = None
    for m in _DEMAND_ENTER_RE.finditer(valid_c_text):
        if int(m.group(2)) > 0:
            heap_enter_match = m
            break
    if heap_enter_match is None:
        raise ValueError("baseline lacks heap-allocating (H > 0) ___group_demand_enter for negative controls 1-2")

    # 1. Drop ___group_demand_enter before heap write
    mut1 = (
        valid_c_text[: heap_enter_match.start()]
        + "/* mutated: dropped demand enter */"
        + valid_c_text[heap_enter_match.end() :]
    )
    r1 = validate_compiled_c(mut1, module_name="<mut1-drop-demand>")
    codes1 = {v["code"] for v in r1["violations"]}
    controls.append(dict(
        id="drop-group-demand-enter",
        rejected=not r1["passed"],
        expectedCode="unguarded-heap-write",
        observedCodes=sorted(codes1),
        passed=(not r1["passed"]) and ("unguarded-heap-write" in codes1),
    ))

    # 2. Under-compute H in ___group_demand_enter to 0
    shrunk_call = (
        f"if(!___group_demand_enter(___ps,&___hp,&___fp,{heap_enter_match.group(1)},0,"
        f"___LBL({heap_enter_match.group(3)}),&___demand_attempt))"
        f"{{___ps->temp1=___LBL({heap_enter_match.group(4)});___JUMPEXTPRM(___NOTHING,___ps->handler_stack_limit);}}"
    )
    mut2 = (
        valid_c_text[: heap_enter_match.start()]
        + shrunk_call
        + valid_c_text[heap_enter_match.end() :]
    )
    r2 = validate_compiled_c(mut2, module_name="<mut2-short-heap-demand>")
    codes2 = {v["code"] for v in r2["violations"]}
    controls.append(dict(
        id="under-computed-heap-demand",
        rejected=not r2["passed"],
        expectedCode="insufficient-heap-demand",
        observedCodes=sorted(codes2),
        passed=(not r2["passed"]) and ("insufficient-heap-demand" in codes2),
    ))

    # 3. Corrupt ___PR_ALL ___R_HEAP / ___NEED_HEAP post-safepoint reload binding
    if "___NEED_HEAP" in valid_c_text:
        mut3 = valid_c_text.replace("___NEED_HEAP", "/* mutated: removed ___NEED_HEAP */", 1)
    else:
        mut3 = re.sub(r"(#define\s+___PR_ALL\s+[^\n]*)\b___R_HEAP\b", r"\1/* mutated: removed R_HEAP */", valid_c_text)
    r3 = validate_compiled_c(mut3, module_name="<mut3-missing-reload>")
    codes3 = {v["code"] for v in r3["violations"]}
    controls.append(dict(
        id="missing-post-safepoint-reload",
        rejected=not r3["passed"],
        expectedCode="missing-safepoint-reload-or-label-mismatch",
        observedCodes=sorted(codes3),
        passed=(not r3["passed"]) and ("missing-safepoint-reload-or-label-mismatch" in codes3),
    ))

    # 4. Corrupt ___IFD frame descriptor link out-of-bounds
    mut4, n4 = _IFD_RE.subn("___IFD(___RETN,2,9,0x3L)", valid_c_text, count=1)
    if n4 != 1:
        raise ValueError("baseline lacks ___IFD descriptor for negative control 4")
    r4 = validate_compiled_c(mut4, module_name="<mut4-bad-ifd>")
    codes4 = {v["code"] for v in r4["violations"]}
    controls.append(dict(
        id="corrupted-frame-descriptor",
        rejected=not r4["passed"],
        expectedCode="invalid-frame-descriptor",
        observedCodes=sorted(codes4),
        passed=(not r4["passed"]) and ("invalid-frame-descriptor" in codes4),
    ))

    # 5. Elide ___POLL(n) from a tight loop back-edge
    mut5, n5 = re.subn(r"___POLL\(\d+\)", "/* mutated: elided poll */", valid_c_text)
    if n5 == 0:
        raise ValueError("baseline lacks ___POLL for negative control 5")
    r5 = validate_compiled_c(mut5, module_name="<mut5-elided-poll>")
    codes5 = {v["code"] for v in r5["violations"]}
    controls.append(dict(
        id="elided-backedge-poll",
        rejected=not r5["passed"],
        expectedCode="poll-free-loop-cycle",
        observedCodes=sorted(codes5),
        passed=(not r5["passed"]) and ("poll-free-loop-cycle" in codes5),
    ))

    return dict(
        schema="compiled-host-negative-controls.v1",
        total=len(controls),
        passed=all(c["passed"] for c in controls),
        controls=controls,
    )

"""Mark the first entered workload host label after a sync-loop return."""
from pathlib import Path
import re
import sys


def first_kind(line: str) -> int:
    macro = re.match(r"\s*___([A-Z0-9_]+)\(", line)
    if not macro:
        return 0
    name = macro[1]
    if re.fullmatch(r"SET_R[0-4]|SET_F64|SET_STK|SET_NARGS|ADJFP", name):
        return 1
    if name == "POLL":
        return 7
    if name == "IF":
        return 2
    if name.startswith("IF_"):
        return 3
    if name.startswith("JUMP") or name == "GOTO":
        return 4
    if name.startswith("DEF_"):
        return 5
    return 6


def instrument(source: str, first_op: bool = False, transfers: bool = False) -> str:
    header = '#include "gambit.h"'
    if source.count(header) != 1:
        raise ValueError("Generated C header anchor changed")
    source = source.replace(
        header,
        header + "\nextern _Thread_local int dev_gc_resume_pending;\n"
        "extern void dev_gc_workload_label(___SCMOBJ target);",
    )
    if first_op:
        source = source.replace(
            header,
            header + "\nextern int dev_gc_first_op_begin(___SCMOBJ target);"
            "\nextern void dev_gc_first_op_end(void);"
            "\nextern void dev_gc_workload_label_kind(___SCMOBJ target, unsigned kind);"
            "\nextern ___SCMOBJ dev_gc_transfer_target(___SCMOBJ target);",
        )

    def mark(match: re.Match[str]) -> str:
        label = match[1]
        indexed = re.match(r"___DEF_SLBL\((\d+),", label)
        target = f"___LBL({indexed[1]})" if indexed else "0"
        if first_op:
            start = match.end() + 1
            end = source.find("\n", start)
            following = source[start:] if end < 0 else source[start:end]
            return f"{label}\n   if (dev_gc_resume_pending) dev_gc_workload_label_kind({target}, {first_kind(following)});"
        return f"{label}\n   if (dev_gc_resume_pending) dev_gc_workload_label({target});"

    source, count = re.subn(
        r"^(___DEF_[SG]LBL\([^\n]+\))$",
        mark,
        source,
        flags=re.MULTILINE,
    )
    if not count:
        raise ValueError("No generated workload labels found")
    if first_op:
        def begin(index: str, kind: int) -> str:
            target = f"___LBL({index})"
            return (
                "int dev_gc_first = 0; if (dev_gc_resume_pending) { "
                f"dev_gc_workload_label_kind({target}, {kind}); "
                f"dev_gc_first = dev_gc_first_op_begin({target}); }}"
            )

        # Only single-line state updates with straight-line macro bodies.
        source, sites = re.subn(
            r"(^___DEF_SLBL\((\d+),[^\n]+\)\n"
            r"   if \(dev_gc_resume_pending\) dev_gc_workload_label_kind\(___LBL\(\2\), \d+\);\n)"
            r"([ \t]+___(?:SET_R[0-4]|SET_F64|SET_STK|SET_NARGS|ADJFP)\([^\n]+\))$",
            lambda m: m[1].splitlines()[0] + "\n   { " + begin(m[2], 1) + "\n"
            + m[3] + "\n   if (dev_gc_first) dev_gc_first_op_end(); }",
            source,
            flags=re.MULTILINE,
        )
        # Keep the original predicate in a single condition evaluation.
        source, predicates = re.subn(
            r"(^___DEF_SLBL\((\d+),[^\n]+\)\n"
            r"   if \(dev_gc_resume_pending\) dev_gc_workload_label_kind\(___LBL\(\2\), \d+\);\n)"
            r"([ \t]+)___IF\(([^\n]+)\)$",
            lambda m: m[1].splitlines()[0] + "\n" + m[3] + "___IF(__extension__ ({ "
            + begin(m[2], 2) + " "
            + f"int dev_gc_test = !!({m[4]}); "
            + "if (dev_gc_first) dev_gc_first_op_end(); dev_gc_test; }))",
            source,
            flags=re.MULTILINE,
        )
        if transfers:
            def transfer(match: re.Match[str]) -> str:
                label, index, macro, args = match.groups()
                prefix = label.splitlines()[0] + "\n   { " + begin(index, 4) + "\n"
                if macro == "JUMPRET":
                    return prefix + (
                        f"   {macro_call(macro, args)}"
                        "\n   }"
                    )
                parts = args.split(",", 2)
                if macro in ("JUMPPRM", "JUMPEXTPRM") and len(parts) >= 2:
                    nargs, value = args.split(",", 1)
                    # The original macro evaluates nargs before the wrapped value.
                    return prefix + f"   ___{macro}({nargs},{target_value(value)})\n   }}"
                if macro == "JUMPGLONOTSAFE" and len(parts) == 3:
                    nargs, i, glo = parts
                    original = f"___{macro}({args})"
                    return (
                        label.splitlines()[0] + "\n#ifndef ___SAFE_CALLS\n   { "
                        + begin(index, 4)
                        + f" {nargs} ___SELF=___GLO({i},{glo}); "
                        + f"___JUMP({target_value('___LABEL_ENTRY_GET(___SELF)')}) }}\n"
                        + "#else\n" + label.split("\n", 1)[1]
                        + f"   {original}\n#endif"
                    )
                return match[0]

            def target_value(value: str) -> str:
                return f"(dev_gc_first ? dev_gc_transfer_target(({value})) : ({value}))"

            def macro_call(macro: str, value: str) -> str:
                return f"___{macro}({target_value(value)})"

            source, _ = re.subn(
                r"(^___DEF_SLBL\((\d+),[^\n]+\)\n"
                r"   if \(dev_gc_resume_pending\) dev_gc_workload_label_kind\(___LBL\(\2\), 4\);\n)"
                r"[ \t]+___(JUMPRET|JUMPPRM|JUMPEXTPRM|JUMPGLONOTSAFE)\(([^\n]+)\)$",
                transfer,
                source,
                flags=re.MULTILINE,
            )
        if not sites + predicates:
            raise ValueError("No supported first-operation sites found")
    return source


def replace_site(source: str, original: str, observed: str) -> str:
    if source.count(original) != 1:
        raise ValueError(f"Generated anchor changed: {original.splitlines()[0]}")
    return source.replace(original, observed)


def direct_edge(source: str, index: int, start: str, end: str) -> str:
    label = f"___DEF_SLBL({index},{start})"
    jump = f"   ___GOTO({end})"
    mark = f"dev_gc_workload_label_kind(___LBL({index}), 4);"
    target = f"___DEF_GLBL({end})\n"
    source = replace_site(
        source, f"{label}\n   if (dev_gc_resume_pending) {mark}\n{jump}",
        f"{label}\n   if (dev_gc_resume_pending) {{ {mark} dev_gc_direct_start(___LBL({index})); }}\n{jump}",
    )
    return replace_site(source, target, target + "   if (dev_gc_resume_pending == 3) dev_gc_direct_arrive();\n")


def poll_edge(source: str, index: int, name: str, resume: int, old_kind: int) -> str:
    label = f"___DEF_SLBL({index},{name})"
    poll = f"   ___POLL({resume})"
    return replace_site(
        source, f"{label}\n   if (dev_gc_resume_pending) dev_gc_workload_label_kind(___LBL({index}), {old_kind});\n{poll}",
        label + "\n   { int dev_gc_poll = 0; if (dev_gc_resume_pending) { "
        f"dev_gc_workload_label_kind(___LBL({index}), 7); dev_gc_poll = dev_gc_first_op_begin(___LBL({index})); }}"
        "\n#pragma push_macro(\"___JUMPEXTPRM\")"
        "\n#undef ___JUMPEXTPRM"
        "\n#define ___JUMPEXTPRM(nargs,val) {nargs "
        "___JUMPEXT(dev_gc_poll ? dev_gc_transfer_target((val)) : (val))}"
        f"\n{poll}"
        "\n#pragma pop_macro(\"___JUMPEXTPRM\")"
        "\n   if (dev_gc_poll) dev_gc_first_op_end(); }",
    )


def direct_declarations(source: str) -> str:
    return source.replace(
        '#include "gambit.h"',
        '#include "gambit.h"\nextern void dev_gc_direct_start(___SCMOBJ source);'
        '\nextern void dev_gc_direct_arrive(void);',
    )


def instrument_tfib_edges(source: str) -> str:
    source = direct_edge(direct_declarations(source), 12, "___L12_tfib", "___L23_tfib")
    source = poll_edge(source, 2, "___L2_tfib", 3, 7)
    source = poll_edge(source, 4, "___L4_go", 5, 7)
    label = "___DEF_SLBL(10,___L10_go)"
    jump = "   ___JUMPGLOSAFE(___SET_NARGS(1),78,___G_make_2d_thread)"
    return replace_site(
        source,
        f"{label}\n   if (dev_gc_resume_pending) dev_gc_workload_label_kind(___LBL(10), 4);\n{jump}",
        label + """
   { int dev_gc_go = 0; if (dev_gc_resume_pending) {
     dev_gc_workload_label_kind(___LBL(10), 4); dev_gc_go = dev_gc_first_op_begin(___LBL(10)); }
   ___SET_NARGS(1)
   ___SELF=___GLO(78,___G_make_2d_thread);
#ifndef ___NOT_SAFE_CALLS
   if (___EXPECT_TRUE(___PROCEDUREP(___SELF)))
#endif
     ___JUMP(dev_gc_go ? dev_gc_transfer_target(___LABEL_ENTRY_GET(___SELF)) : ___LABEL_ENTRY_GET(___SELF))
#ifndef ___NOT_SAFE_CALLS
   ___ps->temp4=(___WORD)&___GLOSTRUCT(78,___G_make_2d_thread);
   ___JUMPEXTPRM(___NOTHING,dev_gc_go ? dev_gc_transfer_target(___ps->handler_not_proc_glo) : ___ps->handler_not_proc_glo)
#endif
   }""",
    )


def instrument_kernel_edges(source: str) -> str:
    if source.count("   dev_gc_return_target(ira);") != 1:
        raise ValueError("Kernel edges require the existing exact-return probe")
    source = poll_edge(direct_declarations(source), 1, "___L1___kernel_23_", 2, 7)
    suffix = "__23__23_execute_2d_jobs_21_"
    source = direct_edge(source, 1, "___L1"+suffix, "___L5"+suffix)
    label = f"___DEF_SLBL(3,___L3{suffix})"
    source = replace_site(
        source,
        label + "\n   if (dev_gc_resume_pending) dev_gc_workload_label_kind(___LBL(3), 5);",
        label + "\n   if (dev_gc_resume_pending) dev_gc_workload_label_kind(___LBL(3), 2);",
    )
    predicate = f"   ___IF(___NOT(___PAIRP(___R1)))\n   ___GOTO(___L6{suffix})"
    return replace_site(
        source, predicate,
        "   ___IF(__extension__ ({ int dev_gc_jobs = dev_gc_first_op_begin(___LBL(3)); "
        "int dev_gc_test = ___NOT(___PAIRP(___R1)); "
        "if (dev_gc_jobs) dev_gc_first_op_end(); dev_gc_test; }))"
        f"\n   ___GOTO(___L6{suffix})",
    )



if __name__ == "__main__":
    output = instrument(Path(sys.argv[1]).read_text(), "--first-op" in sys.argv[3:], "--transfers" in sys.argv[3:])
    if "--tfib-goto" in sys.argv[3:]:
        output = instrument_tfib_edges(output)
    if "--kernel-edges" in sys.argv[3:]:
        output = instrument_kernel_edges(output)
    Path(sys.argv[2]).write_text(output)

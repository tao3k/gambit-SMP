#!/usr/bin/env python3
"""Native SysML projection hooks for the proposed release-authority study."""
import argparse
import importlib.util
import json
import subprocess
from pathlib import Path
from types import SimpleNamespace

spec = importlib.util.spec_from_file_location("formal_study", Path(__file__).with_name("formal-study.py"))
engine = importlib.util.module_from_spec(spec)
spec.loader.exec_module(engine)
ROOT = engine.ROOT
stem = "stream-release-authority"
model = f"dev/architecture/toolchain/models/sysml/{stem}.sysml"
design = f"dev/architecture/toolchain/{stem}-design.org"
matrix = f"dev/architecture/toolchain/{stem}-matrix.org"
diagram = f"dev/architecture/toolchain/diagrams/{stem}.d2"
rules = f"dev/modeling/ascent/{stem}.rules.scm"
param = "models/build/stream_release_parameters.qnt"
groups = [("issuer", 5, "key anchor existing mayIssue cannotIssue"),
          ("gate", 6, "key qualified condition"), ("gain", 4, "key avoided added condition")]


def views(p):
    (ROOT / param).write_text("// Native StreamReleaseAuthority projection.\nmodule stream_release_parameters {\n"
        f"  pure val OwnerGeneration = {p['ownerGeneration']}\n}}\n")
    lines = ["#+TITLE: Stream Release Issuers, Closure and Net-Benefit Matrix",
        "#+SETUPFILE: ../../modeling/org/setup.org", "#+PROPERTY: header-args :eval never", "",
        "* RESEARCH Native SysML projection", ":PROPERTIES:", ":CUSTOM_ID: stream-release-matrix",
        ":AUTHORITY: StreamReleaseAuthority", ":END:", "",
        "Derived from native SysML; proposed credentials are not existing runtime APIs."]
    for name, _, schema in groups:
        fields = schema.split()
        lines += ["", "** " + name.capitalize(), "", "| " + " | ".join(fields) + " |", "|" + "+".join("---" for _ in fields) + "|"]
        lines += ["| " + " | ".join(str(row[field]) for field in fields) + " |" for row in p[name]]
    (ROOT / matrix).write_text("\n".join(lines) + "\n")
    graph = ["# Native SysML issuer containment and proof obligations; not a runtime schedule.", "direction: down",
        'domain: "Old stream release / modern C baseline"', 'issuers: "Existing mechanisms / proposed authority boundaries" {', "  grid-columns: 2"]
    graph += [f" i{n}: " + json.dumps(v["key"] + "\n" + v["anchor"]) for n, v in enumerate(p["issuer"])]
    graph += ["}", 'proof: "RA-H QNT / RA-I Lean; RA-S source / RA-E native"',
        'ascent: "ASCENT exact scopes / ancestor SH-S dependencies"', 'gates: "Six source/native qualification gates remain open"',
        "domain -> issuers", "issuers -> proof", "proof -> ascent", "ascent -> gates"]
    (ROOT / diagram).write_text("\n".join(graph) + "\n")


sources = ["vendor/gambit/" + path for path in ["lib/mem.c", "lib/_kernel.scm", "lib/_thread.scm",
    "lib/os_dyn.c", "examples/tcltk/tcltk.scm", "lib/_io.scm"]]
sources += ["../gerbil-gambit-bootstrap-audit/src/gerbil/runtime/error.ss"]


def source_checks(cache):
    cohort = {name: subprocess.check_output(["git", "-C", path, "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
              for name, path in [("research", "."), ("gerbil", "../gerbil-gambit-bootstrap-audit"), ("gambit", "vendor/gambit")]}
    cohort["selectedGambitStatus"] = subprocess.check_output(["git", "-C", "vendor/gambit", "status", "--porcelain", "--",
        "lib/mem.c", "lib/_kernel.scm", "lib/_thread.scm", "lib/os_dyn.c", "examples/tcltk/tcltk.scm", "lib/_io.scm"], cwd=ROOT, text=True)
    engine.save(cache / "source-cohort.json", cohort)
    tests = [(sources[0], "#define ___PSTATE_MEM(var) ___ps->mem.var"),
        (sources[0], "#define rc_head                 ___PSTATE_MEM(rc_head_)"),
        (sources[0], "mark_array (___PSP &h->data, 1);"),
        (sources[0], "___PROCESSOR_ID(___ps,___vms) == 0"),
        (sources[0], "mark_array (___PSP body+2, 1); /* scan action only */"),
        (sources[1], "(##will-testator-set! will #f)"), (sources[1], "(action testator)"),
        (sources[3], "___set_data_rc (c_closure, proc);"),
        (sources[4], "___EXT(___release_rc) (___CAST(void*,client_data));"),
        (sources[-1], "(unless (&StackTrace-continuation exn)")]
    for path, fragment in tests:
        assert fragment in (ROOT / path).read_text(), (path, fragment)
    engine.save(cache / "source-census.json", dict(checks=[dict(path=p, fragment=f) for p, f in tests],
        bindings={p: engine.sha(ROOT / p) for p in sources},
        compositeIssuer="absent-in-selected-sources", ownerAliasCoverage="open", nativeRootCoverage="open"))


def facts(p, scenario):
    out = [engine.fact("releaseIssuerFact", [v[k] for k in ["key", "anchor", "existing", "mayIssue", "cannotIssue"]]) for v in p["issuer"]]
    for gate in p["gate"]:
        qualified = scenario in {"synthetic-gates", "missing-release"} and not(
            scenario == "missing-release" and gate["key"] == "owner-token-coverage")
        out.append(engine.fact("releaseGateFact", [scenario, gate["key"], str(qualified or gate["qualified"]).lower()]))
    out.append(engine.fact("releaseSourceFact", [scenario, str(scenario in {"synthetic-gates", "missing-release"}).lower()]))
    return out


def check_inference(p, results):
    c = results["current"]
    assert sorted(c["releaseIssuer"]) == sorted(["current"] + [v[k] for k in ["key", "anchor", "existing", "mayIssue", "cannotIssue"]] for v in p["issuer"])
    assert len(c["releaseMissing"]) == len(p["gate"]) and not c["releaseCandidate"]
    assert not results["all-scoped-control"]["releaseCandidate"]
    assert len(results["synthetic-gates"]["releaseCandidate"]) == 1
    assert not results["missing-release"]["releaseCandidate"]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--resume", action="store_true")
    args = parser.parse_args()
    study = SimpleNamespace(task=stem, parent="span-storage-handoff", package="StreamReleaseAuthority", prefix="RA",
        model=model, design=design, matrix=matrix, diagram=diagram, rules=rules, param=param,
        qnt="models/build/stream_release_authority.qnt", lean="models/build/StreamReleaseAuthority.lean",
        parent_design="dev/architecture/toolchain/span-storage-handoff-design.org",
        parent_matrix="dev/architecture/toolchain/span-storage-handoff-matrix.org",
        groups=groups, scalars=["ownerGeneration", "actualAdmitted"], histories=25, controls=11, kernels=8, inits=["init"],
        views=views, source_checks=source_checks, facts=facts, check_inference=check_inference,
        outputs="releaseIssuer releaseMissing releaseBlocked releaseCandidate", sources=sources,
        artifacts=[model, design, matrix, diagram, rules, param, "models/build/stream_release_authority.qnt",
            "models/build/StreamReleaseAuthority.lean", "dev/modeling/tools/stream-release-study.py", "dev/modeling/tools/formal-study.py"])
    engine.execute(study, resume=args.resume)

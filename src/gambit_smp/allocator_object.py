"""Compile only the scoped allocator's real mem.c via its configured make rule."""
import argparse
import json
from pathlib import Path
import shlex

from gambit_smp.allocator_acquire import candidate
from gambit_smp.framework import ROOT, digest, execute, gnu_compiler


def command(plan, compiler, source, output):
    lines = [line for line in plan.splitlines() if line.strip()]
    if len(lines) != 1:
        raise ValueError("single compilation recipe required; no setup or extra tasks")
    args = shlex.split(lines[0])
    if (not args or Path(args[0]).resolve(strict=True) != Path(compiler) or
            args.count("-c") != 1 or args.count("-o") != 1 or
            args[args.index("-o") + 1] != str(output) or args.count(str(source)) != 1 or
            "-D___LIBRARY" not in args or "-D___PRIMAL" not in args or
            any(arg in (";", "&&", "||", ">", "|") for arg in args)):
        raise ValueError("unexpected compiler/input/output recipe")
    return args


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--gcc", type=Path, required=True)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument, required=True)
    args = parser.parse_args()
    campaign = args.candidate.resolve(strict=True)
    source = args.source.resolve(strict=True)
    receipt_path = campaign / "receipt.json"
    prior = json.loads(receipt_path.read_text())
    if (prior.get("schema") != "gambit-allocator-acquire-codegen.v1" or
            prior.get("contextStable") is not True or prior.get("runtimeAdmitted") is not False or
            prior.get("status") != "compiled-inspection-required"):
        raise ValueError("reviewed codegen candidate required")
    inputs = dict(prior["inputs"])
    if any(digest(ROOT / name) != sha for name, sha in inputs.items()):
        raise ValueError("candidate context is stale")
    revised = campaign / "mem.c"
    if (digest(revised) != prior["candidateSourceSha256"] or
            revised.read_text() != candidate(source.read_text())):
        raise ValueError("candidate source is not the narrow reviewed change")
    compiler, env, version = gnu_compiler(args.gcc)
    if digest(Path(compiler)) != prior["compilerSha256"]:
        raise ValueError("candidate compiler changed")
    library = source.parent
    makefile = library / "makefile"
    # Bind local transitive header inputs conservatively, not just direct includes.
    paths = [receipt_path, revised, Path(__file__).resolve(), makefile]
    paths.extend(library.glob("*.h"))
    paths.extend((library.parent / "include").glob("*.h"))
    for path in paths:
        inputs[path.relative_to(ROOT).as_posix()] = digest(path)
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    output = out / "mem.o"
    # -o makefile prevents GNU make from rebuilding its own input even in dry run.
    dry = ["make", "-n", "-o", "makefile", "-W", "mem.c", "mem.o",
           "BUILD_OBJ_INPUT_FILENAMES_PARAM=" + str(revised),
           "BUILD_OBJ_OUTPUT_FILENAME_PARAM=" + str(output)]
    code, plan, timeout, _ = execute(dry, library, 10, env=env)
    if code != 0 or timeout:
        raise ValueError("cannot obtain configured compilation recipe")
    argv = command(plan, compiler, revised, output)
    (out / "recipe.log").write_text(plan)
    code, log, timeout, seconds = execute(argv, library, 90, env=env)
    (out / "compile.log").write_text(log)
    stable = all(digest(ROOT / name) == sha for name, sha in inputs.items())
    stable = stable and digest(Path(compiler)) == prior["compilerSha256"]
    ok = stable and code == 0 and not timeout and output.is_file()
    receipt = {"schema": "gambit-allocator-object.v1", "inputs": inputs,
               "compiler": version.splitlines()[0], "compilerSha256": prior["compilerSha256"],
               "exit": code, "timeout": timeout, "seconds": seconds,
               "contextStable": stable, "status": "object-compiled" if ok else "DENY",
               "objectSha256": digest(output) if output.is_file() else None,
               "recipeSha256": digest(out / "recipe.log"), "logSha256": digest(out / "compile.log"),
               "diagnosticOnly": True, "runtimeAdmitted": False, "releaseAdmitted": False,
               "scope": "Full mem.c object at configured production flags; no linking, execution, GC, bootstrap or performance acceptance."}
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({key: receipt[key] for key in ("status", "seconds", "runtimeAdmitted")}))
    return 0 if ok else 1


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('allocator-object')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('allocator-object', main))

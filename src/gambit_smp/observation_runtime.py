"""Join the rest observer into the configured Make runtime image.

The sealed identity is the GSI Make links. The observer compilation and the
handler object are both products of that Make file. A newer handler source
replaces its archive member before the link. The previous image is kept.
"""
import json
import os
import re
import shutil
import shlex
import sys
from pathlib import Path

from gambit_smp.framework import digest, execute

DEFINE = "-D___GAMBIT_REST_OBSERVATION"
SYMBOL = "___rest_observation_open"
LINK_SCRATCH = frozenset({"gsi/gsi.observation", "gsi/gsi.observation.link.log"})
# The generated kernel in a configured tree still calls these hooks. The
# maintained sources emit the same events from the memory observer, and these
# wrappers keep that kernel linkable.
KERNEL_OBSERVER_DECLARATIONS = """
extern void ___rest_observation_exact_granted(___processor_state ps, ___WORD *hp, ___WORD *fp);
extern void ___rest_observation_note_adjust(___processor_state ps, ___WORD *fp, long words);
extern void ___rest_observation_note_store(___processor_state ps, ___activation_record *record,
                                          ___WORD epoch, ___WORD *fp, ___WORD *address);
extern void ___rest_observation_note_saved_fp(___processor_state ps, ___activation_record *record,
                                             ___WORD epoch, ___WORD *saved, ___WORD *parent);
extern void ___rest_observation_note_return_fp(___processor_state ps, ___activation_record *record,
                                              ___WORD epoch, ___WORD *fp);
extern void ___rest_observation_note_body(___processor_state ps);
"""
KERNEL_OBSERVER_COMPAT = """
#ifdef ___GAMBIT_REST_OBSERVATION
void ___rest_observation_exact_granted(___processor_state ps, ___WORD *hp, ___WORD *fp)
{
  if (ps && hp && fp)
    ___rest_observation_emit(REST_NATIVE_CUT,(uintptr_t)ps,0,0,0,
      (uintptr_t)hp,(uintptr_t)fp,0,0,0,0,0,0);
}
void ___rest_observation_note_adjust(___processor_state ps, ___WORD *fp, long words)
{
  if (fp) ___rest_observation_adjust(ps, fp, (intptr_t)words);
}
void ___rest_observation_note_store(___processor_state ps, ___activation_record *record,
                                    ___WORD epoch, ___WORD *fp, ___WORD *address)
{
  (void)fp;
  if (address)
    ___rest_observation_emit(REST_STORE,(uintptr_t)ps,(uintptr_t)record,
      record?(uint64_t)record->rest_attempt:0,(uint64_t)epoch,
      0,(uintptr_t)address,0,0,0,0,0,0);
}
void ___rest_observation_note_saved_fp(___processor_state ps, ___activation_record *record,
                                      ___WORD epoch, ___WORD *saved, ___WORD *parent)
{
  ___rest_observation_emit(REST_SAVED_FP,(uintptr_t)ps,(uintptr_t)record,
    record?(uint64_t)record->rest_attempt:0,(uint64_t)epoch,
    (uintptr_t)saved,(uintptr_t)parent,0,0,0,0,0,0);
}
void ___rest_observation_note_return_fp(___processor_state ps, ___activation_record *record,
                                       ___WORD epoch, ___WORD *fp)
{
  ___rest_observation_emit(REST_RETURN_FP,(uintptr_t)ps,(uintptr_t)record,
    record?(uint64_t)record->rest_attempt:0,(uint64_t)epoch,
    (uintptr_t)fp,0,0,0,0,0,0,0);
}
void ___rest_observation_note_body(___processor_state ps)
{
  if (ps) ___rest_observation_body(ps);
}
#endif
"""



def sync_maintained_observer(source):
    """Copy the current vendor memory observer into the tree before the Make compile."""
    from gambit_smp.framework import ROOT
    vendor = ROOT / "vendor" / "gambit"
    names = ["lib/mem.c", "lib/lifecycle.h", "lib/rest-observation.h"]
    # allocation-limits.inc is the generated kernel's enter protocol. Replacing
    # it before that kernel is regenerated rejects every write-group arm.
    names.extend(path.relative_to(vendor).as_posix()
                 for path in sorted((vendor / "lib" / "_mem").glob("*.inc"))
                 if path.name != "allocation-limits.inc")
    copied = {}
    for name in names:
        origin = vendor / name
        if not origin.is_file():
            raise ValueError("maintained observer source is missing: " + name)
        destination = Path(source) / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(origin, destination)
        os.utime(destination, None)
        copied[name] = digest(destination)
    allocation = Path(source) / "lib" / "_mem" / "rc-allocation.inc"
    header = Path(source) / "lib" / "lifecycle.h"
    if "___rest_observation_note_store" not in allocation.read_text():
        with allocation.open("a") as stream:
            stream.write(KERNEL_OBSERVER_COMPAT)
        os.utime(allocation, None)
        copied["lib/_mem/rc-allocation.inc"] = digest(allocation)
    if "___rest_observation_note_store" not in header.read_text():
        with header.open("a") as stream:
            stream.write(KERNEL_OBSERVER_DECLARATIONS)
        os.utime(header, None)
        copied["lib/lifecycle.h"] = digest(header)
    return copied


def _recipe(directory, watch, target, output):
    code, plan, timeout, _ = execute(
        ["make", "-n", "-o", "makefile", "-W", watch, target,
         "BUILD_OBJ_OUTPUT_FILENAME_PARAM=" + str(output),
         "BUILD_EXE_OUTPUT_FILENAME_PARAM=" + str(output)],
        directory, 15)
    lines = [line for line in plan.splitlines() if line.strip() and not line.startswith("make:")]
    if code != 0 or timeout or len(lines) != 1:
        raise ValueError("single configured Make recipe required for " + target)
    return shlex.split(lines[0])


def _compile_observed(source):
    lib = source / "lib"
    output = lib / "mem.observation.o"
    if output.exists():
        output.unlink()
    argv = _recipe(lib, "mem.c", "mem.o", output)
    if argv.count(DEFINE) > 1 or argv.count("mem.c") != 1 or argv.count("-c") != 1:
        raise ValueError("mem.o recipe is not the configured single compilation")
    if DEFINE not in argv:
        argv.insert(argv.index("mem.c"), DEFINE)
    code, log, timeout, _ = execute(argv, lib, 180)
    (lib / "mem.observation.compile.log").write_text(log)
    if code != 0 or timeout or not output.is_file():
        raise ValueError("observer mem.o was not produced by the Make recipe")
    return output


def reproduce_handler_object(args, ctx):
    """Compare a fresh configured compile to a retained observation object."""
    from gambit_smp.gambit_build_primitives import command
    from gambit_smp.gate2_collection import dependencies
    from gambit_smp.native_capabilities import compiler
    from gambit_smp.recipes import tree_identity

    ref = args["source"]
    provider = next(row for row in ctx.receipt["steps"] if row["id"] == ref["step"])
    if (ref["output"] != "runtime" or provider["capability"] != "gambit.observation-identity"
            or "retainedRuntime" not in provider["arguments"]):
        raise ValueError("handler comparison requires a retained observation runtime")
    runtime = ctx.reuse_workspace(ref, "source-runtime")
    inventory = provider["outputs"]["runtime"]["identity"]
    unit = Path(args["translationUnit"])
    object_name = unit.with_suffix(".o").as_posix()
    expected = inventory[object_name]["sha256"]
    output = ctx.directory / unit.with_suffix(".o").name
    sidecar = ctx.directory / "gcc.d"
    directory = runtime / "lib"
    gcc = Path(compiler(ctx))
    ctx.bind([runtime / unit, directory / "makefile", runtime / object_name, gcc])
    plan = ctx.require("object-recipe", [ctx.tools["make"], "-n", "-o", "makefile", "-W", unit.name,
        Path(object_name).name, "BUILD_OBJ_OUTPUT_FILENAME_PARAM=" + str(output)], directory, 10)
    argv = command(plan, gcc, unit.name, output)
    if DEFINE not in argv:
        argv.insert(argv.index(unit.name), DEFINE)
    argv += ["-MD", "-MF", str(sidecar)]
    ctx.require("object-compile", argv, directory, ctx.remaining())
    paths = dependencies(sidecar.read_bytes(), directory)
    if runtime / unit not in paths:
        raise ValueError("GCC dependency file omits the handler source")
    ctx.bind(paths)
    if tree_identity(runtime) != inventory:
        raise ValueError("retained runtime changed during focused compilation")
    actual = digest(output)
    return {"outputs": ctx.publish("object", "native-object", output),
            "translationUnit": unit.as_posix(),
            "handlerComparison": dict(scope="focused-object-reproduction", object=object_name,
                expectedSha256=expected, observedSha256=actual, status="PASS" if actual == expected else "MISMATCH",
                dependencySha256=digest(sidecar), inputs={str(path): ctx.extra_inputs[str(path)] for path in sorted(paths)}),
            "claim": "focused-object-reproduction"}


def _compile_handler(source):
    """Rebuild the kernel object when its source is newer than the archive member."""
    lib = source / "lib"
    source_file, current = lib / "_kernel.c", lib / "_kernel.o"
    if not source_file.is_file() or not current.is_file():
        raise ValueError("handler source and object are both required")
    if source_file.stat().st_mtime <= current.stat().st_mtime:
        return current
    output = lib / "_kernel.observation.o"
    if output.exists():
        output.unlink()
    argv = _recipe(lib, "_kernel.c", "_kernel.o", output)
    if argv.count("_kernel.c") != 1 or argv.count("-c") != 1:
        raise ValueError("kernel recipe is not the configured single compilation")
    if DEFINE not in argv:
        argv.insert(argv.index("_kernel.c"), DEFINE)
    code, log, timeout, _ = execute(argv, lib, 180)
    (lib / "_kernel.observation.compile.log").write_text(log)
    if code != 0 or timeout or not output.is_file():
        raise ValueError("handler object was not produced by the Make recipe")
    return output


def _tool(makefile, name):
    for line in makefile.read_text().splitlines():
        if line.startswith(name + " = "):
            return line.split("=", 1)[1].strip()
    raise ValueError("configured " + name + " is not in the Make file")


def _archive(source, members):
    lib = source / "lib"
    work = lib / "observation-join"
    if work.exists():
        shutil.rmtree(work)
    work.mkdir()
    for name, member in members:
        shutil.copy2(member, work / name)
    shutil.copy2(lib / "libgambit.a", work / "libgambit.a")
    ar, ranlib = (_tool(lib / "makefile", name) for name in ("AR", "RANLIB"))
    names = [name for name, _ in members]
    for argv in ([ar, "r", "libgambit.a", *names], [ranlib, "libgambit.a"]):
        code, _, timeout, _ = execute(argv, work, 30)
        if code != 0 or timeout:
            raise ValueError("observer archive update failed")
    listed, listing, timeout, _ = execute([ar, "t", "libgambit.a"], work, 15)
    present = set(listing.split())
    if listed != 0 or timeout or any(name not in present for name in names):
        raise ValueError("observer archive does not contain the refreshed members")
    return work / "libgambit.a"


def _link(source, archive):
    """Replay the configured Make link. The recipe names gcc; nothing substitutes another compiler."""
    gsi = source / "gsi"
    output = gsi / "gsi.observation"
    if output.exists():
        output.unlink()
    argv = _recipe(gsi, "../lib/libgambit.a", "gsi", output)
    replaced = False
    for index, arg in enumerate(argv):
        if arg.endswith("libgambit.a") and "libgambitgsi" not in arg:
            argv[index] = str(archive)
            replaced = True
    compiler = Path(argv[0]).resolve()
    if ("gcc" not in compiler.name.lower() or "clang" in compiler.name.lower()
            or argv.count("-o") != 1 or not replaced):
        raise ValueError("gsi link recipe is not the configured gcc link of the runtime archive")
    # The Make recipe names gcc. gcc then runs ld from PATH. Use the same
    # developer-tool PATH the native build binds, so a package-manager ld
    # earlier on the caller PATH cannot replace it.
    from gambit_smp.native_capabilities import host_tools
    import os
    tools, env = host_tools(compiler, [{"capability": "link"}], os.environ)
    if tools["gcc"] != compiler or "clang" in tools["ld"].name.lower():
        raise ValueError("configured gcc link does not select the developer linker")
    code, log, timeout, _ = execute(argv, gsi, 60, env=env)
    (gsi / "gsi.observation.link.log").write_text(log)
    if code != 0 or timeout or not output.is_file():
        raise ValueError("observer GSI was not produced by the Make gcc link")
    code, symbols, timeout, _ = execute(["nm", "-gU", str(output)], gsi, 15)
    if code != 0 or timeout or SYMBOL not in symbols:
        raise ValueError("linked GSI does not export the rest observer")
    return output, tools["ld"]


def _write_identity(source):
    """Record the joined tree with the runtime-identity hasher. This is not a research publication."""
    from gambit_smp.native_capabilities import runtime_identity_document
    from gambit_smp.rest_observation import contract_from_identity
    document = runtime_identity_document(source, publication="observation-join")
    contract_from_identity(document, [
        {"id": 1, "checklist": 9, "spelling": "ordinary", "situation": "race"}], capacity=1)
    path = source.parent / "identity.json"
    path.write_text(json.dumps(document, indent=2) + "\n")
    return path


def join(source):
    """Replace the tree's GSI with the observer image and retain the prior bytes."""
    source = Path(source).resolve()
    current = source / "gsi" / "gsi"
    previous = digest(current)
    retained = source / "gsi" / ("gsi." + previous[:16] + ".previous")
    if not retained.exists():
        shutil.copy2(current, retained)
    member = _compile_observed(source)
    handler = _compile_handler(source)
    archive = _archive(source, (("mem.o", member), ("_kernel.o", handler)))
    linked, linker = _link(source, archive)
    shutil.copy2(member, source / "lib" / "mem.o")
    if handler.resolve() != (source / "lib" / "_kernel.o").resolve():
        shutil.copy2(handler, source / "lib" / "_kernel.o")
    shutil.copy2(archive, source / "lib" / "libgambit.a")
    shutil.copy2(linked, current)
    current.chmod(0o755)
    identity_path = _write_identity(source)
    return {"schema": "gambit-observation-runtime.v1",
            "previousGsiSha256": previous,
            "retainedImage": retained.relative_to(source).as_posix(),
            "binarySha256": digest(current),
            "librarySha256": digest(source / "lib" / "libgambit.a"),
            "memberSha256": digest(source / "lib" / "mem.o"),
            "handlerSha256": digest(source / "lib" / "_kernel.o"),
            "define": DEFINE,
            "compiler": _tool(source / "gsi" / "makefile", "C_COMPILER"),
            "linker": str(linker),
            "identity": identity_path.relative_to(source.parent).as_posix(),
            "runtimeAdmitted": False}


def validate_observation_identity(args, inputs):
    from gambit_smp.recipes import fields
    fields(args, ("source", "gsiSha256"), ("retainedRuntime",))
    source = Path(args["source"])
    if (not isinstance(args["source"], str) or source.is_absolute() or ".." in source.parts
            or not args["source"].startswith(".cache/tasks/")
            or not re.fullmatch(r"[0-9a-f]{64}", args["gsiSha256"])):
        raise ValueError("observation identity requires a task-cache runtime and an exact GSI digest")
    if inputs is None:
        raise ValueError("observation identity declaration required")
    if "retainedRuntime" in args:
        reference = args["retainedRuntime"]
        fields(reference, ("run", "receiptSha256", "step"))
        if (not isinstance(reference["run"], str) or not reference["run"].startswith(".cache/tasks/")
                or ".." in Path(reference["run"]).parts
                or not isinstance(reference["step"], str) or not reference["step"]
                or not isinstance(reference["receiptSha256"], str)
                or not re.fullmatch(r"[0-9a-f]{64}", reference["receiptSha256"])):
            raise ValueError("retained runtime requires its task run, receipt digest and provider step")


def check_observation_tree(retained, current):
    """Verify every runtime entry, excluding the observation link's scratch files."""
    for name in sorted(retained.keys() | current.keys()):
        before, after = retained.get(name), current.get(name)
        if before == after:
            continue
        if name in LINK_SCRATCH and all(
                row is None or set(row) == {"sha256", "mode"} for row in (before, after)):
            continue
        raise ValueError("retained observation runtime input changed: " + name)


def retained_observation_runtime(args, ctx, source):
    """Lease and publish the exact already-observed runtime from its checkpoint."""
    from gambit_smp.artifact_storage import observation_root
    from gambit_smp.family6_recipes import OBSERVATION_PROVIDER
    from gambit_smp.framework import relative
    from gambit_smp.ordered_stress_audit import checked_json, committed_header, passed_step
    from gambit_smp.recipes import artifact_path, tree_identity
    from gambit_smp.suite_primitives import check_runtime

    reference = args["retainedRuntime"]
    out = relative(ctx.root, reference["run"])
    observation_root(ctx.root, out)
    outer_path, child_path = out / "receipt.json", out / "run/receipt.json"
    ctx.bind([outer_path, child_path])
    outer = checked_json(outer_path, reference["receiptSha256"])
    child = checked_json(child_path, outer["childReceiptSha256"])
    if (outer.get("schema") != "sealed-research-run.v1" or outer.get("root") != str(ctx.root.resolve())
            or outer.get("outcome") != "PASS" or child.get("outcome") != "PASS"
            or outer.get("timeout") is not False or outer.get("exit") != 0
            or outer.get("parentReaped") is not True or outer.get("processGroupQuiescent") is not True
            or child.get("schema") != "evidence-recipe-run.v1" or child.get("recipe") != outer["recipe"]):
        raise ValueError("retained observation runtime requires a completed same-repository Research run")
    step = passed_step(child, reference["step"])
    committed_header(out, outer, child, [step])
    if (step["capability"] != OBSERVATION_PROVIDER
            or step["arguments"].get("gsiSha256") != args["gsiSha256"]):
        raise ValueError("retained observation step names another runtime")
    runtime, identity = (step["outputs"][key] for key in ("runtime", "identity"))
    origin = artifact_path(out / "run", runtime, root=ctx.root)
    if (runtime["type"] != "source-runtime" or identity["type"] != "runtime-identity"
            or origin != relative(ctx.root, step["arguments"]["source"])):
        raise ValueError("retained observation step does not publish its declared runtime")
    identity_path = artifact_path(out / "run", identity, root=ctx.root)
    ctx.bind([identity_path])
    candidate = checked_json(identity_path, identity["sha256"])
    if (candidate.get("schema") != "gambit-recipe-runtime-identity.v1"
            or candidate.get("binarySha256") != args["gsiSha256"]):
        raise ValueError("retained observation identity differs from the declared GSI")
    if source == origin:
        inventory = tree_identity(source)
        check_observation_tree(runtime["identity"], inventory)
    else:
        # An independent restoration must match even the historical scratch files.
        inventory = runtime["identity"]
    ctx.lease_workspace(source, inventory)
    check_runtime(source, candidate)
    path = ctx.directory / "identity.json"
    path.write_bytes(identity_path.read_bytes())
    if digest(path) != identity["sha256"]:
        raise ValueError("retained observation identity changed during transfer")
    return {"outputs": {**ctx.publish("identity", "runtime-identity", path),
                        **ctx.publish("runtime", "source-runtime", source)},
            "retainedRuntime": reference, "runtimeAdmitted": False,
            "claim": "receipt-bound-observation-runtime-not-native-admission"}


def replay_link_map(source, ctx):
    """Replay the configured gcc link into the research directory and keep its map.

    The runtime image stays in place. The replay is the same linked image when
    it differs only by the Darwin UUID and the signature that covers it.
    """
    from gambit_smp.gate2_collection import same_linked_image
    from gambit_smp.gate2_evidence import linked_members
    from gambit_smp.native_capabilities import host_tools

    gsi = source / "gsi"
    output = ctx.directory / "gsi"
    link_map = ctx.directory / "link.map"
    argv = _recipe(gsi, "../lib/libgambit.a", "gsi", output)
    compiler = Path(argv[0]).resolve()
    if ("gcc" not in compiler.name.lower() or "clang" in compiler.name.lower()
            or argv.count("-o") != 1):
        raise ValueError("gsi link recipe is not the configured gcc link")
    argv.extend(["-Xlinker", "-map" if sys.platform == "darwin" else "-Map", "-Xlinker", str(link_map)])
    tools, _env = host_tools(compiler, [{"capability": "link"}], os.environ)
    if tools["gcc"] != compiler or "clang" in tools["ld"].name.lower():
        raise ValueError("configured gcc link does not select the developer linker")
    ctx.require("link-map", argv, gsi, ctx.remaining())
    if not output.is_file() or not link_map.is_file():
        raise ValueError("configured gcc replay did not write the image and its link map")
    if not same_linked_image(output.read_bytes(), (gsi / "gsi").read_bytes()):
        raise ValueError("configured gcc replay did not reproduce the observation image")
    fmt = "darwin" if sys.platform == "darwin" else "gnu"
    members = [list(row) for row in linked_members(link_map.read_bytes(), fmt)]
    selected = {member for _archive_name, member in members}
    missing = [name for name in ("mem.o", "_kernel.o", "_eval.o") if name not in selected]
    if missing:
        raise ValueError("link map did not select " + ", ".join(missing))
    return {"mapSha256": digest(link_map), "replaySha256": digest(output),
            "members": members, "linker": str(tools["ld"]), "sameLinkedImage": True}


def build_closure(source, ctx, members):
    """Record the compiler, configuration, loader, and selected object bytes already in the tree."""
    import hashlib
    makefile = (source / "gsi" / "makefile").read_text().splitlines()
    compiler = next((line.split("=", 1)[1].strip() for line in makefile if line.startswith("C_COMPILER = ")), "")
    compiler_path = Path(compiler)
    if not compiler_path.is_file() or "gcc" not in compiler_path.name.lower() or "clang" in compiler_path.name.lower():
        raise ValueError("configured C compiler is not the gcc named by the gsi makefile")
    config_status, config_header = source / "config.status", source / "include" / "config.h"
    if not config_status.is_file() or not config_header.is_file():
        raise ValueError("configured runtime is missing config.status or include/config.h")
    loader_log = ctx.require("loader", ["/usr/bin/otool", "-L", str(source / "gsi" / "gsi")], source, ctx.remaining())
    loaders = [line.strip().split(" (", 1)[0] for line in loader_log.splitlines()[1:] if line.strip()]
    if not loaders:
        raise ValueError("observation image reported no loaders")
    gsi = source / "gsi"
    objects = {}
    for archive_name, member in members:
        if member not in {"mem.o", "_kernel.o", "_eval.o"}:
            continue
        archive = (gsi / archive_name).resolve()
        ctx.run("member-" + member, ["/usr/bin/ar", "p", str(archive), member], gsi, ctx.remaining(), text=False)
        command = ctx.commands[-1]
        if command["exit"] != 0 or command["timeout"] is not False:
            raise ValueError("archive member was not extracted: " + member)
        member_bytes = ctx.last_stdout
        if not isinstance(member_bytes, bytes) or not member_bytes:
            raise ValueError("archive member bytes were not retained: " + member)
        member_sha = hashlib.sha256(member_bytes).hexdigest()
        loose = archive.parent / member
        if not loose.is_file() or hashlib.sha256(loose.read_bytes()).hexdigest() != member_sha:
            raise ValueError("selected archive member differs from the object file: " + member)
        objects[loose.relative_to(source).as_posix()] = member_sha
    if set(objects) != {"lib/mem.o", "lib/_kernel.o", "lib/_eval.o"}:
        raise ValueError("link map did not yield mem.o, _kernel.o, and _eval.o bytes")
    return {"compiler": str(compiler_path), "compilerSha256": digest(compiler_path),
            "configStatusSha256": digest(config_status), "configHeaderSha256": digest(config_header),
            "loaders": loaders, "objects": objects}


def publish_observation_identity(args, ctx):
    """Import a committed observer tree or record a same-image GCC link map.

    The replay is written in the research directory. It does not replace the
    runtime image or rebuild the runtime.
    """
    from gambit_smp.framework import relative
    from gambit_smp.native_capabilities import runtime_identity_document
    from gambit_smp.recipes import tree_identity
    source = relative(ctx.root, args["source"])
    if not source.is_dir() or not (source / "gsi" / "gsi").is_file():
        raise ValueError("observation runtime tree is absent")
    if digest(source / "gsi" / "gsi") != args["gsiSha256"]:
        raise ValueError("observation runtime GSI differs from the declared digest")
    if "retainedRuntime" in args:
        return retained_observation_runtime(args, ctx, source)
    code, symbols, timeout, _ = execute(["/usr/bin/nm", "-gU", str(source / "gsi" / "gsi")], source, 15)
    if code != 0 or timeout or SYMBOL not in symbols:
        raise ValueError("observation runtime does not export the rest observer")
    ctx.lease_workspace(source, tree_identity(source))
    document = runtime_identity_document(source)
    path = ctx.directory / "identity.json"
    path.write_text(json.dumps(document, indent=2) + "\n")
    link_map = replay_link_map(source, ctx)
    return {"outputs": {**ctx.publish("identity", "runtime-identity", path),
                        **ctx.publish("runtime", "source-runtime", source)},
            "linkMap": link_map,
            "buildClosure": build_closure(source, ctx, link_map["members"]),
            "runtimeAdmitted": False,
            "claim": "published-observation-runtime-is-not-native-admission"}

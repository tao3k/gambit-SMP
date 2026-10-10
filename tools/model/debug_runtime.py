#!/usr/bin/env python3
"""Isolate collector/sync debug symbols without changing candidate ABI/artifacts."""
import argparse
import json
from pathlib import Path
import shlex
import shutil
import subprocess
import textwrap

from check_gambit import digest, execute, native_identity


def capture_command(binary, runtime, script, cwd, processors, observe):
    option = (f"-:p{processors},~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},"
              f"~~include={runtime / 'include'}")
    body = textwrap.dedent(f"""\
        import time
        lldb.debugger.SetAsync(False)
        info=lldb.SBLaunchInfo({[option, str(script)]!r})
        info.SetWorkingDirectory({str(cwd)!r})
        info.SetLaunchFlags(lldb.eLaunchFlagStopAtEntry)
        error=lldb.SBError()
        p=lldb.debugger.GetSelectedTarget().Launch(info,error)
        assert error.Success(),str(error)
        try:
            signals=p.GetUnixSignals()
            alarm=signals.GetSignalNumberFromName('SIGALRM')
            stop_signal=signals.GetSignalNumberFromName('SIGSTOP')
            signals.SetShouldStop(alarm,False)
            signals.SetShouldNotify(alarm,False)
            signals.SetShouldSuppress(alarm,False)
            initial_stop=p.GetStopID()
            lldb.debugger.SetAsync(True)
            continued=p.Continue()
            assert continued.Success(),str(continued)
            end=time.monotonic()+{observe!r}
            while time.monotonic()<end:
                state=p.GetState()
                if state in (lldb.eStateExited,lldb.eStateCrashed): break
                if state==lldb.eStateStopped and p.GetStopID()!=initial_stop and any(
                    t.GetStopReason() in (lldb.eStopReasonBreakpoint,lldb.eStopReasonException)
                    or (t.GetStopReason()==lldb.eStopReasonSignal
                        and t.GetStopReasonDataAtIndex(0) not in (alarm,stop_signal)) for t in p): break
                time.sleep(0.05)
            if p.GetState() in (lldb.eStateRunning,lldb.eStateStepping):
                stopped=p.Stop()
                assert stopped.Success(),str(stopped)
                end=time.monotonic()+2
                while p.GetState()!=lldb.eStateStopped and time.monotonic()<end:
                    time.sleep(0.05)
            print('DIAGNOSTIC-STATE',p.GetState(),'STOP-ID',p.GetStopID(),'INITIAL',initial_stop)
            if p.GetState()==lldb.eStateStopped:
                for thread in p:
                    print('THREAD',thread.GetIndexID(),'REASON',thread.GetStopReason(),
                          'DATA',thread.GetStopReasonDataAtIndex(0))
                    for frame in thread:
                        stream=lldb.SBStream()
                        frame.GetDescription(stream)
                        print(stream.GetData())
                    for frame in thread:
                        name=frame.GetFunctionName() or ''
                        if any(s in name for s in ('mark_array','next_msection_without_locking','barrier_sync_op','mark_reachable_from_marked')):
                            print('LOCALS',thread.GetIndexID(),name)
                            for variable in frame.GetVariables(True,True,False,True):
                                print(variable.GetTypeName(),variable.GetName(),variable.GetValue(),variable.GetError())
                            ps=frame.FindVariable('___ps')
                            if ps.IsValid():
                                state=ps.Dereference()
                                for field in ('sync_id0','sync_id1','sync_id2'):
                                    value=state.GetChildMemberWithName(field)
                                    print('MAILBOX',field,value.GetValue(),value.GetError())
                                for field in ('sync_op0','sync_op1','sync_op2'):
                                    value=state.GetChildMemberWithName(field)
                                    print('MAILBOX',field,'op',value.GetChildMemberWithName('op').GetValue(),
                                          'arg0',value.GetChildMemberWithName('arg').GetChildAtIndex(0).GetValue())
                                for field in ('sop','sop1','sop2'):
                                    value=frame.FindVariable(field)
                                    if value.IsValid():
                                        print('LOCAL-OP',field,value.GetChildMemberWithName('op').GetValue(),
                                              value.GetChildMemberWithName('arg').GetChildAtIndex(0).GetValue())
                                vm=frame.FindVariable('___vms')
                                if vm.IsValid():
                                    vm_mem=vm.Dereference().GetChildMemberWithName('mem')
                                    for field in ('scan_workers_count_','nb_msections_assigned_','target_processor_count_'):
                                        value=vm_mem.GetChildMemberWithName(field)
                                        print('VM',field,value.GetValue(),value.GetChildAtIndex(0).GetValue(),value.GetChildAtIndex(1).GetValue())
                                mem=state.GetChildMemberWithName('mem')
                                for name in ('alloc_heap_ptr_','alloc_heap_limit_','stack_msection_','heap_msection_','tospace_offset_','traverse_weak_refs_'):
                                    value=mem.GetChildMemberWithName(name)
                                    print('PSTATE',name,value.GetValue(),value.GetError())
                            break
        finally:
            if p.GetState()!=lldb.eStateExited:
                print('INFERIOR-CLEANUP',p.Kill())
        """)
    return ["/usr/bin/lldb", "--batch", "-o", "breakpoint set -n ___fatal_error",
            "-o", "script exec(" + repr(body) + ")", "-o", "quit", str(binary)]


def make_command(directory, dependency, target):
    output = subprocess.check_output(
        ["make", "-n", "-W", dependency, target], cwd=directory, text=True)
    lines = output.strip().splitlines()
    if len(lines) != 1:
        raise ValueError("expected one compiler command; source layout needs audit")
    argv = shlex.split(lines[0])
    if "gcc" not in Path(argv[0]).name or argv.count("-o") != 1:
        raise ValueError("expected GNU GCC command with one output")
    return argv


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gambit", type=Path, required=True)
    parser.add_argument("--toolchain-receipt", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--program", choices=("gsi", "gsc"), default="gsi")
    parser.add_argument("--capture-script", type=Path)
    parser.add_argument("--processors", type=int, choices=(1, 2, 4), default=4)
    parser.add_argument("--observe", type=float, default=15)
    args = parser.parse_args()
    if not 0 < args.observe <= 60:
        parser.error("observe must be between 0 and 60 seconds")
    root, out = args.gambit.resolve(), args.out.resolve()
    identity = native_identity(root / "gsi/gsi", args.toolchain_receipt,
                              gsc=root / "gsc/gsc" if args.program == "gsc" else None)
    library = root / "lib/libgambit.a"
    if identity.get("librarySha256") != digest(library):
        raise ValueError("candidate archive digest mismatch")
    modules = ("mem", "setup")
    for module in modules:
        filename = f"lib/{module}.c"
        if identity.get("sourceFiles", {}).get(filename) != digest(root / filename):
            raise ValueError("candidate source digest mismatch: " + filename)
    compile_commands = {module: make_command(root / "lib", module + ".c", module + ".o")
                        for module in modules}
    link_command = make_command(root / args.program, "../lib/libgambit.a", args.program)
    out.mkdir(parents=True, exist_ok=False)
    receipt = {"diagnosticOnly": True, "candidate": identity, "steps": [],
               "checks": "collector and sync DWARF only; no consistency-check or ABI changes",
               "program": args.program}

    def run(name, argv, cwd):
        code, log, timeout, seconds = execute(argv, cwd, 120)
        (out / (name + ".log")).write_text(log)
        receipt["steps"].append(dict(name=name, argv=argv, exit=code,
                                    timeout=timeout, seconds=seconds))
        (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
        if code != 0 or timeout:
            raise RuntimeError(name + " failed; inspect isolated receipt")

    for module, compile_command in compile_commands.items():
        compile_command = [arg for arg in compile_command if not arg.startswith("-O")]
        compile_command[compile_command.index("-o") + 1] = str(out / (module + ".o"))
        compile_command.extend(["-O1", "-g", "-fno-omit-frame-pointer"])
        run("compile-" + module, compile_command, root / "lib")
    archive = out / "libgambit.a"
    shutil.copyfile(library, archive)
    run("archive", ["/usr/bin/ar", "r", str(archive)]
        + [str(out / (module + ".o")) for module in modules], out)
    run("index", ["/usr/bin/ranlib", str(archive)], out)
    if link_command.count("../lib/libgambit.a") != 1:
        raise ValueError("expected one candidate archive in link command")
    link_command[link_command.index("../lib/libgambit.a")] = str(archive)
    executable = out / args.program
    link_command[link_command.index("-o") + 1] = str(executable)
    run("link", link_command, root / args.program)
    receipt.update(binarySha256=digest(executable), librarySha256=digest(archive))
    if args.capture_script:
        command = capture_command(executable, root, args.capture_script.resolve(), out,
                                  args.processors, args.observe)
        run("capture", command, out)
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("DIAGNOSTIC-BUILD-OK; not a release or repaired candidate")


if __name__ == "__main__":
    main()

"""Bounded same-process LLDB observations, never native test admission."""
import json
import os
import time


def launch_environment():
    environment = {key: val for key, val in os.environ.items()
                   if key not in ("SDKROOT", "LIBRARY_PATH", "CPATH")}
    environment["PATH"] = "/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    return [key + "=" + val for key, val in sorted(environment.items())]


def admitted_capture(output, count):
    lines = output.splitlines()
    rows = [line[len("SNAPSHOT-RECEIPT "):] for line in lines if line.startswith("SNAPSHOT-RECEIPT ")]
    if len(rows) != 1 or lines.count("SNAPSHOT-CAPTURE-OK") != 1 or "Traceback (most recent call last)" in output:
        raise ValueError("missing or failed debugger capture")
    receipt = json.loads(rows[0])
    samples = receipt["samples"]
    if (receipt.get("diagnosticOnly") is not True or len(samples) != count
        or len({s["stopId"] for s in samples}) != count
        or any(not any("mailboxes" in t for t in s["threads"]) for s in samples)):
        raise ValueError("incomplete or duplicate same-process observations")
    return receipt


def value(item):
    if not item.IsValid() or item.GetError().Fail():
        return None
    return item.GetValue()


def snapshot(lldb, process, require_barrier=True):
    if process.GetState() != lldb.eStateStopped:
        raise RuntimeError("snapshot requires a stopped process")
    threads = []
    for thread in process:
        frames = []
        state = None
        vm = None
        for frame in thread:
            line = frame.GetLineEntry()
            frames.append({"function": frame.GetFunctionName(),
                           "file": line.GetFileSpec().GetFilename(), "line": line.GetLine(),
                           "pc": frame.GetPC(),
                           "locals": {v.GetName(): value(v) for v in
                                      frame.GetVariables(True, True, False, True)}
                           if line.GetFileSpec().GetFilename() in ("mem.c", "setup.c") else {}})
            if "barrier_sync_op" in (frame.GetFunctionName() or ""):
                state = frame.FindVariable("___ps").Dereference()
                vm = frame.FindVariable("___vms").Dereference()
        row = {"thread": thread.GetIndexID(), "frames": frames,
               "reason": thread.GetStopReason(), "description": thread.GetStopDescription(1024)}
        if state is not None and state.IsValid():
            row["pstate"] = value(state.AddressOf())
            row["mailboxes"] = {name: value(state.GetChildMemberWithName(name))
                                for name in ("sync_id0", "sync_id1", "sync_id2")}
            mem = state.GetChildMemberWithName("mem")
            row["memory"] = {name: value(mem.GetChildMemberWithName(name)) for name in
                             ("tospace_offset_", "traverse_weak_refs_")}
        if vm is not None and vm.IsValid():
            mem = vm.GetChildMemberWithName("mem")
            workers = mem.GetChildMemberWithName("scan_workers_count_")
            row["vm"] = {"processors": value(vm.GetChildMemberWithName("processor_count")),
                         "scanWorkers": [value(workers.GetChildAtIndex(i)) for i in (0, 1)]}
            row["vm"]["heap"] = {name: value(mem.GetChildMemberWithName(name)) for name in
                                  ("nb_gcs_", "heap_size_", "occupied_words_movable_",
                                   "occupied_words_still_", "nb_msections_assigned_",
                                   "nb_msections_stacks_", "overflow_reserve_")}
            sections = mem.GetChildMemberWithName("the_msections_").Dereference()
            row["vm"]["heap"]["nb_sections"] = value(sections.GetChildMemberWithName("nb_sections"))
        threads.append(row)
    if require_barrier and not any("mailboxes" in row for row in threads):
        raise RuntimeError("no symbol-bound barrier frame; capture is not GC evidence")
    return {"stopId": process.GetStopID(), "threads": threads}


def observe(lldb, target, arguments, cwd, first, interval, count):
    if not (1 <= count <= 3 and 0 < first <= 60 and 0 < interval <= 10):
        raise ValueError("invalid bounded snapshot schedule")
    debugger = target.GetDebugger()
    debugger.SetAsync(False)
    launch = lldb.SBLaunchInfo(arguments)
    launch.SetEnvironmentEntries(launch_environment(), False)
    launch.SetWorkingDirectory(cwd)
    launch.SetLaunchFlags(lldb.eLaunchFlagStopAtEntry)
    error = lldb.SBError()
    process = target.Launch(launch, error)
    if error.Fail():
        raise RuntimeError(str(error))
    samples = []
    try:
        signals = process.GetUnixSignals()
        alarm = signals.GetSignalNumberFromName("SIGALRM")
        signals.SetShouldStop(alarm, False)
        signals.SetShouldNotify(alarm, False)
        signals.SetShouldSuppress(alarm, False)
        debugger.SetAsync(True)
        for index in range(count):
            error = process.Continue()
            if error.Fail():
                raise RuntimeError(str(error))
            deadline = time.monotonic() + (first if index == 0 else interval)
            while time.monotonic() < deadline:
                if process.GetState() in (lldb.eStateExited, lldb.eStateCrashed):
                    raise RuntimeError("inferior terminated before scheduled observation")
                time.sleep(0.02)
            error = process.Stop()
            if error.Fail():
                raise RuntimeError(str(error))
            deadline = time.monotonic() + 2
            while process.GetState() != lldb.eStateStopped and time.monotonic() < deadline:
                time.sleep(0.02)
            samples.append(snapshot(lldb, process))
    finally:
        if process.GetState() != lldb.eStateExited:
            error = process.Kill()
            if error.Fail():
                raise RuntimeError("inferior cleanup failed: " + str(error))
    print("SNAPSHOT-RECEIPT " + json.dumps({"diagnosticOnly": True, "samples": samples}))
    print("SNAPSHOT-CAPTURE-OK")


def observe_failure(lldb, target, arguments, cwd, timeout):
    if not 0 < timeout <= 60:
        raise ValueError("invalid failure observation limit")
    debugger = target.GetDebugger()
    debugger.SetAsync(False)
    launch = lldb.SBLaunchInfo(arguments)
    launch.SetEnvironmentEntries(launch_environment(), False)
    launch.SetWorkingDirectory(cwd)
    launch.SetLaunchFlags(lldb.eLaunchFlagStopAtEntry)
    error = lldb.SBError()
    process = target.Launch(launch, error)
    if error.Fail():
        raise RuntimeError(str(error))
    evidence = None
    try:
        signals = process.GetUnixSignals()
        alarm = signals.GetSignalNumberFromName("SIGALRM")
        signals.SetShouldStop(alarm, False)
        signals.SetShouldNotify(alarm, False)
        signals.SetShouldSuppress(alarm, False)
        initial = process.GetStopID()
        debugger.SetAsync(True)
        error = process.Continue()
        if error.Fail():
            raise RuntimeError(str(error))
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if process.GetState() == lldb.eStateExited:
                raise RuntimeError("inferior exited without an observed failure")
            if process.GetState() == lldb.eStateStopped and process.GetStopID() != initial:
                fatal = any(t.GetStopReason() == lldb.eStopReasonException or
                            (t.GetStopReason() == lldb.eStopReasonSignal and
                             t.GetStopReasonDataAtIndex(0) in
                             [signals.GetSignalNumberFromName(n) for n in
                              ("SIGBUS", "SIGSEGV", "SIGILL", "SIGABRT")]) for t in process)
                if fatal:
                    evidence = snapshot(lldb, process, require_barrier=False)
                    break
            time.sleep(0.02)
        if evidence is None:
            raise RuntimeError("no fatal stop before diagnostic deadline")
    finally:
        if process.GetState() != lldb.eStateExited:
            error = process.Kill()
            if error.Fail():
                raise RuntimeError("inferior cleanup failed: " + str(error))
    print("FAILURE-RECEIPT " + json.dumps({"diagnosticOnly": True, "snapshot": evidence}))
    print("FAILURE-CAPTURE-OK")

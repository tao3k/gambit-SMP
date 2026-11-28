"""Bounded Darwin sampling of an already-owned child, never runtime admission."""
import json
from pathlib import Path
import time

from gambit_smp.framework import digest


def sample(process, cwd, budget, environment, diagnostic):
    directory = Path(diagnostic["directory"])
    tool = Path(diagnostic["tool"])
    report = directory / "stack-sample.txt"
    receipt = directory / "stack-sample.json"
    if report.exists() or receipt.exists():
        raise ValueError("fresh diagnostic observation paths required")
    if digest(tool) != diagnostic["toolSha256"]:
        raise ValueError("sealed Darwin sampling tool drift")
    if process.poll() is not None:
        receipt.write_text(json.dumps({"schema": "owned-child-stack-observation.v1",
            "status": "CHILD_COMPLETED", "runtimeAdmitted": False}) + "\n")
        return
    from gambit_smp.process_observation import capture
    started = time.monotonic()
    deadline=started+budget
    files_tool=diagnostic.get('openFilesTool')
    snapshots=[]
    if files_tool is not None:
        files_tool=Path(files_tool)
        if digest(files_tool)!=diagnostic.get('openFilesToolSha256'):
            raise ValueError('sealed Darwin open-file observer drift')
    def open_files(role):
        remaining=deadline-time.monotonic()
        if files_tool is None or remaining<=0 or process.poll() is not None:return
        argv=[str(files_tool),'-a','-p',str(process.pid),'-n','-P','-Fpcftn']
        observed=capture(argv,cwd,min(1.5,remaining),environment)
        output=directory/(role+'.stdout');error=directory/(role+'.stderr')
        output.write_text(observed.stdout);error.write_text(observed.stderr)
        snapshots.append(dict(role=role,argv=argv,exit=observed.exit,timeout=observed.timeout,
            parentReaped=observed.exit is not None,processGroupQuiescent=observed.group_quiescent,
            startedAt=observed.started_at,endedAt=observed.ended_at,
            stdoutSha256=digest(output),stderrSha256=digest(error)))
    open_files('open-files-before')
    argv = [str(tool), str(process.pid), "1", "-file", str(report)]
    remaining=deadline-time.monotonic()
    if remaining<=0:raise TimeoutError('owned stack diagnostic budget exhausted')
    observed=capture(argv,cwd,remaining,environment)
    (directory / "stack-sample.stdout").write_text(observed.stdout)
    (directory / "stack-sample.stderr").write_text(observed.stderr)
    open_files('open-files-after')
    receipt.write_text(json.dumps({"schema": "owned-child-stack-observation.v1",
        "targetPid": process.pid, "argv": argv, "toolSha256": diagnostic["toolSha256"],
        "exit": observed.exit, "timeout": observed.timeout,
        "seconds": time.monotonic() - started,
        "reportSha256": digest(report) if report.is_file() else None,
        "openFileSnapshots":snapshots,"fdToSyscallAssociationProved":False,
        "openFilesToolSha256":diagnostic.get('openFilesToolSha256'),
        "runtimeAdmitted": False}, indent=2) + "\n")
    if digest(tool) != diagnostic["toolSha256"]:
        raise ValueError("Darwin sampling tool changed during observation")
    if files_tool is not None and digest(files_tool)!=diagnostic['openFilesToolSha256']:
        raise ValueError('Darwin open-file observer changed during observation')

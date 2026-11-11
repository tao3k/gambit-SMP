"""Apply the existing delta in its original producer lease; record native controls."""
from pathlib import Path
import hashlib
import json
import os
import sys
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
from gambit_smp.framework import execute

ROOT = Path(__file__).resolve().parents[3]
BUILD = ROOT / ".cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6"
SOURCE = BUILD / "source"
SNAPSHOT = ROOT / ".cache/tasks/repair-9-12/processes/audit/runs/5ca6966c39c442c39a2f5bf73ae7563e/outputs/independent-wait-backend-proposal/prepared/lib/os_io.c"

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    prior_path = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else None
    prior = json.loads(prior_path.read_text()) if prior_path else None
    proved_env = json.loads((BUILD / "configure-proof.json").read_text())["commands"][0]["environment"]
    env = dict(os.environ); env.update(proved_env)
    with w.execution_scope(ROOT, "repair-9-12"):
        out = w.task_output(ROOT, ROOT / ".cache/native-wait-backend")
        out.mkdir(parents=True, exist_ok=True)
        receipt = dict(schema="native-wait-backend.v1", stages=[], runtimeModified=False,
                       coordinatorImplemented=False, nativeAdmitted=False, fullInventoryExecuted=False)
        receipt["prior"] = str(prior_path) if prior_path else None
        receipt["sourceConfigureEnvironment"] = proved_env
        def save():
            (out / "receipt.json").write_text(json.dumps(receipt, indent=2))
        def run(name, argv, cwd, cap, required=False):
            meta = {}
            rc, log, timed, elapsed = execute(argv, cwd, cap, env=env, metadata=meta)
            (out / (name + ".log")).write_text(log)
            row = dict(name=name, exit=rc, timedOut=timed, seconds=elapsed, process=meta)
            receipt["stages"].append(row); save()
            print(name, rc, timed, elapsed, log[-400:], flush=True)
            if required and (rc != 0 or timed):
                raise RuntimeError(name + " failed")
            return row, log
        with workspace_lease(ROOT, SOURCE, tree_identity(SOURCE)):
            files = ["lib/os_io.c", "lib/os_io.o", "lib/libgambit.a", "gsi/gsi"]
            receipt["before"] = {name: sha(SOURCE / name) for name in files}
            save()
            option = "-:p11,~~lib=" + str(SOURCE / "lib") + ",~~bin=" + str(SOURCE / "bin") + ",~~include=" + str(SOURCE / "include")
            def gsi(name, program, cap, required=False):
                script = out / (name + ".scm"); script.write_text(program)
                return run(name, [str(SOURCE / "gsi/gsi"), option, str(script)], out, cap, required)
            program = '(let loop ((i 0)) (if (< i 5) (begin (write (list "enter" i))(newline)(force-output)(##os-condvar-select! #f #t)(loop (+ i 1))) (begin (display "INDEPENDENT-RETURN\n")(force-output))))'
            if prior is None:
                gsi("baseline-smoke", '(display "NATIVE-SMOKE\n")(force-output)', 15, True)
                gsi("baseline-independent-return", program, 3)
                assert receipt["before"]["lib/os_io.c"] == "e17daf7fb752e9eb85b8b6e6e4672d81ae05435332392cff273ceaf6f5f223fa"
                assert sha(SNAPSHOT) == "685d6c8680de87c18de802e13b4be5884d86bd3a5c14a8f17e1b5fd66e75ac0e"
                state = json.loads((BUILD / "source-state.json").read_text())
                delta = out / "delta"; (delta / "lib").mkdir(parents=True)
                (delta / "lib/os_io.c").write_bytes(SNAPSHOT.read_bytes())
                incoming = dict(state["inputs"]); incoming.update(tree_identity(delta))
                w.sync_build_source(ROOT, BUILD, delta, mutable=state.get("mutable", []), inventory=incoming, overlay_files=state.get("overlayFiles", []))
            else:
                assert prior["runtimeModified"] and not prior["nativeAdmitted"]
                assert receipt["before"]["lib/os_io.c"] == "685d6c8680de87c18de802e13b4be5884d86bd3a5c14a8f17e1b5fd66e75ac0e"
            receipt["runtimeModified"] = True; save()
            def remaining(name, original):
                spent = sum(row["seconds"] for row in prior["stages"] if row["name"] == name) if prior else 0
                return original - spent
            try:
                run("build-backend", ["make", "-C", str(SOURCE / "lib"), "-W", "os_io.c", "os_io.o", "libgambit.a"], SOURCE, remaining("build-backend", 300), True)
                run("link-gsi", ["make", "-C", str(SOURCE / "gsi"), "gsi"], SOURCE, remaining("link-gsi", 60), True)
                receipt["after"] = {name: sha(SOURCE / name) for name in files}; save()
                row, log = gsi("candidate-independent-return", program, 15)
                receipt["independentReturnPassed"] = row["exit"] == 0 and not row["timedOut"] and "INDEPENDENT-RETURN" in log
                deadline = '(let ((start (##current-time-point))) (thread-sleep! 0.25) (let ((elapsed (- (##current-time-point) start))) (write (list "REAL-DEADLINE" elapsed))(newline)(force-output)(if (< elapsed 0.24) (exit 21))))'
                row, log = gsi("candidate-real-deadline", deadline, 15)
                receipt["realDeadlinePassed"] = row["exit"] == 0 and not row["timedOut"] and "REAL-DEADLINE" in log
            finally:
                w.checkpoint_build_source(SOURCE, phase="building", backendNativeExperiment=dict(receipt=str(out / "receipt.json"), diagnosticOnly=True, runtimeAdmitted=False))
                save()
        print(out, flush=True)

if __name__ == "__main__":
    main()

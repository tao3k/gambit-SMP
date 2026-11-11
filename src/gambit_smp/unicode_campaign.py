"""Source-bound scalar equivalence using the shared bounded execution framework."""
import argparse
from dataclasses import asdict
import json
from pathlib import Path
import shutil
import time

from gambit_smp.bootstrap_runtime import compiler_binding
from gambit_smp.framework import available_processors, digest, gnu_build_driver, gnu_compiler, parallel_jobs
from gambit_smp.process_observation import capture
from gambit_smp.runtime_identity import check
from gambit_smp.unicode_scalar_records import compare


def accepted(observation, witness=None):
    return (observation.exit == 0 and not observation.timeout
            and observation.group_quiescent is True
            and (witness is None or observation.stdout.splitlines().count(witness) == 1))


def run(pairs, fixture, gcc, out, budget):
    if len(pairs) != 2 or budget <= 0:
        raise ValueError("two source-bound runtimes and a positive whole budget required")
    compiler, environment, version = gnu_compiler(gcc)
    identities = [json.loads(identity.read_text()) for _, identity in pairs]
    drivers = []
    for (runtime, _), identity in zip(pairs, identities):
        check(runtime, identity)
        compiler_binding(runtime, compiler)
        drivers.append(gnu_build_driver(runtime, compiler))
    out.mkdir(parents=True, exist_ok=False)
    capacity = available_processors()
    jobs = min(2, capacity)
    population = max(1, capacity // jobs)
    fixture_hash = digest(fixture)
    start = time.monotonic()

    def worker(index, deadline):
        runtime, identity_path = pairs[index]
        work = out / str(index)
        records = work / "records"
        records.mkdir(parents=True)
        copied = work / fixture.name
        shutil.copyfile(fixture, copied)
        option = (f"~~bin={runtime / 'bin'},~~lib={runtime / 'lib'},"
                  f"~~include={runtime / 'include'}")
        env = dict(environment, GAMBIT_SMP_UNICODE_DIRECTORY=str(records))
        env["GAMBOPT"] = "p1," + option
        stages = []
        commands = [
            ("compile", [str(runtime / "gsc/gsc"), "-:p1," + option,
                         "-f", "-dynamic", "-o", "scalar.o1", copied.name], None),
            ("execute", [str(runtime / "gsi/gsi"), f"-:p{population}," + option,
                         "-f", "scalar.o1"], "NATIVE-OK:unicode_scalar_semantics"),
        ]
        for name, argv, witness in commands:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return dict(status="DENY", reason="whole campaign budget exhausted", stages=stages)
            observation = capture(argv, work, remaining, env)
            row = dict(stage=name, argv=argv, observation=asdict(observation),
                       accepted=accepted(observation, witness))
            stages.append(row)
            if not row["accepted"] or (name == "compile" and not (work / "scalar.o1").is_file()):
                return dict(status="DENY", stages=stages)
        check(runtime, identities[index])
        stable = digest(copied) == fixture_hash and gnu_build_driver(runtime, compiler) == drivers[index]
        return dict(status="PASS" if stable else "DENY", sourceStable=stable,
                    identitySha256=digest(identity_path), driver=drivers[index], stages=stages)

    observations = parallel_jobs(range(2), worker, jobs, budget)
    native_seconds = time.monotonic() - start
    receipt = dict(schema="gambit-unicode-campaign.v1", adapterSha256=digest(Path(__file__)),
                   fixtureSha256=fixture_hash, cpuCapacity=capacity, jobs=jobs,
                   populationPerRuntime=population, processorSelection="host-auto",
                   wholeCampaignBudget=budget, nativeSeconds=native_seconds,
                   compiler=version.splitlines()[0], observations=observations,
                   runtimeAdmitted=False, releaseAdmitted=False, performanceAdmitted=False,
                   status="DENY")
    if all(row["status"] == "PASS" for row in observations) and native_seconds <= budget:
        validation_start = time.monotonic()
        try:
            records = [{p.name: p.read_bytes() for p in (out / str(i) / "records").glob("*.bin")}
                       for i in range(2)]
            receipt["equivalence"] = compare(*records, population)
            receipt["status"] = "PASS"
        except ValueError as error:
            receipt["reason"] = str(error)
        receipt["validationSeconds"] = time.monotonic() - validation_start
    receipt["fixtureStable"] = digest(fixture) == fixture_hash
    if not receipt["fixtureStable"]:
        receipt["status"] = "DENY"
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", type=Path, action="append", required=True)
    parser.add_argument("--identity", type=Path, action="append", required=True)
    parser.add_argument("--fixture", type=Path, required=True)
    parser.add_argument("--gcc", type=Path, required=True)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument, required=True)
    parser.add_argument("--timeout", type=float, required=True)
    args = parser.parse_args()
    if len(args.runtime) != 2 or len(args.identity) != 2:
        parser.error("exactly two runtimes and two identities required")
    receipt = run(list(zip([p.resolve() for p in args.runtime], args.identity)),
                  args.fixture, args.gcc, args.out.resolve(), args.timeout)
    print(json.dumps({key: receipt.get(key) for key in
                      ("status", "nativeSeconds", "validationSeconds", "equivalence")}), flush=True)
    return 0 if receipt["status"] == "PASS" else 1


from gambit_smp.task_entry import managed_tool as _managed_tool
main = _managed_tool('unicode-campaign')(main)

if __name__ == '__main__':
    from gambit_smp.task_entry import tool_main
    raise SystemExit(tool_main('unicode-campaign',main))

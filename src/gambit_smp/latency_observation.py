"""Validate complete native timing populations; summarize, never admit a runtime."""
import json
import math
from pathlib import Path

from gambit_smp.framework import digest
from gambit_smp.recipes import fields


def validate_options(options):
    fields(options, ("path", "minimumSamples", "percentiles"), ("populationPlan",))
    if "populationPlan" in options:
        plan = options["populationPlan"]
        fields(plan, ("reservedPositions", "minimumPopulation", "minimumProcessorsPerOwner"))
        if any(type(value) is not int or value < 1 for value in plan.values()):
            raise ValueError("positive integer CPU-derived population plan required")
    path = options["path"]
    if not isinstance(path, str) or Path(path).name != path or not path.endswith(".jsonl"):
        raise ValueError("latency samples require a local JSONL basename")
    if type(options["minimumSamples"]) is not int or options["minimumSamples"] < 100:
        raise ValueError("latency percentile population must contain at least 100 samples")
    ps = options["percentiles"]
    if (not isinstance(ps, list) or not ps or len(set(ps)) != len(ps)
            or any(type(p) is not int or not 0 < p < 100 for p in ps)):
        raise ValueError("distinct integer percentiles in (0,100) required")


def summarize(directory, options, cpu, run_seconds):
    validate_options(options)
    path = directory / options["path"]
    if path.is_symlink() or not path.is_file() or path.stat().st_size > 16 * 1024 * 1024:
        raise ValueError("bounded regular native latency sample file required")
    before = digest(path)
    with path.open() as stream:
        header = json.loads(next(stream))
        fields(header, ("schema", "cpuCapacity", "groups"))
        if header["schema"] != "native-latency-samples.v1" or header["cpuCapacity"] != cpu:
            raise ValueError("native sample host capacity differs from observed host")
        groups = {}
        for group in header["groups"]:
            fields(group, ("population", "owners", "rounds"))
            if any(type(group[key]) is not int or group[key] <= 0 for key in group):
                raise ValueError("positive integer latency population dimensions required")
            population = group["population"]
            if (population in groups or group["owners"] > cpu
                    or group["owners"] * group["rounds"] < options["minimumSamples"]):
                raise ValueError("unique sufficiently sampled latency populations required")
            groups[population] = {**group, "values": {}, "samples": []}
        if not groups:
            raise ValueError("native latency populations must not be empty")
        if "populationPlan" in options:
            plan = options["populationPlan"]
            maximum = (cpu - plan["reservedPositions"]) // plan["minimumProcessorsPerOwner"]
            expected = set(range(plan["minimumPopulation"], maximum + 1))
            if not expected or set(groups) != expected or any(
                    group["owners"] != population for population, group in groups.items()):
                raise ValueError("native latency groups differ from the CPU-derived complete population plan")
        for index, line in enumerate(stream):
            if index >= 200000:
                raise ValueError("native latency row bound exceeded")
            row = json.loads(line)
            fields(row, ("population", "owner", "round", "nanoseconds"))
            if any(type(value) is not int for value in row.values()):
                raise ValueError("integer raw monotonic latency samples required")
            group = groups.get(row["population"])
            if (group is None or not 1 <= row["owner"] <= group["owners"]
                    or not 0 <= row["round"] < group["rounds"]
                    or not 0 < row["nanoseconds"] <= math.ceil(run_seconds * 1e9)):
                raise ValueError("native latency sample outside observed execution population")
            key = row["owner"], row["round"]
            if key in group["values"]:
                raise ValueError("duplicate native latency trajectory")
            group["values"][key] = row["nanoseconds"]
            group["samples"].append(row["nanoseconds"])
    if digest(path) != before:
        raise ValueError("native latency samples changed while summarizing")
    summaries = []
    for population, group in sorted(groups.items()):
        samples = sorted(group["samples"])
        if len(samples) != group["owners"] * group["rounds"]:
            raise ValueError("incomplete native latency population; retain as failed observation")
        summaries.append({"population": population, "owners": group["owners"],
            "rounds": group["rounds"], "samples": len(samples),
            "minNanoseconds": samples[0], "maxNanoseconds": samples[-1],
            "percentilesNanoseconds": {str(p): samples[math.ceil(len(samples) * p / 100) - 1]
                                       for p in options["percentiles"]}})
    return {"schema": "native-latency-observation.v1", "rawPath": path.name,
            "rawSha256": before, "cpuCapacity": cpu, "groups": summaries,
            "populationPlan": options.get("populationPlan"),
            "method": "nearest-rank; correlated trajectories, not confidence intervals",
            "runtimeAdmitted": False, "performanceAdmitted": False}

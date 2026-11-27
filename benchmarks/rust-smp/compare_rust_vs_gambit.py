#!/usr/bin/env python3
"""Paired Rust (Tokio + Rayon) vs Gambit Scheme SMP multicore comparison runner.

Runs matched workloads across 1..N cores (up to full machine saturation),
compares work_real, scaling speedup, CPU utilization, GC pause %, and RSS,
and writes structured JSON + Markdown summary into .cache/benchmarks/rust-vs-gambit/.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
BENCH_DIR = Path(__file__).resolve().parent


def load_multicore_module():
    mod_path = REPO_ROOT / "vendor/gambit/tests/smp/multicore/run-multicore-suite.py"
    spec = importlib.util.spec_from_file_location("run_multicore_suite", mod_path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def run_gambit_scaling(
    runtime_dir: Path,
    topologies: list[str],
    workers: int,
    repeats: int,
) -> dict:
    mc = load_multicore_module()
    runtime_dir = runtime_dir.resolve()
    gsi = runtime_dir / "gsi/gsi"
    gsc = runtime_dir / "gsc/gsc"
    if not gsi.is_file() or not gsc.is_file():
        raise FileNotFoundError(f"Built Gambit runtime not found under {runtime_dir}")

    env = mc.build_env(runtime_dir)
    summary: dict[str, dict[str, dict]] = {}

    with tempfile.TemporaryDirectory(prefix="gambit-vs-rust-") as tmp:
        work = Path(tmp)
        for sname, (marker, extra_opt, code) in mc.SCALING_WORKLOADS.items():
            # Parameterize worker count if != 8
            patched_code = code.lstrip()
            if workers != 8:
                patched_code = (
                    patched_code.replace("(= i 8)", f"(= i {workers})")
                    .replace("(= w 8)", f"(= w {workers})")
                    .replace("(make-vector 8 #f)", f"(make-vector {workers} #f)")
                    .replace("(n-workers 8)", f"(n-workers {workers})")
                    .replace("workers=8", f"workers={workers}")
                )
            scm = work / f"{sname}.scm"
            scm.write_text(patched_code)
            o1 = mc.compile_o1(gsc, runtime_dir, scm, work / f"{sname}.o1", work, env)

            by_topo: dict[str, dict] = {}
            p1_wall = None
            for topo in topologies:
                runs = []
                for _ in range(repeats):
                    r = mc.run_timed(
                        [str(gsi), f"-:={runtime_dir},{topo}{extra_opt}", str(o1)],
                        work,
                        env,
                        timeout=120,
                        max_footprint_bytes=4 * 1024 * 1024 * 1024,
                    )
                    if r["exit"] != 0 or marker not in r["stdout"]:
                        raise RuntimeError(f"Gambit {sname}[{topo}] failed: {r}")
                    m_w = mc.WORK_REAL_RE.search(r["stdout"])
                    m_g = mc.GC_REAL_RE.search(r["stdout"])
                    m_c = mc.GCS_RE.search(r["stdout"])
                    work_s = float(m_w.group(1)) if m_w else r["realSeconds"]
                    gc_s = float(m_g.group(1)) if m_g else 0.0
                    gcs = int(m_c.group(1)) if m_c else 0
                    runs.append((work_s, r["cpuSeconds"], gc_s, gcs, r["peakRssMiB"]))

                runs.sort(key=lambda x: x[0])
                med = runs[len(runs) // 2]
                work_s, cpu_s, gc_s, gcs, rss_mib = med
                if topo == "p1" and work_s > 0:
                    p1_wall = work_s
                p_num = int(topo[1:])
                speedup = round(p1_wall / work_s, 2) if (p1_wall and work_s > 0) else 1.0
                eff = round(speedup / p_num, 2)
                gc_pct = round(100.0 * gc_s / work_s, 1) if work_s > 0 else 0.0
                by_topo[topo] = {
                    "threads": p_num,
                    "workers": workers,
                    "workReal": round(work_s, 4),
                    "cpu": round(cpu_s, 4),
                    "speedup": speedup,
                    "efficiency": eff,
                    "gcCount": gcs,
                    "gcReal": round(gc_s, 4),
                    "gcPausePct": gc_pct,
                    "rssMiB": round(rss_mib, 2),
                }
                print(
                    f"[GAMBIT] {sname:26s} {topo:3s}: work={work_s:.4f}s cpu={cpu_s:.3f}s "
                    f"S={speedup:5.2f}x E={eff:.2f} gc={gc_s:.3f}s({gc_pct:4.1f}%) rss={rss_mib:.1f}MiB",
                    flush=True,
                )
            summary[sname] = by_topo
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare Rust (Tokio+Rayon) vs Gambit Scheme SMP scaling.")
    parser.add_argument(
        "--gambit-runtime",
        type=Path,
        default=REPO_ROOT
        / ".cache/tasks/modern-c-frame-contract/build/gambit-core/b27ea5d13cf7b840b9b942b1dc1b813d37b03d88e91c46a55814dc3cbcbb5a81/source",
    )
    parser.add_argument("--rust-bin", type=Path, default=REPO_ROOT / ".cache/rust-smp-target/release/rust-smp-bench")
    parser.add_argument("--topologies", default="p1,p2,p4,p6,p8,p12")
    parser.add_argument("--workers", type=int, default=12)
    parser.add_argument("--repeats", type=int, default=3)
    parser.add_argument("--out-dir", type=Path, default=REPO_ROOT / ".cache/benchmarks/rust-vs-gambit")
    args = parser.parse_args()

    topologies = [t.strip() for t in args.topologies.split(",") if t.strip()]
    args.out_dir.mkdir(parents=True, exist_ok=True)
    rust_json = args.out_dir / f"rust_w{args.workers}.json"

    print(f"Running Rust benchmark ({args.rust_bin}) workers={args.workers} topologies={topologies}...")
    subprocess.run(
        [
            str(args.rust_bin),
            "--threads",
            ",".join(t.lstrip("p") for t in topologies),
            "--workers",
            str(args.workers),
            "--repeats",
            str(args.repeats),
            "--json-out",
            str(rust_json),
        ],
        check=True,
    )
    rust_data = json.loads(rust_json.read_text())

    print(f"\nRunning Gambit SMP benchmark ({args.gambit_runtime}) workers={args.workers} topologies={topologies}...")
    gambit_summary = run_gambit_scaling(args.gambit_runtime, topologies, args.workers, args.repeats)

    combined = {
        "schema": "rust-vs-gambit-smp-comparison.v1",
        "workers": args.workers,
        "repeats": args.repeats,
        "topologies": topologies,
        "rust": rust_data["scalingSummary"],
        "gambit": gambit_summary,
    }
    out_json = args.out_dir / f"comparison_w{args.workers}.json"
    out_json.write_text(json.dumps(combined, indent=2) + "\n")

    print("\n=== SIDE-BY-SIDE RATIO (Gambit / Rust work_real; lower = closer to Rust) ===")
    for wname, g_by_t in gambit_summary.items():
        r_by_t = rust_data["scalingSummary"].get(wname, {})
        parts = []
        for t in topologies:
            g = g_by_t[t]["workReal"]
            r = r_by_t[t]["workReal"]
            ratio = g / r if r > 0 else float("inf")
            parts.append(f"{t}: {g:.4f}s vs {r:.4f}s ({ratio:.1f}x)")
        print(f"  {wname:24s} | " + " | ".join(parts))

    print(f"\nSaved combined comparison to {out_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

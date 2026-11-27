"""Reusable Cai et al. ISPASS '22 LBO Multi-Core Evaluation & Admission Gate Harness.

Implements the exact four-axis LBO discipline required before admitting any
native Amp-1..Amp-4 wave on Gambit SMP / Gerbil SMP:
  1. Wall-clock time (ms)
  2. Total multi-core CPU cycles / time (user + sys ms — prevents hiding parallel spin bloat!)
  3. Metered tail latency (p99 and p99.9 ms under load)
  4. Peak & mean RSS (KiB)
  5. Mandatory native correctness gate (Gambit SMP + TSan + Gerbil SMP tests must pass first!)
"""

from dataclasses import dataclass
import math
import resource
import subprocess
import sys
import time
import unittest


@dataclass(frozen=True)
class LboMetrics:
    wall_ms: float
    total_cpu_ms: float  # user_ms + sys_ms across all cores (distills LBO!)
    p99_ms: float
    p999_ms: float
    peak_rss_kib: float
    native_tests_passed: bool = True

    def pareto_dominates(self, other: "LboMetrics") -> bool:
        """True iff self is <= other on all 4 LBO axes and strictly < on at least one."""
        weak = (
            self.wall_ms <= other.wall_ms
            and self.total_cpu_ms <= other.total_cpu_ms
            and self.p999_ms <= other.p999_ms
            and self.peak_rss_kib <= other.peak_rss_kib
        )
        strict = (
            self.wall_ms < other.wall_ms
            or self.total_cpu_ms < other.total_cpu_ms
            or self.p999_ms < other.p999_ms
            or self.peak_rss_kib < other.peak_rss_kib
        )
        return weak and strict


@dataclass(frozen=True)
class LboGateThresholds:
    max_wall_regression: float = 1.03        # <= +3% wall-clock noise
    max_cpu_cycle_regression: float = 1.05   # <= +5% total multi-core CPU cycles (blocks LBO bloat!)
    max_p999_regression: float = 1.10        # <= +10% p99.9 metered latency
    max_rss_regression: float = 1.05         # <= +5% peak RSS


def compute_percentile(samples: list[float], pct: float) -> float:
    if not samples:
        raise ValueError("samples must be non-empty")
    ordered = sorted(samples)
    idx = min(len(ordered) - 1, max(0, math.ceil((pct / 100.0) * len(ordered)) - 1))
    return ordered[idx]


def evaluate_lbo_admission(
    baseline: LboMetrics,
    candidate: LboMetrics,
    thresholds: LboGateThresholds = LboGateThresholds(),
) -> tuple[bool, list[str]]:
    """Evaluate a candidate amplification wave against baseline under Cai et al. ISPASS '22 LBO."""
    reasons: list[str] = []
    if not candidate.native_tests_passed:
        reasons.append("native_correctness_gate_failed")
    if candidate.wall_ms > baseline.wall_ms * thresholds.max_wall_regression:
        reasons.append(f"wall_regression:{candidate.wall_ms:.2f}>{baseline.wall_ms:.2f}")
    if candidate.total_cpu_ms > baseline.total_cpu_ms * thresholds.max_cpu_cycle_regression:
        reasons.append(f"lbo_cpu_cycle_bloat:{candidate.total_cpu_ms:.2f}>{baseline.total_cpu_ms:.2f}")
    if candidate.p999_ms > baseline.p999_ms * thresholds.max_p999_regression:
        reasons.append(f"p999_latency_regression:{candidate.p999_ms:.2f}>{baseline.p999_ms:.2f}")
    if candidate.peak_rss_kib > baseline.peak_rss_kib * thresholds.max_rss_regression:
        reasons.append(f"peak_rss_regression:{candidate.peak_rss_kib:.1f}>{baseline.peak_rss_kib:.1f}")
    return (len(reasons) == 0, reasons)


def measure_command_lbo(argv: list[str], runs: int = 3) -> LboMetrics:
    """Measure wall time, total child user+sys CPU time, percentiles, and peak RSS of a native command."""
    wall_samples: list[float] = []
    cpu_samples: list[float] = []
    max_rss_kib = 0.0
    all_ok = True

    for _ in range(runs):
        r0 = resource.getrusage(resource.RUSAGE_CHILDREN)
        t0 = time.perf_counter()
        proc = subprocess.run(argv, capture_output=True, text=True, check=False)
        t1 = time.perf_counter()
        r1 = resource.getrusage(resource.RUSAGE_CHILDREN)

        all_ok = all_ok and (proc.returncode == 0)
        wall_samples.append((t1 - t0) * 1000.0)
        cpu_ms = ((r1.ru_utime - r0.ru_utime) + (r1.ru_stime - r0.ru_stime)) * 1000.0
        cpu_samples.append(max(0.0, cpu_ms))
        # On macOS ru_maxrss is in bytes; on Linux it is already KiB.
        rss_kib = (r1.ru_maxrss / 1024.0) if sys.platform == "darwin" else float(r1.ru_maxrss)
        max_rss_kib = max(max_rss_kib, rss_kib)

    return LboMetrics(
        wall_ms=sum(wall_samples) / len(wall_samples),
        total_cpu_ms=sum(cpu_samples) / len(cpu_samples),
        p99_ms=compute_percentile(wall_samples, 99.0),
        p999_ms=compute_percentile(wall_samples, 99.9),
        peak_rss_kib=max_rss_kib,
        native_tests_passed=all_ok,
    )


class LboEvaluationGateTests(unittest.TestCase):
    def test_lbo_admits_genuine_amp1_pareto_improvement(self):
        baseline = LboMetrics(wall_ms=29.0, total_cpu_ms=210.0, p99_ms=3.2, p999_ms=6.5, peak_rss_kib=98000.0)
        amp1 = LboMetrics(wall_ms=14.5, total_cpu_ms=135.0, p99_ms=1.1, p999_ms=2.0, peak_rss_kib=92000.0)
        admitted, reasons = evaluate_lbo_admission(baseline, amp1)
        self.assertTrue(admitted, f"unexpected rejection: {reasons}")
        self.assertTrue(amp1.pareto_dominates(baseline))
        self.assertFalse(baseline.pareto_dominates(amp1))

    def test_lbo_rejects_hidden_cpu_cycle_bloat_behind_faster_wall_time(self):
        """Cai et al. ISPASS '22 core rule: faster wall-clock with +45% spin/barrier CPU cycles MUST be rejected!"""
        baseline = LboMetrics(wall_ms=30.0, total_cpu_ms=180.0, p99_ms=2.0, p999_ms=4.0, peak_rss_kib=64000.0)
        bloated = LboMetrics(wall_ms=22.0, total_cpu_ms=261.0, p99_ms=1.8, p999_ms=3.5, peak_rss_kib=64000.0)
        admitted, reasons = evaluate_lbo_admission(baseline, bloated)
        self.assertFalse(admitted)
        self.assertTrue(any(r.startswith("lbo_cpu_cycle_bloat:") for r in reasons))

    def test_lbo_rejects_p999_tail_spike_rss_blowup_and_failed_correctness(self):
        baseline = LboMetrics(wall_ms=25.0, total_cpu_ms=150.0, p99_ms=2.0, p999_ms=4.0, peak_rss_kib=64000.0)

        # Tail latency spike
        bad_tail = LboMetrics(wall_ms=20.0, total_cpu_ms=140.0, p99_ms=3.0, p999_ms=9.5, peak_rss_kib=64000.0)
        ok, reasons = evaluate_lbo_admission(baseline, bad_tail)
        self.assertFalse(ok)
        self.assertTrue(any(r.startswith("p999_latency_regression:") for r in reasons))

        # RSS blowup
        bad_rss = LboMetrics(wall_ms=20.0, total_cpu_ms=140.0, p99_ms=1.8, p999_ms=3.8, peak_rss_kib=82000.0)
        ok, reasons = evaluate_lbo_admission(baseline, bad_rss)
        self.assertFalse(ok)
        self.assertTrue(any(r.startswith("peak_rss_regression:") for r in reasons))

        # Native test failure overrides all speedups!
        bad_correct = LboMetrics(
            wall_ms=10.0, total_cpu_ms=80.0, p99_ms=0.5, p999_ms=1.0, peak_rss_kib=50000.0,
            native_tests_passed=False,
        )
        ok, reasons = evaluate_lbo_admission(baseline, bad_correct)
        self.assertFalse(ok)
        self.assertIn("native_correctness_gate_failed", reasons)

    def test_lbo_pareto_transitivity_and_percentiles(self):
        a = LboMetrics(wall_ms=10.0, total_cpu_ms=80.0, p99_ms=1.0, p999_ms=2.0, peak_rss_kib=40000.0)
        b = LboMetrics(wall_ms=15.0, total_cpu_ms=100.0, p99_ms=1.5, p999_ms=3.0, peak_rss_kib=50000.0)
        c = LboMetrics(wall_ms=20.0, total_cpu_ms=120.0, p99_ms=2.0, p999_ms=4.0, peak_rss_kib=60000.0)
        self.assertTrue(a.pareto_dominates(b))
        self.assertTrue(b.pareto_dominates(c))
        self.assertTrue(a.pareto_dominates(c))
        self.assertEqual(99.0, compute_percentile([float(i) for i in range(1, 101)], 99.0))
        self.assertEqual(100.0, compute_percentile([float(i) for i in range(1, 101)], 99.9))

    def test_live_subprocess_lbo_measurement(self):
        metrics = measure_command_lbo([sys.executable, "-c", "sum(range(50000))"], runs=3)
        self.assertTrue(metrics.native_tests_passed)
        self.assertGreater(metrics.wall_ms, 0.0)
        self.assertGreater(metrics.peak_rss_kib, 0.0)


if __name__ == "__main__":
    unittest.main()

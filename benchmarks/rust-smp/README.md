# Rust SMP Benchmark Suite (Tokio + Rayon)

Top-level Rust reference implementation using **Rayon** (data-parallel work-stealing) and **Tokio** (async multi-threaded runtime + channels) paired 1:1 with Gambit Scheme's SMP multicore scaling workloads (`vendor/gambit/tests/smp/multicore/run-multicore-suite.py`).

## Storage Boundary

Build artifacts use `CARGO_TARGET_DIR=.cache/rust-smp-target` and benchmark outputs go to `.cache/benchmarks/rust-vs-gambit/` so neither Cargo build artifacts nor raw run logs enter Git or `evidence/`.

## Build & Run

```sh
# 1. Build optimized release binary into .cache/
CARGO_TARGET_DIR=.cache/rust-smp-target cargo build --release --manifest-path benchmarks/rust-smp/Cargo.toml

# 2. Run Rust standalone across 1..12 cores (full Apple M2 Pro saturation)
.cache/rust-smp-target/release/rust-smp-bench \
  --threads 1,2,4,6,8,12 --workers 12 --repeats 3 \
  --json-out .cache/benchmarks/rust-vs-gambit/rust_w12.json

# 3. Run paired Rust vs Gambit SMP comparison
python3 benchmarks/rust-smp/compare_rust_vs_gambit.py \
  --topologies p1,p2,p4,p6,p8,p12 --workers 12 --repeats 3
```

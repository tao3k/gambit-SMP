use rayon::prelude::*;
use serde::Serialize;
use std::collections::BTreeMap;
use std::hint::black_box;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Barrier};
use std::time::Instant;

// ---------------------------------------------------------------------------
// Process CPU & RSS telemetry (POSIX getrusage)
// ---------------------------------------------------------------------------

#[derive(Clone, Copy, Debug)]
struct RusageSnap {
    user_s: f64,
    sys_s: f64,
    max_rss_bytes: u64,
}

fn rusage_now() -> RusageSnap {
    unsafe {
        let mut ru: libc::rusage = std::mem::zeroed();
        libc::getrusage(libc::RUSAGE_SELF, &mut ru);
        let user_s = ru.ru_utime.tv_sec as f64 + (ru.ru_utime.tv_usec as f64) * 1e-6;
        let sys_s = ru.ru_stime.tv_sec as f64 + (ru.ru_stime.tv_usec as f64) * 1e-6;
        // On macOS ru_maxrss is in bytes; on Linux it is in KiB.
        #[cfg(target_os = "macos")]
        let max_rss_bytes = ru.ru_maxrss as u64;
        #[cfg(not(target_os = "macos"))]
        let max_rss_bytes = (ru.ru_maxrss as u64) * 1024;
        RusageSnap {
            user_s,
            sys_s,
            max_rss_bytes,
        }
    }
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct RunSample {
    work_real: f64,
    cpu_seconds: f64,
    cpu_utilization_pct: f64,
    rss_mib: f64,
    checksum: u64,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct TopoSummary {
    threads: usize,
    workers: usize,
    work_real: f64,
    p95_real: f64,
    cpu: f64,
    cpu_utilization_pct: f64,
    speedup: f64,
    efficiency: f64,
    rss_mib: f64,
    samples: Vec<RunSample>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct BenchReport {
    schema: String,
    engine: String,
    logical_cpus: usize,
    workers_mode: String,
    repeats: usize,
    topologies: Vec<String>,
    scaling_summary: BTreeMap<String, BTreeMap<String, TopoSummary>>,
}

fn median(vals: &mut [f64]) -> f64 {
    vals.sort_by(|a, b| a.total_cmp(b));
    let n = vals.len();
    if n == 0 {
        0.0
    } else if n % 2 == 1 {
        vals[n / 2]
    } else {
        0.5 * (vals[n / 2 - 1] + vals[n / 2])
    }
}

fn p95(vals: &mut [f64]) -> f64 {
    vals.sort_by(|a, b| a.total_cmp(b));
    if vals.is_empty() {
        return 0.0;
    }
    let idx = ((vals.len() as f64) * 0.95).ceil() as usize;
    vals[idx.saturating_sub(1).min(vals.len() - 1)]
}

fn round4(v: f64) -> f64 {
    (v * 10_000.0).round() / 10_000.0
}

fn round2(v: f64) -> f64 {
    (v * 100.0).round() / 100.0
}

fn measure<F: FnMut() -> u64>(mut f: F) -> RunSample {
    let r0 = rusage_now();
    let t0 = Instant::now();
    let checksum = black_box(f());
    let wall = t0.elapsed().as_secs_f64();
    let r1 = rusage_now();
    let cpu = (r1.user_s - r0.user_s) + (r1.sys_s - r0.sys_s);
    let util = if wall > 0.0 { (cpu / wall) * 100.0 } else { 0.0 };
    RunSample {
        work_real: round4(wall),
        cpu_seconds: round4(cpu.max(0.0)),
        cpu_utilization_pct: round2(util.max(0.0)),
        rss_mib: round2((r1.max_rss_bytes as f64) / (1024.0 * 1024.0)),
        checksum,
    }
}

// ---------------------------------------------------------------------------
// 1. par_compute_fib (Rayon) — 1:1 match with Gambit fib(36)
// ---------------------------------------------------------------------------

#[inline(never)]
fn fib(n: i64) -> i64 {
    if n < 2 {
        n
    } else {
        fib(n - 1) + fib(n - 2)
    }
}

fn bench_par_compute_fib(pool: &rayon::ThreadPool, workers: usize, fib_n: i64) -> u64 {
    let expected = if fib_n == 36 { 14_930_352_i64 } else { 0 };
    pool.install(|| {
        let vals: Vec<i64> = (0..workers)
            .into_par_iter()
            .map(|_| fib(black_box(fib_n)))
            .collect();
        let mut sum = 0u64;
        for v in vals {
            if expected != 0 {
                assert_eq!(v, expected, "fib mismatch");
            }
            sum = sum.wrapping_add(v as u64);
        }
        sum
    })
}

// ---------------------------------------------------------------------------
// 2. par_alloc_gc_m65536 (Rayon) — 1:1 match with Gambit churn-worker
// ---------------------------------------------------------------------------

fn churn_worker(id: usize, iters: usize) -> f64 {
    let mut acc = 0.0_f64;
    for i in 0..iters {
        let fill = (id + (i % 17)) as f64;
        let v = vec![fill; 256];
        let s_str = i.to_string();
        let tup = Box::new((i, id, v));
        let pair = Box::new((i, s_str));
        let s = tup.2[0] + tup.2[255];
        acc += s + if !pair.1.is_empty() { 1.0 } else { 0.0 };
        black_box((&tup, &pair));
    }
    acc
}

fn bench_par_alloc_churn(pool: &rayon::ThreadPool, workers: usize, iters: usize) -> u64 {
    pool.install(|| {
        let vals: Vec<f64> = (0..workers)
            .into_par_iter()
            .map(|id| churn_worker(id, iters))
            .collect();
        let mut sum = 0.0_f64;
        for v in vals {
            assert!(v > 0.0, "alloc churn mismatch");
            sum += v;
        }
        sum.to_bits()
    })
}

// ---------------------------------------------------------------------------
// 3. par_rest_alloc_m65536 (Rayon) — 1:1 match with Gambit variadic/kw rest
// ---------------------------------------------------------------------------

#[inline(never)]
fn rsum(a: i64, b: i64, rest: &[i64]) -> i64 {
    // Allocate a small heap Vec to mirror Scheme's rest-list allocation cost,
    // while keeping idiomatic Rust slice traversal.
    let heap_rest = black_box(rest.to_vec());
    let mut acc = a + b;
    for &x in &heap_rest {
        acc += x;
    }
    acc
}

#[inline(never)]
fn kwsum(a: i64, k1: Option<i64>, k2: Option<i64>, rest: &[i64]) -> i64 {
    let heap_rest = black_box(rest.to_vec());
    a + k1.unwrap_or(3) + k2.unwrap_or(5) + (heap_rest.len() as i64)
}

fn bench_par_rest_alloc(pool: &rayon::ThreadPool, workers: usize, iters: usize) -> u64 {
    let expected = (iters as i64) * 45;
    pool.install(|| {
        let vals: Vec<i64> = (0..workers)
            .into_par_iter()
            .map(|_| {
                let mut acc = 0_i64;
                for _ in 0..iters {
                    acc += rsum(1, 2, black_box(&[3, 4, 5, 6, 7, 8]))
                        + kwsum(1, Some(2), Some(4), black_box(&[9, 10]));
                }
                acc
            })
            .collect();
        let mut sum = 0u64;
        for v in vals {
            assert_eq!(v, expected, "rest mismatch");
            sum = sum.wrapping_add(v as u64);
        }
        sum
    })
}

// ---------------------------------------------------------------------------
// 4. par_gc_pause_live_heap (Rayon) — 1:1 match with Gambit 8x16384 live tree
// ---------------------------------------------------------------------------

enum LiveTree {
    Leaf {
        seed: i64,
        _next: i64,
        _pair: Box<(i64, i64)>,
        _vec: Vec<i64>,
    },
    Node(Box<LiveTree>, Box<LiveTree>),
}

fn build_live_tree(depth: u32, seed: i64) -> LiveTree {
    if depth == 0 {
        LiveTree::Leaf {
            seed,
            _next: seed + 1,
            _pair: Box::new((seed, seed + 2)),
            _vec: vec![seed; 6],
        }
    } else {
        LiveTree::Node(
            Box::new(build_live_tree(depth - 1, seed * 2 + 1)),
            Box::new(build_live_tree(depth - 1, seed * 2 + 2)),
        )
    }
}

fn sum_tree_sample(t: &LiveTree) -> i64 {
    match t {
        LiveTree::Leaf { seed, .. } => *seed,
        LiveTree::Node(l, r) => sum_tree_sample(l).wrapping_add(sum_tree_sample(r)),
    }
}

fn bench_par_live_heap(pool: &rayon::ThreadPool, workers: usize, mutator_iters: usize) -> u64 {
    // Build all live trees BEFORE timing (mirrors Gambit's barrier + (##gc) before t0).
    let trees: Vec<LiveTree> = pool.install(|| {
        (0..workers)
            .into_par_iter()
            .map(|w| build_live_tree(14, (w + 1) as i64))
            .collect()
    });
    let trees = Arc::new(trees);
    let r0 = rusage_now();
    let t0 = Instant::now();
    let checksum = pool.install(|| {
        let vals: Vec<i64> = (0..workers)
            .into_par_iter()
            .map(|w| {
                let mut s = 0_i64;
                for i in 0..mutator_iters {
                    let tmp = black_box(vec![(w + i) as i64; 64]);
                    s = s.wrapping_add(tmp[0]);
                }
                s.wrapping_add(sum_tree_sample(&trees[w]))
            })
            .collect();
        let mut total = 0u64;
        for v in vals {
            assert!(v != 0, "live heap mismatch");
            total = total.wrapping_add(v as u64);
        }
        total
    });
    let _ = (r0, t0);
    drop(trees);
    checksum
}

// Version that measures ONLY the mutator + tree-retention phase (exact match to Gambit's work_real).
fn measure_par_live_heap(pool: &rayon::ThreadPool, workers: usize, mutator_iters: usize) -> RunSample {
    let trees: Vec<LiveTree> = pool.install(|| {
        (0..workers)
            .into_par_iter()
            .map(|w| build_live_tree(14, (w + 1) as i64))
            .collect()
    });
    let sample = measure(|| {
        pool.install(|| {
            let vals: Vec<i64> = (0..workers)
                .into_par_iter()
                .map(|w| {
                    let mut s = 0_i64;
                    for i in 0..mutator_iters {
                        let tmp = black_box(vec![(w + i) as i64; 64]);
                        s = s.wrapping_add(tmp[0]);
                    }
                    s.wrapping_add(sum_tree_sample(&trees[w]))
                })
                .collect();
            let mut total = 0u64;
            for v in vals {
                assert!(v != 0, "live heap mismatch");
                total = total.wrapping_add(v as u64);
            }
            total
        })
    });
    drop(trees);
    sample
}

// ---------------------------------------------------------------------------
// 4b. par_oldgen_churn_live (Rayon) — 1:1 match with Gambit large old-gen churn
// ---------------------------------------------------------------------------

struct OldNode {
    _id: i64,
    seq: i64,
    _pair: Box<(i64, i64)>,
    payload: Vec<i64>,
}

fn make_old_node(id: i64, seq: i64) -> Box<OldNode> {
    Box::new(OldNode {
        _id: id,
        seq,
        _pair: Box::new((seq, seq + 1)),
        payload: vec![seq; 16],
    })
}

fn measure_par_oldgen_churn(pool: &rayon::ThreadPool, workers: usize, iters: usize) -> RunSample {
    const RING_LEN: usize = 4096;
    let mut rings: Vec<Vec<Box<OldNode>>> = pool.install(|| {
        (0..workers)
            .into_par_iter()
            .map(|w| {
                (0..RING_LEN)
                    .map(|i| make_old_node(w as i64, i as i64))
                    .collect()
            })
            .collect()
    });
    let sample = measure(|| {
        pool.install(|| {
            let vals: Vec<i64> = rings
                .par_iter_mut()
                .enumerate()
                .map(|(w, ring)| {
                    let mut s = 0_i64;
                    for i in 0..iters {
                        let slot = i & (RING_LEN - 1);
                        let probe = (i + 17) & (RING_LEN - 1);
                        let node = make_old_node(w as i64, (i + RING_LEN) as i64);
                        ring[slot] = black_box(node);
                        let p = &ring[probe];
                        s = s.wrapping_add(p.seq).wrapping_add(p.payload[0]);
                    }
                    s
                })
                .collect();
            let mut total = 0u64;
            for v in vals {
                assert!(v != 0, "oldgen churn mismatch");
                total = total.wrapping_add(v as u64);
            }
            total
        })
    });
    drop(rings);
    sample
}

// ---------------------------------------------------------------------------
// 5. par_sync_mailbox_cas (Tokio + AtomicU64) — 1:1 match with Gambit mailbox/CAS
// ---------------------------------------------------------------------------

fn bench_par_sync_mailbox_cas(
    rt: &tokio::runtime::Runtime,
    workers: usize,
    cas_per_worker: u64,
    msgs_per_pair: u64,
) -> u64 {
    rt.block_on(async move {
        let shared = Arc::new(AtomicU64::new(0));
        let mut handles = Vec::with_capacity(workers);
        for _ in 0..workers {
            let shared_c = Arc::clone(&shared);
            handles.push(tokio::spawn(async move {
                // Contended CAS loop (exact match to Gambit ##vector-cas! retry loop)
                for _ in 0..cas_per_worker {
                    let mut old = shared_c.load(Ordering::Relaxed);
                    loop {
                        match shared_c.compare_exchange_weak(
                            old,
                            old + 1,
                            Ordering::AcqRel,
                            Ordering::Relaxed,
                        ) {
                            Ok(_) => break,
                            Err(cur) => old = cur,
                        }
                    }
                }
                // Producer -> consumer async mailbox pair
                let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel::<u64>();
                let child = tokio::spawn(async move {
                    let mut acc = 0u64;
                    for _ in 0..msgs_per_pair {
                        acc += rx.recv().await.expect("channel closed early");
                    }
                    acc
                });
                for _ in 0..msgs_per_pair {
                    tx.send(1).expect("send failed");
                }
                let r = child.await.expect("child join failed");
                assert_eq!(r, msgs_per_pair, "mailbox mismatch");
                r
            }));
        }
        let mut msg_total = 0u64;
        for h in handles {
            msg_total += h.await.expect("worker join failed");
        }
        let final_cas = shared.load(Ordering::Acquire);
        assert_eq!(final_cas, (workers as u64) * cas_per_worker, "cas counter mismatch");
        final_cas + msg_total
    })
}

// ---------------------------------------------------------------------------
// 6. full_load_hybrid_tokio_rayon — Saturates all CPU cores with mixed async + CPU + alloc
// ---------------------------------------------------------------------------

fn bench_full_load_hybrid(
    rt: &tokio::runtime::Runtime,
    pool: &Arc<rayon::ThreadPool>,
    tasks: usize,
    fib_n: i64,
    churn_iters: usize,
) -> u64 {
    rt.block_on(async move {
        let counter = Arc::new(AtomicU64::new(0));
        let mut handles = Vec::with_capacity(tasks);
        for id in 0..tasks {
            let pool_c = Arc::clone(pool);
            let counter_c = Arc::clone(&counter);
            handles.push(tokio::spawn(async move {
                let (tx, rx) = tokio::sync::oneshot::channel::<u64>();
                pool_c.spawn(move || {
                    let f = fib(black_box(fib_n)) as u64;
                    let c = churn_worker(id, churn_iters).to_bits();
                    counter_c.fetch_add(1, Ordering::Relaxed);
                    let _ = tx.send(f ^ c);
                });
                rx.await.expect("rayon oneshot dropped")
            }));
        }
        let mut acc = 0u64;
        for h in handles {
            acc ^= h.await.expect("hybrid join failed");
        }
        assert_eq!(counter.load(Ordering::Acquire), tasks as u64);
        acc
    })
}

// ---------------------------------------------------------------------------
// CLI & Runner
// ---------------------------------------------------------------------------

struct Args {
    threads: Vec<usize>,
    workers: usize,
    repeats: usize,
    scale_workers_to_threads: bool,
    full_load: bool,
    json_out: Option<String>,
}

fn parse_args() -> Args {
    let ncpu = std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(8);
    let mut threads: Vec<usize> = vec![1, 2, 4, 6, 8, ncpu]
        .into_iter()
        .filter(|&t| t <= ncpu)
        .collect();
    threads.sort_unstable();
    threads.dedup();

    let mut workers = 8usize;
    let mut repeats = 3usize;
    let mut scale_workers_to_threads = false;
    let mut full_load = true;
    let mut json_out = None;

    let mut it = std::env::args().skip(1);
    while let Some(arg) = it.next() {
        match arg.as_str() {
            "--threads" => {
                let v = it.next().expect("--threads requires value");
                threads = v
                    .split(',')
                    .filter(|s| !s.is_empty())
                    .map(|s| s.trim().trim_start_matches('p').parse::<usize>().expect("invalid thread count"))
                    .collect();
            }
            "--workers" => {
                workers = it.next().expect("--workers requires value").parse().expect("invalid --workers");
            }
            "--repeats" => {
                repeats = it.next().expect("--repeats requires value").parse().expect("invalid --repeats");
            }
            "--match-workers-to-max-threads" => {
                scale_workers_to_threads = true;
            }
            "--no-full-load" => {
                full_load = false;
            }
            "--json-out" => {
                json_out = Some(it.next().expect("--json-out requires value"));
            }
            "--help" | "-h" => {
                eprintln!(
                    "Usage: rust-smp-bench [--threads 1,2,4,6,8,12] [--workers 8] [--repeats 3] [--match-workers-to-max-threads] [--no-full-load] [--json-out PATH]"
                );
                std::process::exit(0);
            }
            other => {
                eprintln!("Unknown argument: {other}");
                std::process::exit(2);
            }
        }
    }
    if scale_workers_to_threads {
        if let Some(&max_t) = threads.iter().max() {
            workers = max_t;
        }
    }
    Args {
        threads,
        workers,
        repeats,
        scale_workers_to_threads,
        full_load,
        json_out,
    }
}

fn main() {
    let args = parse_args();
    let ncpu = std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(8);

    // Silence unused helper warning
    let _ = (bench_par_live_heap as fn(&rayon::ThreadPool, usize, usize) -> u64, Barrier::new);

    println!(
        "=== Rust SMP Benchmark Suite (Rayon + Tokio) | CPUs={ncpu} | workers={} | repeats={} | topologies={:?} ===",
        args.workers, args.repeats, args.threads
    );

    let mut workloads: Vec<&str> = vec![
        "par_compute_fib",
        "par_alloc_gc_m65536",
        "par_rest_alloc_m65536",
        "par_gc_pause_live_heap",
        "par_oldgen_churn_live",
        "par_sync_mailbox_cas",
    ];
    if args.full_load {
        workloads.push("full_load_hybrid_tokio_rayon");
    }

    let mut scaling_summary: BTreeMap<String, BTreeMap<String, TopoSummary>> = BTreeMap::new();

    for wname in workloads {
        let mut by_topo: BTreeMap<String, TopoSummary> = BTreeMap::new();
        let mut p1_med: Option<f64> = None;

        for &t in &args.threads {
            let pool = Arc::new(
                rayon::ThreadPoolBuilder::new()
                    .num_threads(t)
                    .build()
                    .expect("failed to build rayon pool"),
            );
            let rt = tokio::runtime::Builder::new_multi_thread()
                .worker_threads(t)
                .enable_all()
                .build()
                .expect("failed to build tokio runtime");

            // Warmup 1 iteration for thread-pool spinup / allocator arenas
            match wname {
                "par_compute_fib" => {
                    bench_par_compute_fib(&pool, args.workers.min(t.max(1)), 28);
                }
                "par_alloc_gc_m65536" => {
                    bench_par_alloc_churn(&pool, args.workers, 200);
                }
                "par_rest_alloc_m65536" => {
                    bench_par_rest_alloc(&pool, args.workers, 500);
                }
                "par_gc_pause_live_heap" => {
                    let _ = measure_par_live_heap(&pool, 2, 1000);
                }
                "par_oldgen_churn_live" => {
                    let _ = measure_par_oldgen_churn(&pool, 2, 500);
                }
                "par_sync_mailbox_cas" => {
                    bench_par_sync_mailbox_cas(&rt, args.workers, 500, 200);
                }
                "full_load_hybrid_tokio_rayon" => {
                    bench_full_load_hybrid(&rt, &pool, ncpu, 26, 200);
                }
                _ => unreachable!(),
            }

            let mut samples = Vec::with_capacity(args.repeats);
            for _ in 0..args.repeats {
                let s = match wname {
                    "par_compute_fib" => measure(|| bench_par_compute_fib(&pool, args.workers, 36)),
                    "par_alloc_gc_m65536" => measure(|| bench_par_alloc_churn(&pool, args.workers, 25_000)),
                    "par_rest_alloc_m65536" => measure(|| bench_par_rest_alloc(&pool, args.workers, 120_000)),
                    "par_gc_pause_live_heap" => measure_par_live_heap(&pool, args.workers, 150_000),
                    "par_oldgen_churn_live" => measure_par_oldgen_churn(&pool, args.workers, 40_000),
                    "par_sync_mailbox_cas" => {
                        measure(|| bench_par_sync_mailbox_cas(&rt, args.workers, 15_000, 4_000))
                    }
                    "full_load_hybrid_tokio_rayon" => {
                        // Heavy full-machine load: 2 * ncpu tasks (24 tasks on 12-core M2 Pro)
                        measure(|| bench_full_load_hybrid(&rt, &pool, ncpu * 2, 37, 10_000))
                    }
                    _ => unreachable!(),
                };
                samples.push(s);
            }

            let mut walls: Vec<f64> = samples.iter().map(|s| s.work_real).collect();
            let mut cpus: Vec<f64> = samples.iter().map(|s| s.cpu_seconds).collect();
            let mut utils: Vec<f64> = samples.iter().map(|s| s.cpu_utilization_pct).collect();
            let med_wall = round4(median(&mut walls));
            let p95_wall = round4(p95(&mut walls));
            let med_cpu = round4(median(&mut cpus));
            let med_util = round2(median(&mut utils));
            let max_rss = samples
                .iter()
                .map(|s| s.rss_mib)
                .fold(0.0_f64, f64::max);

            if t == 1 && med_wall > 0.0 {
                p1_med = Some(med_wall);
            }
            let speedup = match p1_med {
                Some(b) if med_wall > 0.0 => round2(b / med_wall),
                _ => 1.0,
            };
            let efficiency = round2(speedup / (t as f64));
            let topo_key = format!("p{t}");
            let effective_workers = if wname == "full_load_hybrid_tokio_rayon" {
                ncpu * 2
            } else {
                args.workers
            };

            println!(
                "[RUST] {wname:28} {topo_key:3}: work={med_wall:.4}s p95={p95_wall:.4}s cpu={med_cpu:.3}s ({med_util:6.1}%) S={speedup:5.2}x E={efficiency:.2} rss={max_rss:.1}MiB"
            );

            by_topo.insert(
                topo_key,
                TopoSummary {
                    threads: t,
                    workers: effective_workers,
                    work_real: med_wall,
                    p95_real: p95_wall,
                    cpu: med_cpu,
                    cpu_utilization_pct: med_util,
                    speedup,
                    efficiency,
                    rss_mib: max_rss,
                    samples,
                },
            );
        }
        scaling_summary.insert(wname.to_string(), by_topo);
    }

    let report = BenchReport {
        schema: "rust-smp-bench.v1".to_string(),
        engine: "rust-rayon-tokio".to_string(),
        logical_cpus: ncpu,
        workers_mode: if args.scale_workers_to_threads {
            format!("scaled-to-max-threads({})", args.workers)
        } else {
            format!("fixed({})", args.workers)
        },
        repeats: args.repeats,
        topologies: args.threads.iter().map(|t| format!("p{t}")).collect(),
        scaling_summary,
    };

    if let Some(path) = args.json_out {
        let p = std::path::Path::new(&path);
        if let Some(parent) = p.parent() {
            std::fs::create_dir_all(parent).expect("create json parent dir");
        }
        std::fs::write(p, serde_json::to_string_pretty(&report).unwrap() + "\n")
            .expect("write json report");
        println!("Wrote Rust benchmark report to {path}");
    }
}

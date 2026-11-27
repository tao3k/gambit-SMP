# Weak-Memory Work-Stealing (PPoPP 2013) & Balanced Polling (FPCA 1993)

Sources:
- [Lê, Pop, Cohen, and Zappa Nardelli (PPoPP 2013): *Correct and Efficient Work-Stealing for Weak Memory Models*](https://fzn.fr/readings/ppopp13.pdf)
- [Feeley (FPCA 1993): *Polling Efficiently on Stock Hardware*](https://www-labs.iro.umontreal.ca/~feeley/papers/FeeleyFPCA93.pdf)

Reviewed PDF identities: `evidence/papers-modern-gc-architecture.lock.json`, `le-chase-lev-ppopp-2013` and `feeley-polling-fpca-1993`.
These are repository-owned analysis notes, not the papers' full text.

## Protocol Obligations By Paper & Section

### Lê et al. (PPoPP 2013): C11/ARM Weak-Memory Chase-Lev Deque
- **Four correctness criteria (§2.1)**: LIFO local `take`, well-defined reads, uniqueness (no task executed twice), and existence (every pushed task eventually taken or stolen).
- **Exact minimal C11 atomic ordering (`Figure 1`, §2.2)**:
  - `push(q, x)`: relaxed load `bottom`, acquire load `top`, relaxed buffer store, **`atomic_thread_fence(memory_order_release)`**, relaxed store `bottom = b + 1`.
  - `take(q)`: relaxed decrement `bottom = b`, **`atomic_thread_fence(memory_order_seq_cst)`**, relaxed load `top`. Only when `t == b` (last element) does `take` execute `compare_exchange_strong(&q->top, &t, t + 1, seq_cst, relaxed)` to resolve the race against concurrent `steal`.
  - `steal(q)`: acquire load `top`, **`atomic_thread_fence(memory_order_seq_cst)`**, acquire load `bottom`, consume/acquire load `array`, relaxed load `buffer[t % size]`, `compare_exchange_strong(&q->top, &t, t + 1, seq_cst, relaxed)`.
- **Critical weak-memory pitfall (§2.1, §4)**: On ARM64/POWER/PSO, removing either `seq_cst` fence between `store(bottom)`/`load(top)` in `take` and `load(top)`/`load(bottom)` in `steal` allows both owner and thief to read stale indices simultaneously, causing **duplicate execution or lost tasks** on single-element deques. Conversely, naive full `seq_cst` on every access inserts redundant `dmb` barriers on ARM and `mfence` on x86.

### Feeley (FPCA 1993): Balanced Polling for Bounded Interrupt / Safepoint Latency
- **Explicit polling vs hardware traps (§1.1–1.2)**: Explicit polling stays in user space, keeps critical sections trivial (never emit polls inside inconsistent allocation/tag-manipulation sequences), and preserves portability across OSes.
- **Balanced polling invariants (§5, Figure 5)**:
  - Rather than call-return polling (which incurs 70%–400% higher overhead on short-lived Scheme procedures and divide-and-conquer base cases, §4), balanced polling maintains two compile-time grace parameters `E` (entry grace) and `R` (reduction/tail-call grace), empirically balanced at `E = R = floor(L_max / 6)` (§5.2).
  - Guarantees an upper bound `L_max` instructions between consecutive interrupt checks across arbitrary subproblem calls, tail-call chains, and recursive return unwinding (`length-even?` example §3.2).

## Gambit SMP Correspondence & Source Differences

- **Balanced polling -> STW safepoint arrival & opportunistic spin**:
  - Gambit's `___POLL` macro directly implements Feeley FPCA '93 balanced polling. When a core requests a STW minor GC or concurrent-major remark handshake, peer cores arrive within bounded instruction count `L_max` — *except* when blocked in foreign C calls (`___EXT` / OS I/O) or descheduled by the OS (hybrid 8P+4E E-cores).
  - Combining Feeley's bounded user-space polling with OCaml 5's opportunistic major-slice spin callback (`domain.c:enter_spin_callback`) ensures fast cores waiting for a straggler never waste cycles while preserving bounded safepoint latency.
- **Work-stealing deque -> Parallel GC mark-stack stealing & Gerbil task schedulers**:
  - Gambit's current parallel GC chunk queues (`mem.c`) and thread runqueues use mutex-guarded structures rather than lock-free Chase-Lev deques. Any future lock-free mark-work stealing deque or Gerbil work-stealing executor MUST preserve Lê et al.'s Figure 1 `release`/`seq_cst` fence pairing (especially on Apple Silicon ARM64!) and verify every fence removal as a killed CBMC `--mm pso` mutant.

## Formal Model Obligations & Non-Import Boundaries

- **Non-import boundaries**:
  - Do **not** translate Lê et al.'s ARMv7 hand-tuned inline assembly (`ctrl_isync` / `LL/SC`, Figure 2) directly into portable C23 runtime code; use the proven C11/C23 Figure 1 atomic sequence and verify under CBMC `--mm pso` / TSan.
  - Do **not** remove return-path polling checks in Gambit's C backend without re-proving Feeley §3.2's bounded unwinding latency `L_max`.

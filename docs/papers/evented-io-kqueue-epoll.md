# Evented SMP I/O Reactors: Kqueue (USENIX ATC 2001) & Epoll Evaluation (OLS 2004)

Sources:
- [Jonathan Lemon (USENIX ATC 2001): *Kqueue: A Generic and Scalable Event Notification Facility*](https://www.usenix.org/legacy/events/usenix01/freenix01/full_papers/lemon/lemon.pdf)
- [Louay Gammo, Tim Brecht, Amol Shukla, and David Pariag (OLS 2004): *Comparing and Evaluating epoll, select, and poll Event Mechanisms*](https://www.kernel.org/doc/ols/2004/ols2004v1-pages-215-226.pdf)

Reviewed PDF identities: `evidence/papers-modern-gc-architecture.lock.json`, `lemon-kqueue-usenix-2001` and `gammo-epoll-ols-2004`.
These are repository-owned analysis notes, not the papers' full text.

## Protocol Obligations By Paper & Section

### Lemon (USENIX ATC 2001): Stateful Persistent Interest & Coalesced Level-Triggered Delivery
- **Why stateless `select()`/`poll()` fail at scale (§2)**: When sleeping on large descriptor sets, stateless interfaces incur **three O(N) passes** (kernel registration scan + wakeup scan + userspace scan) and two user/kernel copies per wait; in production servers ~95% of descriptors are idle.
- **Batched stateful `kevent()` API (§3–4, Figures 1–2)**:
  - Combines interest updates (`changelist`) and readiness retrieval (`eventlist`) in one syscall, avoiding per-FD `ctl` syscall amplification.
  - Level-triggered semantics by default preserve partial-read correctness identical to `select`/`poll` (no silent event loss if fewer than `data` bytes are read).
  - Pre-existing pending data is detected immediately on `EV_ADD` registration (closing the registration-vs-arrival race).
  - Closing a file descriptor automatically deletes attached knotes from the kqueue (§3 p.3, §6), preventing stale notifications after FD reuse — though **in-flight userspace event batches** still require explicit userspace custody fencing before `close(fd)`.

### Gammo et al. (OLS 2004): `epoll_ctl` Syscall Overhead Trap & Idle-Connection Scaling
- **Active-only caveat (§3, §5 Table 1)**: With zero idle connections (`22,000 req/s` one-byte workload), naive level-triggered `epoll-LT` spent **16.34%** of runtime in `epoll_ctl` plus **7.15%** in `epoll_wait` (23.49% combined) vs **13.33%** for `select`/`poll`!
- **Idle-connection scaling (§5.1, Figures 5–6)**: Once 10,000 idle connections are present, `select()` and `poll()` collapse linearly while `epoll` stays `O(ready)`.
- **Explicit delete before `close(fd)` (§3 p.218)**: Relying on implicit `close()` cleanup increased `close()` kernel time; explicitly unregistering via `epoll_ctl(EPOLL_CTL_DEL)` before closing kept removal deterministic and avoided FD-reuse hazards.
- **Design takeaway**: Keep persistent interest registration (`epoll_ctl` once on open / rare interest change, NOT on every read/write cycle) and prefer level-triggered or explicit one-shot semantics aligned with Gambit's condvar-select wait loop.

## Gambit SMP Correspondence & Source Differences

- Gambit's `lib/os_io.c` currently relies on `select()`/`poll()` with a hardened userspace `select_active` acquire/release fence across BOTH poll wait and post-poll device inspection before `close(fd)` (Slice 2.5).
- For **Slice 3B (Evented SMP I/O Reactor)** on macOS (`kqueue` + `EVFILT_USER` wakeup) and Linux (`epoll` + `eventfd` wakeup):
  1. Batch descriptor interest changes into `kevent(..., changelist, ...)` on Darwin/BSD, and amortize `epoll_ctl` on Linux so active small-FD workloads never regress below `poll()`.
  2. Never rely solely on kernel auto-removal at `close(fd)` to protect userspace `dgroup` / device pointers carried in `udata`/`epoll_data`: retain Gambit's userspace `select_active` drain fence before freeing device structs or closing the FD!

## Formal Model Obligations & Non-Import Boundaries

- **Existing sibling model anchors**: `evented_io_reactor_park_v2.qnt`, `per_domain_rest_slab_and_io_check_v2.qnt`, `per_domain_rest_slab_and_io_check_pso.c`, and `SmpIoSelectCloseRefinement.lean`.
- **Non-import boundaries**:
  - Do **not** adopt edge-triggered `EPOLLET` without a full userspace readiness state machine (Gammo §5 reports ~2% extra state tracking overhead plus starvation/missed-wakeup hazards under partial reads).
  - Do **not** skip explicit userspace device-custody fencing before `close(fd)` on the assumption that kernel knote/epoll auto-removal prevents userspace UAF on concurrently retrieved event arrays.

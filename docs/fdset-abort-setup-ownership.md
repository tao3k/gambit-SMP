# FD-Set And Select-Abort Setup Ownership

## Source Finding And Decision

The preceding descriptor rollback repair does not release fd-set storage.
lib/os_io.c:fdset_init clears the three pointers, then fdset_realloc allocates
read/write and optional except storage. A successful bank allocation precedes
pipe creation and both nonblocking settings. If any later step fails, setup
returns an error without releasing that bank. setup_os_and_mem_pstate cleans
OS resources only after successful OS setup followed by memory setup failure;
it cannot repair this earlier partial OS failure.

Normal cleanup_io_pstate only closes the select-abort pipe/event. No fd-set
release is paired there, so successful teardown/reuse also loses the bank.
Adding release after the current ready-based early return would still miss
failed, unready setup. This is POSIX memory ownership, not Darwin-only cost or
an explanation of a historical GC crash.

Existing pstate setup/resource models abstract OS setup and require helper-owned
failure rollback. Existing public cleanup readiness models represent the abort
resource, not this independent memory bank. This model closes that specific
contract gap. Expected benefit is leak-free setup/teardown; no speedup is claimed.

## Proposed Source Rule

Use the existing fdset_realloc(ps,0) operation, which allocates nothing, frees
owned buffers, assigns NULL to their fields and resets size. Invoke it on late
POSIX setup failure and on normal POSIX cleanup independently of the abort-ready
flag. Change that early return to a conditional abort-resource close, preserving
the existing atomic readiness ownership and drained-user premise. Do not add
new state fields, heap allocators, public APIs or locks.

## Model Scope

The model covers two/three buffer banks, async abort enabled/disabled, failure
at each actual allocation, pipe creation, write-fcntl and read-fcntl, success and
two cleanup calls. Allocation-helper partial rollback is explicit; a successful
bank transfers from scratch ownership to PSTATE ownership. Controls separately
omit bank cleanup, gate failed-setup cleanup on abort readiness, or free without
clearing the ownership fields. Counts are resource parts, never CPU limits.

Assumptions include exclusive setup/cleanup ownership and previously drained
resource users. It does not prove allocator/OS internals, arbitrary repeated
setup without cleanup, concurrent destruction, fd-set resize barriers, C memory
ordering or real fault reachability. Windows has no POSIX bank and remains out
of this finite bank model. No runtime injection/private cleanup call is used.

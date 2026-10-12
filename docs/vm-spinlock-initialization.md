# VM Spinlock Prefix Ownership

## Route Review

The source has two VM-level initialization calls before scan resources and heap
acquisition: `misc_mem_lock` and `alloc_mem_lock`. The previous VM model did not
track their alternative mutex-backed ownership. This is a correctness boundary,
not proof of a selected-backend performance issue or the historical SMP crash.
No unchanged native failure is rerun.

The configured header selects ticket locks unless `___USE_MUTEX_FOR_SPINLOCK` is
defined. Ticket initialization sets counters; destruction has no external resource
to release. The optional mutex implementation inherits POSIX boolean or platform
void initialization semantics. A failure control on the POSIX mutex backend must
not be reported as a failure of the currently selected ticket backend.

`vm_spinlock_initialization.qnt` covers threaded on/off and ticket, POSIX mutex and
normally returning void mutex backends. Independent controls check first-init
failure, second-init failure and a proposed unconditional destructor. The positive
unimplemented prefix transaction returns both ready locks, or releases only the
successful owned mutexes. It assumes returning primitives and successful
destruction, excludes users/contention, and does not prove platform ABI or memory
ordering. P0's heap-chunk scan spinlock remains a separate obligation.

The VM memory constructor now consumes that checked-prefix contract and tracks
mutex-backed spin ownership through later root/scan/heap failure. Spin mutexes are
released last after the later initialized resources, not forgotten after prefix
success. This is an abstract composition, not evidence that the checked prefix
has been implemented in `mem.c`. Constructor source/native correspondence remains
pending.

Campaign001 rejected three controls and checked safety plus temporal progress:
47 distinct / 65 generated states, zero queued, 25.242 seconds for the positive
check. Inputs and model stayed stable. Portable evidence is under
`evidence/model-results/vm-spinlock-initialization-model/`. This verifies the
bounded prefix contract, not a C implementation or real pthread error injection.

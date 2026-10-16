# Single-workspace retention

Build workspaces, reusable active products and historical evidence have separate
lifetimes. A ROOT-owned in-place workspace is exclusively leased by the existing
sealed kernel. It is not Working's workspace. Intermediate build generations
are recorded by the existing workspace-state journal, not copied as complete
historical build trees. Switching candidates requires exact pinned source bytes
and the build system's clean/regeneration protocol; stale generated C is not a
source match. A single source-regenerated core is not two-pass bootstrap.

Historical receipts, original exits, failures, budgets, traces and source bindings
remain unchanged. Only explicitly selected inactive copies may be retired.
The storage primitive checks process use, Git ownership, quarantine, the same
workspace lease, source inode and complete before/after file inventories.
Unknown files are archived, never guessed to be cache. Exact caller-reviewed
source SHA bindings can omit reproducible source bytes from the archive; JSON,
logs, stdout and stderr cannot be declared disposable this way. Fixed Git
revision/overlay bindings must accompany such retirement. This is trusted-host
filesystem maintenance, not inference, native admission or authorization.

The first retirement selects only three ROOT source reproductions. Its source
bindings and original materialization JSON are under
`evidence/source-results/workspace-retention/036`. All 6261 omitted source files
were compared against the pinned Git archive plus candidate overlay. 6279 regular
files are inventoried, 321908972 logical source bytes retired and 65439 bytes
archived. These are logical sizes, not measured APFS disk savings. Working's
directories and all 64 captured historical view references are untouched.

The isolated build 034 failed at the legacy two-tree capacity guard. The new
single-workspace build 036 adopted the current source, then correctly refused
duplicate configuration because a new matching Darwin completed bootstrap had
been registered. Both failures, raw stage logs and receipts are archived without
changing their hashes. No guard was bypassed and no execution budget was raised.

The current producer is bound to source-lock SHA
`316c87a64b5fd16f588141e2601fcce16f38ec88a4e7b7831baffe9467093c52`.
Four active products are retained locally with exact hashes in
`current-products.json`: gsc, gsi, libgambit.a and gambit.h. Capture rechecked the
complete producer before and after copy-on-write transfer. This does not make
the four files a complete relocated runtime or establish GC/FFI, lifecycle or
performance acceptance.

Remaining contracts are explicit custody reconstruction for the unavailable
baseline and a source-bound minimal execution-product closure for consumers.
The current completed-runtime interface requires a complete live tree; it must
not be fooled with a partial directory, aliases, deleted producer references,
weaker hashes or a new untyped runner. Matching performance remains blocked
until independently qualified baseline and candidate products can be consumed.

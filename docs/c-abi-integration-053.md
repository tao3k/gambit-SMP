# Compiled Algorithm Integration

The current architectural direction supersedes the forward-looking instruction
in `rust-consumer-graph-051.md` to implement remaining closures and component
algorithms directly in Rust. That file and its wheel/receipt identities remain
historical observations; they are not rewritten or upgraded by this change.

The primary route is an existing compiled algorithm's C ABI, upstream
`gerbil-scheme-rust` owned-value/callable/state conversions and lifecycle,
a thin Rust host, and Python transport. Do not create a Rust Scheme interpreter,
rewrite algorithms merely because the host is Rust, or substitute generated Rust
closures for missing C exports. Python owns no inference semantics.

The upstream `gerbil_scheme_owned.h` and `c_abi` feature specify independent
immutable results, compiled callback captures, transactional component replacement,
owner-thread execution and exact-once release. Generic C tests validate this
contract; they are not the actual catalog/review/history producer.

ASCENT's existing `bindings/c/runtime.c` initializes Scheme with `___setup` before
calling `ascent_scheme_dispatch`. Thus its present rich-DSL C ABI cannot be reused
on the no-VM path unchanged. A `.c` file or function pointer is not evidence of
VM independence. This is a producer capability gap, not permission to skip
initialization, enable fallback, or fabricate a successful DSL result.

The 051 installed wheel remains a separate local artifact. No 053 ASCENT wheel,
complete consumer pass, sealed-review pass, fresh current graph, speedup or Git
publication is established by this bridge work. Original failure receipts and
execution budgets remain in force. New qualification must bind the actual
VM-independent producer exports, fixed wheel bytes, full source inventories and
real downstream DSL behavior before any of these gates can be closed.

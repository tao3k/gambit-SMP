# GC Paper To Current Source Refinement

## Reading Status

OCaml ICFP 2020 sections 3.1-3.5 and 4.1-4.4 were read in sequence, plus
section 5.4 and the evaluation setup/sequential-throughput passage in 6.1.
The remaining language-feature and evaluation sections are not close-read.
Primary paper: https://kcsrk.info/papers/retro-parallel_icfp_20.pdf
GHC ISMM 2008 sections 3.1 and 3.3-3.5 were re-read from the existing cached,
SHA-checked paper. Chez's fixed `c/gc.c:123-185` was re-read, not all generated
collector code. No new model branch was introduced.

## Applicable Questions, Not Imported Answers

The OCaml paper supplies three useful discriminators: a claimed intermediate
state before publishing forwarding; servicing interrupts while waiting for
remote promotion; and root marking before fiber resume. Its major collector
also drains departing domains' work. These are protocol questions for Gambit,
not interchangeable layouts. Its concurrent minor collector prohibits cross
minor-heap pointers, unlike the parallel alternative. Gambit VM compatibility
must be established independently. Section 6 uses an older x86-64 system and
controls scheduling/frequency; it cannot predict this machine's speedup.

| Exact current-source bytes | Difference and required counterexample | Design decision |
| --- | --- | --- |
| `lib/mem.c:3740-3795` | Forwarding CAS precedes copy; a returned address alone does not imply readable destination payload. GHC/OCaml claim states differ. | Audit actual destination consumers and export eligibility; do not add a header lock merely to resemble a paper. |
| `lib/c_intf.c:1683-1727` | Foreign release clears fields before callback; ordinary pointer data remains under C ownership. | Distinguish stable malloc payload from borrowed movable Scheme pointers and callbacks. A stable-payload fixture cannot qualify all FFI. |
| `lib/_thread.scm:3190-3207` | Donor thread root retained while collective synchronization is serviced; processor target publication has thread ownership. | This is processor migration within the current representation, not evidence of an arbitrary cross-VM continuation API. |
| `lib/mem.c:4013-4298` | Representation-specific frame/continuation traversal. | Reuse existing root/epoch models; validate detached roots and producer-owned links against real execution. |
| Chez `c/gc.c:123-185` | Owner routing permits repeated remote re-sweep and has specific bitmap visibility conditions. | Preserve repeated-sweep controls; do not import owner routing without measuring its traffic and scan costs. |

All three Gambit files above were independently rehashed and matched the
`candidateSha256` entries in the declared Darwin candidate lock:

- `lib/mem.c`: `38b69316dc682ac6771904a976af00547f9c628a78752e6448d3f1171be53dcd`
- `lib/c_intf.c`: `ceff0ccde038fa1a1f480253d8beda81168b026a71b5ea2eb7a614de9afa8954`
- `lib/_thread.scm`: `0250e820e99119e15a37f0f77328244374b43baa04cda4ad862e161deb197541`

The byte-identical archived source is a source reference, not a reused binary.
Chez `gc.c` matches its fixed source manifest. Cached GHC PDF SHA is
`d4fb03654550c99960616fb72098639dedc9bba0783e6bede44bbb63764a3f10`.
The remote OCaml reading is paper-version/URL bound, not a new locally hashed
source checkout or a full-paper reading receipt.

## Real Execution Boundary

`.data/experimental-scheme-ffi-005` executed the new sealed framework with
request-local leased identity reuse. Actual whole time was 3.255/20 seconds,
exit 2, no timeout. Source reuse was DENY because inspection of the completed
producer reported drift. Producer reuse and FFI compilation were BLOCKED.
The old producer, source lock, source SHA and all failed runs are unchanged.
Working owns the historical archive/custody repair and received the exact
finding; no reply, interrupted build or duplicate framework repair was requested.

Do not bypass this with a direct binary invocation, reconstructed receipt,
ignored source check or increased cap. A changed, hash-bound provenance repair
must be reviewed before the next actual compiled fixture run. No three-flag
runtime, Scheme/C FFI or GC performance acceptance follows from this attempt.

## Performance Preconditions

There is no implemented alternative collector in this study. Therefore a
baseline-versus-candidate collector speed comparison would currently be false.
The first experiment remains stable C payload across real Scheme collections;
then qualify movable borrowing/callback retirement separately. Record exact
binary/configuration and all three observed flags, original budgets, workload
bytes, heap/VM/processor topology and failure inventory. Keep pauses, throughput,
CPU, RSS and FFI crossing latency distinct from framework validation cost.

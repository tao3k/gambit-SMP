# Shared-runtime VM entry audit

## Scope and identity

Read-only audit; no Gambit configure, compilation, source modification, or
new wheel qualification was performed. This is a capability observation, not
multi-VM acceptance.

- Bridge checkout HEAD: `2c82b845c141ce68147cf74cb5a4ec680c6ffb07`, with existing
  staged bridge changes preserved.
- Installed SDK: `/opt/homebrew/opt/gerbil-scheme@0.19/1cfb032`.
- `gsc -v`: Gambit `ea114fc`; configured with `--enable-multiple-vms` and
  `--enable-smp`, without `--enable-multiple-threaded-vms`.
- Installed `include/gambit.h` SHA256:
  `8257ff05aadb634e2ef2532f7e1a21608a828c4adae35cf88276b78e7efff1e5`.
- Existing dual-backend ledger wheel 024 SHA256:
  `cb4458a04ab0a3ddcd5643ab0b18c91f5571c720464a7f04ae491446c8febf15`.

## Independent facts

The configured processor ceiling is one **per VM**, not one per process.
SMP selects the Scheme scheduler; it does not imply OS-thread VM selection.
The maintainer explains these independent settings at:
https://mailman.iro.umontreal.ca/pipermail/gambit-list/2020-March/009358.html

The installed header's single-threaded-VM branch, lines 8622-8627, selects
`vmstate0.aligned_pstate[0].pstate`; `___SET_REAL_PSTATE(ps)` is empty.
Lines 8723-8741 select implicit processor-state lookup and erase `___PSD`.
Consequently the public `___call` declaration at line 14897 does not carry an
explicit processor-state argument in this build. `___run` at line 14903 takes
only a thunk. Generated `___BEGIN_SFUN*` entries likewise obtain their state
from `___PSTATE`; adding Rust owner threads does not change this ABI.

`nm` of installed wheel 024's `gerbil_ledger/_core.abi3.so` shows local
`___setup_vmstate`, `___cleanup_vmstate`, `___call`, and `___run` implementations.
The same symbol search found no `___get_tls_ptr` or `___set_tls_ptr` symbol.
Symbol presence alone is not a callable contract or proof of isolation.

The existing instance probe loads separate runtime images. Its independent
global states and parallel execution are not shared-runtime VM qualification.
The Python bridge still initializes a process-global `GerbilRuntime` and
rejects a second live instance; removing that guard does not fix entry selection.

## Remaining capability boundary

No supported per-owner VM selector has been established for this installed
ABI. VM-state allocation is insufficient: module/global initialization,
root ownership, all call/conversion paths, and independent teardown must also
use that VM. Recompiling only a bridge with different Gambit ABI macros is not
a compatible fix. Neither a shared mutable selector nor serialized VM entry
qualifies simultaneous independent VM execution.

The requested installed-wheel multi-VM and ASCENT Scheme acceptance remains
unqualified. Under the prohibition on modifying or rebuilding Gambit, a
supported existing runtime entry capability must first be identified. No
fallback to independent images, process workers, or VM0 aliases is admitted.
All earlier failures and receipts remain unchanged.
